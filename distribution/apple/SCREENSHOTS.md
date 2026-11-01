# Apple store screenshot package

The generator produces five mobile feature stories and six Mac stories for each of Romanian, English and Russian, using fresh native fictional app captures. The UI pixels are captured from the actual app; the renderer scales and composites the entire screenshot with localized captions, rounded inset image corners and rounded app icons. Upload canvases remain rectangular and opaque. It does not redraw app controls, hide labels in the final image, or include personal card data.

Stories: prepare documents; batch and card selection; consent/PIN; verification picker; card certificate details; Mac adds the embedded public-service browser. A compatible ID card and USB card reader requirement appears on every promotional screenshot. The screenshots make no NFC or hardware-free signing claim. No secure PIN is entered during capture.

## Submission dimensions

- iPhone large-display portrait: 1320 × 2868 PNG.
- iPad 13-inch portrait: 2064 × 2752 PNG.
- Mac: 2880 × 1800 PNG, 16:10.

Each submission export is RGB/opaque PNG. Five mobile images and six Mac images per locale, within Apple's maximum of ten. Original captures and SHA-256 provenance are retained alongside the exports; original Mac window captures can contain alpha and are **not** the submission files.

Current official sources checked 1 November 2026:

- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) — accepted device sizes, formats and slot requirements.
- [App Store localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/) — Romanian, English and Russian are supported listing localizations.
- [App Review Guidelines, accurate metadata](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata) — screenshots show actual use, truthful features and no unsupported claims. App Review approval remains Apple's decision.

## Reproduce

Use a current Debug application with presentation fixtures. The isolated capture flags require all of: Debug, mock card fixture, `md.esemnbun.qa.*` preferences, `MSIGN_QA_NO_HARDWARE=1`, and `MSIGN_SCREENSHOT_CAPTURE=1` to suppress the demo notice. Ordinary demo sessions and Release builds retain the notice. Capture never starts hardware monitoring or submits a PIN.

The all-platform entry point is `python3 distribution/tools/create-store-screenshots.py --output /path/output`. Apple alone: `python3 distribution/tools/apple_capture_all.py --output /path/output`. It builds current SDK applications, chooses the latest installed stable iOS 26 runtime, creates task-owned simulators and deletes only those simulators after capture. Manifests record the exact runtime and SDK; iOS 18 captures are rejected so the real system Liquid Glass tab bar is retained.

```sh
python3 distribution/tools/apple_capture.py --app /path/eSemnBun.app --device DISPOSABLE_SIMULATOR_UDID --family iphone --output /path/raw
python3 distribution/tools/apple_capture.py --app /path/eSemnBun.app --device DISPOSABLE_SIMULATOR_UDID --family ipad --output /path/raw
python3 distribution/tools/apple_capture_macos.py --app /path/macOS/eSemnBun.app --output /path/raw
python3 distribution/tools/apple_render.py --raw /path/raw --output /path/screenshots
```

The iOS capture script shuts down its specified simulator; create a disposable one and delete it afterward. Never pass a simulator that holds a personal session. The Mac script launches only task-owned fixture processes, captures their native window, then terminates those processes.

Final delivery: Desktop/esemnbun-store-submission/2026-11-01/revision2/apple/. No images have been uploaded or submitted to a portal.

Duo compact and expanded images are supplemental promotional/QA images, separate from App Store upload slots. On current iOS 27 foldable runtimes, use the native Device Hub compositor (`--devicehub-helper`) because the simctl framebuffer can omit application scene content. Never render status-only framebuffers as application screenshots.

The default Apple driver automates iPhone, iPad and Mac. Standard phone/tablet capture uses the newest installed iOS 26 runtime. `--developer-dir`, `--ios-app`, `--macos-app` and `--families` allow build reuse and a reduced family set.

Duo orientation automation remains unproven on Device Hub 27.1: native commands can lose device selection, and `simctl` omits app scene content. The delivered 30 Duo images were captured with the native compositor after preparing each physical state through Device Hub. To recapture one prepared state, create a disposable `eSemnBun-store-*` Duo with iOS 27.1, select it in foreground Device Hub, set compact portrait or expanded landscape, then run `apple_capture_all.py --output ROOT --families duo-compact --duo-device UDID --ios-app APP` (or `duo-expanded`). This explicit mode leaves the provided simulator booted. Native dimensions are asserted (1398 × 2034 compact, 2853 × 2007 expanded); incorrectly oriented files are rejected. Existing Accessibility authorization is required. This is a manual preparation step, not fully automated Duo lifecycle coverage.

Outputs are `apple/raw` (unaltered captures and runtime/SDK provenance), `apple/screenshots` (48 standard upload exports) and `apple/supplemental` (30 Duo promotional variants, explicitly not App Store device slots). Capture `--stories` and `--languages` filters allow targeted reruns without replacing unrelated provenance.
