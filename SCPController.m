/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */
 
#import "SCPController.h"
#import "SCPTransfer.h"
#import "NSString(SSHAdditions).h"

#include <sys/types.h>
#include <sys/file.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <dirent.h>
#include <fcntl.h>
#include <pwd.h>
#include <unistd.h>
#include <string.h>
#include <util.h>
#include "keychain.h"

#define UPLOAD		0
#define	DOWNLOAD	1

extern char		**environ;

@implementation SCPController

static int		SCPTYPE = 0;

+ ( SCPController * )sharedInstance
{
    SCPController	*sharedInstance = [[ SCPController alloc ] init ];
    return( [ sharedInstance autorelease ] );
}

- ( id )init
{
    scp = [[ SCPTransfer alloc ] init ];
    scppid = 0;
    bytescopied = 0.0;
    return (( self = [ super init ] ) ? self : nil );
}

- ( void )awakeFromNib
{
    [ localFileImageView setDelegate: self ];
    [ localFileField setDelegate: self ];
}

- ( id )delegate
{
    return( _scpDelegate );
}

- ( void )setDelegate: ( id )delegate
{
    if ( delegate == nil ) {
        [ NSException raise: NSInternalInconsistencyException
                        format: @"delegate parameter cannot be nil" ];
        return;
    }
    _scpDelegate = delegate;
}

- ( void )getSecureCopyWindowForFile: ( NSString * )filename
            scpType: ( int )scpType copyToPath: ( NSString * )destPath
            fromHost: ( NSString * )rhost userName: ( NSString * )user
            delegate: ( id )delegate
{
    NSUserDefaults	*defaults;
    NSArray		*rscps, *favs;
    int			i;
    
    [ self setFirstPasswordPrompt: YES ];
    [ self setGotPasswordFromKeychain: NO ];
    if ( delegate != nil ) {
        [ self setDelegate: delegate ];
    }
    
    defaults = [ NSUserDefaults standardUserDefaults ];
    rscps = [ defaults objectForKey: @"recentscps" ];
    favs = [ defaults objectForKey: @"Favorites" ];
    
    [ recentCopiesList removeAllItems ];
    [ recentCopiesList addItemWithTitle: @"Recent Copies" ];
    [ recentCopiesList addItemsWithTitles: (( rscps == nil )
                                        ? [ NSArray arrayWithObject: @"" ] : rscps )];
    [ recentCopiesList setAction: @selector( selectFromRecentSCPs: ) ];
    [ destServerField setStringValue: rhost ];
    
    /*
     * since I was foolish and made favorites in
     * early releases just NSStrings, we have to extract the
     * relevant information depending on the type of favorite
     * we're dealing with.
     */
    for ( i = 0; i < [ favs count ]; i++ ) {
        id		favobj = nil;
        
        if ( [[ favs objectAtIndex: i ] isKindOfClass: [ NSDictionary class ]] ) {
            favobj = [[ favs objectAtIndex: i ] objectForKey: @"host" ];
        } else if ( [[ favs objectAtIndex: i ] isKindOfClass: [ NSString class ]] ) {
            favobj = [ favs objectAtIndex: i ];
        } else {
            continue;
        }
        if ( favobj != nil ) {
            [ destServerField addItemWithObjectValue: favobj ];
        }
    }

    [ destServerField setCompletes: YES ];
    [ destServerField setNumberOfVisibleItems: [ destServerField numberOfItems ]];
    [ destUserNameField setStringValue: user ];
    [ localFileField setStringValue: filename ];
    [ destPathField setStringValue: destPath ];
    [ copyType selectCellAtRow: scpType column: 0 ];
    scpFileSize = 100.0;
    
    if ( [[ NSFileManager defaultManager ] fileExistsAtPath: filename ] ) {
        [ localFileImageView setImage:
                [[ NSWorkspace sharedWorkspace ]
                    iconForFile: filename ]];
    } else {
        [ localFileImageView setImage:
                [[ NSWorkspace sharedWorkspace ]
                    iconForFileType: @"'doc '" ]];
    }
    
    [ scpWindow center ];
    [ scpWindow makeKeyAndOrderFront: nil ];
}

