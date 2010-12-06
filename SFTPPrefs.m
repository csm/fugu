/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "SFTPPrefs.h"
#import "NSMutableDictionary(Fugu).h"
#import "SFTPPrefTableView.h"

#import "NSWorkspace(LaunchServices).h"

#include <sys/param.h>
#include <string.h>
#include <unistd.h>
#include "argcargv.h"

#define SFTPPrefToolbarGeneralIdentifier	@"generalprefs"
#define SFTPPrefToolbarFavoritesIdentifier	@"favoritesprefs"
#define SFTPPrefToolbarKnownHostsIdentifier	@"knownhostprefs"
#define SFTPPrefToolbarFilesIdentifier		@"fileeditingprefs"
#define SFTPPrefToolbarTransfersIdentifier	@"transfersprefs"

extern int		errno;
static NSMutableArray	*knownHosts = nil;

@implementation SFTPPrefs

- ( id )init
{
    self = [ super init ];
    return( self );
}

- ( void )showPreferencePanel
{
    [ prefPanel makeKeyAndOrderFront: nil ];
}

- ( void )toolbarSetup
{
    NSToolbar *preftbar = [[[ NSToolbar alloc ] initWithIdentifier:  @"SFTPPrefToolbar" ] autorelease ];
    
    [ preftbar setAllowsUserCustomization: NO ];
    [ preftbar setAutosavesConfiguration: NO ];
    [ preftbar setDisplayMode: NSToolbarDisplayModeIconAndLabel ];
    
    [ preftbar setDelegate: self ];
    [ prefPanel setToolbar: preftbar ];
}

- ( void )awakeFromNib
{
    NSTableColumn       *tableColumn = [ prefFavTable tableColumnWithIdentifier: @"ssh1" ];
    NSButtonCell        *protoCell = [[[ NSButtonCell alloc ]
                                            initTextCell: @"" ] autorelease ];
                                            
    [ protoCell setButtonType: NSSwitchButton ];
    [ protoCell setEditable: YES ];
    if ( tableColumn ) {
        [ tableColumn setDataCell: protoCell ];
    }
    tableColumn = [ prefFavTable tableColumnWithIdentifier: @"compress" ];
    if ( tableColumn ) {
        [ tableColumn setDataCell: protoCell ];
    }
    
    favs = [[ NSMutableArray alloc ] init ];
    
    [ prefFavTable setDelegate: self ];
    [ prefFavTable setDataSource: self ];
    
    [ prefKnownHostsTable setDelegate: self ];
    [ prefKnownHostsTable setDataSource: self ];
    
    [ prefDefaultHost setCompletes: YES ];
    [ self toolbarSetup ];
    [ self readFavorites ];
    [ self readGeneralPrefs ];
    
    [ prefFavTable reloadData ];
    [ self showGeneralPreferences: nil ];
    [ prefPanel center ];
    [ prefPanel makeKeyAndOrderFront: nil ];
}

/**/
/* required toolbar delegate methods */
/**/

