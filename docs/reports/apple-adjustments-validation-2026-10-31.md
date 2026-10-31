# Apple adjustments validation — 31 October 2026

## Implemented behavior

- Shared native signing hierarchy: standalone card/reader target, selected files, independent document drop target.
  macOS has no extra “Semnezi cu” container around the dotted reader placeholder.
- Wide iPad and expanded iPhone Duo use 24-point inner/outer pane gutters and a sign action centered under the card.
  The right pane offers format selection, removal, file import/drop and results share/export.
- 3:5 portrait frames contain a compact uniformly scaled head-and-shoulders bust. The chip is right-centered with
  eight contact regions: three left, three right and two central. Native centered paging also keeps the
  middle selected card fully visible and aligned with the sign action.
- PIN cells are 48 points high, adapt to narrow screens, and document/holder content is centered.
- All Apple localized prose uses typed stable catalog keys rather than source-text lookup.
- Certificate reads, document signing, verification and activity persistence have narrow injectable ports;
  file access/output and persistence are separate adapters. Debug history/preferences are isolated from user data.
- Direct-distribution macOS embeds a separate configurable `SMAppService.agent` watcher. It opens the app for a
  newly connected reader or newly inserted card while the UI app is closed. Its initial snapshot/removals are silent.
  It does not connect a card or access credentials. The App Store build excludes the utility.
- Initial application launch and subsequent reopen requests show the main macOS window.
- A newly remembered PIN is stored at most once per frozen batch, after its first successful file. A failed
  storage attempt is not repeated for subsequent files; card signing still stops on the first signing error.

## Evidence

- Eight Apple policy tests pass: four batch/session policy tests and four actual helper transition policy tests.
  Log: `/tmp/esemnbun-apple-revision-policy-tests.log`.
- Native Debug macOS and iOS simulator builds pass with Xcode 27.1 RC; unsigned sandboxed Store-candidate Release
  arm64 build passes, including its bundled macOS privacy manifest (app-owned UserDefaults, CA92.1) and
  absence of the external insertion helper. Logs: `/tmp/esemnbun-apple-revision-build.log`, `/tmp/esemnbun-ios-revision-build.log`,
  `/tmp/esemnbun-store-revision-build.log`.
- Actual separate-helper process test used a Debug-only synthetic snapshot source (no CryptoTokenKit manager).
  With the app closed, reader insertion opened PID 84867 and visible window 14496. After quitting that app,
  card insertion opened a different process, PID 84878, and visible window 14504.
  `macos/2026-10-31/watcher-validation.json` records this proof.
- First launch without an explicit “show” argument opened PID 85421/window 14529 using a fresh Debug-only
  preference domain. `macos/2026-10-31/first-launch-validation.json` records it. Existing preferences were not reset.
- Twenty-one current targeted screenshots live under the Desktop screenshot folder: nine macOS,
  eight iPad and four expanded Duo images in `macos/2026-10-31` / `ios/2026-10-31`. They exercise empty reader,
  selected middle card, batch files and larger blank PIN controls. Older dated matrices remain historical evidence;
  this focused refresh does not claim a full new matrix of every screen. No physical-card PIN was entered.
- Non-store Release helper compiles separately and a binary check confirms its Debug-only mock-snapshot
  argument is absent. The helper has its own smart-card entitlement; probing/unresponsive cards count as present.

## Release boundary

The owner's Apple Distribution identity is installed. A local universal App Store archive compiled and reached
codesign, which requested the owner's login-keychain password to use its private key. No password was supplied;
the own signing process was stopped. The Distribution-signed archive/export and its acceptance checks therefore remain
unverified. Log: `/tmp/esemnbun-mac-store-signed-archive.log`.

A separate ad-hoc signed copy of the current Store Release app launched successfully with the same sandbox,
smart-card, user-selected-file and network entitlements. It used bundle identifier `md.esemnbun.qa.sandbox`,
leaving the production container/preferences intact. Its actual process sandbox check returned `1` with errno `0`.
The native window displayed “Connect the reader”; its CryptoTokenKit monitor was available. The app used a new
QA container, bundled its privacy manifest, excluded the external helper and ran with the bridge disabled.
`store-sandbox-runtime.png` and `store-sandbox-validation.json` record this bounded runtime proof. The app was
terminated afterwards. This test does not establish Distribution export, real-card signing, PIN keychain access,
file-picker export or loopback HTTPS inside the sandbox.

System Settings may require approval of the registered background item. The synthetic process test validates
closed-app activation, while signed installed-app registration and that system approval remain release acceptance
steps. No privileged wrapper, store submission, account agreement or security setting was changed.
