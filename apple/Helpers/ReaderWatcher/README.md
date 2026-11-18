# Reader insertion utility

Both macOS editions embed `esemnbun-reader-watcher` in `Contents/Helpers` and
a job plist in `Contents/Library/LaunchAgents`. Settings registers the
bundled LaunchAgent using `SMAppService.agent`. macOS may require approval in System Settings;
Settings exposes that state and links to Login Items. Disabling the setting unregisters the job.
No administrator rights, sudo wrapper, shell profile or global daemon is installed.

The helper is a separate process and remains available after the user quits the menu-bar app.
It observes CryptoTokenKit slot names and card-presence state every 500 ms. A newly attached reader
or an empty-to-present card transition opens the containing app. Probing, unresponsive and valid cards all
count as physically present, so the app can display reading/error guidance as well as ready state. Initial state and removal are
silent. The helper never connects a card, transmits APDUs, reads certificates, asks for a PIN or signs.
The main app handles reopen and its first explicit launch by showing its main window.

The Store job is `md.esemnbun.mac.reader-watcher`. Its executable has an embedded identity,
its own sandbox and smart-card entitlement. A team-prefixed macOS app group shares the demo-mode
flag. On insertion the helper delivers `esemnbun-reader://inserted` directly to its containing
app through Launch Services. The app handles this as a window request, including on cold launch.
The background item and Start at sign-in have separate opt-ins.

`ReaderInsertionPolicyTests` test the same transition policy compiled into the helper without
hardware. Run the Apple policy package tests as one batch with `swift test --package-path apple`.
A signed installed app and System Settings approval must be used for end-to-end background-item
acceptance; Debug screenshots alone do not establish that approval.