- ( void )getContinueQueryWithString: ( NSString * )string
{
    NSDictionary	*dict;
    
    dict = [ NSString unknownHostInfoFromString: string ];
    
    [ unknownHostMsgField setStringValue: [ dict objectForKey: @"msg" ]];
    [ unknownHostMsgField setEditable: NO ];
    [ unknownHostKeyField setStringValue: [ dict objectForKey: @"key" ]];
    [ unknownHostKeyField setEditable: NO ];
    
    [ scpSheet setContentView: unknownHostView ];
}

- ( IBAction )acceptHost: ( id )sender
{
    [ self write: "yes" ];
}

- ( IBAction )refuseHost: ( id )sender
{
    [ self write: "no" ];
}

- ( BOOL )firstPasswordPrompt
{
    return( _firstPasswordPrompt );
}

- ( void )setFirstPasswordPrompt: ( BOOL )fp
{
    _firstPasswordPrompt = fp;
}

- ( BOOL )gotPasswordFromKeychain
{
    return( _gotPasswordFromKeychain );
}

- ( void )setGotPasswordFromKeychain: ( BOOL )gp
{
    _gotPasswordFromKeychain = gp;
}

- ( BOOL )retrievePasswordFromKeychain
{
    char	*password;
    OSStatus	error;
    
    if (( password = getpwdfromkeychain( [[ destServerField stringValue ] UTF8String ],
                            [[ destUserNameField stringValue ] UTF8String ], &error )) == NULL ) {
        if ( error == errSecItemNotFound ) {
            NSLog( @"Keychain item not found" );
        } else {
            NSLog( @"Attempting to retrieve password from keychain return error %d", error );
        }
        return( NO );
    }
    
    [ self setGotPasswordFromKeychain: YES ];
    [ self write: password ];
    free( password );
    return( YES );
}

- ( void )authenticateWithPrompt: ( char * )prompt
{
    [ progBar stopAnimation: nil ];
    [ authProgBar retain ];
    [ authProgBar removeFromSuperview ];
    
    if ( [ self firstPasswordPrompt ] && [ self retrievePasswordFromKeychain ] == YES ) {
        [ self setFirstPasswordPrompt: NO ];
        return;
    }
    
    if ( ! [ self firstPasswordPrompt ] && [ self gotPasswordFromKeychain ] ) {
        {
            NSAlert *alert = [[ NSAlert alloc ] init ];
            [ alert setMessageText: NSLocalizedString( @"Error", @"Error" )];
            [ alert setInformativeText:
                NSLocalizedString( @"The password in the keychain was rejected "
                                   @"by this server. Would "
                                   @"you like to open Keychain Access to edit it?",
                                   @"The password in the keychain was rejected "
                                   @"by this server. Would "
                                   @"you like to open Keychain Access to edit it?" )];
            [ alert addButtonWithTitle:
                NSLocalizedString( @"Open Keychain Access", @"Open Keychain Access" )];
            [ alert addButtonWithTitle: NSLocalizedString( @"Cancel", @"Cancel" )];
            NSModalResponse rc = [ alert runModal ];
            [ alert release ];
            if ( rc == NSAlertFirstButtonReturn ) {
                [[ NSWorkspace sharedWorkspace ] openURL:
                    [ NSURL fileURLWithPath:
                        @"/Applications/Utilities/Keychain Access.app" ]];
            }
        }
    }
    
    [ passErrorField setStringValue: @"" ];
    [ scpSheet setContentView: passpromptView ];
    [ passPromptField setStringValue: [ NSString stringWithUTF8String: prompt ]];
    [ passwordField selectText: nil ];
}

- ( void )write: ( char * )buf
{
    NSInteger		wr;
    
    if (( wr = write( masterfd, buf, strlen( buf ))) != strlen( buf )) goto WRITE_ERR;
    if (( wr = write( masterfd, "\n", strlen( "\n" ))) != strlen( "\n" )) goto WRITE_ERR;
    
    return;
    
WRITE_ERR:
    {
        NSAlert *alert = [[ NSAlert alloc ] init ];
        [ alert setMessageText:
            NSLocalizedString( @"Write failed: Did not write correct number of bytes!",
                               @"Write failed: Did not write correct number of bytes!" )];
        [ alert addButtonWithTitle: NSLocalizedString( @"Exit", @"Exit" )];
        [ alert runModal ];
        [ alert release ];
    }
    exit( 2 );
}

