# Style Guide

Follow the Swift API Design Guidelines. This is a macOS AppKit app.

- Types that cross the Objective-C boundary stay classes with explicit `@objc` names. Pure Swift state uses structs and enums.
- Access control is `private` or `internal`. No new public surface.
- Concurrency comes later (`async`/`await` with `@objc` completion wrappers). Step 1 adds no runtime behavior.
- Do not introduce UIKit, `UIViewController`, or `SceneDelegate`.
- Do not add a third-party package when Foundation, AppKit, Security, or `Process` already covers the job.
- Folder names match features that exist today: `App`, `Core`, `Features/SFTP`, `Features/SCP`, `Features/SSHTunnel`, `Features/Browser`, `Resources`. Do not create empty `ViewModels` or `Models` directories.
- Nullability: `NS_ASSUME_NONNULL_BEGIN` / `END` on Objective-C headers. Mark pointers that can be nil (`NSError **`, optional return values, disconnected outlets) as `nullable`. Leave C headers on `_Nullable` / `_Nonnull`.
- Comments only where the next reader would otherwise miss a constraint (XIB selectors, Gestalt packing, OpenSSH text parsing).
