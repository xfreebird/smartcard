# Windows and Android image preparation

Checked 1 November 2026 against the official requirements below. This is a local upload pack; no upload or submission is performed by the scripts.

## Microsoft Store

Official source: [MSIX screenshots, images and trailers](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/screenshots-and-images).

- Four native desktop screenshots per Romanian, English and Russian listing. PNG, at least 1366 × 768 pixels, below 50 MB each. Captures use DWM visible window bounds, avoiding unrelated desktop content.
- Screenshots contain actual app UI with fictional cards and synthetic documents. No promotional overlay or extra logo is added. The source capture flag suppresses only the demo banner in Debug screenshot fixtures; normal demo mode remains labelled.
- Localized captions are separate JSON entries, each below 200 characters. The Store uploads screenshots/captions per locale.
- Optional hero art is 1920 × 1080 PNG, without text, app UI, device imagery, national/political imagery or flags. It uses a document/signature motif. Do not upload the contact sheet as a listing image.
- The optional app tile is 300 × 300 PNG from the app's existing artwork.

## Google Play

Official source: [Add preview assets to showcase your app](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).

- Four screenshots for each phone, 7-inch tablet and 10-inch tablet section, in each of Romanian, English and Russian. They are 1080 × 1920 portrait or 1920 × 1080 landscape, 24-bit RGB PNG, without alpha. These meet the 9:16/16:9 large-screen recommendation and minimum 1080-pixel edge.
- Tablet screenshots are unaltered UI without extra marketing text. Native device layout is captured through emulator density/window configuration, not by stretching an image.
- Feature graphics are localized 1024 × 500 RGB PNG. They use the real app card illustration, concise text, no ranking/price/testimonial claims and no prominent duplicate app icon. The app's 512 × 512 icon is supplied separately.
- The same app supports tablets, but no screenshots are supplied for unsupported TV/Wear/Automotive/VR form factors.
- The demo fixture characters and certificates are fictional; no physical card, PIN, personal documents or signed personal output are used. No banner is painted out of screenshots after capture. Only lossless RGB format conversion is applied.

## Reproduction

- `distribution/tools/capture-android-store.py`: dedicated emulator, current Debug APK, `--output distribution/google/assets/android`.
- `distribution/tools/capture-windows-store.ps1`: run in an interactive isolated Windows test session with a self-contained Debug app and output folder. It uses a separate preferences file and mock services; never terminates the installed app.
- `distribution/tools/render-windows-android-assets.py`: localized Play feature graphics, text-free Microsoft hero art, app icons and captions.
- `distribution/tools/validate-windows-android-assets.py`: verify dimensions/formats, create checksummed asset manifest and reviewer contact sheet.

Raw capture manifests record locale, page, mock scenario and source build identity. The final checksummed inventory is `distribution/windows-android-assets.json`. Generated exports and the source screenshot/asset list should be regenerated together when UI changes.

Android activity fixtures are intentionally omitted from the upload pack: their stored demo subtitles predate keyed localization and mix languages. The four retained screens demonstrate signing, card selection, verification input and browser connection without manufacturing translated UI.

Build evidence: Android Debug APK build and Release Kotlin compilation passed after capture gating. Windows self-contained Debug publish passed on Windows ARM; screenshots were captured on the native Windows desktop at 100% scale. The app executable SHA-256 is recorded in the capture manifest. Capture tasks were removed and the original installed app left running. Android dedicated read-only emulator was stopped after capture.
