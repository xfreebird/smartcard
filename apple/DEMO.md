# User-controlled demo mode

macOS: Settings → General → Demo mode. iOS/iPadOS: Card → Settings → Demo mode.
Enabling presents an explicit disclaimer. Cancel leaves the mode off; acceptance persists the
choice, installs fictional cards/sample documents immediately, and displays a visible demo banner.
The setting is available in normal Release builds and the Mac App Store configuration.

Demo signing simulates progress and creates new, unsigned PDF samples marked `DEMO SAMPLE` and
`NOT A VALID ELECTRONIC SIGNATURE`. It never reads or overwrites an imported document's bytes,
never asks for a real PIN and never opens a card. Outputs have unique `DEMO-result-…pdf` names and
are available through the normal export/share controls. Demo verification shows an explicit
simulation notice instead of claiming cryptographic validity.

The app keeps demo PIN/history dependencies in memory, stops its bridge and reader monitor, and
rejects all hardware transport/enumeration access through an atomic `DemoHardwareGate`. A live
connection prevents changing modes until it disconnects. Reader snapshots and old bridge callbacks
are ignored while demo is active. Switching modes clears selected documents/results/certificates
and restores the corresponding history/vault boundary. iOS's embedded browser becomes inert while
demo is active.

The non-App-Store insertion helper reads the app's persisted demo preference. It continues updating
its insertion baseline without launching during demo, avoids a deferred launch immediately after
exit, and resumes normal behavior on the next reader/card insertion.

## Implementation boundaries

- `DesignSystem/DemoModeSettings.swift`: shared native toggle, disclaimer, banner.
- `Services/Demo/DemoHardwareGate.swift`: synchronous connection/transition interlock.
- `Services/Demo/DemoDocumentFiles.swift`: deterministic unsigned PDF/sample inputs.
- `Services/Demo/DemoAppServices.swift`: simulated signer/verifier and gated transport wrapper.
- `MemoryPinVault` / `MemoryActivityStore`: isolated volatile dependencies, available in Release.
- `AppModel`: orchestration and mode transitions; the production card protocol remains unchanged.
- `MobileSettingsView`: iOS native settings entry point; macOS uses General Settings.

## Verification, 31 October 2026

- 17 hardware-free Apple policy tests passed, including transport interlock, PDFKit parsing of the
  visibly unsigned sample, preservation of original fixture inputs, and helper suppression/resume.
- macOS Debug, non-Store Release, Mac App Store Release configuration, iOS simulator Debug and iOS
  device Release compilation passed with signing disabled. Distribution signing was not attempted.
- Native macOS QA accepted the disclaimer, enabled demo without restarting, simulated two outputs,
  showed the centered empty saved-PIN state, and returned to a cleared live workspace. The QA live
  side used an injected empty reader/denied transport; no physical card or PIN was used.
- One native iPhone16Pro/iOS18.3 UI test passed the explicit disclaimer, mock signing, persistence
  after relaunch, and safe return to live. Its screenshots include share controls; actual native
  share-sheet presentation was not verified. An optional stronger presentation check was stopped
  while its runner was stalled, preserving the earlier passing result and evidence.
- The existing Debug insertion helper passed a real process test with fake JSON reader snapshots
  and an isolated preference domain. It stayed quiet in demo and on exit, then opened an isolated
  fixture app on the next fake insertion.
- The tray Open/Quit separator is implemented and the action ordering was observed in native AX.
  A separate tray screenshot was not verified because the capture selected the main window.

Evidence is under `~/Desktop/esemnbun-screenshots/{macos,ios}/2026-10-31/user-demo/` with hash/proof
JSON. macOS captures were archived as original JPEGs and converted to actual PNG files. Logs:

- `/tmp/esemnbun-user-demo-policy-tests.log`
- `/tmp/esemnbun-user-demo-macos-build.log`
- `/tmp/esemnbun-user-demo-macos-release-build.log`
- `/tmp/esemnbun-user-demo-macos-store-release-build.log`
- `/tmp/esemnbun-user-demo-ios-build.log`
- `/tmp/esemnbun-user-demo-ios-release-build.log`
- `/tmp/esemnbun-user-demo-helper-test.log`
- `/tmp/esemnbun-user-demo-ios-native4/GestureProof.xcresult`

For a dedicated Debug UI fixture, use an isolated `MSIGN_DEMO_PREFERENCES_SUITE` beginning with
`md.esemnbun.qa.` and `MSIGN_QA_NO_HARDWARE=1`. This injects an empty reader source and denied live
transport while leaving the user-facing demo toggle/disclaimer functional. Do not use real user
preferences or data. Existing `MSIGN_DEMO_CARDS` screenshot scenarios remain hardware-free and
locked; that developer fixture does not replace the user-facing persistent setting.
