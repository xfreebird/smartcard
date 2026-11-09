# File protection implementation and validation — 2026-11-09

## Delivered source changes

- Password and certificate/card encrypt/decrypt in all three native cores and desktop CLIs.
- MoldSign AES password compatibility, plus read-only legacy 3DES, DES and RC2 support. New password encryption uses AES-256; certificate CMS uses AES-128/RSA PKCS#1 v1.5.
- Encryption-key discovery from card PKCS#15 directories, key-usage checks, identity revalidation before PIN verification, extended secure-message APDUs and no automatic PIN retries. Signing-only keys are not repurposed.
- Localized EN/RO/RU Protect files entry in Documents on macOS, iPhone/iPad, Android, Windows and Linux. Native file selection, password confirmation, certificate import/card selection and separate save step.
- Desktop best-effort overwrite/removal with explicit confirmation and link/volume guards. Mobile does not offer a false overwrite guarantee for document providers.
- Bounded parsers/input sizes, exclusive CLI/Windows/Linux output creation (Apple uses the native export picker), secret-field clearing and no PIN/password command arguments. New Windows output files receive an owner-only ACL at creation; POSIX CLI output uses mode 0600.

## Evidence

| Check | Result |
|---|---|
| Swift/macOS core regression | 83 tests, eight opt-in skips, zero failures |
| Linux core regression | 63 tests, seven opt-in skips, zero failures |
| Kotlin core tests and Android Debug APK | Passed, including independent extended APDU vectors and simulated-card unwrap |
| Android emulator instrumentation | AES round trip and vendor 3DES/DES/RC2 fixtures passed inside Android runtime |
| RC2 implementation | Eight RFC 2268 vectors and vendor fixtures passed; needed because Android has no RC2 cipher provider |
| iOS simulator app/widget build | Passed |
| macOS Debug app build | Passed; screenshot binary ad-hoc signed with smart-card entitlement, no iCloud provisioning claim |
| Linux GNOME build | Passed |
| Windows native WinUI build | Passed on final source, zero warnings/errors; an earlier clean attempt hit a transient x64 translation-cache file lock |
| Windows simulated-card tests | 22 focused encryption, card, file-I/O, owner-only ACL, extended-message and capability tests passed on final source |
| Swift and Windows CLI integration | Password round trip, byte comparison, original preservation, existing-output refusal and explicit disposable-file removal passed |
| Vendor reverse interoperability | Vendor password worker and exact IAIK CMS library read Swift, Kotlin and C# generated files |
| Localization generation/check | Passed |

The full Windows run reported 239 passed and four failures: the capability-command expectation needed updating for the new commands; two existing MCP stdio timing checks and a bridge TLS timeout also failed in the loaded VM. After updating the capability expectation, all 22 focused checks passed. The three existing MCP/bridge failures also passed on isolated rerun (three tests, zero failures). The initial full-run failures are retained here rather than described as a clean full-suite pass.

## Screenshot provenance

Local review assets: `.local/encryption-compatibility/screenshots/` (ignored). Captures use Debug-only fictional filename/card fixtures and no demo banner. They show the native forms, not successful real-card operations. Targets: iPhone 18 Pro/iOS 27, iPad Pro 11-inch/iOS 27, iPhone Duo/iOS 27.1, Android API 36 foldable/tablet emulator, macOS, Fedora 44 GNOME and Windows 11 ARM64 running the x64 app. The 48 PNGs cover password, certificate, decrypt and desktop-removal forms in light/dark, with the exact set and SHA-256 hashes in `screenshots/manifest.json`. Windows captures use PrintWindow for the task process so an older foreground installation cannot be mistaken for the new build. Android phone captures use a 1080×2400 test display override, restored afterwards; foldable/tablet captures use the native emulator display.

## Limits and release gates

- Physical-card decryption and vendor Desktop hardware/UI round trips remain untested; no real PIN was supplied or used. A card must actually expose a supported encryption key/certificate.
- CBC is unauthenticated. Padding success cannot prove a correct password or integrity; the UI/CLI tells users to check decrypted content.
- Overwriting is best effort only. SSD translation, copy-on-write, snapshots, backups, cloud copies and other copies may retain content.
- Native forms and runtime crypto are checked separately. Linux actions stay in a fixed footer while the form scrolls. Screenshots do not establish complete file-provider save/cancel/background behavior on every OS.
- No store submission, release, commit or push is part of this feature change.
