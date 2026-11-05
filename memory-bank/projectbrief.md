# Project Brief

Fugu 1.2.1b is a macOS SFTP/SCP client (bundle id `edu.umich.fugu`). It browses a local folder and a remote SFTP folder, copies with SCP, and manages SSH local forwards. The UI is AppKit XIBs. The transfer engine shells out to the system `sftp`, `scp`, and `ssh` binaries.

## Task

Incrementally migrate the Objective-C/C codebase to idiomatic Swift and a feature-based on-disk layout. Every step must keep the app building and behaviorally identical. There is no automated test suite.

## Development host

All implementation and verification happen on the local Mac with Xcode. The Linux workspace does not build or run the app.

## Non-goals for the first step

No Swift rewrites of controllers, no SSH library swap, no SwiftUI conversion, no deployment-target change.
