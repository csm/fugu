# Data-model Decision: remote listing entries

📌 CREATIVE PHASE START: Listing model
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 1. Problem

`SFTPTServer` parses `sftp` text into `NSMutableDictionary`. There is no model class. Keys written today:

- `name` (string, unknown encoding allowed)
- `NameAsRawBytes` (data)
- `perm` (string mode)
- `type` (`file`, `directory`, or the `typeforchar` result)
- `owner`, `group`, `size`, `date` (strings; owner and group may be `N/A`)

Callers in `SFTPController` read these keys directly. The parser returns nil for `.`, `..`, and unreadable lines.

Requirements:

- Same keys, same nil cases, same permission strings.
- Objective-C can keep using dictionaries until the controller is Swift.
- Do not invent fields the parser does not emit.

## 2. Options

- Option A: Keep dictionaries as the only representation.
- Option B: Add a Swift struct with `init(dictionary:)` and `dictionary` for the way back. The parser still returns `NSMutableDictionary` until it moves.
- Option C: Replace the dictionary now with an `@objc` class and change every reader in Step 3.

## 3. Analysis

| Criterion | A dictionaries | B struct plus bridge | C replace now |
| --- | --- | --- | --- |
| Parity | Exact | Exact if the bridge is lossless | Easy to drop `NameAsRawBytes` |
| When readers change | Never | When each caller moves | Step 3, inside `SFTPController` |
| ObjC interop | Native | Dictionary stays the ObjC API | Forced |
| Risk | No progress | Low | High |

`NameAsRawBytes` has to stay `Data`. A `String`-only name loses the unknown-encoding path in `NSString(UnknownEncoding)`.

## 4. Decision

Selected: Option B.

Rationale: A struct gives new Swift code a type without a flag-day edit of the table view. The dictionary remains the wire format until `SFTPTServer` and `SFTPController` are both Swift.

## 5. Implementation notes

- Name the type `RemoteEntry`. Properties match the keys above. `owner` and `group` are optional strings because VShell rows use `N/A` and some rows omit them.
- `nameRawBytes` maps to `NameAsRawBytes`. Do not rename the dictionary key.
- `type` stays a string in Step 3. An enum can wait until every producer is Swift.
- The struct is not `@objc`. The bridge methods are the boundary.
- Step 3 adds the type and tests the round trip on the Mac with one captured `sftp` line per server shape already handled in `remoteObjectFromSFTPLine` (OpenSSH long form, old OpenSSH octal mode, VShell). Do not delete the dictionary readers.
- Step 4 may make the parser return `RemoteEntry` internally and convert to a dictionary at the Objective-C boundary.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 CREATIVE PHASE END
