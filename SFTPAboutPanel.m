/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "SFTPAboutPanel.h"

@implementation SFTPAboutPanel

- ( void )awakeFromNib
{
    [ creditsTextField setEditable: NO ];
}

- ( IBAction )viewReadMe: ( id )sender
{
    NSString *path = [[ NSBundle mainBundle ] pathForResource: @"Fugu README"
                                                       ofType: @"rtfd" ];
    if ( path == nil ||
         ! [[ NSWorkspace sharedWorkspace ] openURL: [ NSURL fileURLWithPath: path ]]) {
        NSAlert *alert = [[ NSAlert alloc ] init ];
        [ alert setMessageText: @"Failed to open Read Me file!" ];
        [ alert setInformativeText:
            @"It seems something's wrong inside Fugu. You may want to reinstall. "
            @"You will not lose any of your settings if you choose to reinstall." ];
        [ alert addButtonWithTitle: @"OK" ];
        [ alert runModal ];
        [ alert release ];
    }
}

- ( IBAction )emailAuthor: ( id )sender
{
    [[ NSWorkspace sharedWorkspace ] openURL: [ NSURL URLWithString: @"mailto:fugu@umich.edu" ]];
}

- ( IBAction )visitHomePage: ( id )sender
{
    [[ NSWorkspace sharedWorkspace ] openURL:
        [ NSURL URLWithString: @"http://rsug.itd.umich.edu/software/fugu" ]];
}

@end
