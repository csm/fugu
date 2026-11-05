# System Patterns

## Current architecture

One application target, `Fugu`. Sources sit in the repository root. Xcode groups (`SFTP`, `SCP`, `SSHTunnel`, `Categories`, `Subclasses`, `Misc Classes`, `Other Sources`, `Resources`) are virtual: `PBXFileReference` paths are filenames only, `sourceTree = "<group>"`, and groups have no `path`.

`main.m` calls `NSApplicationMain`. `Info.plist` sets `NSMainNibFile` to `MainMenu` and `NSPrincipalClass` to `NSApplication`. `SFTPController` is an `NSObject` app delegate created from the nib. There is no scene delegate and no `UIViewController`.

Transfer work is in-process. `SFTPController.establishDOConnection` only allocates `SFTPTServer`. No `NSConnection` or `NSDistantObject` remains. `SFTPTServer`, `SCPTransfer`, and `SSHTunnelAuth` still drive OpenSSH subprocesses (`fork` in `ee.c` and `sshversion.c`).

Listings and favorites are `NSMutableDictionary` records parsed from `sftp` text. UI is `NSWindow`, `NSPanel`, `NSTableView`, `NSSplitView`, and custom cells, loaded from four English XIBs.

## Where work happens

Source edits that need a compile, and every branch in `migrate/step-*`, are made on the Mac with Xcode. Planning notes may be updated from elsewhere. A change is not verified until that Mac builds and launches Fugu.

## Patterns to keep during migration

- AppKit, not UIKit. macOS HIG, not iOS view-controller templates.
- System OpenSSH as the protocol engine until a later design decision says otherwise.
- `@objc` visibility for anything a XIB outlet, action, or remaining Objective-C caller still touches.
- Quoted `#import "Header.h"` plus the target header map. A folder move must not require new import strings if the header map still sees the headers.

## Patterns that are already partly modern

- ARC and weak references are on (`CLANG_ENABLE_OBJC_ARC`, `CLANG_ENABLE_OBJC_WEAK`).
- Keychain uses `SecItemCopyMatching` / `SecItemAdd`, not the old `SecKeychain` API.
- Alias resolution uses `NSURL`, not `FSRef` (`NSString(FSRefAdditions)`). `aevent.c` still uses `FSRef`/`FSSpec`.
- OS version uses `NSProcessInfo.operatingSystemVersion`, then packs it into the old Gestalt `0xMMmmpp` shape.
