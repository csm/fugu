/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "NSString(FSRefAdditions).h"

@implementation NSString(FSRefAdditions)

- ( NSString * )stringByResolvingAliasInPath
{
    NSURL *url = [ NSURL fileURLWithPath: self ];
    NSError *error = nil;
    NSURL *resolved = [ NSURL URLByResolvingAliasFileAtURL: url
                              options: NSURLBookmarkResolutionWithoutUI
                              relativeTo: nil error: &error ];
    if ( error || !resolved ) {
        return self;
    }
    return [ resolved path ] ?: self;
}

- ( BOOL )isAliasFile
{
    NSURL *url = [ NSURL fileURLWithPath: self ];
    NSNumber *isAlias = nil;
    [ url getResourceValue: &isAlias forKey: NSURLIsAliasFileKey error: nil ];
    return [ isAlias boolValue ];
}

@end
