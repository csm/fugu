# Architecture Decision: app entry and bridging cleanup

📌 CREATIVE PHASE START: `@main` cutover
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 1. Problem

`main.m` calls `NSApplicationMain`. `Info.plist` sets `NSMainNibFile` to `MainMenu` and `NSPrincipalClass` to `NSApplication`. The nib creates `SFTPController`, and `init` assigns `NSApp.delegate`. Step 6 has to remove `main.m` without taking the delegate away from the nib in the same change.

Requirements:

- Launch still loads `MainMenu.xib`.
- The delegate object is still the nib object until a separate change says otherwise.
- The bridging header disappears only when Swift no longer imports a project Objective-C header.
- C files may remain compiled in the target after that. They do not need the bridging header.

## 2. Options

- Option A: A Swift `@main` type whose only job is `NSApplicationMain`, nib unchanged.
- Option B: A Swift app delegate that loads the nib itself and replaces `SFTPController` as `NSApplicationDelegate` in the same step.
- Option C: Keep `main.m` permanently.

## 3. Analysis

| Criterion | A Swift NSApplicationMain | B new delegate | C keep main.m |
| --- | --- | --- | --- |
| Launch parity | Same call | Different owner | Unchanged |
| Nib risk | None | High | None |
| Finishes the migration | Yes | Yes, with extra behavior | No |

Option B mixes entry-point cleanup with the hardest object in the app. Those are different failures.

## 4. Decision

Selected: Option A, and only on `migrate/step-06-app-lifecycle-and-cleanup`, after Steps 1–5 are merged on the Mac.

## 5. Implementation notes

- The Swift entry point is equivalent to today's `main.m`. Leave `NSMainNibFile` and `NSPrincipalClass` as they are.
- Delete `main.m` in that commit, after the Mac build shows the same first window.
- Do not move `[NSApp setDelegate:]` out of `SFTPController` here, whether that class is still Objective-C or already Swift.
- Remove `SWIFT_OBJC_BRIDGING_HEADER` when no Swift file imports a project `.h`. C sources (`aevent.c`, `keychain.c`, and any spawn helpers still in C) stay in Compile Sources.
- Drop `@objc` and `NSObject` only from types that no XIB and no remaining Objective-C file names. `RemoteEntry` is already a struct. UI classes that XIBs instantiate stay `@objc`.
- Mac check: cold launch, Services menu `secureCopyFile` still reaches the app, quit leaves no SSH child.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 CREATIVE PHASE END
