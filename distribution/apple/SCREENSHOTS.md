# Apple store screenshot package

The generator produces five mobile feature stories and six Mac stories for each of Romanian, English and Russian, using fresh native fictional app captures. The UI pixels are captured from the actual app; the renderer scales and composites the entire screenshot with localized captions, rounded inset image corners, unmodified official Apple iPhone product PNG frames and their real camera cutouts, and rounded app icons. Upload canvases remain rectangular and opaque. It does not redraw app controls, hide labels in the final image, or include personal card data.

Stories: prepare documents; batch and card selection; consent/PIN; verification picker; card certificate details; Mac adds the embedded public-service browser. A compatible ID card and USB card reader requirement appears on every promotional screenshot. The screenshots make no NFC or hardware-free signing claim. No secure PIN is entered during capture.

## Submission dimensions

- iPhone large-display portrait: 1320 × 2868 PNG.
- iPad 13-inch portrait: 2064 × 2752 PNG.
- Mac: 2880 × 1800 PNG, 16:10.
- iPhone Duo: 1398 × 2034 compact and 2853 × 2007 expanded, five of each per locale in the dedicated Duo slot.

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

Final delivery: Desktop/esemnbun-store-submission/2026-11-01/revision2/apple/. Upload state is recorded in docs/reports/store-uploads-2026-11-01.md; uploads do not submit the app for review.

Duo compact and expanded images use the dedicated APP_IPHONE_DUO Store slot (ten images per locale). They remain in the supplemental directory for compatibility with existing capture tooling. On current iOS 27 foldable runtimes, use the native Device Hub compositor (`--devicehub-helper`) because the simctl framebuffer can omit application scene content. Never render status-only framebuffers as application screenshots.

The default Apple driver automates iPhone, iPad and Mac. Standard phone/tablet capture uses the newest installed iOS 26 runtime. `--developer-dir`, `--ios-app`, `--macos-app` and `--families` allow build reuse and a reduced family set.

Duo orientation automation remains unproven on Device Hub 27.1: native commands can lose device selection, and `simctl` omits app scene content. The delivered 30 Duo images were captured with the native compositor after preparing each physical state through Device Hub. To recapture one prepared state, create a disposable `eSemnBun-store-*` Duo with iOS 27.1, select it in foreground Device Hub, set compact portrait or expanded landscape, then run `apple_capture_all.py --output ROOT --families duo-compact --duo-device UDID --ios-app APP` (or `duo-expanded`). This explicit mode leaves the provided simulator booted. Native dimensions are asserted (1398 × 2034 compact, 2853 × 2007 expanded); incorrectly oriented files are rejected. Existing Accessibility authorization is required. This is a manual preparation step, not fully automated Duo lifecycle coverage.

Outputs are `apple/raw` (unaltered captures and runtime/SDK provenance), `apple/screenshots` (48 standard upload exports) and `apple/supplemental` (30 Duo upload variants, compact and expanded). Capture `--stories` and `--languages` filters allow targeted reruns without replacing unrelated provenance.

## Header and Search Results

Header and Search Results use two opaque RGB compositions at their exact placement sizes: Header is 3840 × 1646 (21:9) and Search Results is 3840 × 2560 (3:2). Both show unaltered native Sign captures for NFC and reader signing in official Apple frames. The central headline and method names remain within Apple's safe area, while enlarged phone bodies extend into auxiliary artwork. Search uses a stacked headline; Header leaves room for the App Store navigation controls. Check phone-size previews as well as full-resolution files. Original owner photos are references only and must never be committed or uploaded.

Export approved sources with `python3 distribution/tools/export-apple-creative.py --output /path/apple/creative`. Upload in each locale under Header and Search Results and preview both placements. See [Apple creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications).

Refresh the framed iPhone and Duo screenshot sets with `bundle exec ruby distribution/tools/upload-apple-draft.rb ios PACK --screenshots-only --replace-screenshots`. Replacement explicitly refreshes existing screenshot sets; it does not submit the version.

## Official Apple product frames

Use Apple’s original iPhone 17 Pro Max Deep Blue portrait frame, iPhone Duo Night Sky outer closed portrait frame, and inner open landscape frame. Native display openings are exactly 1320×2868, 1398×2034 and 2853×2007. Screens are inserted at their native pixel coordinates before the entire device is scaled uniformly. Camera hardware, buttons, hinge, corners and metal edges come from Apple’s PNG; no synthetic bezel is drawn. The renderer checks asset hashes and refuses a mismatched capture size.

Download [iPhone 17](https://devimages-cdn.apple.com/design/resources/download/Bezel-iPhone-17.dmg) and [iPhone Duo](https://devimages-cdn.apple.com/design/resources/download/Bezel-iPhone-Duo.dmg) from [Apple Design Resources](https://developer.apple.com/design/resources/#product-bezels). Accept Apple’s Design Resources License before mounting/using the files. The owner authorized acceptance for this work. With both volumes mounted, run `python3 distribution/tools/import-apple-product-bezels.py`. Assets and license copies are cached under `~/Library/Caches/esemnbun-apple-bezels`; licensed source PNGs are not redistributed in the repository. `ESN_APPLE_BEZEL_CACHE` selects a different renderer cache.

Use `--screenshots-only --replace-changed-screenshot-sets` with the draft uploader to compare local and remote checksums and refresh only sets whose artwork changed. Unchanged sets and creative placements remain intact.

After upload processing, run `bundle exec ruby distribution/tools/verify-apple-screenshot-upload.rb ios PACK` (or `macos`). This reads every target set back, requires COMPLETE processing and expected story order, and compares each server source-file checksum with its local PNG. JSON receipts are saved under `PACK/upload`; this verification does not change any Store data.
