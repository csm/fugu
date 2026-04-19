# Prompt

You are a senior macOS/AppKit modernization engineer working in Xcode on a legacy Cocoa application that is about 19 years old.

Goal:
Modernize this Mac app so it builds cleanly in the current Xcode version, keeps existing behavior, and adopts current Apple-recommended APIs, language features, frameworks, and project settings. Do not break working functionality. Prefer incremental, reviewable changes over large rewrites.

Primary objectives:
1. Make the project compile and run cleanly on the newest supported Xcode/macOS SDK.
2. Remove deprecations and high-value warnings systematically.
3. Replace obsolete custom implementations with Apple-provided frameworks, APIs, and system components where appropriate.
4. Modernize Objective-C code first where needed, then assess and perform safe incremental migration to Swift.
5. Preserve app behavior, file formats, UI flows, persistence, and user-visible functionality unless a change is clearly required for compatibility.

Rules:
- Do not do a full rewrite.
- Do not invent new architecture or frameworks if Apple already provides a suitable solution.
- Do not replace stable AppKit code with SwiftUI unless there is a clear, low-risk reason.
- Keep the project buildable after each step.
- Prefer small commits/patches with clear explanations.
- When uncertain, keep the old behavior and add a note instead of guessing.

Modernization workflow:
1. Inspect the project structure, targets, build settings, deployment target, warnings, deprecated APIs, nib/xib/storyboard usage, Objective-C patterns, memory-management model, and third-party dependencies.
2. Produce a categorized audit:
   - Build setting issues
   - Deprecated APIs
   - Unsafe or outdated Objective-C patterns
   - Legacy Cocoa/AppKit patterns
   - Nullability/type-safety gaps
   - Possible replacements with Apple frameworks
   - Swift migration candidates
3. Prioritize fixes in this order:
   - Build errors
   - Runtime-risk warnings
   - Deprecated APIs
   - Type-safety and annotation improvements
   - Project/build setting modernization
   - Opportunistic refactors
4. Apply changes incrementally and explain each change briefly.
5. After each change set, verify that the app still builds and that behavior is unchanged.

Code modernization requirements:
- Replace deprecated Cocoa/AppKit/Foundation APIs with current Apple-supported APIs.
- Prefer modern Objective-C features where files remain in Objective-C:
  - ARC-compatible patterns
  - properties instead of raw ivars where appropriate
  - instancetype
  - NS_ENUM / NS_OPTIONS
  - lightweight generics
  - nullability annotations
  - literals and subscripting
  - modern collection and string APIs
  - clearer error handling
- Remove obsolete manual workarounds if current frameworks already solve the problem.
- Preserve AppKit unless there is a specific benefit to changing a localized area.
- Improve thread-safety and main-thread UI correctness where needed.
- Keep Interface Builder resources compatible if they already work.

Framework and API guidance:
- Reuse Apple frameworks/modules already available in the SDK before writing custom replacements.
- Identify places where old custom code should be replaced by AppKit, Foundation, UniformTypeIdentifiers, UserDefaults, NSFileCoordinator, NSDocument, NSOperation, Auto Layout, modern pasteboard/drag-drop APIs, modern menu/toolbar APIs, etc., when applicable.
- Do not introduce unnecessary external dependencies.

Swift migration analysis:
- Analyse whether the project can be migrated partially or gradually to Swift.
- Identify low-risk first candidates for Swift conversion, such as utility classes, model objects, parsing/helpers, isolated controllers, and code with limited runtime dynamism.
- Identify high-risk areas that should remain Objective-C for now, such as deeply dynamic Cocoa Bindings/KVC/KVO-heavy code, old nib-driven controller glue, fragile runtime behavior, or code relying heavily on Objective-C message forwarding.
- If Swift migration is viable, propose a phased plan:
  - Phase 1: prepare Objective-C for interoperability
  - Phase 2: add Swift to the target and bridging
  - Phase 3: migrate isolated leaf components
  - Phase 4: migrate larger modules only after tests/build stability
