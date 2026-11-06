/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "NSAttributedString-Ellipsis.h"

@implementation NSAttributedString(Ellipsis)

- ( NSAttributedString * )ellipsisAbbreviatedStringForWidth: ( double )width
{
    NSAttributedString *attrString = [[ NSAttributedString alloc ] initWithString: [ self string ]];
    return( attrString );
}

@end
