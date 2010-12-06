/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import <Cocoa/Cocoa.h>

@interface NSAttributedString(Ellipsis)

- ( NSAttributedString * )ellipsisAbbreviatedStringForWidth: ( double )width;

@end
