# Native validation and remaining fixes — 7 November 2026

This phase builds on the UX/security review and the first recommendation implementation. It ran on the main Mac and the MacBook Air's Fedora/Windows guests. The working tree remains uncommitted; no release, store submission, publication or real-card signing was performed. All runtime documents and history records used here are synthetic.

## Outcome

Documents and History now have independent persistence on every platform. Native checks exercised document details, clearing History and restarting the application. Details inspect the current file: a historical success record attached to an unsigned fixture does not turn into a valid signature claim.

Apple verification now exposes missing detached XML originals as incomplete/unconfirmed, offers native original-file selection in Verify and document details, and revalidates only the explicitly selected files. The core distinguishes unavailable original bytes from a genuine content mismatch. Android's corresponding flow was exercised through the actual Downloads picker.

A new iOS persistence correction stores app-owned document references relative to Documents and migrates recognized legacy container URLs. App updates can change the container UUID; saved documents must not become unavailable merely because that location changed. External macOS paths remain unchanged. Traversal and malformed relative paths are rejected, and resolving a location grants no external-file permission.

The Swift CLI now implements `verify --json` as the next read-only automation step. Capability discovery accurately advertises this only on macOS/Linux; Windows still advertises its narrower capabilities. MCP, signing approval brokerage and remote access remain separate work.

## Build and test results

| Check | Result |
| --- | --- |
| Swift core | 65 tests, 5 expected opt-in skips, zero failures |
| Apple policy/document-library suite | 30 tests, zero failures |
| Focused genuine detached-signature/contained-read tests | 3 tests, zero failures |
| Focused document-location/migration tests | 6 tests, zero failures; included in the full Apple policy suite |
| Android core | 123 tests, 1 expected live-TSA skip, zero failures |
| Android saved-PIN certificate-binding regression | 1 test, zero failures |
| Fedora native GNOME suite | 18 tests, zero failures |
| Windows CLI capability suite | 10 tests, zero failures |
| Swift CLI process regression script | 11 checks passed |
| iPhone Duo native Documents-modal smoke | 1 UI test passed, default surface only |
| iOS SDK 27.1 Debug simulator build | Passed, including App Intents metadata extraction |
| iOS SDK 27.1 unsigned Release simulator build | Passed |
| macOS signed desktop Debug build | Passed; strict signature/distribution checks and smart-card entitlement verified |
| macOS signed AppStore Debug build | Passed; Store sandbox/distribution boundaries verified separately |
| Android final Debug APK | Built and installed for native runtime checks |
| Fedora native Debug app and CLI | Built; actual capability/verification JSON processes exercised |
| Windows native x64 WinUI Debug app on ARM64 guest | Built with zero warnings/errors |

Totals include skips where stated. Focused tests overlap the full suites and must not be added to them as independent coverage. The initial plain Debug invocation of the macOS Store scheme compiled the desktop configuration; the boundary verifier rejected it. It was replaced with an actual AppStore Debug build and successful Store-boundary verification.

## Native behavior checked

### iOS

An isolated simulator used real PreferencesActivityStore persistence with hardware disabled. Tests migrated legacy signed-output records, opened current-file details, cleared History, terminated/relaunched and confirmed Documents remained while History stayed empty. A genuine software-simulated detached signature showed incomplete verification until its original was selected through Files.

The final upgrade check installed the new app without reseeding the existing QA records, changed the container UUID and retained readable document details. The original-selection test subsequently passed with the actual TXT original and an updated integrity result. These phone assertions preceded only the last caption/severity refinement; all Apple variants were rebuilt afterward. Earlier picker assertion failures were traced to test selectors selecting an outgoing hidden XML cell/folder before a Files navigation transition; they are not presented as proven product defects. The completed-inspection guard additionally prevents needless parent reinspection during nested presentation.

### iPhone Duo

A dedicated iOS 27.1 Duo simulator passed the native Documents-modal test: the saved XML opened in the actual modal, original-file selection was present, and the incomplete verdict was visible. Its XCTest screenshot is included as default-surface evidence. The added Device Hub control attempt did not complete, so this phase does not claim another display switch, fold continuity or a second-surface Documents check. The earlier report's full Sign-screen display matrix remains separate evidence, not a substitute for this phase's modal validation. The smoke predates only the final caption/severity refinement; the same missing-original layout remains unchanged.

### Android

The final APK was exercised on the explicit API 36 ARM64 emulator with phone, compact landscape and tablet viewports. Opening/closing details left the saved history/library bytes unchanged. History clearing followed by process death/restart preserved Documents; a legacy-only profile migrated eligible local signing outputs and excluded verification/browser events. A software-key PDF showed successful integrity/RSA checks and unconfirmed trust for its test CA. Certificate disclosure expanded and scrolled.

Detached XML was tested from missing-original guidance through the actual Downloads picker to successful content/signature revalidation. Missing/inaccessible files displayed localized recovery text without an internal filesystem path. Viewports were emulator size profiles, not claims about physical device models.

### macOS

Actual native interaction opened document details, Quick Look and the Share menu. The preview displayed the synthetic PDF text; Share was canceled without transmission. Clearing isolated History retained the library; exported preferences contained history=0, library=1, and relaunch displayed that saved document. The Preview action now has its correct label and the sheet/preview dimensions are bounded.

