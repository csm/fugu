/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import <Cocoa/Cocoa.h>

@interface NSWorkspace(LaunchServices)

- ( NSURL * )findApplicationNamed: ( NSString * )name
                         bundleID: ( NSString * )bundleID;

- ( void )openFileURL: ( NSURL * )fileURL
   withApplicationURL: ( NSURL * )appURL
            odbParams: ( NSAppleEventDescriptor * )params
    completionHandler: ( void (^)( NSError * ) )handler;

@end
