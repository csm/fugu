/*
 * Copyright (c) 2005 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "SFTPPrefTableView.h"

static NSColor			*sStripeColor = nil;

@implementation SFTPPrefTableView

/* workaround for tablecolumn bug, which always draws its cells' backgrounds */
- ( void )awakeFromNib
{
    NSTextFieldCell		*cell = [[ NSTextFieldCell alloc ] init ];
    NSArray			*columns = [ self tableColumns ];
    int				i;
    
    [ cell setDrawsBackground: NO ];
    [ cell setEditable: YES ];
    
    for ( i = 0; i < [ columns count ]; i++ ) {
        [[ columns objectAtIndex: i ] setDataCell: cell ];
    }
    [ cell release ];
}

/* stripe table rows. gleaned from code posted to cocoadev.com */
- ( void )drawStripesInRect: ( NSRect )rect
{
    NSRect			stripeRect;
    float			fullRowHeight = ( [ self rowHeight] + [ self intercellSpacing ].height );
    float 			clipBottom = NSMaxY( rect );
    int 			firstStripe = ( rect.origin.y / fullRowHeight );
    
    /* shade odd-numbered rows */
    if (( firstStripe % 2 ) != 0 ) {
        firstStripe++;
    }
        
    stripeRect.origin.x = rect.origin.x;
    stripeRect.origin.y = ( firstStripe * fullRowHeight );
    stripeRect.size.width = rect.size.width;
    stripeRect.size.height = fullRowHeight;

    if ( sStripeColor == nil ) {
        sStripeColor = [[ NSColor colorWithCalibratedRed: ( 237.0 / 255.0 )
                           green: ( 243.0 / 255.0 )
                           blue: ( 254.0 / 255.0 )
                           alpha: 1.0 ] retain ];
    }
    
    [ sStripeColor set ];

    while ( stripeRect.origin.y < clipBottom ) {
        NSRectFill( stripeRect );
        stripeRect.origin.y += ( fullRowHeight * 2.0 );
    }
}

- ( void )highlightSelectionInClipRect: ( NSRect )rect
{
    [ self drawStripesInRect: rect ];
    [ super highlightSelectionInClipRect: rect ];
}

- ( void )textDidEndEditing: ( NSNotification * )aNotification
{
    NSNotification		*notification = nil;
    int				tm = [[[ aNotification userInfo ]
                                            objectForKey: @"NSTextMovement" ] intValue ];
    
    if ( tm == NSReturnTextMovement ) {
        NSMutableDictionary	*dict = [ NSMutableDictionary dictionaryWithDictionary:
                                            [ aNotification userInfo ]];
                                            
        [ dict setObject: [ NSNumber numberWithInt: NSIllegalTextMovement ]
                        forKey: @"NSTextMovement" ];

        notification = [ NSNotification notificationWithName: [ aNotification name ]
                                        object: [ aNotification object ]
                                        userInfo: dict ];
    } else {
        notification = aNotification;
    }
    
    [ super textDidEndEditing: notification ];
    if ( tm != NSTabTextMovement ) {
        [[ self window ] makeFirstResponder: self ];
    }
}

@end
