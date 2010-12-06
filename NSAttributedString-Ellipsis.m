/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "NSAttributedString-Ellipsis.h"
#include <Carbon/Carbon.h>
#include <CoreFoundation/CoreFoundation.h>

@implementation NSAttributedString(Ellipsis)

- ( NSAttributedString * )ellipsisAbbreviatedStringForWidth: ( double )width
{
    NSAttributedString          *attrString = nil;
    NSMutableString             *string = [[[ self string ] mutableCopy ] autorelease ];
    OSStatus                    status;
    double                      paddedWidth = ( width - 24.0 );
    
    if (( status = TruncateThemeText(( CFMutableStringRef )string,
                    kThemeViewsFont, kThemeStateActive, paddedWidth, truncMiddle, NULL ))
                    != noErr ) {
        NSLog( @"TruncateThemeText %@ returned error %d", string, ( int )status );
        return( self );
    }
    
    attrString = [[ NSAttributedString alloc ] initWithString: string ];
    
    return( [ attrString autorelease ] );
}

@end
