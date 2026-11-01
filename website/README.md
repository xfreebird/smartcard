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

The signing illustration is continuously driven by normalized scroll progress (`scrollScene.mjs`), with overlapping animation ranges and no step-snap delays. The opening screen is 140vw, positioned low in the viewport, and continuously recedes to its device frame. The desktop screen reaches 75vw before shrinking to fit the connected hardware vertically. Mobile animation begins during entrance, as soon as more than 10% of the enlarged screenshot is visible, and includes that entrance distance in the scroll timeline. The final mobile screenshot targets 85% of viewport width (height-limited on short screens); the reader and ID overlap the lower phone area. Native light-mode reader-without-card captures appear before insertion; the mobile reader moves right while its cable endpoint follows, leaving room for the approaching ID. Card details fade in only after insertion. Card height is 98% of the white reader's measured insertion span (source y=44…977), preserving the app card image's aspect ratio. Run `node --test tests/*.test.mjs` for timeline and proportion checks.

Mobile download widgets use unmodified official Apple App Store and localized Google Play badge assets. Apple source: https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg . Google source: https://play.google.com/intl/en_us/badges/ .

To replace the macOS story, build a Debug app from current source and run `website/scripts/capture-macos-story.sh APP OUTPUT_DIR en` from the repository root. It uses the normal app window, isolated mock preferences, light appearance and the same Contract.pdf in every state. It rejects preview windows or changed title/dimensions. Copy the three PNGs and macos-story.json together into static/img; CI verifies native dimensions and hashes so mixed capture sessions cannot slip back in.
