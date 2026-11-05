# Product Context

Fugu is a dual-pane file transfer utility for macOS 11.5 and later.

User-visible surfaces that must keep working:

- Connect to an SSH host, authenticate, list a remote directory, upload, download, mkdir, delete, rename, preview, and edit remote files.
- SCP copy window (`SCP.xib`) and the Services menu item `secureCopyFile`.
- SSH tunnel window (`SSHTunnel.xib`).
- Preferences (`Prefs.xib`): general, favorites, known hosts, file associations, transfers.
- Passwords stored via the Security framework (`SecItem`).
- External-editor handoff (ODB Apple Event suite in `aevent.c`).
- Version check against `http://rsug.itd.umich.edu/software/fugu/version.plist`.

Persistence is `NSUserDefaults` plus the login keychain. Directory listings are dictionaries, not model objects. There is no document format to migrate.
