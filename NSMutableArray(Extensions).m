/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "NSMutableArray(Extensions).h"

@implementation NSMutableArray(Extensions)

- ( NSMutableArray * )visibleItems
{
    NSMutableArray		*vis = nil;
    int				i;
    char			c;
    
    if ( self == nil || [ self count ] == 0 ) {
        return( nil );
    }
    
    vis = [[ NSMutableArray alloc ] init ];
    
    for ( i = 0; i < [ self count ]; i++ ) {
        if (( c = [[[[ self objectAtIndex: i ] objectForKey: @"name" ]
                    lastPathComponent ] characterAtIndex: 0 ] ) != '.' ) {
            [ vis addObject: [ self objectAtIndex: i ]];
        }
    }
    
    return( [ vis autorelease ] );
}

- ( void )reverse
{
    NSMutableArray		*rev = nil;
    int				i;
    
    if ( self == nil || [ self count ] == 0 ) {
        return;
    }
    
    rev = [[ NSMutableArray alloc ] init ];
    
    for ( i = 0; i < [ self count ]; i++ ) {
        [ rev insertObject: [ self objectAtIndex: i ] atIndex: 0 ];
    }

    [ self setArray: rev ];
    [ rev release ];
}

@end
