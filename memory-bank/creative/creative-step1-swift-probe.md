# Architecture Decision: Step 1 Swift probe

📌 CREATIVE PHASE START: Swift compilation probe
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 1. Problem

Swift 6 is configured and no Swift file exists. Step 1 must prove the target can compile Swift and emit `Fugu-Swift.h`. The repository has no test target. The original request asked for an empty Swift test file, which can mean a compilation witness or an XCTest bundle.

Requirements:

- One new Swift file, no callers, no behavior.
- Bridging header present and empty.
- `PRODUCT_MODULE_NAME` is `Fugu` so later XIBs and `Fugu-Swift.h` share one module name.
- Still one application target unless a test bundle is clearly worth the extra project risk.

## 2. Options

- Option A: `App/FuguSwiftBridge.swift` in the Fugu app target, plus an empty bridging header.
- Option B: New FuguTests XCTest target and a single empty test.
- Option C: Both A and B in Step 1.

## 3. Analysis

| Criterion | A app probe | B XCTest | C both |
| --- | --- | --- | --- |
| Proves Swift compiles | Yes | Yes | Yes |
| Proves `Fugu-Swift.h` | Yes | Only if the app also has Swift | Yes |
| Project risk | One file, three build settings | New target, host app, scheme | Highest |
| Fits "no behavior change" | Yes | Yes | Yes |

A unit-test bundle does not test the nib, the `sftp` parser, or the keychain. It would be a green test that does not protect the smoke checklist.

## 4. Decision

Selected: Option A.

Rationale: The witness belongs in the app target so the generated header and the module name exist before any screen moves. An XCTest target can wait until there is a pure function worth testing, such as the listing parser after Step 4.

## 5. Implementation notes

- Settings, changed only in the target configurations: `PRODUCT_MODULE_NAME = Fugu`, `DEFINES_MODULE = YES`, `SWIFT_OBJC_BRIDGING_HEADER = App/Fugu-Bridging-Header.h`.
- Bridging header is empty apart from the include guard. Do not import the whole app into Swift in Step 1.
- Swift file:

```swift
import Foundation

/// Proves the Fugu target compiles Swift next to Objective-C. No callers.
enum FuguSwiftBridge {
    static let isEnabled = true
}
```

- Add that file to Compile Sources only.
- Mac check: build log contains a Swift compile of `FuguSwiftBridge.swift`, and the app still launches to the dual-pane window.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 CREATIVE PHASE END
