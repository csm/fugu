/*
 *
 * subclass of NSTextFieldCell that shows image and text. Based on
 * Apple's sample code for ImageAndTextCell in DragAndDropOutlineView.
 * 
 */

#import "SFTPItemCell.h"

@implementation SFTPItemCell

- ( void )dealloc
{
    [ image release ];
    image = nil;
    [ super dealloc ];
}

- copyWithZone: ( NSZone * )zone
{
    SFTPItemCell 	*cell = ( SFTPItemCell * )[ super copyWithZone: zone ];
    cell->image = [ image retain ];
    return( cell );
}

- ( void )italicizeStringValue
{
    NSMutableAttributedString	*as;
    NSFontManager		*fm;
    NSFont			*font;
    NSRange			range;
    unsigned int		i;
    
    range = [[ self stringValue ] rangeOfString: [ self stringValue ]];

    if (( i = range.location ) == NSNotFound ) { NSLog( @"not found" ); return; }
    
    fm = [ NSFontManager sharedFontManager ];
    as = [[ NSMutableAttributedString alloc ] init ];
    [ as setAttributedString: [ self attributedStringValue ]];
    while ( NSLocationInRange( i, range )) {
        font = [ fm convertFont: [ NSFont fontWithName: @"Helvetica" size: 12.0 ]
                    toHaveTrait: NSItalicFontMask ];
        [ as addAttribute: NSFontAttributeName value: font range: range ];
        i = NSMaxRange( range );
    }
    [ self setAttributedStringValue: as ];
    [ as release ];
}

- ( void )setImage: ( NSImage * )anImage
{
    if ( anImage != image ) {
        [ image release ];
        image = [ anImage retain ];
    }
}

- ( NSImage * )image
{
    return( image );
}

- ( NSRect )imageFrameForCellFrame: ( NSRect )cellFrame
{
    if ( image != nil ) {
        NSRect 		imageFrame;
        
        imageFrame.size = [ image size ];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 1;
        imageFrame.origin.y += ceil(( cellFrame.size.height - imageFrame.size.height ) / 2 );
        return( imageFrame );
    } else {
        return( NSZeroRect );
    }
}

- ( void )editWithFrame: ( NSRect )aRect inView: ( NSView * )controlView editor:( NSText * )textObj
            delegate: ( id )anObject event: ( NSEvent * )theEvent
{
    NSRect 		textFrame, imageFrame;
    
    NSDivideRect( aRect, &imageFrame, &textFrame, ( [ image size ].width + 1 ), NSMinXEdge );
    [ super editWithFrame: textFrame inView: controlView editor: textObj
            delegate: anObject event: theEvent ];
}

- ( void )selectWithFrame: ( NSRect )aRect inView: ( NSView * )controlView editor: ( NSText * )textObj
            delegate: ( id )anObject start: ( int )selStart length: ( int )selLength
{
    NSRect 		textFrame, imageFrame;
    
    NSDivideRect( aRect, &imageFrame, &textFrame, ( [ image size ].width + 1 ), NSMinXEdge );
    [ super selectWithFrame: textFrame inView: controlView editor: textObj
            delegate: anObject start: selStart length: selLength ];
}

- ( void )drawWithFrame: ( NSRect )cellFrame inView: ( NSView * )controlView
{
    if ( image != nil ) {
        NSSize			imageSize;
        NSRect			imageFrame;
        
        imageSize = [ image size ];
        NSDivideRect( cellFrame, &imageFrame, &cellFrame, ( imageSize.width + 1 ), NSMinXEdge );
        imageFrame.origin.x += 1;
        imageFrame.size = imageSize;
        

        if ( [ controlView isFlipped ] ) {
            imageFrame.origin.y += ceil(( cellFrame.size.height + imageFrame.size.height ) / 2 );
        } else {
            imageFrame.origin.y += ceil(( cellFrame.size.height - imageFrame.size.height ) / 2 );
        }

        [ image compositeToPoint: imageFrame.origin operation: NSCompositeSourceOver ];
    }
    [ super drawWithFrame: cellFrame inView: controlView ];
}

- ( NSSize )cellSize
{
    NSSize 		cellSize = [ super cellSize ];
    cellSize.width += ( image ? [ image size ].width : 0 ) + 1;
    return( cellSize );
}

@end