- ( NSToolbarItem * )toolbar: ( NSToolbar * )toolbar itemForItemIdentifier: ( NSString * )itemIdent willBeInsertedIntoToolbar: ( BOOL )flag
{
    NSToolbarItem *preftbarItem = [[[ NSToolbarItem alloc ]
                                    initWithItemIdentifier: itemIdent ] autorelease ];
    
    if ( [ itemIdent isEqualToString: SFTPPrefToolbarGeneralIdentifier ] ) {
        [ preftbarItem setLabel:
                NSLocalizedStringFromTable( @"General", @"SFTPPrefToolbar",
                                            @"General" ) ];
        [ preftbarItem setPaletteLabel:
                NSLocalizedStringFromTable( @"General", @"SFTPPrefToolbar",
                                            @"General" ) ];
        [ preftbarItem setToolTip:
                NSLocalizedStringFromTable( @"Show General Preferences", @"SFTPPrefToolbar",
                                            @"Show General Preferences" ) ];
        [ preftbarItem setImage: [ NSImage imageNamed: @"generalprefs.png" ]];
        [ preftbarItem setAction: @selector( showGeneralPreferences: ) ];
        [ preftbarItem setTarget: self ];
    } else if ( [ itemIdent isEqualToString: SFTPPrefToolbarFavoritesIdentifier ] ) {
        [ preftbarItem setLabel:
                NSLocalizedStringFromTable( @"Favorites", @"SFTPPrefToolbar",
                                            @"Favorites" ) ];
        [ preftbarItem setPaletteLabel:
                NSLocalizedStringFromTable( @"Favorites", @"SFTPPrefToolbar",
                                            @"Favorites" ) ];
        [ preftbarItem setToolTip:
                NSLocalizedStringFromTable( @"Show Favorites", @"SFTPPrefToolbar",
                                            @"Show Favorites" ) ];
        [ preftbarItem setImage: [ NSImage imageNamed: @"favoritesprefs.png" ]];
        [ preftbarItem setAction: @selector( showFavorites: ) ];
        [ preftbarItem setTarget: self ];
    } else if ( [ itemIdent isEqualToString: SFTPPrefToolbarTransfersIdentifier ] ) {
	[ preftbarItem setLabel:
                NSLocalizedStringFromTable( @"Transfers", @"SFTPPrefToolbar",
                                            @"Transfers" ) ];
        [ preftbarItem setPaletteLabel:
                NSLocalizedStringFromTable( @"Transfers", @"SFTPPrefToolbar",
                                            @"Transfers" ) ];
        [ preftbarItem setToolTip:
                NSLocalizedStringFromTable( @"Show Transfer Preferences", @"SFTPPrefToolbar",
                                            @"Show Transfer Preferences" ) ];
        [ preftbarItem setImage: [ NSImage imageNamed: @"transfers.png" ]];
        [ preftbarItem setAction: @selector( showTransfersPrefs: ) ];
        [ preftbarItem setTarget: self ];
    } else if ( [ itemIdent isEqualToString: SFTPPrefToolbarFilesIdentifier ] ) {
	[ preftbarItem setLabel:
                NSLocalizedStringFromTable( @"Files", @"SFTPPrefToolbar",
                                            @"Files" ) ];
        [ preftbarItem setPaletteLabel:
                NSLocalizedStringFromTable( @"Files", @"SFTPPrefToolbar",
                                            @"Files" ) ];
        [ preftbarItem setToolTip:
                NSLocalizedStringFromTable( @"Show Text File Editing Preferences", @"SFTPPrefToolbar",
                                            @"Show Text File Editing Preferences" ) ];
        [ preftbarItem setImage: [ NSImage imageNamed: @"files.png" ]];
        [ preftbarItem setAction: @selector( showFilesPrefs: ) ];
        [ preftbarItem setTarget: self ];
    } else if ( [ itemIdent isEqualToString: SFTPPrefToolbarKnownHostsIdentifier ] ) {
	[ preftbarItem setLabel:
                NSLocalizedStringFromTable( @"Known Hosts", @"SFTPPrefToolbar",
                                            @"Known Hosts" ) ];
        [ preftbarItem setPaletteLabel:
                NSLocalizedStringFromTable( @"Known Hosts", @"SFTPPrefToolbar",
                                            @"Known Hosts" ) ];
        [ preftbarItem setToolTip:
                NSLocalizedStringFromTable( @"Known Host Manager", @"SFTPPrefToolbar",
                                            @"Known Host Manager" ) ];
        [ preftbarItem setImage: [ NSImage imageNamed: @"knownhosts.png" ]];
        [ preftbarItem setAction: @selector( showKnownHosts: ) ];
        [ preftbarItem setTarget: self ];
    }
            
    return( preftbarItem );
}

- ( BOOL )validateToolbarItem: ( NSToolbarItem * )tItem
{
    return( YES );
}

- ( NSArray * )toolbarDefaultItemIdentifiers: ( NSToolbar * )toolbar
{
    NSArray	*tmp = [ NSArray arrayWithObjects:
                            SFTPPrefToolbarGeneralIdentifier,
                            SFTPPrefToolbarFavoritesIdentifier,
			    SFTPPrefToolbarTransfersIdentifier,
			    SFTPPrefToolbarFilesIdentifier,
			    SFTPPrefToolbarKnownHostsIdentifier, nil ];
                            
    return( tmp );
}

- ( NSArray * )toolbarAllowedItemIdentifiers: ( NSToolbar * )toolbar
{
    NSArray	*tmp = [ NSArray arrayWithObjects:
                            SFTPPrefToolbarGeneralIdentifier,
                            SFTPPrefToolbarFavoritesIdentifier,
			    SFTPPrefToolbarTransfersIdentifier,
			    SFTPPrefToolbarFilesIdentifier,
			    SFTPPrefToolbarKnownHostsIdentifier, nil ];
                            
    return( tmp );
}
/* end required toolbar delegate methods */

