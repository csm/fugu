/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import <Foundation/Foundation.h>
#import "SFTPErrorHandler.h"

@implementation SFTPErrorHandler

- ( void )runErrorPanel: ( NSString * )theError
{
    NSAlert *alert = [[ NSAlert alloc ] init ];
    [ alert setMessageText: @"Error" ];
    [ alert setInformativeText: theError ];
    [ alert addButtonWithTitle: @"OK" ];
    [ alert runModal ];
}

- ( void )fatalErrorPanel: ( NSString * )fatalError
{
    NSAlert *alert = [[ NSAlert alloc ] init ];
    [ alert setMessageText: @"Fatal Error" ];
    [ alert setInformativeText: fatalError ];
    [ alert addButtonWithTitle: @"Quit" ];
    [ alert runModal ];
    exit( 2 );
}

@end
