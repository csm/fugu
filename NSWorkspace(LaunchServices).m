/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "NSWorkspace(LaunchServices).h"

@implementation NSWorkspace(LaunchServices)

- ( NSURL * )findApplicationNamed: ( NSString * )name bundleID: ( NSString * )bundleID
{
    if ( bundleID && ![ bundleID isEqualToString: @"-" ] ) {
        NSURL *url = [ self URLForApplicationWithBundleIdentifier: bundleID ];
        if ( url ) return url;
    }
    if ( name ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSString *path = [ self fullPathForApplication: name ];
        if ( !path ) path = [ self fullPathForApplication: [ name stringByDeletingPathExtension ]];
        if ( !path ) {
            NSString *withExt = [[ name stringByDeletingPathExtension ] stringByAppendingPathExtension: @"app" ];
            path = [ self fullPathForApplication: withExt ];
        }
#pragma clang diagnostic pop
        if ( path ) return [ NSURL fileURLWithPath: path ];
    }
    return nil;
}

- ( void )openFileURL: ( NSURL * )fileURL
   withApplicationURL: ( NSURL * )appURL
            odbParams: ( NSAppleEventDescriptor * )params
    completionHandler: ( void (^)( NSError * ) )handler
{
    if ( !appURL ) {
        if ( handler ) {
            handler( [ NSError errorWithDomain: NSCocoaErrorDomain
                                          code: NSFileNoSuchFileError
                                      userInfo: nil ] );
        }
        return;
    }
    NSWorkspaceOpenConfiguration *config = [ NSWorkspaceOpenConfiguration configuration ];
    if ( params ) config.appleEvent = params;
    [ self openURLs: @[ fileURL ] withApplicationAtURL: appURL
       configuration: config
   completionHandler: ^( NSRunningApplication *app, NSError *err ) {
        if ( handler ) {
            dispatch_async( dispatch_get_main_queue(), ^{ handler( err ); } );
        }
    }];
}

@end
