# eSemnBun website

Docusaurus source lives here. `npm ci && npm run build` compiles it into **website/pages/** (generated output, not committed). `npm start` develops locally; `npm run serve` previews the production build.

GitHub Actions builds and deploys that directory through GitHub Pages at **https://esemnbun.md/**. Website CI sets `SITE_URL=https://esemnbun.md` and `BASE_URL=/`; local builds retain the GitHub project-path defaults unless those variables are supplied. Store links use `/`, `/support/`, `/privacy/` and `/terms/` on the custom domain.

App Store / Play / Microsoft listing links are included with availability labels while review/testing is pending. Direct installer downloads lead to the latest GitHub Release. Store listing URL updates are separate from website deployment.

The landing sequence uses native app captures and the existing reader illustration. Reduced-motion users receive a static layout. No analytics scripts or app credentials are included. Typography uses system fonts; no third-party font requests are made.

The Linux platform icon uses Tux by Larry Ewing, created with The GIMP, traced by Kjoonlee. The SVG is hosted locally and keeps its original proportions. Source and attribution terms are included in `static/img/platforms/TUX-NOTICE.txt`; it retains its own license rather than the repository's MIT license.

## Hosting and domain configuration

```sh
GH_HOST=github.com gh api repos/xfreebird/smartcard/pages -X POST -f build_type=workflow
GH_HOST=github.com gh api repos/xfreebird/smartcard/pages -X PUT -f cname=esemnbun.md -f build_type=workflow
GH_HOST=github.com gh variable set ENABLE_PAGES_DEPLOYMENT -R xfreebird/smartcard -b true
GH_HOST=github.com gh workflow run website.yml -R xfreebird/smartcard
```

Pages was enabled on 2 November 2026. The repository remains private; its Pages website is public. `ENABLE_PAGES_DEPLOYMENT=true` enables the existing deployment job. No `CNAME` file is needed for the custom Actions publishing source: the domain is configured in repository Pages settings.

Cloudflare DNS uses four apex A records (`185.199.108.153` through `185.199.111.153`), four apex AAAA records (`2606:50c0:8000::153` through `2606:50c0:8003::153`), and `www` CNAME → `xfreebird.github.io`. Records are **DNS only**, with a five-minute TTL, so GitHub handles the HTTPS certificate and redirects. Configure the GitHub custom domain before pointing DNS at it. Enable GitHub's Enforce HTTPS after certificate issuance.

Direct installer URLs currently refer to this private repository's releases and require repository access. Publishing the website does not publish those releases. Public installer distribution must be arranged separately; do not change repository visibility as a workaround without auditing private/vendor material.

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
serve these files before automatic checks can succeed. The deployment gate is controlled by
the `ENABLE_PAGES_DEPLOYMENT` repository variable.

## Downloads

The localized `/downloads/` page groups release installers and store listings by platform, with setup guides and command-line documentation. The shared landing-page button opens this page; its adjacent control exposes the platform menu (hover, keyboard or touch). On phones the menu becomes a scrollable sheet with an explicit close action.

`src/data/release.json` is a checked-in snapshot of the latest published GitHub release. Website CI regenerates it alongside the desktop update manifests, so installer names, URLs, versions and file sizes come from real release assets. To refresh it locally:

```sh
GH_HOST=github.com gh api repos/xfreebird/smartcard/releases/latest > /tmp/esemnbun-release.json
python3 website/scripts/generate-downloads.py /tmp/esemnbun-release.json
```

Store links are kept separate from direct downloads; review or testing access can affect availability.

## Search visibility

Home-page titles/descriptions and visible copy are localized for Romanian, English and Russian. The linked `/docs/moldsign/` guide explains electronic-ID signing and eSemnBun's independent relationship to MoldSign/MSign. Use natural wording around semnătură electronică and carte de identitate; do not add repeated keyword lists or imply official affiliation. The homepage emits factual SoftwareApplication JSON-LD without invented reviews or ratings. This does not guarantee a rich result or ranking.

Docusaurus generates canonical URLs, language alternates and a sitemap for every locale. The build plugin generates `robots.txt` with sitemap links using the actual `SITE_URL`/`BASE_URL`. On GitHub project Pages, `/smartcard/robots.txt` is not the host-root robots file; submit the sitemap URLs directly to Search Console. On a custom domain served at `/`, the generated robots file is at the correct root.

After `npm run build`, run `npm run verify:seo` (also in Website CI). It inspects generated HTML for descriptions, canonical/language links, social images, app metadata, target-language content, and sitemap entries.

After deployment and HTTPS issuance, verify the live domain returns 200, add `esemnbun.md` in Google Search Console, verify ownership, and submit `https://esemnbun.md/sitemap.xml`, `https://esemnbun.md/ro/sitemap.xml`, and `https://esemnbun.md/ru/sitemap.xml`. Check indexing and query impressions for MoldSign, semnatura electronica, and carte de identitate after publishing; rankings are not immediate or guaranteed.