- ( void )readKnownHosts
{
    FILE	*knfp = NULL;
    char	buf[ LINE_MAX ];
    NSString	*knownhostspath = [ NSString stringWithFormat: @"%@/.ssh/known_hosts",
								NSHomeDirectory() ];
    
    if (( knfp = fopen( [ knownhostspath UTF8String ], "r" )) == NULL ) {
	NSRunAlertPanel( @"Couldn't open ~/.ssh/known_hosts.",
		@"fopen %@: %s", @"OK", @"", @"",
		knownhostspath, strerror( errno ));
	return;
    }
    
    [ knownHosts removeAllObjects ];
    
    while ( fgets( buf, LINE_MAX, knfp ) != NULL ) {
	int	tac;
	char	*line = NULL, **targv;
	
	if (( line = strdup( buf )) == NULL ) {
	    perror( "strdup" );
	    exit( 2 );
	}
	
	if (( tac = argcargv( line, &targv )) != 3 ) {
	    free( line );
	    continue;
	}
	
	if ( knownHosts == nil ) {
	    knownHosts = [[ NSMutableArray alloc ] init ];
	}
	
	[ knownHosts addObject: [ NSMutableDictionary dictionaryWithObjectsAndKeys:
		[ NSString stringWithUTF8String: targv[ 0 ]], @"hostid",
		[ NSString stringWithUTF8String: targv[ 1 ]], @"keytype",
		[ NSString stringWithUTF8String: targv[ 2 ]], @"key", nil ]];
	
	free( line );
    }
    
    ( void )fclose( knfp );
    
    [ prefKnownHostsTable reloadData ];
}

- ( void )showGeneralPreferences: ( id )sender
{
    NSRect		boxRect, newRect, windowRect;
    
    if ( [[ prefViewBox contentView ] isEqual: prefGeneralView ] ) {
        return;
    }
    
    boxRect = [ prefViewBox frame ];
    newRect = [ prefGeneralView frame ];
    windowRect = [ prefPanel frame ];
    
    windowRect.size.height -= ( NSHeight( boxRect ) - NSHeight( newRect ));
    windowRect.size.width -= ( NSWidth( boxRect ) - NSWidth( newRect ));
    windowRect.origin.y += ( NSHeight( boxRect ) - NSHeight( newRect ));
    boxRect.size.height = NSHeight( newRect );
    boxRect.size.width = NSWidth( newRect );
    
    [ prefViewBox setContentView: nil ];
    
    [ prefViewBox setFrame: boxRect ];
    [ prefPanel setFrame: windowRect display: YES animate: YES ];
    [ prefPanel setTitle: NSLocalizedString( @"Fugu Preferences: General",
                                @"Fugu Preferences: General" ) ];
    
    [ prefViewBox setContentView: prefGeneralView ];
}

- ( void )showFavorites: ( id )sender
{
    NSRect		boxRect, newRect, windowRect;
    
    if ( [[ prefViewBox contentView ] isEqual: prefFavoritesView ] ) {
        return;
    }
    
    boxRect = [ prefViewBox frame ];
    newRect = [ prefFavoritesView frame ];
    windowRect = [ prefPanel frame ];
    
    windowRect.size.height -= ( NSHeight( boxRect ) - NSHeight( newRect ));
    windowRect.size.width -= ( NSWidth( boxRect ) - NSWidth( newRect ));
    windowRect.origin.y += ( NSHeight( boxRect ) - NSHeight( newRect ));
    boxRect.size.height = NSHeight( newRect );
    boxRect.size.width = NSWidth( newRect );
    
    [ prefViewBox setContentView: nil ];
    
    [ prefViewBox setFrame: boxRect ];
    [ prefPanel setFrame: windowRect display: YES animate: YES ];
    
    [ prefViewBox setContentView: prefFavoritesView ];
    [ prefPanel setTitle: NSLocalizedString( @"Fugu Preferences: Favorites Editor",
                                    @"Fugu Preferences: Favorites Editor" ) ];
    [[ prefFavTable window ] makeFirstResponder: prefFavTable ];
}

- ( void )showKnownHosts: ( id )sender
{
    NSRect		boxRect, newRect, windowRect;
    
    if ( [[ prefViewBox contentView ] isEqual: prefKnownHostsView ] ) {
        return;
    }
    
    boxRect = [ prefViewBox frame ];
    newRect = [ prefKnownHostsView frame ];
    windowRect = [ prefPanel frame ];
    
    windowRect.size.height -= ( NSHeight( boxRect ) - NSHeight( newRect ));
    windowRect.size.width -= ( NSWidth( boxRect ) - NSWidth( newRect ));
    windowRect.origin.y += ( NSHeight( boxRect ) - NSHeight( newRect ));
    boxRect.size.height = NSHeight( newRect );
    boxRect.size.width = NSWidth( newRect );
    
    [ prefViewBox setContentView: nil ];
    
    [ prefViewBox setFrame: boxRect ];
    [ prefPanel setFrame: windowRect display: YES animate: YES ];
    
    [ self readKnownHosts ];
    
    [ prefViewBox setContentView: prefKnownHostsView ];
    [ prefPanel setTitle: NSLocalizedString( @"Fugu Preferences: SSH Known Hosts Editor",
                                    @"Fugu Preferences: SSH Known Hosts Editor" ) ];
}