- ( IBAction )authenticate: ( id )sender
{
    char	pass[ NAME_MAX ] = { 0 };
    
    [ passErrorField setStringValue: [ NSString stringWithFormat: @"\n%@",
                                    NSLocalizedString( @"Authenticating....",
                                                        @"Authenticating...." ) ]];
    [ passpromptView addSubview: authProgBar ];
    [ authProgBar setUsesThreadedAnimation: YES ];
    [ authProgBar startAnimation: nil ];

    bcopy( [[ passwordField stringValue ] UTF8String ], pass,
            strlen( [[ passwordField stringValue ] UTF8String ] ));
    if ( [ addToKeychainSwitch state ] == NSControlStateValueOn ) {
        addpwdtokeychain( [[ destServerField stringValue ] UTF8String ],
                [[ destUserNameField stringValue ] UTF8String ], pass );
    }
    [ self write: pass ];
    [ passwordField setStringValue: @"" ];
}

- ( void )passError
{
    [ passErrorField setStringValue:
            NSLocalizedString( @"Permission denied. Try again.",
                                @"Permission denied. Try again." ) ];
}

- ( void )sessionError: ( NSString * )err
{
    NSAlert *alert = [[ NSAlert alloc ] init ];
    [ alert setMessageText: NSLocalizedString( @"Error", @"Error" )];
    [ alert setInformativeText: err ];
    [ alert addButtonWithTitle: NSLocalizedString( @"OK", @"OK" )];
    [ alert runModal ];
    [ alert release ];
}

- ( IBAction )beginSCP: ( id )sender
{
    char		userathost[ MAXPATHLEN ];
    char		*port;
    NSUserDefaults	*defaults;
    int			no;
    
    scpFileSize = 100.0;
    
    SCPTYPE = [ copyType selectedRow ];
    
    if ( snprintf( userathost, MAXPATHLEN, "%s@%s:",
                ( char * )[[ destUserNameField stringValue ] UTF8String ],
                ( char * )[[ destServerField stringValue ] UTF8String ] ) > ( MAXPATHLEN - 1 )) {
        NSAlert *alert = [[ NSAlert alloc ] init ];
        [ alert setMessageText: NSLocalizedString( @"Error", @"Error" )];
        [ alert setInformativeText:
            NSLocalizedString( @"Parameter length exceeds bounds. Try again.",
                               @"Parameter length exceeds bounds. Try again." )];
        [ alert addButtonWithTitle: NSLocalizedString( @"OK", @"OK" )];
        [ alert runModal ];
        [ alert release ];
        return;
    }
    if ( [[ destPathField stringValue ] length ] ) {
        if ( snprintf( userathost, MAXPATHLEN, "%s\"%s\"",
                userathost,
                ( SCPTYPE == DOWNLOAD ? ( char * )[[ localFileField stringValue ] UTF8String ]
                    : ( char * )[[ destPathField stringValue ] UTF8String ] ))
                    > ( MAXPATHLEN - 1 )) {
            NSAlert *alert = [[ NSAlert alloc ] init ];
            [ alert setMessageText: NSLocalizedString( @"Error", @"Error" )];
            [ alert setInformativeText:
                NSLocalizedString( @"Parameter length exceeds bounds. Try again.",
                                   @"Parameter length exceeds bounds. Try again." )];
            [ alert addButtonWithTitle: NSLocalizedString( @"OK", @"OK" )];
            [ alert runModal ];
            [ alert release ];
            return;
        }
    }
    
    [ scpSheet setContentView: connectProgView ];
    [ progBar setIndeterminate: YES ];
    [ progBar setUsesThreadedAnimation: YES ];
    [ progBar startAnimation: nil ];
    [ connectProgMsg setStringValue:
        [ NSString stringWithFormat: NSLocalizedString( @"Connecting....", @"Connecting...." ),
                    [ destServerField stringValue ]]];
    
    [ scpWindow beginSheet: scpSheet completionHandler: nil ];
            
    scpFileName = [ localFileField stringValue ];
    port = ( char * )[[ destPortField stringValue ] UTF8String ];
    if ( !strlen( port )) port = "22";

    defaults = [ NSUserDefaults standardUserDefaults ];
    if ( ![[ recentCopiesList itemTitles ] containsObject: scpFileName ] ) {
        [ recentCopiesList insertItemWithTitle: scpFileName atIndex: 1 ];
    }
    no = [[ defaults objectForKey: @"numrscps" ] intValue ];
    if ( !no ) no = 10;
    [ recentCopiesList removeItemAtIndex: 0 ];
    if ( [ recentCopiesList numberOfItems ] > no ) {
        [ recentCopiesList removeItemAtIndex: ( [ recentCopiesList numberOfItems ] - 1 ) ];
    }
    [ defaults setObject: [ recentCopiesList itemTitles ] forKey: @"recentscps" ];
    [ recentCopiesList insertItemWithTitle: @"Recent Copies" atIndex: 0 ];

    {
        char *_uah  = strdup( userathost );
        char *_port = strdup( port );
        char *_item = strdup( SCPTYPE == DOWNLOAD ?
                                ( char * )[[ destPathField stringValue ] UTF8String ]
                                : ( char * )[ scpFileName UTF8String ] );
        int   _type = SCPTYPE;
        dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
            [ scp scpConnect: _uah toPort: _port forItem: _item
                            scpType: _type fromController: self ];
            free( _uah );
            free( _port );
            free( _item );
        });
    }
}

