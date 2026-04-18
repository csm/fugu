/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import <Foundation/Foundation.h>

@interface NSString(FSRefAdditions)
- ( NSString * )stringByResolvingAliasInPath;
- ( BOOL )isAliasFile;
@end