- ( void )showFilesPrefs: ( id )sender
{
    int			row, i;
    NSRect		boxRect, newRect, windowRect;
    NSNumber		*num = nil;
    NSString		*editor = nil;
    NSString		*sshPath = nil;
    NSBundle            *bundle = [ NSBundle bundleForClass: [ self class ]];
    NSDictionary        *editorPlist = nil;
    NSArray             *editorArray = nil;
    
    if ( [[ prefViewBox contentView ] isEqual: prefFilesView ] ) {
        return;
    }
    
    editorPlist = [ NSDictionary dictionaryWithContentsOfFile:
                    [ bundle pathForResource: @"ODBEditors" ofType: @"plist" ]];
    if ( ! editorPlist ) {
        NSLog( @"Failed to load list of ODB editors" );
        return;
    }
    editorArray = [ editorPlist objectForKey: @"ODBEditors" ];
    
    if (( editor = [[ NSUserDefaults standardUserDefaults ]
			objectForKey: @"ODBTextEditor" ] ) == nil ) {
	editor = @"BBEdit";
    }
    
    [ prefTextEditorPopUp removeAllItems ];
    
    for ( i = 0; i < [ editorArray count ]; i++ ) {
        NSString    *bundleID = [[ editorArray objectAtIndex: i ] objectForKey: @"ODBEditorBundleID" ];
        NSString    *name = [[ editorArray objectAtIndex: i ] objectForKey: @"ODBEditorName" ];
        NSString    *signature = [[ editorArray objectAtIndex: i ] objectForKey: @"ODBEditorCreatorCode" ];
        NSImage     *odbIcon = nil;
        NSURL       *appURL;
        NSMenu      *popupMenu = [ prefTextEditorPopUp menu ];
        NSMenuItem  *menuItem = nil;
        const char  *sig;
        OSType      cc;
        
        if ( signature ) {
            sig = [ signature UTF8String ];
            cc = *(OSType *)sig;
        } else {
            cc = kLSUnknownCreator;
        }
        
        if ( [[ NSWorkspace sharedWorkspace ]
                launchServicesFindApplicationForCreatorType: cc
                bundleID: ( CFStringRef )bundleID appName: ( CFStringRef )name
                foundAppRef: NULL foundAppURL: ( CFURLRef * )&appURL ] ) {
            odbIcon = [[ NSWorkspace sharedWorkspace ] iconForFile: [ appURL path ]];
        } else if ( [ bundleID isEqualToString: @"-" ] ) {
            odbIcon = [[ NSWorkspace sharedWorkspace ] iconForFile:
                        [[ editorArray objectAtIndex: i ] objectForKey: @"ODBEditorPath" ]];
        } else {
            odbIcon = [[[ NSImage alloc ] initWithSize: NSMakeSize( 16.0, 16.0 ) ] autorelease ];
        }
        
        menuItem = [[ NSMenuItem alloc ] initWithTitle: name action: NULL keyEquivalent: @"" ];
        if ( odbIcon ) {
            [ odbIcon setScalesWhenResized: YES ];
            [ odbIcon setSize: NSMakeSize( 16.0, 16.0 ) ];
            [ menuItem setImage: odbIcon ];
        }
        
        [ popupMenu addItem: menuItem ];
        [ menuItem release ];
    }
    
    [ prefTextEditorPopUp selectItemWithTitle: editor ];
    
    if (( num = [[ NSUserDefaults standardUserDefaults ]
                        objectForKey: @"PostEditBehaviour" ] ) == nil ) {
        num = [ NSNumber numberWithInt: 0 ];
    }
    row = [ num intValue ];
    [ prefPostEditMatrix selectCellAtRow: row column: 0 ];
    
    if ( [[ NSUserDefaults standardUserDefaults ]
                        boolForKey: @"ASCIIOrderSorting" ] == YES ) {
        [ prefSortingMatrix selectCellAtRow: 1 column: 0 ];
    } else {
        [ prefSortingMatrix selectCellAtRow: 0 column: 0 ];
    }
    
    sshPath = [[ NSUserDefaults standardUserDefaults ]
			objectForKey: @"ExecutableSearchPath" ];
    if ( sshPath ) {
        if ( [ prefSSHPath indexOfItemWithObjectValue: sshPath ] == NSNotFound ) {
            [ prefSSHPath addItemWithObjectValue: sshPath ];
	}
        [ prefSSHPath setStringValue: sshPath ];
        [ prefSSHPath selectItemWithObjectValue:sshPath ];
    }
    
    boxRect = [ prefViewBox frame ];
    newRect = [ prefFilesView frame ];
    windowRect = [ prefPanel frame ];
    
    windowRect.size.height -= ( NSHeight( boxRect ) - NSHeight( newRect ));
    windowRect.size.width -= ( NSWidth( boxRect ) - NSWidth( newRect ));
    windowRect.origin.y += ( NSHeight( boxRect ) - NSHeight( newRect ));
    boxRect.size.height = NSHeight( newRect );
    boxRect.size.width = NSWidth( newRect );
    
    [ prefViewBox setContentView: nil ];
    
    [ prefViewBox setFrame: boxRect ];
    [ prefPanel setFrame: windowRect display: YES animate: YES ];
    
    [ prefViewBox setContentView: prefFilesView ];
    [ prefPanel setTitle: NSLocalizedString( @"Fugu Preferences: File Editing",
                                @"Fugu Preferences: File Editing" ) ];
}

