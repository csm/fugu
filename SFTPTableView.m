/*
 * Copyright (c) 2005 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "SFTPTableView.h"

@implementation SFTPTableView

- ( id )init
{
    self = [ super init ];
    _sftpOriginalDragImage = nil;
    _sftpOriginalPboardTypes = nil;
    _sftpOriginalPboardPlists = nil;
    _sftpDragPhase = 0;
    _sftpDragPromisedFiles = NO;
    
    return( self );
}

- ( BOOL )dragPromisedFiles
{
    return( _sftpDragPromisedFiles );
}

- ( void )setDragPromisedFiles: ( BOOL )promised
{
    _sftpDragPromisedFiles = promised;
}

/* catch key events */
- ( void )keyDown: ( NSEvent * )theEvent
{
    if ( ! [(id)[ self delegate ] handleEvent: theEvent fromTable: self ] ) {
        [ super keyDown: theEvent ];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- ( void )dragImage: ( NSImage * )anImage at: ( NSPoint )imageLoc offset: ( NSSize )mouseOffset
        event: ( NSEvent * )theEvent pasteboard: ( NSPasteboard * )pboard
	source: ( id )sourceObject slideBack: ( BOOL )slideBack
{
    NSInteger           row = [ self rowAtPoint: imageLoc ];
    NSRect		imageframe = [ self frameOfCellAtColumn: 0 row: row ];
    NSRect		imageRect;
    float		width = NSWidth( imageframe );
    float		height = NSHeight( imageframe );
    NSSize		imagesize;
    NSImage		*image = nil;
    NSView		*view = nil;
    int			i;

    if ( _sftpDragPhase == 0 ) {
	/*
	 * phase 0: capture image and original pasteboard
	 * contents, then drag promised files if required
	 */
	if (( view = [[ self superview ] superview ] ) == nil ) {
	    view = self;
	}
	height = NSHeight( [ view frame ] );

	imagesize = NSMakeSize( width, height );
	image = [[ NSImage alloc ] initWithSize: imagesize ];
    
	/* only draw the portion from the filename column */
	[ image lockFocus ];
	[ anImage dissolveToPoint: NSZeroPoint fraction: 1.0 ];
	[ image unlockFocus ];
	
	if ( ! [ self dragPromisedFiles ] ) {
	    [ super dragImage: image at: imageLoc offset: mouseOffset
		event: theEvent pasteboard: pboard source: sourceObject
		slideBack: slideBack ];
	    return;
	}
	
	_sftpOriginalDragImage = image;
	_sftpOriginalPboardTypes = [[ pboard types ] copy ];
	
	_sftpOriginalPboardPlists = nil;
	_sftpOriginalPboardPlists = [[ NSMutableArray alloc ] init ];
	for ( i = 0; i < [ _sftpOriginalPboardTypes count ]; i++ ) {
	    [ _sftpOriginalPboardPlists addObject:
		    [ pboard propertyListForType:
			[ _sftpOriginalPboardTypes objectAtIndex: i ]]];
	}
	_sftpDragPhase = 1;
	
	imageRect.origin = imageLoc;
	imageRect.size = NSMakeSize( 0.0, 0.0 );
	
	[ self dragPromisedFilesOfTypes: [ NSArray arrayWithObject: @"'doc '" ]
		    fromRect: imageRect source: self slideBack: YES event: theEvent ];
		    
    } else {
	/*
	 * phase 1: restore original image; add old pasteboard
	 * contents; and let super do all the rest
	 */
	NSArray		*types = _sftpOriginalPboardTypes;
	id		plist;
	int		i;

	[ pboard addTypes: types owner: [ self delegate ]];
	for ( i = 0; i < [ types count ]; i++ ) {
	    plist = [ _sftpOriginalPboardPlists objectAtIndex: i ];
	    [ pboard setPropertyList: plist forType: [ types objectAtIndex: i ]];
	}
	
	[ super dragImage: _sftpOriginalDragImage at: imageLoc offset: mouseOffset
		event: theEvent pasteboard: pboard source: sourceObject
		slideBack: slideBack ];
		
	_sftpOriginalDragImage = nil;
	_sftpOriginalPboardTypes = nil;

	_sftpDragPhase = 0;
    }
}

- ( NSArray * )namesOfPromisedFilesDroppedAtDestination: ( NSURL * )url
{
    NSArray	    *plists = _sftpOriginalPboardPlists;
    NSArray	    *names = [(id)[ self dataSource ] promisedNamesFromPlists: plists ];
    BOOL	    handled;

    handled = !![(id)[ self dataSource ]
		    handleDroppedPromisedFiles: [ plists objectAtIndex: 0 ]
		    destination: [ url path ]];
    if ( ! handled ) {
	NSLog( @"failed to handle promised files" );
    }
    
    _sftpOriginalPboardPlists = nil;
    
    return( names );
}

- ( NSDragOperation )draggingSourceOperationMaskForLocal: ( BOOL )isLocal
{
    return( NSDragOperationCopy );
}

- ( void )draggedImage: ( NSImage * )image endedAt: ( NSPoint )point
	    operation: ( NSDragOperation )operation
{
    /* work around a bug in Panther */
    [[ NSPasteboard pasteboardWithName: NSDragPboard ]
	    declareTypes: @[] owner: nil ];
}

- ( void )doSpringLoadedAction: ( NSTimer * )timer
{
    [(NSObject *)[ self delegate ] performSelector:
                    @selector( performSpringLoadedActionInTable: )
                                    withObject: self
                                    afterDelay: 0.0 ];

    [ springLoadedTimer invalidate ];
    springLoadedTimer = nil;
}

#ifdef SPRINGLOADED
- ( NSDragOperation )draggingEntered: ( id <NSDraggingInfo> )sender
{
    [ springLoadedTimer invalidate ];
    springLoadedTimer = nil;
    
    if ( [[ self delegate ] respondsToSelector:
                    @selector( performSpringLoadedActionInTable: ) ] ) {
        springLoadedTimer = [ NSTimer scheduledTimerWithTimeInterval: 2.0
                                        target: self
                                        selector: @selector( doSpringLoadedAction: )
                                        userInfo: nil
                                        repeats: NO ];
    }
    
    return( [ super draggingEntered: sender ] );
}
#endif /* SPRINGLOADED */

/* watch for keydown events while dragging for spring-loaded folders */
- ( NSDragOperation )draggingUpdated: ( id <NSDraggingInfo> )sender
{
    NSEvent         *e = [ NSApp currentEvent ];
    NSEventType     type = [ e type ];
    NSDragOperation op = [ super draggingUpdated: sender ];
    
    if ( type == NSEventTypeKeyDown ) {
        NSEvent         *newEvent = nil;
        NSPoint         pt;
        unichar         key = [[ e charactersIgnoringModifiers ] characterAtIndex: 0 ];
        
        if ( key == ' ' ) {
            if ( [[ self delegate ] respondsToSelector:
                            @selector( performSpringLoadedActionInTable: ) ] ) {
                [ springLoadedTimer invalidate ];
                springLoadedTimer = nil;
                [(NSObject *)[ self delegate ] performSelector:
                    @selector( performSpringLoadedActionInTable: )
                                    withObject: self
                                    afterDelay: 0.0 ];
            }
        }
        
        pt = NSMakePoint( [ e locationInWindow ].x + 1, [ e locationInWindow ].y + 1 );
        
        /* send a fake event to avoid repeats */
        newEvent = [ NSEvent mouseEventWithType: NSEventTypeLeftMouseDragged
                    location: pt modifierFlags: [ e modifierFlags ]
                    timestamp: ( [ e timestamp ] + 0.1 ) windowNumber: [ e windowNumber ]
                    context: nil eventNumber: 1
                    clickCount: 0 pressure: 0.0 ];
                    
        [ NSApp postEvent: newEvent atStart: YES ];
    }

    return( op );
}

- ( void )draggingExited: ( id <NSDraggingInfo> )sender
{
    if ( springLoadedTimer != nil ) {
        [ springLoadedTimer invalidate ];
        springLoadedTimer = nil;
    }
    
    if ( [[ self delegate ] respondsToSelector:
            @selector( springLoadedActionCancelledInTable: ) ] ) {
        [(NSObject *)[ self delegate ] performSelector:
                    @selector( springLoadedActionCancelledInTable: )
                            withObject: self
                            afterDelay: 0.0 ];
    }
    
    [ super draggingExited: sender ];
}

#ifdef SPRINGLOADED
- ( void )mouseMoved: ( NSEvent * )event
{
    switch ( [ event type ] ) {
    case NSLeftMouseDragged:
        if ( springLoadedTimer != nil ) {
            [ springLoadedTimer invalidate ];
            springLoadedTimer = nil;
            springLoadedTimer = [ NSTimer scheduledTimerWithTimeInterval: 2.0
                                        target: self
                                        selector: @selector( doSpringLoadedAction: )
                                        userInfo: nil
                                        repeats: NO ];
        }
        
    default:
        break;
    }
    
    [ super mouseMoved: event ];
}
#endif /* SPRINGLOADED */

- ( BOOL )needsPanelToBecomeKey
{
    return( YES );
}

/* display contextual menus for both of the browsers */
- ( NSMenu * )menuForEvent: ( NSEvent * )event
{
    NSPoint	p = [ self convertPoint: [ event locationInWindow ]
                            fromView: nil ];
    NSInteger	column = [ self columnAtPoint: p ];
    NSInteger	row = [ self rowAtPoint: p ];
    
    rightClickedRow = 0;
    
    if ( column == 0 && row >= 0  &&
        [[ self delegate ] respondsToSelector:
                @selector( menuForTable:column:row: ) ] ) {
        rightClickedRow = row;
        [ self selectRowIndexes: [ NSIndexSet indexSetWithIndex: row ] byExtendingSelection: NO ];
        
        return( [(id)[ self delegate ] menuForTable: self
                                    column: column
                                    row: row ] );
    }
    return( nil );
}

- ( void )textDidEndEditing: ( NSNotification * )aNotification
{
    if ( [[[ aNotification userInfo ] objectForKey: @"NSTextMovement" ]
                                        intValue ] == NSReturnTextMovement ) {
        NSInteger	column = [ self editedColumn ];

        if ( ! [[ self delegate ] respondsToSelector:
                    @selector( handleChangedText:forTable:column: ) ] ) {
            NSBeep();
            [ super textDidEndEditing: aNotification ];
            return;
        }
        
        [(id)[ self delegate ] handleChangedText: [[ aNotification object ] string ]
                forTable: self
                column: column ];
        [[ self window ] endEditingFor: self ];
        [[ self window ] makeFirstResponder: self ];
        [ self reloadData ];
    } else {
        [ super textDidEndEditing: aNotification ];
    }
}
#pragma clang diagnostic pop

- ( NSInteger )rightClickedRow
{
    return( rightClickedRow );
}

- ( NSPoint )originOfSelectedCell
{
    NSRect		cellframe;
    NSPoint		cellorigin;
    NSInteger		row = [ self selectedRow ];
    
    if ( row < 0 ) {
        return( NSZeroPoint );
    }
    
    cellframe = [ self frameOfCellAtColumn: 0 row: row ];
    cellorigin = NSMakePoint( cellframe.origin.x, cellframe.origin.y );
    
    cellorigin = [[[ self window ] contentView ] convertPoint: cellorigin fromView: self ];
    cellorigin = [[ self window ] convertPointToScreen: cellorigin ];
    
    return( cellorigin );
}

- ( void )addTableColumnWithIdentifier: ( id )identifier
            columnTitle: ( NSString * )title width: ( float )width
{
    NSTableColumn	*column = nil;
    
    if ( identifier == nil || title == nil || [ title isEqualToString: @"" ] ) {
        return;
    }
    
    column = [[ NSTableColumn alloc ] initWithIdentifier: identifier ];
                                        
    [[ column headerCell ] setStringValue: title ];
    [ column setMinWidth: ( width / 2 ) ];
    [ column setMaxWidth: ( width * 5 ) ];
    [ column setWidth: width ];
    if ( [ identifier isEqualToString: @"sizecolumn" ] ) {
        [[ column headerCell ] setAlignment: NSTextAlignmentRight ];
        [[ column dataCell ] setAlignment: NSTextAlignmentRight ];
    }
    
    [ self addTableColumn: column ];
}

    NSString *
ColumnTitleFromIdentifier( NSString *identifier )
{
    NSString		*title = @"";
    
    if ( [ identifier isEqualToString: @"datecolumn" ] ) {
        title = NSLocalizedString( @"Date", @"Date" );
    } else if ( [ identifier isEqualToString: @"groupcolumn" ] ) {
        title = NSLocalizedString( @"Group", @"Group" );
    } else if ( [ identifier isEqualToString: @"ownercolumn" ] ) {
        title = NSLocalizedString( @"Owner", @"Owner" );
    } else if ( [ identifier isEqualToString: @"permcolumn" ] ) {
        title = NSLocalizedString( @"Permissions", @"Permissions" );
    } else if ( [ identifier isEqualToString: @"sizecolumn" ] ) {
        title = NSLocalizedString( @"Size", @"Size" );
    }

    return( title );
}

    float
WidthForColumnWithIdentifier( NSString *identifier )
{
    float		width = 50.0; /* arbitrary non-zero width */
    
    if ( [ identifier isEqualToString: @"datecolumn" ] ) {
        width = DATE_COLUMN_WIDTH;
    } else if ( [ identifier isEqualToString: @"groupcolumn" ] ) {
        width = GROUP_COLUMN_WIDTH;
    } else if ( [ identifier isEqualToString: @"ownercolumn" ] ) {
        width = OWNER_COLUMN_WIDTH;
    } else if ( [ identifier isEqualToString: @"permcolumn" ] ) {
        width = MODE_COLUMN_WIDTH;
    } else if ( [ identifier isEqualToString: @"sizecolumn" ] ) {
        width = SIZE_COLUMN_WIDTH;
    }
    
    return( width );
}

@end
