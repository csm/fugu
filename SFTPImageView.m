/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "SFTPImageView.h"

//@implementation NSImageCell(DraggableExtensions)
//
//- ( NSImage * )scaledImage
//{
//    return( _scaledImage );
//}
//
//@end



@implementation SFTPImageView

- ( void )awakeFromNib
{
    _imageLocationPath_ = nil;
}

/* allow user to drag image out of image view */
- ( void )mouseDown: ( NSEvent * )theEvent
{
    NSImage		*dragImage = nil;
    NSImage		*scaledImage = [ self image ];
    NSPoint		point;
    
    point = NSMakePoint((( [ self bounds ].size.width - [ scaledImage size ].width ) / 2.0 ),
                        (( [ self bounds ].size.height - [ scaledImage size ].height ) / 2.0 ));

    dragImage = [[ NSImage alloc ] initWithSize: [ scaledImage size ]];
    [ dragImage lockFocus ];
    [ scaledImage drawAtPoint: NSMakePoint( 0.0, 0.0 ) fromRect: NSZeroRect
                    operation: NSCompositingOperationSourceOver fraction: 0.5 ];
    [ dragImage unlockFocus ];

    NSPasteboardItem *pbItem = [[ NSPasteboardItem alloc ] init ];
    [ pbItem setData: [[ self image ] TIFFRepresentation ] forType: NSPasteboardTypeTIFF ];
    if ( [ self imageLocationPath ] != nil ) {
        NSURL *fileURL = [ NSURL fileURLWithPath: [ self imageLocationPath ]];
        [ pbItem setString: [ fileURL absoluteString ] forType: NSPasteboardTypeFileURL ];
    }

    NSDraggingItem *dragItem = [[ NSDraggingItem alloc ] initWithPasteboardWriter: pbItem ];
    [ pbItem release ];
    [ dragItem setDraggingFrame: NSMakeRect( point.x, point.y,
                                            [ scaledImage size ].width,
                                            [ scaledImage size ].height )
                       contents: dragImage ];
    [ dragImage release ];

    [ self beginDraggingSessionWithItems: @[ dragItem ] event: theEvent source: self ];
    [ dragItem release ];
}

- ( BOOL )needsPanelToBecomeKey
{
    return( YES );
}

- ( BOOL )acceptsFirstResponder
{
    return( YES );
}

- ( NSDragOperation )draggingSession: ( NSDraggingSession * )session
      sourceOperationMaskForDraggingContext: ( NSDraggingContext )context
{
    if ( context == NSDraggingContextWithinApplication ) {
        return NSDragOperationNone;
    }
    return NSDragOperationGeneric | NSDragOperationCopy;
}

- ( void )setImageLocationPath: ( NSString * )path
{
    if ( _imageLocationPath_ != nil ) {
        [ _imageLocationPath_ release ];
        _imageLocationPath_ = nil;
    }
    
    if ( path == nil || [ path isEqualToString: @"" ] ) {
        return;
    }
    
    _imageLocationPath_ = [[ NSString alloc ] initWithString: path ];
}

- ( NSString * )imageLocationPath
{
    return( _imageLocationPath_ );
}

@end
