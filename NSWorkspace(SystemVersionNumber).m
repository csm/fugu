/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "NSWorkspace(SystemVersionNumber).h"

@implementation NSWorkspace(SystemVersionNumber)

+ ( SInt32 )systemVersion
{
    NSOperatingSystemVersion v = [[ NSProcessInfo processInfo ] operatingSystemVersion ];
    /* encode as 0xMMmmpp to match the old Gestalt gestaltSystemVersion format */
    return ( SInt32 )(( v.majorVersion << 8 ) | ( v.minorVersion << 4 ) | v.patchVersion );
}

@end
