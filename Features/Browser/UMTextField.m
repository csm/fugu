/*
 * Copyright (c) 2005 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "UMTextField.h"

@implementation UMTextField

- ( void )setDelegate: ( id )delegate
{
    _umTextFieldDelegate = delegate;
}

- ( id )delegate
{
    return( _umTextFieldDelegate );
}

- ( id )initWithFrame: ( NSRect )frame {
    self = [ super initWithFrame: frame ];
    _umTextFieldDelegate = nil;
    return( self );
}

- ( void )drawRect: ( NSRect )rect {
    [ super drawRect: rect ];
}

- ( void )awakeFromNib
{
    [ self registerForDraggedTypes: @[ NSPasteboardTypeFileURL ]];
}

- ( NSDragOperation )draggingEntered: ( id <NSDraggingInfo> )sender
{
    NSPasteboard *pb = [ sender draggingPasteboard ];
    NSArray *urls = [ pb readObjectsForClasses: @[ [ NSURL class ] ]
                         options: @{ NSPasteboardURLReadingFileURLsOnlyKey: @YES } ];
    if ( [ urls count ] == 0 ) {
        return( NSDragOperationNone );
    }
    [ self setBackgroundColor: [ NSColor lightGrayColor ]];
    [ self setEditable: NO ];
    [ self setNeedsDisplay: YES ];
    return( NSDragOperationCopy );
}

- ( void )draggingExited: ( id <NSDraggingInfo> )sender
{
    [ self setBackgroundColor: [ NSColor controlBackgroundColor ]];
    [ self setEditable: YES ];
    [ self setNeedsDisplay: YES ];
}

- ( BOOL )performDragOperation: ( id <NSDraggingInfo> )sender
{
    NSPasteboard *pb = [ sender draggingPasteboard ];
    NSArray *urls = [ pb readObjectsForClasses: @[ [ NSURL class ] ]
                         options: @{ NSPasteboardURLReadingFileURLsOnlyKey: @YES } ];
    if ( [ urls count ] == 0 ) {
        return( NO );
    }

    NSString *path = [[ urls objectAtIndex: 0 ] path ];

    [ self setStringValue: path ];
    [ self setEditable: YES ];
    [ self setBackgroundColor: [ NSColor controlBackgroundColor ]];
    [ self setNeedsDisplay: YES ];

    if ( [[ self delegate ] respondsToSelector:
            @selector( umTextFieldContentsChanged: ) ] ) {
        [[ self delegate ] umTextFieldContentsChanged:
            [ NSDictionary dictionaryWithObjectsAndKeys:
                self, @"UMTextField",
                path, @"UMTextFieldString", nil ]];
    }

    return( YES );
}

@end