- ( void )secureCopy
{
    [ authProgBar stopAnimation: nil ];
    [ connectProgMsg setStringValue: @"" ];
    [ scpWindow setTitle: [ NSString stringWithFormat: @"SCP to %@", [ destServerField stringValue ]]];
    [ scpSheet setContentView: connectProgView ];
    [ progBar setIndeterminate: NO ];
    [ progBar setMinValue: 0.0 ];
    [ progBar setMaxValue: 100.0 ];
    [ progBar setDoubleValue: 0.0 ];
}

- ( void )fileCopying: ( NSString * )fname
            updateWithPercentDone: ( char * )pc
            eta: ( char * )eta
            bytesCopied: ( char * )bytes
{
    if ( atoi( pc ) == 0 || [[ connectProgMsg stringValue ] isEqualToString: @"" ] ) {
        [ connectProgMsg setStringValue: [ NSString stringWithFormat:
                NSLocalizedStringFromTable( @"Copying %@...", @"SCP",
                                            @"Copying %@..." ), fname ]];
    }
    [ progBar setDoubleValue: atof( pc ) ];
    [ percentDoneField setStringValue: [ NSString stringWithFormat:
            NSLocalizedStringFromTable( @"%s Done", @"SCP", @"%s Done" ), pc ]];
    [ etaField setStringValue: [ NSString stringWithFormat:
            NSLocalizedStringFromTable( @"Time Remaining: %s", @"SCP",
                                        @"Time Remaining: %s" ), eta ]];
    [ bytesCopiedField setStringValue:
            [ NSString stringWithUTF8String: bytes ]];
}

- ( void )secureCopyFinishedWithStatus: ( int )status
{

    [ scpSheet orderOut: nil ];
    [ NSApp endSheet: scpSheet ];
    
    if ( [[ self delegate ] respondsToSelector: @selector( scpFinished ) ] ) {
        [[ self delegate ] scpFinished ];
    }
    
    if ( status ) {
        NSAlert *errAlert = [[ NSAlert alloc ] init ];
        [ errAlert setMessageText: NSLocalizedString( @"Error", @"Error" )];
        [ errAlert setInformativeText: [ NSString stringWithFormat:
            @"scp exited with abnormal status %d", status ]];
        [ errAlert addButtonWithTitle: @"OK" ];
        [ errAlert runModal ];
        [ errAlert release ];
        return;
    }
    {
        NSAlert *alert = [[ NSAlert alloc ] init ];
        [ alert setMessageText: [ NSString stringWithFormat: @"%@ copied successfully %@ %@",
            [ localFileField stringValue ],
            ( SCPTYPE == DOWNLOAD ? @"from" : @"to" ), [ destServerField stringValue ]]];
        [ alert addButtonWithTitle: @"Done" ];
        [ alert addButtonWithTitle: @"New Secure Copy" ];
        NSModalResponse rc = [ alert runModal ];
        [ alert release ];
        [ progBar setIndeterminate: YES ];
        [ progBar stopAnimation: nil ];
        [ percentDoneField setStringValue: @"" ];
        [ etaField setStringValue: @"" ];
        [ bytesCopiedField setStringValue: @"" ];
        [ scpWindow setTitle: @"Secure Copy" ];
        if ( rc == NSAlertFirstButtonReturn ) {
            [ scpWindow close ];
            return;
        }
    }
    
    [ self setFirstPasswordPrompt: YES ];
    [ self setGotPasswordFromKeychain: NO ];
}