- ( void )showTransfersPrefs: ( id )sender
{
    NSRect		boxRect, newRect, windowRect;
    BOOL		retainTime = NO;
    
    if ( [[ prefViewBox contentView ] isEqual: prefTransfersView ] ) {
        return;
    }
    
    boxRect = [ prefViewBox frame ];
    newRect = [ prefTransfersView frame ];
    windowRect = [ prefPanel frame ];
    
    windowRect.size.height -= ( NSHeight( boxRect ) - NSHeight( newRect ));
    windowRect.size.width -= ( NSWidth( boxRect ) - NSWidth( newRect ));
    windowRect.origin.y += ( NSHeight( boxRect ) - NSHeight( newRect ));
    boxRect.size.height = NSHeight( newRect );
    boxRect.size.width = NSWidth( newRect );
    
    [ prefViewBox setContentView: nil ];
    
    retainTime = [[ NSUserDefaults standardUserDefaults ] boolForKey: @"RetainFileTimestamp" ];
    
    [ prefViewBox setFrame: boxRect ];
    [ prefPanel setFrame: windowRect display: YES animate: YES ];
    [ prefRetainFileTimeSwitch setState: retainTime ];
    
    [ prefViewBox setContentView: prefTransfersView ];
    [ prefPanel setTitle: NSLocalizedString( @"Fugu Preferences: Transfers",
                                @"Fugu Preferences: Transfers" ) ];
}

- ( IBAction )toggleRetainFileTime: ( id )sender
{
    if ( [ prefRetainFileTimeSwitch state ] == NSOnState ) {
	[[ NSUserDefaults standardUserDefaults ] setBool: YES forKey: @"RetainFileTimestamp" ];
    } else {
	[[ NSUserDefaults standardUserDefaults ] setBool: NO forKey: @"RetainFileTimestamp" ];
    }
}

- ( IBAction )setPostEditBehaviour: ( id )sender
{
    int			row = [ prefPostEditMatrix selectedRow ];
    
    [[ NSUserDefaults standardUserDefaults ] setObject: [ NSNumber numberWithInt: row ]
                                                forKey: @"PostEditBehaviour" ];
}

- ( IBAction )setSortingBehaviour: ( id )sender
{
    int			row = [ prefSortingMatrix selectedRow ];
    
    [[ NSUserDefaults standardUserDefaults ] setBool: ( BOOL )row
                                                forKey: @"ASCIIOrderSorting" ];
}

- ( IBAction )setSSHPath: ( id )sender
{
    [[ NSUserDefaults standardUserDefaults ] setObject: [ sender stringValue ] 
					    forKey: @"ExecutableSearchPath" ];
}

- ( IBAction )deleteKnownHost: ( id )sender
{
    int			row = [ prefKnownHostsTable selectedRow ];
    
    if ( row < 0 ) {
	NSLog( @"Attempted to delete invalid row." );
	return;
    }
    
    [ knownHosts removeObjectAtIndex: row ];
    [ prefKnownHostsTable reloadData ];
}

