# Automated screenshot pack

From the repository root:

```sh
python3 distribution/tools/create-store-screenshots.py --output "$HOME/Desktop/esemnbun-store-submission/current"
```

The entry point builds and captures isolated mock applications, sequentially runs Apple, Windows and Android capture drivers, renders localized presentations, validates the Apple upload slots and metadata, and writes `pack-manifest.json` with source revision and image hashes. It never uses physical cards or PINs. Demo banners are suppressed only in guarded Debug capture fixtures. Normal interactive demo mode remains labelled.

Select platforms with `--platforms apple,windows,android`. Use `--dry-run` to inspect the exact argv pipeline without launching anything, or `--render-only` to reuse an existing pack's raw captures. Driver failures stop the pipeline; they are not silently replaced by old images.

Requirements: macOS with Xcode and current iOS simulator runtimes, Python/Pillow; Android SDK/JDK; configured SSH access to the MacBook Air and its running Windows test VM. Duo capture additionally needs the iOS 27 runtime, Device Hub and existing macOS Accessibility authorization for the native capture helper. Standard iPhone/iPad captures use an iOS 26 or newer runtime and the modern SDK. Platform drivers print actionable missing-prerequisite errors. They create disposable device/task instances and preserve user sessions. See each driver's help and the repository VM skill for machine provisioning. The output option is configurable and existing outputs are not recursively deleted.

Presentation policy: round inset screenshot and application-icon artwork; retain opaque rectangular store canvases with required dimensions. Actual app controls are not painted over. Microsoft native screenshots remain separate from promotional compositions. Google retains native phone/tablet upload sets. Duo compact/expanded exports use the dedicated APP_IPHONE_DUO slot (1398×2034 and 2853×2007), ten images per locale; the supplemental folder name is retained for capture-tool compatibility.

The default Apple driver covers standard iPhone, iPad and Mac. Duo orientation cannot currently be reproduced reliably without native Device Hub interaction. The delivered compact/expanded Duo sets are complete, but unattended Duo state transitions remain open in PLAN.md. For a targeted Duo rerun, manually prepare a task-owned `eSemnBun-store-*` simulator in foreground Device Hub, select its fold state/orientation, then invoke `apple_capture_all.py --output ROOT --families duo-compact --duo-device UDID` (or `duo-expanded`). Its exact source dimensions are checked. This opt-in mode leaves the caller-prepared device intact. Run the top-level `--render-only` pipeline afterward to combine those raw captures with the standard pack.

## Uploading prepared drafts

Apple listing and screenshot uploads use `bundle exec ruby distribution/tools/upload-apple-draft.rb ios|macos PACK` with `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` from the owner's offline secrets. An app record must exist first. This uploads localized draft assets, skips duplicate images and never submits or releases. Set `REVIEW_CONTACT_PHONE` only when uploading the owner's approved review contact; do not commit the number. The separate Mac record uses `eSemnBun for Mac` to avoid localized name collisions with the iOS bundle, with English artwork also supplied for its primary en-GB locale.

Microsoft: export the current listing CSV from Partner Center, then run `python3 distribution/tools/prepare-microsoft-import.py --template EXPORTED.csv --pack PACK --output /absolute/path/microsoft`. Import the **whole output folder**, which contains the CSV and its referenced images. The selected root folder name is included in image paths as required by Partner Center. Upload the current MSIX separately and verify the portal's validation result before saving.

Android promotional compositions use 1440×2560 portrait and 2560×1440 landscape canvases for the Play Console's 9:16/16:9 slots. Actual application UI remains proportional within each composition. Native captures remain separately available.

The 1 November Google upload uses `PACK/promotional/android/{en,ro,ru}/{phone,seven-inch,ten-inch}`, four images per slot, plus localized `PACK/google/assets/android/{locale}/feature-graphic.png` and the shared icon. The native captures remain available for audit. Windows uploads use the native `microsoft/assets` sets.

Apple creative assets: export `distribution/apple/creative/source/{en,ro,ru}.png` using `python3 distribution/tools/export-apple-creative.py --output PACK/apple/creative`, then run `bundle exec ruby distribution/tools/upload-apple-creative.rb PACK` with the same ASC credentials. This queries Apple's current reference data, uploads each localized universal image into Asset Library, and creates/read-verifies Header and Search Results placements on the editable iOS 0.2.0 draft. It does not submit assets for review. Reruns reuse identical artwork; an existing placement pointing to different artwork stops for review rather than silently replacing it. Receipts contain asset/placement IDs and states, never credentials.
