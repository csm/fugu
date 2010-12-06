/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import <Cocoa/Cocoa.h>

#define SFTPPrefsChangedNotification	@"SFTPPrefsChangedNotification"

@class SFTPPrefTableView;

@interface SFTPPrefs : NSObject
{
    IBOutlet NSComboBox 	*prefDefaultHost;
    IBOutlet NSTextField	*prefDefaultUser;
    IBOutlet NSTextField	*prefDefaultLDir;
    IBOutlet NSTextField	*prefDefaultRDir;
    IBOutlet NSTextField	*prefDefaultPort;
    IBOutlet SFTPPrefTableView 	*prefFavTable;
    IBOutlet NSPanel 		*prefPanel;
    IBOutlet NSBox		*prefViewBox;
    IBOutlet NSView		*prefGeneralView;
    IBOutlet NSView		*prefFavoritesView;
    IBOutlet NSView		*prefKnownHostsView;
    IBOutlet SFTPPrefTableView	*prefKnownHostsTable;
    
    IBOutlet NSView		*prefFilesView;   
    IBOutlet NSPopUpButton	*prefTextEditorPopUp;
    IBOutlet NSMatrix		*prefPostEditMatrix;
    IBOutlet NSMatrix		*prefSortingMatrix;
	IBOutlet NSComboBox		*prefSSHPath;
    
    IBOutlet NSView		*prefTransfersView;
    IBOutlet NSButton		*prefRetainFileTimeSwitch;

@private
    NSMutableArray		*favs;
}
- ( IBAction )addFavorite: ( id )sender;
- ( IBAction )deleteFavorite: ( id )sender;

- ( IBAction )setGeneralDefaults: ( id )sender;
- ( IBAction )clearDefaults: ( id )sender;

- ( IBAction )deleteKnownHost: ( id )sender;
- ( IBAction )saveKnownHosts: ( id )sender;

- ( IBAction )setODBTextEditor: ( id )sender;

- ( IBAction )toggleRetainFileTime: ( id )sender;

- ( IBAction )setPostEditBehaviour: ( id )sender;

- ( IBAction )setSortingBehaviour: ( id )sender;

- ( IBAction )setSSHPath: ( id )sender;

- ( void )readGeneralPrefs;
- ( void )readFavorites;

- ( void )showGeneralPreferences: ( id )sender;

- ( IBAction )chooseDefaultLocalDirectory: ( id )sender;

- ( void )showPreferencePanel;

@end