- ( IBAction )saveKnownHosts: ( id )sender
{
    char		khpath[ MAXPATHLEN ];
    char		khpathbak[ MAXPATHLEN ];
    const char		*backupext = ".backup";
    int			haskhfile = 1, i;
    FILE		*fp;
    
    if ( snprintf( khpath, MAXPATHLEN, "%s/.ssh/known_hosts", [ NSHomeDirectory() UTF8String ] )
		    > ( MAXPATHLEN - 1 )) {
	NSBeginAlertSheet( NSLocalizedString( @"Error", @"Error" ),
		    NSLocalizedString( @"OK", @"OK" ), @"", @"", prefPanel,
		    self, NULL, nil, NULL,
		    @"%@/.ssh/known_hosts: path too long", NSHomeDirectory());
	return;
    }
	
    if ( access( khpath, R_OK | W_OK | F_OK ) < 0 ) {
	if ( errno != ENOENT ) {
	    NSBeginAlertSheet( NSLocalizedString( @"Error", @"Error" ),
			NSLocalizedString( @"OK", @"OK" ), @"", @"", prefPanel,
			self, NULL, nil, NULL,
			@"access %s: %s", khpath, strerror( errno ));
	    return;
	} else {
	    haskhfile = 0;
	}
    }
    
    if ( haskhfile ) {
	if ( strlcpy( khpathbak, khpath, sizeof( khpath )) >= sizeof( khpath )) {
	    NSBeginAlertSheet( NSLocalizedString( @"Error", @"Error" ),
			NSLocalizedString( @"OK", @"OK" ), @"", @"", prefPanel,
			self, NULL, nil, NULL,
			@"strlcpy %s failed: string exceeds bounds." );
	    return;
	}
	
	if ( strlcat( khpathbak, backupext, sizeof( backupext )) >= sizeof( khpathbak )) {
	    NSBeginAlertSheet( NSLocalizedString( @"Error", @"Error" ),
			NSLocalizedString( @"OK", @"OK" ), @"", @"", prefPanel,
			self, NULL, nil, NULL,
			@"strlcat %s failed: string exceeds bounds.", khpathbak );
	    return;
	}
	
	if ( rename( khpath, khpathbak ) != 0 ) {
	    NSBeginAlertSheet( NSLocalizedString( @"Error", @"Error" ),
			NSLocalizedString( @"OK", @"OK" ), @"", @"", prefPanel,
			self, NULL, nil, NULL,
			@"rename %s to %s: %s", khpath, khpathbak, strerror( errno ));
	    return;
	}
    }
    
    if (( fp = fopen( khpath, "w+" )) == NULL ) {
	NSBeginAlertSheet( NSLocalizedString( @"Error", @"Error" ),
			NSLocalizedString( @"OK", @"OK" ), @"", @"", prefPanel,
			self, NULL, nil, NULL,
			@"fopen %s: %s", khpath, strerror( errno ));
	( void )rename( khpathbak, khpath );
	return;
    }
    
    for ( i = 0; i < [ knownHosts count ]; i++ ) {
	NSDictionary	*dict = [ knownHosts objectAtIndex: i ];
	
	fprintf( fp, "%s %s %s\n", ( char * )[[ dict objectForKey: @"hostid" ] cString ],
				( char * )[[ dict objectForKey: @"keytype" ] cString ],
				( char * )[[ dict objectForKey: @"key" ] cString ] );
    }
    
    ( void )fclose( fp );
}

- ( void )readFavorites
{
    int			i;
    NSMutableArray	*favarray;
    id			fobj;
    
    [ favs removeAllObjects ];
    favarray = [[ NSUserDefaults standardUserDefaults ] objectForKey: @"Favorites" ];
    
    for ( i = 0; i < [ favarray count ]; i++ ) {
        fobj = [ favarray objectAtIndex: i ];
        
        if ( [ fobj isKindOfClass: [ NSString class ]] ) {
            NSMutableDictionary	*dict;
            
            dict = [ NSMutableDictionary favoriteDictionaryFromHostname: fobj ];
            [ favarray replaceObjectAtIndex: i withObject: dict ];
        }
    }
    
    [ favs addObjectsFromArray: favarray ];
    [[ NSUserDefaults standardUserDefaults ] setObject: favs forKey: @"Favorites" ];
}

