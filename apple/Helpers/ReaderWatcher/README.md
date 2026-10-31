# Reader insertion utility

The direct-distribution macOS app embeds `esemnbun-reader-watcher` in `Contents/Helpers` and
`md.esemnbun.reader-watcher.plist` in `Contents/Library/LaunchAgents`. Settings registers the
bundled LaunchAgent using `SMAppService.agent`. macOS may require approval in System Settings;
Settings exposes that state and links to Login Items. Disabling the setting unregisters the job.
No administrator rights, sudo wrapper, shell profile or global daemon is installed.

The helper is a separate process and remains available after the user quits the menu-bar app.
It observes CryptoTokenKit slot names and card-presence state every 500 ms. A newly attached reader
or an empty-to-present card transition opens the containing app. Probing, unresponsive and valid cards all
count as physically present, so the app can display reading/error guidance as well as ready state. Initial state and removal are
silent. The helper never connects a card, transmits APDUs, reads certificates, asks for a PIN or signs.
The main app handles reopen and its first explicit launch by showing its main window.

The App Store configuration does not embed or register the helper. Its existing foreground
card detection and system-supported app login preference remain available.

`ReaderInsertionPolicyTests` test the same transition policy compiled into the helper without
hardware. Run the Apple policy package tests as one batch with `swift test --package-path apple`.
A signed installed app and System Settings approval must be used for end-to-end background-item
acceptance; Debug screenshots alone do not establish that approval.
