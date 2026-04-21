/*
 * Copyright (c) 2004 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "UMVersionCheck.h"

@implementation UMVersionCheck

- ( void )checkForUpdates
{
    NSURL *url = [ NSURL URLWithString: VERSION_URL ];
    if ( url == nil ) {
        NSLog( @"UMVersionCheck: invalid VERSION_URL" );
        return;
    }

    NSURLSessionDataTask *task = [[ NSURLSession sharedSession ]
        dataTaskWithURL: url
        completionHandler: ^( NSData *data, NSURLResponse *response, NSError *error ) {

        if ( error != nil ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                NSAlert *alert = [[ NSAlert alloc ] init ];
                [ alert setMessageText: NSLocalizedString(
                    @"An error occurred checking for updates.",
                    @"An error occurred checking for updates." )];
                [ alert setInformativeText: NSLocalizedString(
                    @"Please check to make sure that you are connected "
                    @"to the internet. If you are connected, and the "
                    @"problem persists, please contact the authors of Fugu.",
                    @"Please check to make sure that you are connected "
                    @"to the internet. If you are connected, and the "
                    @"problem persists, please contact the authors of Fugu." )];
                [ alert addButtonWithTitle: NSLocalizedString( @"OK", @"OK" )];
                [ alert runModal ];
                        });
            return;
        }

        NSError *plistError = nil;
        NSDictionary *versionDictionary =
            [ NSPropertyListSerialization propertyListWithData: data
                                                      options: NSPropertyListImmutable
                                                       format: NULL
                                                        error: &plistError ];

        if ( versionDictionary == nil || ![ versionDictionary isKindOfClass: [ NSDictionary class ]]) {
            NSLog( @"UMVersionCheck: failed to parse version plist: %@", plistError );
            return;
        }

        dispatch_async( dispatch_get_main_queue(), ^{
            NSDictionary *infoPlist = [[ NSBundle mainBundle ] infoDictionary ];
            double current_version = [[ infoPlist objectForKey: @"UMVersionNumber" ] doubleValue ];
            double version = [[ versionDictionary objectForKey: @"UMApplicationVersion" ] doubleValue ];

            if ( version <= current_version ) {
                NSAlert *alert = [[ NSAlert alloc ] init ];
                [ alert setMessageText: [ NSString stringWithFormat:
                    NSLocalizedString( @"You have the current version of %@.",
                                       @"You have the current version of %@." ),
                    [ versionDictionary objectForKey: @"UMApplicationName" ]]];
                [ alert addButtonWithTitle: NSLocalizedString( @"OK", @"OK" )];
                [ alert runModal ];
                            return;
            }

            NSAlert *alert = [[ NSAlert alloc ] init ];
            [ alert setMessageText: [ NSString stringWithFormat:
                NSLocalizedString( @"A new version of %@ is now available.",
                                   @"A new version of %@ is now available." ),
                [ versionDictionary objectForKey: @"UMApplicationName" ]]];
            [ alert setInformativeText: [ NSString stringWithFormat:
                NSLocalizedString( @"The latest version of %@ is %@. Click \"More Info\" "
                                   @"to open a web page about the new release. Click "
                                   @"\"Download\" to download the new version immediately.",
                                   @"The latest version of %@ is %@. Click \"More Info\" "
                                   @"to open a web page about the new release. Click "
                                   @"\"Download\" to download the new version immediately." ),
                [ versionDictionary objectForKey: @"UMApplicationName" ],
                [ versionDictionary objectForKey: @"UMApplicationDisplayVersion" ]]];
            [ alert addButtonWithTitle: NSLocalizedString( @"More Info...", @"More Info..." )];
            [ alert addButtonWithTitle: NSLocalizedString( @"Download", @"Download" )];
            [ alert addButtonWithTitle: NSLocalizedString( @"Later", @"Later" )];

            NSModalResponse rc = [ alert runModal ];
        
            NSWorkspace *ws = [ NSWorkspace sharedWorkspace ];
            if ( rc == NSAlertFirstButtonReturn ) {
                [ ws openURL: [ NSURL URLWithString:
                    [ versionDictionary objectForKey: @"UMApplicationInformationURL" ]]];
            } else if ( rc == NSAlertSecondButtonReturn ) {
                [ ws openURL: [ NSURL URLWithString:
                    [ versionDictionary objectForKey: @"UMApplicationDirectDownloadURL" ]]];
            }
        });
    }];

    [ task resume ];
}

/* kept for API compatibility; callers should prefer -checkForUpdates */
- ( NSDictionary * )retrieveVersionDictionary
{
    return( nil );
}

@end