- ( void )readGeneralPrefs
{
    int			i;
    NSUserDefaults	*defaults = [ NSUserDefaults standardUserDefaults ];
    id			defaultHost = [ defaults objectForKey: @"defaulthost" ];
    NSString		*defaultUser = [ defaults objectForKey: @"defaultuser" ];
    NSString		*defaultPort = [ defaults objectForKey: @"defaultport" ];
    NSString		*defaultRDir = [ defaults objectForKey: @"defaultrdir" ];
    NSString		*defaultLDir = [ defaults objectForKey: @"defaultdir" ];
    
    if ( defaultHost != nil ) {
        if ( [ defaultHost isKindOfClass: [ NSString class ]] ) {
            [ prefDefaultHost setStringValue: defaultHost ];
        } else if ( [ defaultHost isKindOfClass: [ NSDictionary class ]] ) {
            [ prefDefaultHost setStringValue: [ defaultHost objectForKey: @"host" ]];
        }
    }
    if ( defaultUser != nil ) {
        [ prefDefaultUser setStringValue: defaultUser ];
    }
    if ( defaultPort != nil ) {
        [ prefDefaultPort setStringValue: defaultPort ];
    }
    if ( defaultRDir != nil ) {
        [ prefDefaultRDir setStringValue: defaultRDir ];
    }
    if ( defaultLDir != nil ) {
        [ prefDefaultLDir setStringValue: defaultLDir ];
    }
    
    for ( i = 0; i < [ favs count ]; i++ ) {
        [ prefDefaultHost addItemWithObjectValue: [[ favs objectAtIndex: i ] objectForKey: @"host" ]];
    }
}

- ( IBAction )setODBTextEditor: ( id )sender
{
    [[ NSUserDefaults standardUserDefaults ]
	    setObject: [ prefTextEditorPopUp titleOfSelectedItem ]
	    forKey: @"ODBTextEditor" ];
}

- ( IBAction )addFavorite:( id )sender
{
    NSMutableDictionary		*dict;
    
    dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    @"newhost", @"nick",
                                    @"unreal.hostname.local", @"host",
                                    @"", @"user",
                                    @"", @"port",
                                    @"", @"dir", nil ];
    [ favs addObject: dict ];
    [ prefFavTable reloadData ];
    [ prefFavTable selectRow: ( [ favs count ] - 1 ) byExtendingSelection: NO ];
    [ prefFavTable editColumn: 0 row: ( [ favs count ] - 1 ) withEvent: nil select: YES ];
}

- ( IBAction )setGeneralDefaults: ( id )sender
{
    NSUserDefaults	*defaults = [ NSUserDefaults standardUserDefaults ];
    
    if ( [[ prefDefaultHost stringValue ] length ] ) {
        [ defaults setObject: [ prefDefaultHost stringValue ] forKey: @"defaulthost" ];
    }
    if ( [[ prefDefaultUser stringValue ] length ] ) {
        [ defaults setObject: [ prefDefaultUser stringValue ] forKey: @"defaultuser" ];
    }
    if ( [[ prefDefaultPort stringValue ] length ] ) {
        [ defaults setObject: [ prefDefaultPort stringValue ] forKey: @"defaultport" ];
    }
    if ( [[ prefDefaultRDir stringValue ] length ] ) {
        [ defaults setObject: [ prefDefaultRDir stringValue ] forKey: @"defaultrdir" ];
    }
    if ( [[ prefDefaultLDir stringValue ] length ] ) {
        [ defaults setObject: [ prefDefaultLDir stringValue ] forKey: @"defaultdir" ];
    }

    [ defaults synchronize ];
    
    [ self readGeneralPrefs ];
}

- ( IBAction )clearDefaults: ( id )sender
{
    NSBeginAlertSheet( NSLocalizedString( @"Clear Defaults?", @"Clear Defaults?" ),
		NSLocalizedString( @"Clear", @"Clear" ), NSLocalizedString( @"Cancel", @"Cancel" ),
		@"", prefPanel, self, @selector( clearDefaultsSheetDidEnd:returnCode:contextInfo: ),
		NULL, NULL, @"" );
}

- ( void )clearDefaultsSheetDidEnd: ( NSPanel * )sheet returnCode: ( int )rc
	    contextInfo: ( void * )contextInfo
{
    NSUserDefaults	*defaults;
    
    [ sheet orderOut: nil ];
    [ NSApp endSheet: sheet ];
    
    [ prefPanel makeKeyAndOrderFront: nil ];
    
    switch ( rc ) {
    case NSAlertDefaultReturn:
	break;
    case NSAlertAlternateReturn:
    default:
	return;
    }
    
    defaults = [ NSUserDefaults standardUserDefaults ];
    [ defaults setObject: @"" forKey: @"defaulthost" ];
    [ defaults setObject: @"" forKey: @"defaultuser" ];
    [ defaults setObject: @"" forKey: @"defaultport" ];
    [ defaults setObject: @"" forKey: @"defaultdir" ];
    [ defaults setObject: @"" forKey: @"defaultrdir" ];
    
    [ self readGeneralPrefs ];
}

