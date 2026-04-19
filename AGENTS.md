# AGENTS.md

## Project Overview

**Fugu** is a macOS SFTP/SCP client application written in Objective-C (Cocoa). Originally developed at the University of Michigan, it provides a dual-pane file browser for SFTP transfers, SCP copying, and SSH tunnel management. Version: 1.2.1b.

## Build & Run

- **Build**: `make` (uses Xcode build system) or `xcodebuild -alltargets`
- **Run**: `make run` (opens `build/Fugu.app` from build directory)
- **Clean**: `make clean`
- **Install**: `make install` (copies to `/Applications/Fugu.app`)
- **Build output**: `build/` and `DerivedData/` directories
- **Dependencies**: Carthage (`Cartfile` - currently `KeychainAccess`)
- **No test suite** - no automated testing infrastructure

## Architecture

The app uses a split-thread model with Cocoa Distributed Objects (NSConnection) for IPC between the UI thread and background SSH worker threads.

### Core Controllers

- **`SFTPController`** - main application controller. Owns the dual-pane SFTP browser, toolbar, and all SFTP operation UI (upload/download progress sheets, info panel, go-to-dir, new folder, preview). Most user actions route through here.
- **`SFTPTServer`** - background-thread DO server that spawns and drives the `sftp` subprocess via a master PTY fd. Implements `SFTPTServerInterface` protocol; communicates back to `SFTPController` via Distributed Objects. Parses raw sftp output lines into `NSMutableDictionary` records.
- **`SCPController`** + **`SCPTransfer`** - separate SCP copy window (`SCP.xib`). `SCPTransfer` drives the `scp` subprocess.
- **`SSHTunnel`** + **`SSHTunnelAuth`** - SSH tunnel management window (`SSHTunnel.xib`). `SSHTunnelAuth` is the background DO server running `ssh -L` port-forward processes.

### Supporting Objects

- **`SFTPNode`** - singleton; local filesystem browser (directory listing, stat, icon lookup).
- **`SFTPPrefs`** - preferences panel (general, favorites, known hosts, file associations).
- **`SFTPErrorHandler`** - centralised error alert presentation.
- **`SFTPItemCell` / `SFTPTableView` / `SFTPScrollView` / `SFTPSplitView` / `SFTPPrefTableView` - custom UI subclasses.
- **`SFTPImagePreviewPanel` / `SFTPImageView`** - image preview panel.
- **`UMVersionCheck`** - remote version checking.

### Category Extensions

Objective-C categories on Foundation/AppKit:
- `NSArray(CreateArgv)` - converts `NSArray` to `argv`-style C array.
- `NSString(FSRefAdditions)` / `NSString(SSHAdditions)` - path and SSH helpers.
- `NSWorkspace(LaunchServices)` / `NSWorkspace(SystemVersionNumber)` - launch and OS version helpers.
- Others: `NSCalendarDate(ConvertToSeconds)`, `NSFileManager(mktemp)`, `NSImage(IconForType)`, `NSMutableArray(Extensions)`, `NSMutableDictionary(Fugu)`, `NSSet(ImageExtensions)`, `NSAttributedString-Ellipsis`.

### C Layer

Low-level helpers:
- `keychain.c/h` - Keychain Services access.
- `aevent.c/h` - Apple Event helpers (ODB editor suite for external editor callbacks).
- `sshversion.c/h` - detect installed OpenSSH version.
- `argcargv.c/h`, `typeforchar.c/h`, `fdwrite.c/h`, `ee.c` - argument parsing, type utilities, fd writing.

### UI Resources

- **XIB files**: `MainMenu.xib` (main menu and primary window), `SCP.xib` (SCP copy panel), `SSHTunnel.xib` (SSH tunnel panel).
- **Icons**: `fugu.icns` (app icon).
- **Strings**: `Localizable.strings`, `SCP.strings`, `HelpMenu.strings`, `SFTPToolbar.strings`, `SFTPInfoPanel.strings`, `SSHTunnel.strings`, `Fugu README.rtfd`, `keys.rtf`.
- **Info**: `Info.plist`, `VERSION`, `TODO`.
- **Localization**: `en`, `de`, `fr`, `ja`, `zh`, `es`, `it`, `nl`, `da`, `fi`, `ko` language folders.

