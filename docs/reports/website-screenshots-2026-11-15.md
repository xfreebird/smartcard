# Website screenshots — 15 November 2026

Refreshed the scrolling signing scene on all five platforms: three native states (reader disconnected,
reader connected without a card, card ready), each in light and dark appearance. All 30 captures use
isolated Debug fixtures with the demo-data banner hidden. The 10 documentation overview images and
15 legacy image URLs mirror the same refreshed captures.

The documentation has 348 mobile screenshots with visible status clocks. 285 were normalized using
cropped native 09:41 glyphs; 63 already showed 09:41. Six cropped iPad sheets have no system clock.
The normalization preserves the original canvas, alpha and every pixel outside the declared clock
rectangle. Document timestamps, certificate data, results and UI content are unchanged. Each edit's
original/result hash and rectangle is in `website/static/img/screenshot-clocks.json`.

Windows captures exclude desktop wallpaper, taskbar, shadows and rounded-corner background.
All 54 existing Windows guide images were cropped too; their annotation coordinates were transformed
from the original canvas and the English/Romanian/Russian task pages regenerated. Crop boxes and
hashes are in `website/static/img/screenshot-window-crops.json`. The perimeter scan found no coloured
desktop pixels on any of the 54 guide or six animation captures. Mac window corners retain their
native transparency, with no captured desktop behind them; Linux captures contain the GTK window only.

## Capture provenance and checks

- Existing Debug apps were used: macOS built 12 November, iPhone capture app retained from the
  13 November store-artwork run, Android Debug APK built 14 November, Linux Debug app built
  12 November, Windows Debug publish retained from 13 November. Binary hashes and clock results
  are in `website-screenshots-2026-11-15/capture-audit.json`. No native rebuild or native test run
  was performed for this asset update.
- iPhone: task-owned iPhone 17 Pro Max simulator, iOS 26.5, native 1320×2868; system clock override.
  Android: dedicated emulator session, native 1080×2400, System UI demo clock and 24-hour format.
  macOS: normal 1280×800-point app window, native 2560×1600 capture. Linux: isolated X11 surface,
  native 1280×800. Windows: interactive VM window, cropped to 1352×900.
- Native ready markers were checked. All 30 scene images were visually inspected, including both
  appearances and all states. System-clock OCR confirmed all 12 mobile animation images.
- Documentation clock OCR confirmed 347/348 clocks; the remaining Romanian Android tablet menu
  screenshot was inspected visually and reads 09:41. Every clock edit was checked for pixel changes
  outside its declared rectangle; none were found. Clock manifest/hash check passed.
- Text extraction covered all 619 guide, overview, scene and verification screenshots for banner
  review. Settings' demo-mode controls and sample-document wording are ordinary documented content;
  the global demo-data banner is absent. Refreshed scene captures received a separate final audit.
- JSX/JavaScript and Python syntax parsed; whitespace check passed. Website regression checks now
  enforce reviewed image hashes, dimensions and complete distinct scene/theme coverage. Image URLs
  include a new revision so returning browsers request the replacement artwork.

The contact sheet is `website-screenshots-2026-11-15/animation-contact-sheet.jpg`.
Native fixtures demonstrate presentation only; these images do not prove real card signing.
## Publication

Published source: `023edbaad200ebb4e2b459ee91b3aed87aef92cb`.
[Website workflow 43695852792](https://github.com/xfreebird/smartcard/actions/runs/43695852792)
succeeded: 36 tests, guide organization/illustration checks, English/Romanian/Russian production
build, SEO verification and Pages deployment. The repository CI run also passed.

All **394 changed public PNGs** were fetched over HTTPS and their SHA-256 hashes matched the committed
images. The full readback is `website-screenshots-2026-11-15/live-images.json`. Direct curl succeeded
after Python's TLS client received connection resets; no image mismatch remained.

Live Chrome verification covered desktop and 390×844 mobile scrolling, native light/dark artwork,
09:41 on the mobile scene, cache revision URLs and the enlarged Windows guide with transformed
callouts and clean window edges. No browser console errors were observed. Original system theme
preference and normal browser viewport were restored. Physical Safari/Android browsers were not
exercised; the five-platform native image sets were inspected separately.

Screenshots: `live-desktop.jpg`, `live-desktop-dark.jpg`, `live-mobile.jpg`, and
`live-windows-guide.jpg` in the adjacent evidence directory. The task-owned iPhone simulator,
Android emulator session and Windows capture scheduled task were cleaned up; existing devices,
VMs and unrelated working files were preserved.
