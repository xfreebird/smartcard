# Apple store screenshot package

The generator produces five mobile feature stories and six Mac stories for each of Romanian, English and Russian, using fresh native fictional app captures. The UI pixels are captured from the actual app; the renderer only scales and composites the entire screenshot with localized captions. It does not redraw app controls, hide labels in the final image, or include personal card data.

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

```sh
python3 distribution/tools/apple_capture.py --app /path/eSemnBun.app --device DISPOSABLE_SIMULATOR_UDID --family iphone --output /path/raw
python3 distribution/tools/apple_capture.py --app /path/eSemnBun.app --device DISPOSABLE_SIMULATOR_UDID --family ipad --output /path/raw
python3 distribution/tools/apple_capture_macos.py --app /path/macOS/eSemnBun.app --output /path/raw
python3 distribution/tools/apple_render.py --raw /path/raw --output /path/screenshots
```

The iOS capture script shuts down its specified simulator; create a disposable one and delete it afterward. Never pass a simulator that holds a personal session. The Mac script launches only task-owned fixture processes, captures their native window, then terminates those processes.

Final delivery: Desktop/esemnbun-store-submission/2026-11-01/apple/. No images have been uploaded or submitted to a portal.
