# Active Context

## Current Focus

`/build` is blocked on the Mac baseline. Step 1 has not started.

## Status

Planning and creative decisions are done. On 5 Nov 2026 the build command was attempted in this Linux workspace. `xcodebuild` is not installed. No project files were changed.

## Next action, on the Mac

From the Fugu checkout that has Xcode:

```bash
xcodebuild -project Fugu.xcodeproj -scheme Fugu -configuration Development build
```

If the scheme is missing, mark Fugu shared in Xcode first. After that build exits 0 and the app opens, create `migrate/step-01-project-structure-and-bridging` and follow `/workspace/memory-bank/creative/creative-step1-layout.md`, `creative-step1-nullability.md`, and `creative-step1-swift-probe.md`.

## Latest Changes

Recorded the failed environment check in `tasks.md` and `progress.md`. Source tree is still the original flat Objective-C project, plus untracked `.cursor/` and `memory-bank/`.
