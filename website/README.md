# eSemnBun website

Docusaurus source lives here. `npm ci && npm run build` compiles it into **website/pages/** (generated output, not committed). `npm start` develops locally; `npm run serve` previews the production build.

GitHub Actions builds and deploys that directory through GitHub Pages. The initial address is https://xfreebird.github.io/smartcard/ . The public store URLs are `/smartcard/`, `/smartcard/support/`, `/smartcard/privacy/` and `/smartcard/terms/` on that host. After acquiring the domain, set `SITE_URL=https://esemnbun.md` and `BASE_URL=/` in the build configuration, and configure its DNS/Pages custom domain.

App Store / Play / Microsoft listing links are included with availability labels while review/testing is pending. Direct installer downloads lead to the latest GitHub Release. Store listing URL updates are separate from website deployment.

The landing sequence uses native app captures and the existing reader illustration. Reduced-motion users receive a static layout. No analytics scripts or app credentials are included. Typography uses system fonts; no third-party font requests are made.

## Enable hosting after the plan upgrade

```sh
GH_HOST=github.com gh api repos/xfreebird/smartcard/pages -X POST -f build_type=workflow
GH_HOST=github.com gh variable set ENABLE_PAGES_DEPLOYMENT -R xfreebird/smartcard -b true
GH_HOST=github.com gh workflow run website.yml -R xfreebird/smartcard
```

Until then the action builds and saves the Pages artifact; deployment is skipped. Do not change live store URLs to the GitHub address until hosting is enabled and those routes are reachable.

Device illustration geometry lives in `src/components/deviceGeometry.js`: the phone outline uses the official iPhone product-resource proportions and the Android screenshot keeps its 9:20 ratio. Desktop app windows are contained inside a generic 16:9 display. SVG images use `preserveAspectRatio`; the reader, cable and ports share the same coordinate system.

## Languages

English uses the root route; Romanian uses `/ro/` and Russian `/ru/`. All three are emitted into `pages/` by one build. The language menu is available in the navigation bar. On a first unlocalized visit in a tab, the browser's language list selects Romanian, English or Russian (regional variants supported; English fallback). Explicit localized links and subsequent manual language switches are respected. No locale redirect is performed without browser storage access.

Landing-page UI strings use stable keys in `src/i18n/catalog.json`; Docusaurus navigation/theme translations and translated Markdown live in `i18n/ro` and `i18n/ru`.

The signing illustration is continuously driven by normalized scroll progress (`scrollScene.mjs`), with overlapping animation ranges and no step-snap delays. The opening screen is 140vw, positioned low in the viewport, and continuously recedes to its device frame. The desktop screen reaches 75vw before shrinking to fit the connected hardware vertically. Both desktop and mobile animation begin during entrance, as soon as more than 10% of the enlarged screenshot is visible, and include that entrance distance in the shared scroll timeline. The final mobile screenshot targets 85% of viewport width (height-limited on short screens); the reader and ID overlap the lower phone area. Native light-mode reader-without-card captures appear before insertion; the mobile reader stays at one fixed position during connection and insertion, leaving room for the approaching ID. Card details fade in only after insertion. Card height is 98% of the white reader's measured insertion span (source y=44…977), preserving the app card image's aspect ratio. Run `node --test tests/*.test.mjs` for timeline and proportion checks.

Mobile download widgets use unmodified official Apple App Store and localized Google Play badge assets. Apple source: https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg . Google source: https://play.google.com/intl/en_us/badges/ .

## Versioned platform documentation and screenshots

The public documentation is split by delivery target under `docs/platforms/`. Each guide names the current marketing version and distinguishes the desktop, store, and CLI distributions where they differ. Do not state a feature as available in a store build unless that guide explicitly lists it.

Desktop and CLI guides have separate sidebar entries. Each desktop guide covers installation, reader setup, signing and output, verification, preferences, browser integration, updates, and platform-specific recovery. CLI guides include reader selection, formats, secure PIN input, verification, exit codes, and service setup. `PlatformScreenshots` renders one native image selected by Docusaurus `colorMode`; theme changes update it immediately. Documentation never displays light and dark captures side by side.

Capture native documentation artwork into `~/Desktop/esemnbun-screenshots/docs/YYYY-MM-DD/` with mock-only capture mode, then copy the curated `ready`, `reading`, and `no-reader` pairs into `static/img/landing/<platform>/`. The landing scene uses the light pair when the website is light and the dark pair when it is dark; it never recolours a screenshot with CSS.

```sh
# macOS and iOS (Debug app only)
MSIGN_CAPTURE_SCENARIOS='no-reader reading ready' \
  scripts/capture-screenshots.sh macos /path/to/eSemnBun.app ~/Desktop/esemnbun-screenshots/docs/YYYY-MM-DD/macos
MSIGN_CAPTURE_SCENARIOS='no-reader reading ready' \
  scripts/capture-screenshots.sh ios /path/to/eSemnBun.app ~/Desktop/esemnbun-screenshots/docs/YYYY-MM-DD/ios <simulator-udid>

# Android emulator (Debug APK only)
MSIGN_CAPTURE_SCENARIOS='no-reader reading ready' MSIGN_CAPTURE_PAGES=sign \
  scripts/capture-screenshots.sh android android/app/build/outputs/apk/debug/app-debug.apk ~/Desktop/esemnbun-screenshots/docs/YYYY-MM-DD/android emulator-5554

# Linux and Windows: use the Air's running Fedora and Windows VMs.
# The dedicated VM drivers validate a mock-ready marker before each capture.
scripts/capture-screenshots.sh linux
pwsh windows/scripts/capture-scenarios.ps1 -App <debug-eSemnBun.exe> -Scenarios none,reading,1 -Pages sign -Themes light,dark
```

The capture-only `MSIGN_SCREENSHOT_CAPTURE=1` path suppresses the demo notice, disables reader, bridge, PIN, and signing I/O, and is not included in release behaviour. Keep normal interactive demo mode visibly labelled.

To replace the macOS story, build a Debug app from current source and run `website/scripts/capture-macos-story.sh APP OUTPUT_DIR en` from the repository root. It uses the normal app window, isolated mock preferences, light appearance and the same Contract.pdf in every state. It rejects preview windows or changed title/dimensions. Copy the three PNGs and macos-story.json together into static/img; CI verifies native dimensions and hashes so mixed capture sessions cannot slip back in.

The story uses the live dynamic viewport (including browser-chrome changes), with no inherited mobile minimum height. Its compact progress capsule keeps the current localized label and four continuous segments visible. Site navigation hides during scrolling and the pinned story; keyboard focus can reveal it, and reduced-motion mode keeps static navigation.

## Debug platform preview

The landing page shows a **Preview platform** selector in development (`npm start`) and on loopback production previews (`npm run serve` at localhost/127.0.0.1/IPv6 loopback). Choose macOS, Windows, Linux, iPhone or Android to switch the complete signing illustration, including its native screenshots, device frame and scroll geometry. **Automatic** restores browser/device detection. The choice persists for the current tab, including language changes. The selector stays available during scrolling and is translated into all three languages. Public production hosts do not expose this control or apply saved overrides; no query parameter enables it.

## Appearance

The website follows the browser/system colour scheme on first visit. The navigation theme button cycles through light, dark and system; on mobile it is inside the navigation drawer. Explicit preferences persist across reloads, documentation routes and locale changes. Shared tokens in `src/css/palette.css` style the landing page, download menu, signing progress/result, cable and debug controls alongside Docusaurus documentation. Native app captures retain their original colours.

### Standalone app update channel

The website publishes `/updates/macos.json`, `/updates/windows.json`, and `/updates/linux.json`.
Each contains the stable marketing `version` and an HTTPS `downloadURL` on `esemnbun.md`.
The Website workflow regenerates them from the latest published GitHub release before building,
and runs again after the Release workflow completes. Local regeneration:

```sh
python3 website/scripts/generate-update-manifests.py --version 0.2.0
```

Standalone desktop apps check at most weekly after the last check, or on demand. Store builds
use their store's updates. No binaries are installed by this mechanism. The production domain must
serve these files before automatic checks can succeed; the private repository's Pages plan gate
remains unchanged.