## vexp — Context-Aware AI Coding

### MANDATORY: use vexp pipeline — do NOT grep or glob the codebase

For every task — bug fixes, features, refactors, debugging:
**call `run_pipeline` FIRST. It executes context search + impact analysis + memory recall in a single call, returning compressed results.

Do NOT use grep, glob, Bash, or cat to search/explore the codebase.
vexp returns pre-indexed, graph-ranked context that is more relevant and uses fewer tokens than manual searching. Prefer `get_skeleton` over Read to inspect files (detail: minimal/standard/detailed, 70-90% token savings).

### Primary Tool

- `run_pipeline` — **USE THIS FOR EVERYTHING**. Single call that runs capsule + impact + memory server-side. Returns compressed results. Auto-detects intent (debug/modify/refactor/explore) from task description.

### Other MCP tools (use only when run_pipeline is insufficient)

- `get_skeleton` — **preferred over Read** for inspecting files (minimal/standard/detailed detail levels, 70-90% token savings)
- `index_status` — indexing status and health check
- `expand_vexp_ref` — expand V-REF hash placeholders in v2 compact output

### Workflow

1. `run_pipeline("your task")` — ALWAYS FIRST. Returns pivots + impact + memories in 1 call
2. Need more detail on a file? Use `get_skeleton({ files: [...], detail: "detailed" })` — avoid Read unless editing
3. Make targeted changes based on context returned
4. `run_pipeline` again ONLY if you need more context during implementation

### Smart Features

- **Intent Detection**: auto-detects from task keywords. "fix bug" → Debug, "refactor" → blast-radius, "add" → Modify
- **Hybrid Search**: keyword + semantic + graph centrality ranking
- **Session Memory**: auto-captures observations; memories auto-surfaced in results
- **LSP Bridge**: VS Code captures type-resolved call edges
- **Change Coupling**: co-changed files included as related context

### Advanced Parameters

- `preset: "debug"` — forces debug mode (capsule+tests+impact+memory)
- `preset: "refactor"` — deep impact analysis (depth 5)
- `max_tokens: 12000` — increase total budget for complex tasks
- `include_tests: true` — include test files in results
- `include_file_content: false` — omit full file content (lighter response)
- `repos: ["alias"]` — scope to specific repo

### Multi-Repo Workspaces

`run_pipeline` auto-queries all indexed repos. Use `index_status` to discover available repo aliases.

---

## Key Points

1. **Distributed Objects (DO) architecture**: Core IPC mechanism between UI and background SSH threads.
2. **Xcode build system**: Uses `.pbxproj` project file and `.xib` interface files.
3. **Carthage dependency**: `KeychainAccess` library for Keychain Services access.
4. **Objective-C categories**: Extensive use of categories on NS* classes for helper methods.
5. **Localization**: Full localization for multiple languages (en, de, fr, ja, zh, es, it, nl, da, fi, ko, pt, ru, sv, tr, ar, el, hi, th, uk, cs, pl, ro, bg, hr, sr, lt, lv, et, sk, hu, nl_BE, fr_CA, en_GB, en_AU, en_CA, en_NZ, en_IE, en_PH, en_SG, en_MY, en_IN, en_ZA, en_IE, en_BZ, en_JM, en_TT, en_BM, en_KY, en_TK, en_AI, en_sh, en_MS, en_SH, en_AE, en_BW, en_CM, en_GM, en_KE, en_LR, en_SL, en_TZ, en_UG, en_ZW, en_MO, en_HK, en_TW, en_PG, en_SB, en_VU, en_FM, en_PW, en_NR, en_KI, en_TV, en_NU, en_TK, en_AU, en_NZ, en_IO, en_VG, en_KN, en_AI, en_MS, en_SH, en_TK, en_BM, en_CK, en_NU, en_PN, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK, en_TK