- ( void )clearLog
{
    [ scpLogField setString: @"" ];
}

- ( void )addToLog: ( NSString * )buf
{
    [[ scpLogField textStorage ] appendAttributedString:
        [[[ NSAttributedString alloc ] initWithString: buf ] autorelease ]];
}

- ( void )setMasterFD: ( int )fd
{
    masterfd = fd;
}

- ( void )setSCPPID: ( pid_t )pid
{
    scppid = pid;
}

- ( IBAction )cancelSCP: ( id )sender
{
    NSAlert *alert = [[ NSAlert alloc ] init ];
    [ alert setMessageText: @"Cancel SCP:" ];
    [ alert setInformativeText:
        NSLocalizedString( @"Are you sure you want to cancel this copy?",
                           @"Are you sure you want to cancel this copy?" )];
    [ alert addButtonWithTitle: NSLocalizedString( @"Don't Cancel", @"Don't Cancel" )];
    [ alert addButtonWithTitle: NSLocalizedString( @"Cancel", @"Cancel" )];
    NSModalResponse rc = [ alert runModal ];
    [ alert release ];
    if ( rc != NSAlertSecondButtonReturn ) return;

    if ( kill( scppid, SIGINT ) < 0 ) {
        NSAlert *errAlert = [[ NSAlert alloc ] init ];
        [ errAlert setMessageText: @"Couldn't kill scp process:" ];
        [ errAlert setInformativeText: [ NSString stringWithFormat:
            @"kill %d: %s", scppid, strerror( errno )]];
        [ errAlert addButtonWithTitle: @"OK" ];
        [ errAlert runModal ];
        [ errAlert release ];
        return;
    }
}

- ( IBAction )cancelSCPDialog: ( id )sender
{
    [ scpWindow close ];
    return;
}

- ( IBAction )chooseLocalFile: ( id )sender
{
    NSOpenPanel *op = [ NSOpenPanel openPanel ];
    NSString    *dir = [[ NSUserDefaults standardUserDefaults ]
                            objectForKey: @"NSDefaultOpenDirectory" ];
    if ( dir == nil ) dir = NSHomeDirectory();

    [ op setCanChooseDirectories: YES ];
    [ op setTitle: @"Choose an Item to Secure Copy" ];
    [ op setPrompt: @"Choose" ];
    [ op setDirectoryURL: [ NSURL fileURLWithPath: dir isDirectory: YES ]];
    [ op beginSheetModalForWindow: scpWindow completionHandler: ^( NSModalResponse result ) {
        if ( result != NSModalResponseOK ) return;
        NSURL   *url  = [[ op URLs ] objectAtIndex: 0 ];
        NSString *path = [ url path ];
        [ localFileField setStringValue: path ];
        [ localFileImageView setImage:
            [[ NSWorkspace sharedWorkspace ] iconForFile: path ]];
        scpFileName = path;
    }];
}

- ( IBAction )selectFromRecentSCPs: ( id )sender
{
    if ( [[ recentCopiesList titleOfSelectedItem ] isEqualToString: @"Recent Copies" ] ) return;
    
    [ localFileField setStringValue: [ recentCopiesList titleOfSelectedItem ]];
        [ localFileImageView setImage:
            [[ NSWorkspace sharedWorkspace ] iconForFile: [ localFileField stringValue ]]];
}

/* UMDragDropImageView delegate method */
- ( void )dropImageViewChanged: ( NSDictionary * )changeDictionary
{
    NSString		*path = [ changeDictionary objectForKey: @"UMDragDropPath" ];
    
    if ( path == nil ) {
	return;
    }
    
    [ localFileField setStringValue: path ];
}

/* UMTextField delegate method */
- ( void )umTextFieldContentsChanged: ( NSDictionary * )changeDictionary
{
    NSString		*s = [ changeDictionary objectForKey: @"UMTextFieldString" ];
    NSImage		*icon = nil;
    
    if ( s == nil ) {
	return;
    }
    
    icon = [[ NSWorkspace sharedWorkspace ] iconForFile: s ];
    
    [ localFileImageView setImage: icon ];
}

- ( void )dealloc
{
    [ scp release ];
    [ scpFileName release ];
    [ super dealloc ];
}

@end