- ( IBAction )deleteFavorite: ( id )sender
{
    if ( [ prefFavTable selectedRow ] < 0 ) return;
    if ( [ favs count ] > 0 ) {
        [ favs removeObjectAtIndex: [ prefFavTable selectedRow ]];
    }
    [[ NSUserDefaults standardUserDefaults ] setObject: favs forKey: @"Favorites" ];
    [[ NSNotificationCenter defaultCenter ] postNotificationName: SFTPPrefsChangedNotification
                                            object: nil ];
    [ prefFavTable reloadData ];
}

- ( IBAction )dismissPrefPanel: ( id )sender
{
    [ prefPanel close ];
}

- ( IBAction )chooseDefaultLocalDirectory: ( id )sender
{
    NSOpenPanel		*op = [ NSOpenPanel openPanel ];
    NSString		*ddir = [[ NSUserDefaults standardUserDefaults ]
                                    objectForKey: @"NSDefaultOpenDirectory" ];
    
    if ( ddir == nil ) ddir = NSHomeDirectory();
    
    [ op setCanChooseFiles: NO ];
    [ op setCanChooseDirectories: YES ];
    [ op setTitle: @"Choose a Default Folder" ];
    [ op setPrompt: @"Choose" ];
    
    [ op beginSheetForDirectory: ddir
        file: nil
        types: nil
        modalForWindow: prefPanel
        modalDelegate: self
        didEndSelector: @selector( defaultDirOpenPanelDidEnd:returnCode:contextInfo: )
        contextInfo: nil ];
}

- ( void )defaultDirOpenPanelDidEnd: ( NSOpenPanel * )sheet returnCode: ( int )rc
        contextInfo: ( void * )contextInfo
{
    switch ( rc ) {
    case NSOKButton:
        [ prefDefaultLDir setStringValue: [[ sheet filenames ] objectAtIndex: 0 ]];
        break;
    case NSCancelButton:
        return;
    }
}

/* tableview datasource methods */
- ( int )numberOfRowsInTableView: ( NSTableView * )aTableView
{
    if ( [ aTableView isEqual: prefFavTable ] ) {
	return( [ favs count ] );
    } else if ( [ aTableView isEqual: prefKnownHostsTable ] ) {
	return( [ knownHosts count ] );
    }
    
    return( 0 );
}

- ( id )tableView: ( NSTableView * )aTableView
        objectValueForTableColumn: ( NSTableColumn * )aTableColumn
        row: ( int )rowIndex
{
    NSMutableArray      *array = nil;
    
    if ( [ aTableView isEqual: prefFavTable ] ) {
	if ( [[ favs objectAtIndex: rowIndex ] isKindOfClass: [ NSString class ]] 
		&& [[ aTableColumn identifier ] isEqualToString: @"host" ] ) {
	    return( [ favs objectAtIndex: rowIndex ] );
	}
        array = favs;
    } else if ( [ aTableView isEqual: prefKnownHostsTable ] ) {
        array = knownHosts;
    }
	
    return( [[ array objectAtIndex: rowIndex ]
                objectForKey: [ aTableColumn identifier ]] );
}

- ( void )tableView: ( NSTableView * )aTableView
            setObjectValue: ( id )anObject
            forTableColumn: ( NSTableColumn * )aTableColumn
            row: ( int )rowIndex
{
    NSMutableDictionary		*dict = nil;
    
    if ( [ aTableView isEqual: prefFavTable ] ) {
	if ( [ favs count ] <= 0 || [ favs count ] <= rowIndex ) return;
	
	if ( [[ favs objectAtIndex: rowIndex ] isKindOfClass: [ NSString class ]]
		&& [[ aTableColumn identifier ] isEqualToString: @"fhost" ] ) {
	    [ favs replaceObjectAtIndex: rowIndex
		    withObject:
			[ NSMutableDictionary favoriteDictionaryFromHostname:
					[ favs objectAtIndex: rowIndex ]]];
	    return;
	}
	
	dict = [[ favs objectAtIndex: rowIndex ] mutableCopy ];
	
        [ dict setObject: anObject forKey: [ aTableColumn identifier ]];
        
	[ favs replaceObjectAtIndex: rowIndex withObject: dict ];
	[ dict release ];
	[[ NSUserDefaults standardUserDefaults ] setObject: favs forKey: @"Favorites" ];
	[[ NSNotificationCenter defaultCenter ] postNotificationName: SFTPPrefsChangedNotification
                                            object: nil ];
    }
}


@end