- Do not convert files to Swift blindly. Only convert when the result is simpler, safer, and behaviorally equivalent.

Expected output format:
1. Short audit summary
2. Modernization plan with phases
3. Concrete code changes to apply now
4. Deprecated APIs and their replacements
5. Apple framework/module replacements for old custom code
6. Swift migration feasibility assessment:
   - yes/no/partial
   - best first files to migrate
   - files to postpone
   - risks and blockers
7. Updated code patches
8. Build verification checklist
9. Remaining issues / next steps

Important constraints:
- Keep all existing functionality intact.
- Favor minimal-risk refactoring.
- If a warning can be fixed without behavioral change, do it.
- If a fix may alter behavior, flag it before changing.
- If tests are missing, propose focused regression checks for the affected area.
- Make all changes idiomatic for current Xcode, current macOS SDKs, modern Objective-C, and interoperable Swift.

Success criteria:
- Fewer or no deprecation warnings
- Significantly reduced compiler warnings
- Current project settings
- Cleaner, type-safer code
- Clear recommendation on partial Swift migration
- No functional regressions

---

# Audit

  1. Audit Summary

  Project: Fugu — macOS SFTP/SCP client, ~19 years old, ~43 Objective-C/C source files
  Build status after prior session work: ✅ BUILD SUCCEEDED — 17 warnings remain (down from ~80+)
  Memory model: Manual Reference Counting (MRC) — no ARC enabled
  Deployment target: macOS 11.0
  Swift version: 6.0 configured, zero Swift files exist
  Third-party deps: Carthage (KeychainAccess) only

  ---
  2. Categorized Audit

  2a. Build Setting Issues

  ┌────────────────────────────────────────────┬────────────────────┬───────────────────────────────────────┬─────────────────────────────────────┐
  │                  Setting                   │      Current       │              Recommended              │                Risk                 │
  ├────────────────────────────────────────────┼────────────────────┼───────────────────────────────────────┼─────────────────────────────────────┤
  │ CLANG_ENABLE_OBJC_ARC                      │ OFF (unset)        │ ON per-file or project-wide           │ High — requires MRC→ARC audit first │
  ├────────────────────────────────────────────┼────────────────────┼───────────────────────────────────────┼─────────────────────────────────────┤
  │ MACOSX_DEPLOYMENT_TARGET                   │ 11.0               │ 13.0+ (drops lots of old API surface) │ Low once code is clean              │
  ├────────────────────────────────────────────┼────────────────────┼───────────────────────────────────────┼─────────────────────────────────────┤
  │ ENABLE_HARDENED_RUNTIME                    │ NO                 │ YES (required for notarization)       │ Low                                 │
  ├────────────────────────────────────────────┼────────────────────┼───────────────────────────────────────┼─────────────────────────────────────┤
  │ GCC_OPTIMIZATION_LEVEL                     │ not set            │ Review — debug/release split          │ None                                │
  ├────────────────────────────────────────────┼────────────────────┼───────────────────────────────────────┼─────────────────────────────────────┤
  │ CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS │ YES                │ YES (keep)                            │ —                                   │
  ├────────────────────────────────────────────┼────────────────────┼───────────────────────────────────────┼─────────────────────────────────────┤
  │ Swift version                              │ 6.0 set but unused │ Keep or remove                        │ None                                │
  ├────────────────────────────────────────────┼────────────────────┼───────────────────────────────────────┼─────────────────────────────────────┤
  │ Code signing                               │ - (ad-hoc)         │ Needs Team ID for distribution        │ —                                   │
  └────────────────────────────────────────────┴────────────────────┴───────────────────────────────────────┴─────────────────────────────────────┘

  2b. Deprecated APIs (remaining after this session)

  ┌───────────────────────────┬─────────────────────────────────────────────────────────────────────┬──────────────────────────────────────────┬──────────────────────┐
  │           File            │                                 API                                 │               Replacement                │        Effort        │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SFTPController.m:187      │ NSConnection                                                        │ NSXPCConnection                          │ High — architectural │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SCPController.h:46        │ NSDrawer                                                            │ NSSplitViewController or sheet           │ High — UI rework     │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SCPController.h:52, .m:47 │ NSConnection                                                        │ NSXPCConnection                          │ High                 │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SCPTransfer.h/m           │ NSConnection                                                        │ NSXPCConnection                          │ High                 │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SSHTunnel.h:45            │ NSConnection                                                        │ NSXPCConnection                          │ High                 │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SFTPTServer.m             │ NSConnection                                                        │ NSXPCConnection                          │ High                 │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SCPController.m:305       │ NSOnState                                                           │ NSControlStateValueOn                    │ Low                  │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SCPController.m:380       │ beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo: │ [NSWindow beginSheet:completionHandler:] │ Low                  │
  ├───────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────┼──────────────────────┤
  │ SCPController.m:495       │ insertText:                                                         │ [[textStorage] appendAttributedString:]  │ Low                  │
  └───────────────────────────┴─────────────────────────────────────────────────────────────────────┴──────────────────────────────────────────┴──────────────────────┘

  2c. Active Warnings (remaining 17)

  SCPController.h:46    NSDrawer deprecated
  SCPController.h:52    NSConnection deprecated
  SCPController.m:47    NSConnection deprecated
  SCPController.m:239   unused variable 'rc'
  SCPController.m:305   NSOnState deprecated
  SCPController.m:380   beginSheet:modalForWindow deprecated
  SCPController.m:393   precision loss NSInteger→int
  SCPController.m:495   insertText: deprecated
  SCPTransfer.m:34,37   NSConnection deprecated
  SCPTransfer.m:71      t_rate set but unused
  SCPTransfer.m:145     pwsent, threestrikes set but unused
  SCPTransfer.m:159     format string insufficient args (%@ with no arg)
  SFTPController.m:187  NSConnection deprecated
  SSHTunnel.h:45        NSConnection deprecated

  2d. Unsafe / Outdated Objective-C Patterns

  ┌──────────────────────────────────────┬──────────────────────────────────────┬─────────────────────────────────────────┬─────────────────────────┐
  │               Pattern                │                Files                 │                  Risk                   │           Fix           │
  ├──────────────────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────┼─────────────────────────┤
  │ Manual Reference Counting (MRC)      │ All .m files                         │ Crash risk if retain/release imbalanced │ ARC migration (Phase 4) │
  ├──────────────────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────┼─────────────────────────┤
  │ extern int errno;                    │ All — already fixed                  │ Macro vs declaration conflict           │ Done ✅                 │
  ├──────────────────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────┼─────────────────────────┤
  │ int for NSInteger/NSUInteger returns │ All — mostly fixed                   │ 64-bit truncation                       │ Done ✅                 │
  ├──────────────────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────┼─────────────────────────┤
  │ Informal protocols (no @protocol)    │ SFTPTableView.h                      │ Compiler blind to type                  │ Pragmas added ✅        │
  ├──────────────────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────┼─────────────────────────┤
  │ C-style string NULL check on char*   │ NSString(SSHAdditions), sshversion.c │ Pointer/integer mismatch                │ Fixed ✅                │
  ├──────────────────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────┼─────────────────────────┤
  │ p = '\0' instead of *p = '\0'        │ SFTPTServer.m                        │ Real bug — fixed                        │ Done ✅                 │
  ├──────────────────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────┼─────────────────────────┤
  │ strlcpy/strlcat wrong sizeof         │ SFTPPrefs.m                          │ Buffer overflow                         │ Fixed ✅                │
  └──────────────────────────────────────┴──────────────────────────────────────┴─────────────────────────────────────────┴─────────────────────────┘

  2e. Legacy Cocoa/AppKit Patterns

  ┌─────────────────────────────────────────────────────────┬─────────────────────────────────────────┬────────────┬─────────────────────────────────────────────────────────────┐
  │                         Pattern                         │                  File                   │   Status   │                         Replacement                         │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ NSRunAlertPanel                                         │ All — fixed                             │ Done ✅    │ NSAlert                                                     │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ NSBeginAlertSheet                                       │ All — fixed                             │ Done ✅    │ beginSheetModalForWindow:completionHandler:                 │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ beginSheet:modalForWindow:modalDelegate:didEndSelector: │ SCPController.m                         │ Pending    │ beginSheet:completionHandler:                               │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ selectedRowEnumerator                                   │ All — fixed                             │ Done ✅    │ selectedRowIndexes + block                                  │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ NSFilenamesPboardType                                   │ All — fixed                             │ Done ✅    │ NSPasteboardTypeFileURL                                     │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ insertText:                                             │ SCPController.m                         │ Pending    │ appendAttributedString:                                     │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ NSConnection / DO IPC                                   │ SFTPTServer, SCPTransfer, SSHTunnelAuth │ Deferred   │ NSXPCConnection                                             │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ NSDrawer                                                │ SCPController                           │ Deferred   │ NSSplitViewController or panel                              │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ noteFileSystemChanged:                                  │ All — fixed                             │ Done ✅    │ Removed                                                     │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ loadNibNamed:owner: (class method)                      │ All — fixed                             │ Done ✅    │ [[NSBundle mainBundle] loadNibNamed:owner:topLevelObjects:] │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ dragImage:at:offset:… file promise drag                 │ SFTPTableView.m                         │ Suppressed │ NSFilePromiseProvider (complex)                             │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ tableView:writeRows:toPasteboard:                       │ SFTPController.m                        │ Suppressed │ writeRowsWithIndexes:                                       │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ validateMenuItem: informal protocol                     │ SFTPController.m                        │ Fixed ✅   │ NSMenuItemValidation formal protocol                        │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ validateToolbarItem: informal protocol                  │ SFTPController.m                        │ Fixed ✅   │ NSToolbarItemValidation formal protocol                     │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ LSCopyKindStringForURL                                  │ Fixed                                   │ Done ✅    │ NSURLLocalizedTypeDescriptionKey                            │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ recycleURLs (sync)                                      │ Fixed                                   │ Done ✅    │ recycleURLs:completionHandler:                              │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ launchApplication:                                      │ Fixed                                   │ Done ✅    │ openApplicationAtURL:configuration:completionHandler:       │
  ├─────────────────────────────────────────────────────────┼─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────┤
  │ NSNetService resolve                                    │ Fixed                                   │ Done ✅    │ resolveWithTimeout:                                         │
  └─────────────────────────────────────────────────────────┴─────────────────────────────────────────┴────────────┴─────────────────────────────────────────────────────────────┘

  2f. Nullability / Type-Safety Gaps

  - No NS_ASSUME_NONNULL_BEGIN/END in any header
  - No nullable / nonnull annotations on method parameters
  - No lightweight generics on NSArray, NSDictionary, NSMutableArray ivars
  - Protocol conformances were informal; formal ones added for NSMenuItemValidation, NSToolbarItemValidation, NSTableViewDelegate/DataSource

  ---
  3. Modernization Plan — Phases

  Phase 1 (Done ✅) — Build Errors → Deprecation Warnings in Large Files

  - All NSRunAlertPanel, NSBeginAlertSheet, beginSheet:modalForWindow: → NSAlert
  - All selectedRowEnumerator, removeObjectsFromIndices: → modern index set APIs
  - All NSFilenamesPboardType → NSPasteboardTypeFileURL
  - All insertText: in SFTPController → appendAttributedString:
  - All int precision → NSInteger/NSUInteger/NSModalResponse
  - All extern int errno; removed
  - Deprecated drag method pragmas applied
  - NSNetService resolve, LSCopyKindStringForURL, recycleURLs, launchApplication: all replaced
  - loadNibNamed: class method → instance method
  - validateMenuItem:, validateToolbarItem: formal protocol conformances added
  - NSToolbarSeparatorItemIdentifier pragma-suppressed
  - p = '\0' bug fixed; strlcpy/strlcat sizeof bugs fixed

  Phase 2 (Next) — Remaining Small Files

  Fix the remaining 17 warnings in SCPController.m, SCPTransfer.m, NSString(SSHAdditions).m. These are straightforward, same patterns already applied to SFTPController.

  Estimated effort: 1–2 hours

  Phase 3 (Medium) — NSConnection → NSXPCConnection

  Replace the Distributed Objects IPC layer. This is the largest remaining architectural change:

  - SFTPTServer (background SFTP subprocess driver) communicates with SFTPController via DO
  - SCPTransfer communicates with SCPController via DO
  - SSHTunnelAuth communicates with SSHTunnel via DO

  Options:
  1. NSXPCConnection — Apple's modern replacement. Type-safe, process-isolated. Requires formal @protocol definitions for all DO interfaces (already exist as SFTPTServerInterface etc.). Best long-term
   choice but substantial testing required.
  2. GCD + blocks — Replace the background threads + DO with dispatch_async/NSOperationQueue. Since these are same-process (not XPC processes), GCD is simpler and sufficient. No security sandbox
  needed here. Recommended.
  3. Keep NSConnection + suppress warning — Pragmas, since DO still works on macOS 14+ (just deprecated). Stop-gap only.

  Estimated effort: 3–5 days

  Phase 4 (Long-term) — ARC Migration

  Enable ARC project-wide after Phase 3. The MRC patterns are consistent but error-prone. All retain/release/autorelease/drain would be removed by the compiler.

  Blocker: DO/NSConnection code uses autorelease pools in background threads that interact with the threading model. Must resolve Phase 3 first.

  Estimated effort: 1–2 days after Phase 3

  Phase 5 (Long-term) — NSDrawer → Modern UI

  SCPController uses NSDrawer for its drawer panel (deprecated since macOS 10.13). Options:
  - Replace drawer with an NSSplitViewController (requires XIB redesign)
  - Replace with a floating panel or popover
  - Replace with an NSTabViewController inside the main window

  Estimated effort: 1 day

  Phase 6 (Optional) — Swift Migration

  See section 6 below.

  ---
  4. Deprecated API Replacements — Quick Reference

  ┌────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────┬──────────────────────────────┐
  │                                    Old API                                     │                               New API                               │            Notes             │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ NSRunAlertPanel()                                                              │ NSAlert + -runModal                                                 │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ NSBeginAlertSheet()                                                            │ NSAlert -beginSheetModalForWindow:completionHandler:                │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSWindow beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo:] │ [NSWindow beginSheet:completionHandler:]                            │ SCPController pending        │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSTextView insertText:]                                                       │ [[textView textStorage] appendAttributedString:]                    │ SCPController pending        │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ NSFilenamesPboardType                                                          │ NSPasteboardTypeFileURL                                             │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSTableView selectedRowEnumerator]                                            │ [[tv selectedRowIndexes] enumerateIndexesUsingBlock:]               │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSTableView removeObjectsFromIndices:numIndices:]                             │ [array removeObjectsAtIndexes:]                                     │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSTableView selectRow:byExtendingSelection:]                                  │ [tv selectRowIndexes:byExtendingSelection:]                         │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ NSOnState / NSOffState                                                         │ NSControlStateValueOn / NSControlStateValueOff                      │ SCPController pending        │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ NSConnection                                                                   │ NSXPCConnection or GCD                                              │ Phase 3                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ NSDrawer                                                                       │ NSSplitViewController                                               │ Phase 5                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ NSNetService -resolve                                                          │ -resolveWithTimeout:                                                │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ LSCopyKindStringForURL                                                         │ NSURLLocalizedTypeDescriptionKey via getResourceValue:forKey:error: │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSWorkspace recycleURLs:] (sync via performFileOperation:)                    │ -recycleURLs:completionHandler:                                     │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSWorkspace launchApplication:]                                               │ -openApplicationAtURL:configuration:completionHandler:              │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSBundle loadNibNamed:owner:] (class)                                         │ [[NSBundle mainBundle] loadNibNamed:owner:topLevelObjects:]         │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSView convertBaseToScreen:]                                                  │ [NSWindow convertPointToScreen:]                                    │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ [NSView convertScreenToBase:]                                                  │ [NSWindow convertPointFromScreen:]                                  │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ dragImage:at:offset:event:pasteboard:source:slideBack:                         │ NSFilePromiseProvider                                               │ Suppressed — complex rewrite │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ tableView:writeRows:toPasteboard:                                              │ tableView:writeRowsWithIndexes:toPasteboard:                        │ Suppressed                   │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ validateMenuItem: (informal)                                                   │ NSMenuItemValidation protocol                                       │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ validateToolbarItem: (informal)                                                │ NSToolbarItemValidation protocol                                    │ Done ✅                      │
  ├────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┼──────────────────────────────┤
  │ dissolveToPoint:fraction: (NSImage)                                            │ drawAtPoint:fromRect:operation:fraction:                            │ SFTPTableView.m if raised    │
  └────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────┴──────────────────────────────┘

  ---
  5. Apple Framework Replacements for Custom Code

  ┌──────────────────────────────────────────────────────────┬─────────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────┬──────────┐
  │                       Custom Code                        │                Location                 │                              Apple Replacement                               │ Priority │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Manual DO/NSConnection IPC                               │ SFTPTServer, SCPTransfer, SSHTunnelAuth │ NSXPCConnection or NSOperation+GCD                                           │ High     │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Manual PTY / subprocess driving (fdwrite.c, ee.c)        │ SFTPTServer.m, SCPTransfer.m            │ NSTask (partial) — PTY still needs custom C                                  │ Medium   │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Manual Keychain (keychain.c)                             │ keychain.c                              │ SecItemCopyMatching (modernize), or use existing KeychainAccess Carthage dep │ Medium   │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Manual Apple Event handling (aevent.c, ODBEditorSuite.h) │ SFTPController.m                        │ NSAppleEventManager (still valid, but FSRef usage inside needs replacement)  │ Medium   │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ sshversion.c — manual OpenSSH version parse              │ sshversion.c                            │ Keep C, but modernize NSTask-based launch                                    │ Low      │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ argcargv.c                                               │ SCPTransfer.m                           │ Could use NSString componentsSeparatedByString: or keep                      │ Low      │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Manual drag image creation                               │ SFTPTableView.m                         │ NSTableView -draggingImageForRowsWithIndexes:tableColumns:event:offset:      │ Medium   │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ NSNetService for Bonjour                                 │ SFTPController.m                        │ Network.framework (NWBrowser)                                                │ Low      │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Manual date format for file listings                     │ SFTPNode.m                              │ NSDateFormatter (already used), add dateStyle/timeStyle                      │ Low      │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Manual type detection (typeforchar.c)                    │ Supporting code                         │ UTType / UniformTypeIdentifiers.framework                                    │ Low      │
  └──────────────────────────────────────────────────────────┴─────────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────┴──────────┘

  ---
  6. Swift Migration Feasibility

  Verdict: Partial — yes, viable in phases. Core controllers must stay Objective-C for now.

  Blocker Analysis

  The app's core IPC uses Cocoa Distributed Objects (NSConnection), which is not Swift-compatible. The @protocol SFTPTServerInterface used with DO relies on Objective-C runtime message forwarding that
   Swift cannot express cleanly. This must be resolved (Phase 3) before migrating the controllers to Swift.

  MRC (no ARC) is also incompatible with Swift. ARC must be enabled (Phase 4) before any controller can move to Swift.

  Best First Candidates for Swift (after ARC)

  ┌──────────────────────────────┬──────────────────────────────────────────────────────────────────┬────────┐
  │             File             │                              Reason                              │  Risk  │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ SFTPNode.m                   │ Pure model — local filesystem stat/listing, no IPC, no IBOutlets │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ NSImage(IconForType).m       │ Small category, icon lookup                                      │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ NSSet(ImageExtensions).m     │ Trivial — returns a set of strings                               │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ NSMutableArray(Extensions).m │ Trivial extensions                                               │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ NSMutableDictionary(Fugu).m  │ Small extensions                                                 │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ SFTPErrorHandler.m           │ Simple alert presenter, no IPC                                   │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ SFTPAboutPanel.m             │ Simple UI, no IPC                                                │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ UMVersionCheck.m             │ Already uses NSURLSession — clean                                │ Low    │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ SFTPPrefs.m                  │ Preferences panel, moderate complexity                           │ Medium │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────┼────────┤
  │ SCPController.m              │ SCP window, after NSDrawer removed                               │ Medium │
  └──────────────────────────────┴──────────────────────────────────────────────────────────────────┴────────┘

  Files to Postpone

  ┌──────────────────────────────┬──────────────────────────────────────────────────────────────────────────┐
  │             File             │                                  Reason                                  │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ SFTPController.m             │ 5000+ lines, DO IPC, all IBOutlets, all actions — migrate last           │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ SFTPTServer.m                │ DO server background thread — replace with GCD first                     │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ SCPTransfer.m                │ DO client — replace with GCD first                                       │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ SSHTunnel.m, SSHTunnelAuth.m │ DO IPC — replace with GCD first                                          │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ aevent.c                     │ Uses FSRef/FSSpec (Carbon types) — needs separate FSRef migration        │
  ├──────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ keychain.c                   │ C code with Security.framework — can be replaced by Swift but not urgent │
  └──────────────────────────────┴──────────────────────────────────────────────────────────────────────────┘

  Phased Swift Plan

  Phase A (now, no blockers): Add Swift file to target, create bridging header, migrate 2–3 trivial category files to Swift extensions.

  Phase B (after ARC): Migrate SFTPNode, SFTPErrorHandler, SFTPAboutPanel, UMVersionCheck to Swift.

  Phase C (after Phase 3 GCD rewrite): Migrate SCPController, SSHTunnel, SFTPPrefs to Swift.

  Phase D (last): Migrate SFTPController to Swift — break it into smaller coordinator + view model objects first.

  ---
  7. Concrete Changes to Apply Now (Phase 2)

  7a. SCPController.m — 5 fixes

  Fix 1: NSOnState → NSControlStateValueOn
  // Before (line 305):
  if ( [ addToKeychainSwitch state ] == NSOnState ) {
  // After:
  if ( [ addToKeychainSwitch state ] == NSControlStateValueOn ) {

  Fix 2: beginSheet:modalForWindow: → beginSheet:completionHandler:
  // Before (line 380):
  [ NSApp beginSheet: scpSheet
          modalForWindow: scpWindow
          modalDelegate: self
          didEndSelector: NULL
          contextInfo: nil ];
  // After:
  [ scpWindow beginSheet: scpSheet completionHandler: nil ];

  Fix 3: Remove unused rc (line 239)
  // Before:
  NSInteger   rc;
  { NSAlert *alert = ... rc = [alert runModal]; [alert release]; }
  // After: just remove the rc= assignment; if rc is checked, keep as NSModalResponse

  Fix 4: insertText: → appendAttributedString: (line 495)
  // Before:
  [ scpLogField insertText: buf ];
  // After:
  [[ scpLogField textStorage ] appendAttributedString:
      [[ NSAttributedString alloc ] initWithString: buf ]];
  // (or autorelease in MRC)

  Fix 5: Precision loss at line 393 — intValue returns int, local var is int which is fine; the issue is long returned by something. Check and cast.

  7b. SCPTransfer.m — 4 fixes

  Fix 1: pwsent, threestrikes set but unused — add __attribute__((unused)) or use them properly (they already drive the auth flow, the "set but not used" warning is misleading — the variables ARE read
   in conditionals; the warning fires because the compiler sees them only being written in certain paths). Solution: (void)pwsent; at end of scope or correct use.

  Fix 2: t_rate set but unused — set on line 124 but never passed anywhere useful. Either pass to UI or remove and replace with tav[pc_index + 2] inline.

  Fix 3: Format string bug at line 159
  // Before:
  NSLog( @"%@: too long" );  // no argument for %@
  // After:
  NSLog( @"scpBinary: too long" );

  Fix 4: NSConnection deprecation — suppress with pragma (same as SFTPTServer) until Phase 3.

  ---
  8. Build Verification Checklist

  After each phase of changes, verify:

  - xcodebuild -target Fugu -configuration Debug exits 0
  - Warning count does not increase vs. baseline
  - App launches (.app opens without crash)
  - SFTP connection to a test server succeeds
  - Local directory browsing works (left pane)
  - Remote directory listing appears (right pane)
  - Upload a file (drag or button)
  - Download a file (drag or button)
  - Delete local file — goes to trash
  - Delete remote file — prompts and executes
  - Rename remote file (in-cell edit)
  - SCP copy window opens and transfers
  - SSH Tunnel window opens and creates tunnel
  - Preferences panel opens and saves
  - About panel / version check works
  - Contextual menus on both browsers work
  - Bonjour/Rendezvous browser populates (if server present)

  ---
  9. Remaining Issues / Next Steps

  Immediate (Phase 2 — ~2 hours)

  Apply the SCPController/SCPTransfer fixes listed in section 7. This eliminates 16 of the 17 remaining warnings. Only the NSConnection deprecation group will remain.

  Short-term (Phase 3 — ~3–5 days)

  NSConnection → GCD migration. The background thread model is:

  UI Thread (SFTPController)
      ↕ NSConnection / Distributed Objects
  Background Thread (SFTPTServer) — drives sftp subprocess via PTY

  Replacement architecture:
  UI Thread (SFTPController)
      ↕ NSOperationQueue + completion blocks / delegates
  Background NSOperation (SFTPOperation) — drives sftp subprocess via PTY

  The @protocol SFTPTServerInterface methods would become async operations with delegate callbacks. The DO vend/connect ceremony would be replaced by direct object references with thread-safety
  enforced by the operation queue.

  Medium-term (Phase 4 — ~1–2 days after Phase 3)

  Enable ARC. Run the ARC migration tool on each file individually. The tool handles retain/release/autorelease/drain but may miss subtle ownership transfers in C-level callbacks (PTY fd handling).
  Review those manually.

  Files needing manual ARC review:
  - SFTPTServer.m — PTY/subprocess, C callbacks
  - SCPTransfer.m — subprocess, argcargv.c interaction
  - SSHTunnelAuth.m — subprocess, write() calls

  Long-term (Phase 5+)

  - Replace NSDrawer in SCPController with a sheet or split view
  - Replace aevent.c FSRef/FSSpec with modern bookmark URLs (NSURLBookmark)
  - Replace manual Bonjour (NSNetService) with Network.framework
  - Add NSSecureCoding to any archived objects
  - Enable Hardened Runtime for notarization
  - Add NSPrincipalClass and sandbox entitlements if targeting Mac App Store
  - Update Info.plist for Privacy manifests (macOS 15+ requirement)

  Key Risk Areas

  ┌─────────────────────────────────────────────────┬──────────────────────────────────────────────────────┬───────────────────────────────────────────────────────┐
  │                      Area                       │                         Risk                         │                      Mitigation                       │
  ├─────────────────────────────────────────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┤
  │ MRC retain/release in blocks                    │ Crash if block captures object that gets deallocated │ ARC migration eliminates this                         │
  ├─────────────────────────────────────────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┤
  │ PTY master fd lifetime                          │ C-level fd can outlive ObjC wrappers                 │ Explicit close in dealloc (verify)                    │
  ├─────────────────────────────────────────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┤
  │ NSNetService delegate                           │ Delegate retained by NSNetService — potential cycles │ Verify with Instruments                               │
  ├─────────────────────────────────────────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┤
  │ ODB editor callback (aevent.c)                  │ Uses deprecated FSRef/Carbon APIs                    │ Wrap with try/suppress; migrate to NSURL bookmarks    │
  ├─────────────────────────────────────────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┤
  │ dissolveToPoint:fraction: in SFTPTableView drag │ Generates deprecated impl warning if raised          │ Replace with drawAtPoint:fromRect:operation:fraction: │
  └─────────────────────────────────────────────────┴──────────────────────────────────────────────────────┴───────────────────────────────────────────────────────┘
