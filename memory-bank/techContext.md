# Tech Context

## Build

- Project: `/workspace/Fugu.xcodeproj` (object name still `ScruFTP`, product `Fugu`).
- Configurations: Development, Deployment, Default. Deployment target macOS 11.5. `SWIFT_VERSION = 6.0` with zero Swift files.
- `PRODUCT_BUNDLE_IDENTIFIER = edu.umich.fugu`. `INFOPLIST_FILE = Info.plist`.
- Linked frameworks: Cocoa, Security, CoreServices, CoreFoundation.
- No CocoaPods, Carthage, or Swift package on disk. `audit.md` mentions KeychainAccess; that dependency is not in this tree.
- `CC = /usr/bin/gcc` and Development `ZERO_LINK = YES` are leftover settings. Leave them for a later build-settings pass. They are not Step 1.
- Development host: the local Mac with Xcode. Build with `xcodebuild -project Fugu.xcodeproj -scheme Fugu -configuration Development build` from that checkout.
- The Fugu scheme currently lives only under gitignored `xcuserdata`. Share it from Xcode on the Mac if a fresh clone has no scheme.
- A user scheme named `externaleditor` points at a target that is gone. Do not build it.
- This cloud workspace is Linux and does not run `xcodebuild`. It is not a substitute for the Mac build.

## Languages and size

About 13,300 lines across the `.m`, `.h`, and `.c` files. `SFTPController.m` is the bulk of that (implementation starts at line 176 and runs past line 5400). 42 headers. No nullability annotations anywhere in source.

## Localization

Only `en.lproj` (`MainMenu.xib`, `Prefs.xib`, `SCP.xib`, `SSHTunnel.xib`). Images and `fugu.icns` live at the repository root and are grouped virtually under Resources.

## Tests

No test target, no test files. "Pass all tests" is not a safety net until a target exists.
