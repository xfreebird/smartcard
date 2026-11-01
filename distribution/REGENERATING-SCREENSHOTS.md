# Automated screenshot pack

From the repository root:

```sh
python3 distribution/tools/create-store-screenshots.py --output "$HOME/Desktop/esemnbun-store-submission/current"
```

The entry point builds and captures isolated mock applications, sequentially runs Apple, Windows and Android capture drivers, renders localized presentations, validates the Apple upload slots and metadata, and writes `pack-manifest.json` with source revision and image hashes. It never uses physical cards or PINs. Demo banners are suppressed only in guarded Debug capture fixtures. Normal interactive demo mode remains labelled.

Select platforms with `--platforms apple,windows,android`. Use `--dry-run` to inspect the exact argv pipeline without launching anything, or `--render-only` to reuse an existing pack's raw captures. Driver failures stop the pipeline; they are not silently replaced by old images.

Requirements: macOS with Xcode and current iOS simulator runtimes, Python/Pillow; Android SDK/JDK; configured SSH access to the MacBook Air and its running Windows test VM. Duo capture additionally needs the iOS 27 runtime, Device Hub and existing macOS Accessibility authorization for the native capture helper. Standard iPhone/iPad captures use an iOS 26 or newer runtime and the modern SDK. Platform drivers print actionable missing-prerequisite errors. They create disposable device/task instances and preserve user sessions. See each driver's help and the repository VM skill for machine provisioning. The output option is configurable and existing outputs are not recursively deleted.

Presentation policy: round inset screenshot and application-icon artwork; retain opaque rectangular store canvases with required dimensions. Actual app controls are not painted over. Microsoft native screenshots remain separate from promotional compositions. Google retains native phone/tablet upload sets. Supplemental iPhone Duo captures are identified separately from official device upload slots when their dimensions are not accepted by a store.

The default Apple driver covers standard iPhone, iPad and Mac. Duo orientation cannot currently be reproduced reliably without native Device Hub interaction. The delivered compact/expanded Duo sets are complete, but unattended Duo state transitions remain open in PLAN.md. For a targeted Duo rerun, manually prepare a task-owned `eSemnBun-store-*` simulator in foreground Device Hub, select its fold state/orientation, then invoke `apple_capture_all.py --output ROOT --families duo-compact --duo-device UDID` (or `duo-expanded`). Its exact source dimensions are checked. This opt-in mode leaves the caller-prepared device intact. Run the top-level `--render-only` pipeline afterward to combine those raw captures with the standard pack.
