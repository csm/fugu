# Architecture Decision: transfer process engine

📌 CREATIVE PHASE START: SSH process engine
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 1. Problem

`SFTPTServer`, `SCPTransfer`, and `SSHTunnelAuth` drive system `sftp`, `scp`, and `ssh`. `ee.c` and `sshversion.c` use `fork`. The UI depends on prompt text: password, unknown host key, and the `sftp>` prompt. `establishDOConnection` only allocates `SFTPTServer`. Distributed Objects are already gone.

Requirements:

- Same binaries, same prompts, same known-hosts and keychain behavior.
- No new package unless the system tools cannot do the job.
- Objective-C callers keep a completion or delegate shaped API until they move.
- Work happens on the Mac, where those binaries exist.

## 2. Options

- Option A: Keep system OpenSSH. In Step 4, wrap the current spawn path in Swift. Prefer `Process` only where it can own the same pty behavior. Leave `fork` in place if `Process` cannot.
- Option B: Replace the engine with a third-party SSH library.
- Option C: Reimplement SFTP in Swift.

## 3. Analysis

| Criterion | A system OpenSSH | B SSH package | C custom SFTP |
| --- | --- | --- | --- |
| Prompt and auth parity | Keeps today's parser | New auth UI and host-key flow | New everything |
| Dependency | None | Package plus review | None, large code |
| Mac fit | Uses the installed `ssh` | Embeds another stack | Embeds another stack |
| Step 4 size | Wrapper | Rewrite | Rewrite |

`Process` does not automatically provide the pty these tools use. That is why Option A allows `fork` to remain behind the Swift type.

## 4. Decision

Selected: Option A.

Rationale: Fugu is a front end for the system SSH tools. Swapping the protocol stack changes authentication and listing behavior, which violates the parity rule. A package is a future product decision, not part of this migration.

## 5. Implementation notes

- Step 2 does not touch `ee.c`, `argcargv`, `fdwrite`, `typeforchar`, or `sshversion.c`.
- Step 4 introduces a Swift type, `SSHProcess`, that owns start, write, read, and stop. The first implementation calls the existing C spawn functions.
- Move a call to `Process` only after a Mac session shows the same password prompt, host-key prompt, and `sftp>` prompt.
- Public Objective-C methods keep their current names until `SFTPController` is Swift. Add completion handlers beside them. Do not delete the old methods in the same commit.
- Cancel must still reap the child. The smoke test is: connect, interrupt, quit, and `pgrep` shows no leftover `sftp`, `scp`, or `ssh` started by Fugu.

```mermaid
graph LR
    UI["SFTPController"] --> Swift["SSHProcess"]
    Swift --> C["existing fork and pty"]
    C --> Bin["sftp / scp / ssh"]
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 CREATIVE PHASE END