macOS captures follow the Preview/layout fixes and precede the final shared verification-caption refinement and iOS-specific location-policy extension. Both desktop and Store variants were rebuilt afterward; their signed boundaries were checked separately. Finder Service routing was compiled and its plist validated; actual Finder registration/invocation and external login-item changes were not exercised in this pass.

### Windows and Fedora

The Air's native guests exercised isolated migrated profiles, whole-row document activation, History cleanup, relaunch and persisted history=0/library=1/file-exists assertions. Fedora also exercised a narrow dark modal. Windows uses x64 emulation on an ARM64 guest; this does not establish native ARM64 or multi-monitor coverage.

Runtime checks required waiting for an actual verification outcome, not merely an open/loading dialog. Detailed desktop reports record the final settled-state and close/reopen results, final artifact hashes and captures.

## Defects corrected during validation

- iOS app-owned saved-document references could retain an old app-container UUID after upgrade. Relative persistence and safe legacy migration address this.
- Apple missing originals were previously interpreted as content modification. Incomplete metadata and explicit selection now separate the two cases.
- The new Apple Preview button used a signature-stamp label. A dedicated localized Preview resource replaces it.
- Apple unconfirmed-trust results used a caption that also said no signature was found. Recognized signatures now have a distinct trust explanation, and independent invalid checks take priority over missing-original status.
- Android's saved-document fixture omitted its signing-output flag. The corrected fixture now exercises the independent library.
- Android's modal consumed almost the full screen for short results. It sizes to its contents with a bounded scrollable maximum.
- Android missing-file errors could expose ENOENT/internal cache paths. Saved-document details now show localized recovery text.
- Linux whole-row pointer activation did not open details. The list now resolves the actual activated row and opens its modal.
- Linux presentation dropped the new missing-reference metadata. It now preserves incomplete status and neutral original-file guidance.
- Windows saved rows displayed a raw Verify resource key. They now use the proper localized action.
- Windows dialogs did not inherit the parent dark appearance. They now explicitly follow the page theme.
- Windows ContentDialog reparenting could leave details stuck in Verifying by invalidating the asynchronous result on page unload. Verification lifecycle is now tied to dialog open/close, with final settled-state and ordinary close/reopen checks. The small fixture completed too quickly to establish forced in-flight cancellation.

## Structured CLI verification

`esemnbun verify --json <file.pdf|signature.xml> [documents_directory]` emits one versioned JSON object. `ok:true` means the verifier executed; `data.status` carries valid, invalid, incomplete, unconfirmed or no_recognized_signature. Results explicitly report offline mode and unchecked revocation.

The command performs no reader/card/PIN/environment access. Input must be a regular explicit file, and detached references remain confined beneath the selected directory. It omits signer identity, certificate content, document paths/names and bytes. Usage/read failures use sanitized stable codes on stdout, with diagnostics on stderr. Unavailable originals alone do not establish modification; an independent cryptographic failure remains invalid.

The process suite covers capabilities, unsigned content, missing/resolved/tampered originals, unreadable input, usage, unsupported signing JSON, symlink and FIFO rejection, and failure to accept an unsupported XML quoting representation. The existing vendor-oriented XML canonicalizer still does not support every equivalent XML spelling; this interface does not expand its underlying standards coverage. Windows structured document verification remains unavailable and is advertised accordingly.

Reproduce the process suite with `python3 scripts/test-cli-json.py /path/to/esemnbun --detached-fixtures /path/to/synthetic-fixtures`. The optional genuine fixtures are exported by the software-simulated detached-signature core test; no physical card is required.

## Boundaries and remaining validation

These results establish representative local native Debug behavior and compilation of the stated production/Store variants. They do not establish physical-reader signing, live biometric/Keychain/Keystore/Windows Hello/Secret Service authorization, current revocation/TSA validity, physical Duo behavior, every accessibility/language/size combination, installer behavior or Store deployment.

App Intents metadata was extracted in both iOS configurations, including localized phrases. Actual Siri voice execution, locked-device authentication, on-device discovery and provider revocation still require device validation. macOS Store sandbox runtime, Finder Service cold/warm delivery and external login-item approval changes also remain unexercised.

Next implementation stages remain Windows CLI verification parity, a local MCP adapter and foreground approval broker, and optional deeper Siri/document-entity integration. These are not implied by capability discovery or by passing this phase's tests.

## Evidence

Sanitized current-build screenshots and manifests are in `validation-next-2026-11-07/`, `desktop-documents-validation-2026-11-07/` and `evidence/apple-documents-2026-11-07/`. Detailed records are `documents-android-validation-2026-11-07.md`, `documents-desktop-validation-2026-11-07.md`, `apple-detached-originals-2026-11-07.md` and `apple-documents-native-validation-2026-11-07.md`. Full local build/test logs remain under `/tmp/esemnbun-next-*` and platform-specific validation directories.

Only task-owned processes/simulators/emulators are stopped or removed after captures. Existing installed applications, user profiles and the existing Duo simulator are preserved.
