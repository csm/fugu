# Architecture Decision: Step 1 nullability

📌 CREATIVE PHASE START: Nullability
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 1. Problem

No header uses `NS_ASSUME_NONNULL`. Swift would import almost every object as an implicitly unwrapped optional. Wrapping a whole header, including `IBOutlet` ivars, marks those ivars nonnull even though they are nil inside `init` before the nib connects them.

Requirements:

- Swift sees real optionality on anything that can be nil.
- Connected outlets still work after the nib loads.
- No runtime behavior change. This is annotations only.
- C headers (`keychain.h`, `sshversion.h`, and the rest) stay on `_Nullable` / `_Nonnull`, not the assume-nonnull macros.

## 2. Options

- Option A: `NS_ASSUME_NONNULL_BEGIN` around each entire `.h`, ivars included.
- Option B: Assume nonnull around methods only. Leave the ivar block outside it. Mark pointers that can be nil as `nullable`.
- Option C: Skip nullability until a later step.

## 3. Analysis

| Criterion | A whole header | B methods only | C defer |
| --- | --- | --- | --- |
| Swift import quality | High, but outlets lie | High | Unchanged |
| Early-nil crash risk | Higher | Lower | None |
| Diff size | Medium | Medium | None |
| Fits Step 1 | Yes | Yes | Delays the interop goal |

`SFTPTServer` already returns nil for a bad `sftp` line. That return must be `nullable`. `IBAction` senders can be nil when called from code. `NSError **` out-parameters stay nullable.

## 4. Decision

Selected: Option B.

Rationale: The nib owns outlet lifetime. Pretending an outlet is nonnull in `init` hides the only bug the annotation is supposed to show. Methods that never return nil can sit inside the assume-nonnull region.

## 5. Implementation notes

- Put `NS_ASSUME_NONNULL_BEGIN` after the ivar block and `NS_ASSUME_NONNULL_END` at the end of the `@interface`.
- Annotate every `IBOutlet` ivar `_Nullable`. Do not convert those ivars into properties in Step 1.
- Mark nullable: listing parsers that return nil, optional `NSError **`, and `IBAction` senders (`id _Nullable`).
- Add lightweight generics only when the element type is obvious and already true, such as an array of strings passed as argv. Leave listing dictionaries as `NSMutableDictionary` until the listing-model decision lands.
- Do not annotate inside `.m` files except to satisfy a warning the header change creates.
- Verify on the Mac with a build that treats new nullability warnings as a failed Step 1.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 CREATIVE PHASE END
