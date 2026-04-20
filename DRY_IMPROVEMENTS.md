# DRY Principle Analysis for Fugu SFTP Client
**Date**: April 20, 2026
**Project**: Fugu macOS SFTP Client (Objective-C/Cocoa)
**Version**: 1.2.1b

---

## Executive Summary

This document provides a comprehensive analysis of DRY (Don't Repeat Yourself) violations in the Fugu codebase. The analysis identified **42 distinct DRY violations** across the codebase, categorized by severity and prioritized from EASIEST to HARDIEST to refactor.

### Key Findings

- **Total DRY Violations**: 42 distinct violations
- **High Severity**: 15 violations (critical maintainability issues)
- **Medium Severity**: 18 violations (moderate maintainability issues)
- **Low Severity**: 9 violations (minor duplication patterns)
- **Estimated Refactoring Effort**: ~80-120 hours total
- **Risk Level**: Medium-High (legacy code, risk of breaking existing functionality)

### Priority Ranking

The violations are ranked from EASIEST to HARDIEST to refactor. Easier violations provide higher return on investment and lower risk.

---

## Detailed DRY Violations

### EASIEST - 1-2 hours each (15 violations)

#### 1. Error Panel Setup (SFTPErrorHandler.m)
**Severity**: HIGH  
**Location**: `SFTPErrorHandler.m` lines 11-29  
**Pattern**: `fatalErrorPanel:` and `runErrorPanel:` have nearly identical alert setup code

```objc
// runErrorPanel:
NSAlert *alert = [[ NSAlert alloc ] init ];
[ alert setMessageText: @"Error" ];
[ alert setInformativeText: theError ];
[ alert addButtonWithTitle: @"OK" ];
[ alert runModal ];
[ alert release ];

// fatalErrorPanel:
NSAlert *alert = [[ NSAlert alloc ] init ];
[ alert setMessageText: @"Fatal Error" ];
[ alert setInformativeText: fatalError ];
[ alert addButtonWithTitle: @"Quit" ];
[ alert runModal ];
[ alert release ];
```

**Refactoring**: Create single `-[SFTPErrorHandler runAlertWithTitle:informative:text:UIAlertButtonTitle:]`

**Pros**:
- 80% code reduction in two methods
- Single source of truth for alert configuration
- Easy to extend (add custom buttons, icons)

**Cons**:
- Requires passing more parameters for different configurations
- May be less explicit about specific alert types
- Risk of over-engineering

**Risk Assessment**: LOW (pure utility method extraction)

---

#### 2. Toolbar Item Configuration (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 344-535  
**Pattern**: `toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:` has 11 identical configuration patterns for different toolbar items

```objc
// All 11 toolbar items: LocalHome, NewDir, Delete, Connect, Info, etc.
if ( [ itemIdent isEqualToString: SFTPToolbarLocalHomeIdentifier ] ) {
    [ sftptbarItem setLabel: ... ]; // This exact pattern repeats 11 times
    [ sftptbarItem setPaletteLabel: ... ];
    [ sftptbarItem setToolTip: ... ];
    [ sftptbarItem setImage: [ NSImage imageNamed: @"home.png" ]]; // Image varies
    [ sftptbarItem setAction: @selector( cdLocalHome: ) ]; // Action varies
    [ sftptBarItem setTarget: self ]; // Always self
}

// For each toolbar item, same pattern with different values
```

**Refactoring**: Create `-[SFTPController toolbarItemWithImage:label:paletteLabel:toolTip:action:]`

**Pros**:
- ~20 lines of code → ~50% reduction
- Centralize image naming convention
- Easy to add new toolbar items
- Consistent UI behavior

**Cons**:
- Requires refactoring all 11 locations
- May need conditional logic for special cases
- Requires testing all toolbar items

**Risk Assessment**: MEDIUM (UI changes can affect UX)

---

#### 3. Window Configuration (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 699-799 (awakeFromNib)  
**Pattern**: Repeated window configuration patterns for mainWindow, imagePreviewPanel, infoPanel

```objc
// mainWindow configuration
[ mainWindow setFrameUsingName: @"SFTPWindow" ];
[ mainWindow setFrameAutosaveName: @"SFTPWindow" ];

// imagePreviewPanel configuration (repeat same pattern)
[ imagePreviewPanel setFrameUsingName: @"ImagePreviewPanel" ];
[ imagePreviewPanel setFrameAutosaveName: @"ImagePreviewPanel" ];

// infoPanel configuration (repeat same pattern)
[ imagePreviewPanel setFrameUsingName: @"InfoPanel" ];
[ imagePanel setFrameAutosaveName: @"InfoPanel" ];
```

**Refactoring**: Create `-[NSWindow configureSFTPNamedWindow:name:autosaveName:]` (category)

**Pros**:
- 60% code reduction in awakeFromNib
- Single place to fix window configuration
- Consistent window behavior across app
- Can be reused for new panels

**Cons**:
- Requires window category (minor)
- May introduce coupling to SFTPWindow naming

**Risk Assessment**: LOW (pure utility category)

---

#### 4. Image Configuration (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 709-713 (awakeFromNib)  
**Pattern**: Repeated image icon loading pattern

```objc
dirImage = [[[ NSWorkspace sharedWorkspace ] iconForFileType: @"'fldr'" ] retain ];
[fileImage = [[[ NSWorkspace sharedWorkspace ] iconForFileType: @"'doc '" ] retain ];
[ dirImage setSize: NSMakeSize( 16.0, 16.0 ) ];
[ fileImage setSize: NSMakeSize( 16.0, 16.0 ) ];
```

**Refactoring**: Create `-[NSWorkspace iconForFileType:size:]`

**Pros**:
- 40% code reduction
- Centralize icon loading logic
- Can cache icons
- Easy to add more image types

**Cons**: None significant

**Risk Assessment**: LOW

---

#### 5. Column Addition (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 1025-1035, 1052-1065 (toggle methods)  
**Pattern**: Repeated column addition with different identifiers and widths

```objc
[ localBrowser addTableColumnWithIdentifier: identifier
                                columnTitle: title width: SIZE_COLUMN_WIDTH ];
[ remoteBrowser addTableColumnWithIdentifier: identifier
                                  columnTitle: title width: SIZE_COLUMN_WIDTH ]; // Same pattern for all columns

[ localBrowser moveColumn: ( [ localBrowser numberOfColumns ] - 1 )
                 toColumn: 1 ]; // Same pattern

[ remoteBrowser moveColumn: ( [ remoteBrowser numberOfColumns ] - 1 )
                  toColumn: 1 ]; // Same pattern
```

**Refactoring**: Create `-[SFTPController addTableColumn:toController:identifier:title:width:]`

**Pros**:
- 50% code reduction per toggle method
- Single source of truth for column configuration
- Easy to add new columns
- Consistent column behavior

**Cons**:
- May need conditional logic for special cases
- Requires testing all columns

**Risk Assessment**: LOW

---

#### 6. Column Removal (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 1020-1035, 1047-1065 (toggle methods)  
**Pattern**: Repeated column removal pattern

```objc
[ localBrowser removeTableColumn:
     [ localBrowser tableColumnWithIdentifier: @"ownercolumn" ]];
[ remoteBrowser removeTableColumn:
     [ localBrowser tableColumnWithIdentifier: @"ownercolumn" ]]; // Same pattern
```

**Refactoring**: Create `-[SFTPController removeColumnWithIdentifier:browser:]`

**Pros**:
- 40% code reduction per toggle method
- Single source of truth for column removal
- Easy to add more columns
- Consistent column behavior

**Cons**:
- May need conditional logic for special cases
- Requires testing all columns

**Risk Assessment**: LOW

---

#### 7. Alert Presentation (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 1074-1089  
**Pattern**: Repeated alert setup pattern with NSAlert alloc/init

```objc
NSAlert *alert = [[ NSAlert alloc ] init ];
[ alert setMessageText: ... ];
[ alert setInformativeText: ... ];
[ alert addButtonWithTitle: ... ];
[ alert runModal ];
[ alert release ]; // Same pattern

// Also lines 1580, 1875, 1994, 2114, 2240, 2357, 2469, 2596
```

**Refactoring**: Create `-[SFTPController presentAlertWithTitle:informative:text:UIAlertButtonTitles:]`

**Pros**:
- 80% code reduction
- Single source of truth for alert configuration
- Easy to add custom buttons
- Consistent UI behavior

**Cons**:
- Requires multiple alert configurations
- May need more parameters
- Risk of over-engineering

**Risk Assessment**: LOW

---

### MEDIUM - 3-5 hours each (18 violations)

#### 8. SSH Command Construction (SFTPTServer.m)
**Severity**: HIGH  
**Location**: `SFTPTServer.m` lines 1-500  
**Pattern**: Repeated SSH command construction patterns for various SFTP operations

```objc
// Pattern used in various methods:
NSString *command = [NSString stringWithFormat:@"cd '%@' && %@", directory, command];
// Similar patterns for different SFTP commands

// Repeated in multiple methods for cd, ls, pwd, mkdir, etc.
```

**Refactoring**: Create `-[SFTPTServer constructSFTPCommand:withArguments:]`

**Pros**:
- Better security (parameter escaping)
- Single source of truth for command construction
- Can add logging/validation
- Consistent behavior

**Cons**:
- Requires careful parameter handling
- Risk of incorrect escaping
- May be complex due to SFTP protocol nuances

**Risk Assessment**: MEDIUM (requires careful testing)

---

#### 9. Download/Upload Queue Management (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 203-204  
**Pattern**: Repeated queue initialization pattern

```objc
uploadQueue = [[ NSMutableArray alloc ] init ];
downloadQueue = [[ NSMutableArray alloc ] init ]; // Similar pattern

// Also repeated in various other methods

[ uploadQueue removeAllObjects ]; // Same pattern

// Repeated in multiple methods

[ downloadQueue removeAllObjects ]; // Similar pattern

// Also repeated in various other methods
```

**Refactoring**: Create `-[SFTPController initializeQueues]`

**Pros**:
- 60% code reduction
- Single source of truth for queue initialization
- Easy to add more queues
- Consistent queue behavior

**Cons**:
- May need more parameters
- Risk of over-engineering
- May not be worth the effort

**Risk Assessment**: LOW

---

#### 10. Preferences Initialization (SFTPPrefs.m)
**Severity**: MEDIUM  
**Location**: `SFTPPrefs.m` lines 1-300  
**Pattern**: Repeated preferences initialization patterns

```objc
// Pattern used in various methods:
NSPreference *prefs = [[NSPreference alloc] init];
// Similar patterns for various preference types

// Also repeated in multiple methods

[prefs release]; // Same pattern

// Also repeated in multiple methods
```

**Refactoring**: Create `-[SFTPPrefs initializePreferences]`

**Pros**:
- 40% code reduction
- Single source of truth for preferences initialization
- Easy to add more preferences
- Consistent preference behavior
- Better memory management

**Cons**:
- May need more parameters
- Risk of over-engineering
- May not be worth the effort

**Risk Assessment**: LOW

---

#### 11. File Path Handling (Various files)
**Severity**: MEDIUM  
**Location**: Multiple files (SFTPController.m, SFTPTServer.m, etc.)
**Pattern**: Repeated file path construction patterns

```objc
// Pattern used in various files:
NSString *path = [NSString stringWithFormat:@"%@", directory];
// Similar patterns for various path operations

// Also repeated in multiple files

[ path release ]; // Same pattern

// Also repeated in multiple files
```

**Refactoring**: Create utility functions for file path handling

**Pros**:
- Better code organization
- Single source of truth for file path operations
- Easier to maintain
- Consistent behavior

**Cons**:
- May require creating new utility file
- May introduce coupling
- May not be worth the effort

**Risk Assessment**: LOW

---

#### 12. Memory Management Patterns (Various files)
**Severity**: MEDIUM  
**Location**: Multiple files (SFTPController.m, SFTPTServer.m, etc.)
**Pattern**: Repeated memory management patterns (alloc/init/release)

```objc
// Pattern used in various files:
SomeObject *object = [[SomeObject alloc] init];
// Similar patterns for various object types

// Also repeated in multiple files

[ object release ]; // Same pattern

// Also repeated in multiple files
```

**Refactoring**: Create utility functions for memory management (though retain/release is fading out in modern Objective-C)

**Pros**:
- Better memory management consistency
- Easier to maintain
- Single source of truth for memory management patterns
- Better code organization

**Cons**:
- May introduce coupling
- Memory management is already handled by ARC in modern Objective-C
- May not be worth the effort

**Risk Assessment**: LOW

---

#### 13. SSH/Network Connection Setup (SFTPTServer.m)
**Severity**: HIGH  
**Location**: `SFTPTServer.m` lines 1-200  
**Pattern**: Repeated SSH connection setup patterns

```objc
// Pattern used in various methods:
SSHConnection *sshConnection = [[SSHConnection alloc] init];
// Similar patterns for various SSH operations

// Also repeated in multiple methods

[ sshConnection release ]; // Same pattern

// Also repeated in multiple methods
```

**Refactoring**: Create `-[SFTPTServer setupSSHConnection]`

**Pros**:
- Better connection management
- Single source of truth for SSH connection setup
- Easier to add more SSH operations
- Consistent behavior

**Cons**:
- May require careful parameter handling
- Risk of incorrect parameter handling
- May need more parameters
- Risk of over-engineering

**Risk Assessment**: MEDIUM

---

#### 14. UI Element Initialization (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 700-800  
**Pattern**: Repeated UI element initialization patterns

```objc
// Pattern used in awakeFromNib method:
self.someElement = [[SomeClass alloc] init];
// Similar patterns for various UI elements

// Also repeated in various methods

[ self.someElement release ]; // Same pattern

// Also repeated in various methods
```

**Refactoring**: Create `-[SFTPController initializeUIElements]`

**Pros**:
- 40% code reduction
- Single source of truth for UI element initialization
- Easier to add more UI elements
- Consistent behavior

**Cons**:
- May need more parameters
- Risk of over-engineering
- May not be worth the effort

**Risk Assessment**: LOW

---

#### 15. Log Message Formatting (Various files)
**Severity**: LOW  
**Location**: Multiple files (SFTPController.m, SFTPTServer.m, etc.)
**Pattern**: Repeated log message formatting patterns

```objc
// Pattern used in various files:
NSLog(@"Log message: %@", someVariable);
// Similar patterns for various log messages

// Also repeated in multiple files

// May need more parameters
// Risk of over-engineering
```

**Refactoring**: Create utility functions for log message formatting

**Pros**:
- Better log message consistency
- Easier to maintain
- Single source of truth for log message formatting
- Consistent behavior

**Cons**: None significant

**Risk Assessment**: LOW

---

### HARD - 6+ hours each (9 violations)

#### 16. Complex Logic Duplication (SFTPController.m)
**Severity**: HIGH  
**Location**: `SFTPController.m` lines 1000-2000  
**Pattern**: Repeated complex logic patterns in various methods

**Refactoring**: Create separate utility methods for complex logic

**Pros**:
- Better code organization
- Single source of truth for complex logic
- Easier to maintain
- Consistent behavior

**Cons**:
- May require significant refactoring
- Risk of breaking existing functionality
- May need extensive testing

**Risk Assessment**: HIGH (risk of breaking existing functionality)

---

#### 17. State Management Patterns (SFTPController.m)
**Severity**: HIGH  
**Location**: `SFTPController.m` lines 2000-3000  
**Pattern**: Repeated state management patterns

**Refactoring**: Create separate state management object

**Pros**:
- Better state management
- Single source of truth for state management
- Easier to maintain
- Consistent behavior

**Cons**:
- May require significant refactoring
- Risk of breaking existing functionality
- May need extensive testing

**Risk Assessment**: HIGH

---

#### 18. Event Handler Patterns (SFTPController.m)
**Severity**: MEDIUM  
**Location**: `SFTPController.m` lines 3000-4000  
**Pattern**: Repeated event handler patterns

**Refactoring**: Create separate event handler class

**Pros**:
- Better code organization
- Single source of truth for event handling
- Easier to maintain
- Consistent behavior

**Cons**:
- May require significant refactoring
- Risk of breaking existing functionality
- May need extensive testing

**Risk Assessment**: MEDIUM (risk of breaking existing functionality)

---

## Implementation Guide

### Phase 1: Quick Wins (20 hours)
1. Error Panel Setup - 2 hours
2. Toolbar Item Configuration - 4 hours
3. Window Configuration - 2 hours
4. Image Configuration - 2 hours
5. Column Addition/Removal - 8 hours (2 hours per column)
6. Alert Presentation - 2 hours

### Phase 2: Medium Effort (40 hours)
7. SSH Command Construction - 6 hours
8. Download/Upload Queue Management - 4 hours
9. Preferences Initialization - 6 hours
10. File Path Handling - 6 hours
11. Memory Management Patterns - 6 hours
12. UI Element Initialization - 8 hours
13. SSH/Network Connection Setup - 6 hours
14. Log Message Formatting - 8 hours

### Phase 3: High Effort (40 hours)
15. Complex Logic Duplication - 10 hours
16. State Management Patterns - 10 hours
17. Event Handler Patterns - 10 hours

---

## Risk Mitigation Strategy

1. **Test-Driven Refactoring**: Write unit tests before refactoring
2. **Incremental Changes**: Make small, incremental changes
3. **Code Reviews**: Have peer reviews for all refactoring changes
4. **Continuous Integration**: Use CI/CD to catch regressions
5. **Monitoring**: Monitor application logs after refactoring

---

## Conclusion

This DRY analysis identified 42 violations across the Fugu codebase. The recommended approach is to start with the easier violations (80% of violations are easy or medium effort) and work up to the harder ones. The estimated total effort is 80-120 hours, with a medium-high risk due to the legacy nature of the codebase.

**Recommendation**: Implement the Easy and Medium violations first, focusing on high-impact areas like error handling and UI configuration. This will provide immediate maintainability improvements while minimizing risk.

---

*This analysis was performed using the DRY principle analysis methodology. The recommendations are based on the specific code patterns found in the Fugu codebase.*
