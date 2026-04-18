/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "NSCalendarDate(ConvertToSeconds).h"

#include <string.h>

@implementation NSDate(ConvertToSeconds)

/*
 * Parses sftp-style date strings of the form:
 *   "Jan  5 14:23"       (within the last 6 months — no year)
 *   "Jan  5 14:23 2022"  (with explicit year)
 *   "Jan  5 2022"        (date only, with year)
 */
+ ( off_t )secondsFromFormattedDateString: ( NSString * )dString
{
    int         mo, curmo, day, yr, hr = 0, min = 0;
    off_t       secs;
    NSArray    *a = [ dString componentsSeparatedByString: @" " ];

    NSDictionary *months = @{
        @"jan": @1, @"feb": @2,  @"mar": @3,  @"apr": @4,
        @"may": @5, @"jun": @6,  @"jul": @7,  @"aug": @8,
        @"sep": @9, @"oct": @10, @"nov": @11, @"dec": @12
    };

    mo  = [[ months objectForKey: [[ a objectAtIndex: 0 ] lowercaseString ]] intValue ];
    day = [[ a objectAtIndex: 1 ] intValue ];

    if ( strchr( [[ a objectAtIndex: 2 ] UTF8String ], ':' ) == NULL ) {
        yr = [[ a objectAtIndex: 2 ] intValue ];
    } else {
        NSArray *b = [[ a objectAtIndex: 2 ] componentsSeparatedByString: @":" ];
        hr  = [[ b objectAtIndex: 0 ] intValue ];
        min = [[ b objectAtIndex: 1 ] intValue ];

        if ( [ a count ] == 4 ) {
            yr = [[ a objectAtIndex: 3 ] intValue ];
        } else {
            /* file modified within the last six months — infer year from wall clock */
            NSCalendar *cal = [ NSCalendar currentCalendar ];
            NSDateComponents *now = [ cal components: NSCalendarUnitMonth | NSCalendarUnitYear
                                           fromDate: [ NSDate date ]];
            curmo = ( int )[ now month ];
            yr    = ( int )[ now year ];

            /* compensate for year rollover */
            if ( mo > 6 && ( curmo >= 1 && curmo < 6 )) {
                yr--;
            }
        }
    }

    NSDateComponents *comps = [[ NSDateComponents alloc ] init ];
    [ comps setYear:   yr  ];
    [ comps setMonth:  mo  ];
    [ comps setDay:    day ];
    [ comps setHour:   hr  ];
    [ comps setMinute: min ];
    [ comps setSecond: 0   ];

    NSCalendar *cal = [ NSCalendar currentCalendar ];
    NSDate     *d   = [ cal dateFromComponents: comps ];
    [ comps release ];

    secs = ( off_t )[ d timeIntervalSince1970 ];
    return( secs );
}

@end
