# eSemnBun website

## Developer handbook

The public developer entry is `/docs/developers/overview/`, with a separate sidebar and navbar link.
Its twelve English chapters cover architecture, card/reader bytes, formats/bridge, native design systems,
builds, automated tests, release operations, website publishing, an agent reference and glossary.
Edit `docs/developers/` directly. The English handbook falls back in other HTML locales; it is not a
translated technical reference. Keep the English language notice in its overview and localized navigation.

Regenerate the two accessible local SVG diagrams with
`python3 website/scripts/generate-developer-diagrams.py` from the repository root. The explanatory
text is also available to readers who cannot use the images. No external renderer is needed.

`src/data/search-discovery.json` lists translated product documents separately from `englishDocuments`.
The existing discovery plugin exports the handbook only in the English Markdown/text/JSON catalog;
all locale indexes link to the English entry. Keep exports derived from the public source, and never
include internal protocol captures, vendor authentication material or private reports.

Run the verification batch documented below before publication, then inspect the developer sidebar,
both diagrams and the agent Markdown links at desktop/mobile widths. See the handbook's
`website.md` and `testing.md` for the complete workflow. Site builds/tests and deployment must be
reported separately from static source checks.

Docusaurus source lives here. `npm ci && npm run build` compiles it into **website/pages/** (generated output, not committed). `npm start` develops locally; `npm run serve` previews the production build.

GitHub Actions builds and deploys that directory through GitHub Pages at **https://esemnbun.md/**. Both local builds and Website CI default to `SITE_URL=https://esemnbun.md` and `BASE_URL=/`, so omitting environment variables cannot publish GitHub-project canonical URLs accidentally. Alternate deployments can explicitly override both values. Store links use `/`, `/support/`, `/privacy/` and `/terms/` on the custom domain.

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

Cloudflare DNS uses four apex A records (`185.199.108.153` through `185.199.111.153`), four apex AAAA records (`2606:50c0:8000::153` through `2606:50c0:8003::153`), and `www` CNAME → `xfreebird.github.io`. Records are **DNS only**, with a five-minute TTL, so GitHub handles the HTTPS certificate and redirects. Configure the GitHub custom domain before pointing DNS at it. The certificate for both names is issued and GitHub's Enforce HTTPS is enabled.

The domain is verified in the owner's GitHub account. Keep the `_github-pages-challenge-xfreebird` TXT record in Cloudflare to retain ownership protection. Website workflow [41415337721](https://github.com/xfreebird/smartcard/actions/runs/41415337721) built and deployed successfully. HTTPS homepage, localized pages, downloads, policy pages, sitemap and update feed were checked from the MacBook Air; `www` redirects to the apex. A company web filter on the main Mac currently blocks this new domain as high-risk, independently of the successful public deployment.

Direct installer URLs currently refer to this private repository's releases and require repository access. Publishing the website does not publish those releases. Public installer distribution must be arranged separately; do not change repository visibility as a workaround without auditing private/vendor material.

Device illustration geometry lives in `src/components/deviceGeometry.js`: the phone outline uses the official iPhone product-resource proportions and the Android screenshot keeps its 9:20 ratio. Desktop app windows are contained inside a generic 16:9 display. SVG images use `preserveAspectRatio`; the reader, cable and ports share the same coordinate system.

## Languages

English uses the root route; Romanian uses `/ro/` and Russian `/ru/`. All three are emitted into `pages/` by one build. The requested URL determines the language; the navigation menu lets visitors choose a translation. There is no automatic language redirect, so shared URLs and crawler visits stay on the requested page.

Landing-page UI strings use stable keys in `src/i18n/catalog.json`; Docusaurus navigation/theme translations and translated Markdown live in `i18n/ro` and `i18n/ru`.

The signing illustration is continuously driven by normalized scroll progress (`scrollScene.mjs`), with overlapping animation ranges and no step-snap delays. The opening screen is 140vw, positioned low in the viewport, and continuously recedes to its device frame. The desktop screen reaches 75vw before shrinking to fit the connected hardware vertically. Both desktop and mobile animation begin during entrance, as soon as more than 10% of the enlarged screenshot is visible, and include that entrance distance in the shared scroll timeline. The final mobile screenshot targets 85% of viewport width (height-limited on short screens); the reader and ID overlap the lower phone area. Native light-mode reader-without-card captures appear before insertion; the mobile reader stays at one fixed position during connection and insertion, leaving room for the approaching ID. Card details fade in only after insertion. Card height is 98% of the white reader's measured insertion span (source y=44…977), preserving the app card image's aspect ratio. Run `node --test tests/*.test.mjs` for timeline and proportion checks.

Mobile download widgets use unmodified official Apple App Store and localized Google Play badge assets. Apple source: https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg . Google source: https://play.google.com/intl/en_us/badges/ .

The downloads page keeps all five platform links visible in an equal-width sticky row, with icons
above labels on phones. `useDownloadNavigation` follows the reading position below the sticky
controls using the visual viewport, including mobile browser-chrome resizing. It measures the nav
height for anchor offsets, keeps tall cards selected while reading, and retains the chosen desktop
column when two cards share a row. Scroll updates replace the URL hash without adding history;
platform links retain keyboard focus and direct-link navigation. Geometry and legacy-hash cases
are covered by `tests/downloadNavigation.test.mjs`.

## Versioned platform documentation and screenshots

The public documentation is split by delivery target under `docs/platforms/`. Each guide names the current marketing version and distinguishes the desktop, store, and CLI distributions where they differ. Do not state a feature as available in a store build unless that guide explicitly lists it.

Desktop and CLI guides have separate sidebar entries. Each desktop guide covers installation, reader setup, signing and output, verification, preferences, browser integration, updates, and platform-specific recovery. CLI guides include reader selection, formats, secure PIN input, verification, exit codes, and service setup. `PlatformScreenshots` renders one native image selected by Docusaurus `colorMode`; theme changes update it immediately. Documentation never displays light and dark captures side by side.

Capture native documentation artwork with the isolated Debug screenshot modes. The landing scene
uses `static/img/landing/<platform>/{disconnected,reader,ready}-{light,dark}.png`. Keep one native
canvas size per platform across all six states, and capture both appearances in the app. A connected
reader without a card is the `reader` state. `static/img/docs/v0.2.0/` and the legacy root image paths
remain compatibility mirrors of the same current set; the directory name is not the capture version.

For Apple captures use `MSIGN_SCREENSHOT_CAPTURE=1`, `MSIGN_QA_NO_HARDWARE=1` and isolated
preferences. macOS must also use `MSIGN_DEMO_PREVIEW=0` with `--show-main-window` so the real main
window is captured. Android launches require both a Debug demo scenario and `--ez store_capture true`;
check readiness and dismiss first-run disclosures in the isolated emulator before capture. Windows
and Linux use `MSIGN_SCREENSHOT_CAPTURE=1` with their Debug fixture inputs. These modes hide the
**demo-data banner** while keeping hardware, signing and bridge I/O isolated. Inspect every result;
a readiness marker alone does not prove that a dialog or banner is absent.

Set iOS simulator clocks with `xcrun simctl status_bar DEVICE override --time '09:41'` and Android
System UI demo clock to `0941` with the 24-hour setting before capture. All visible status-bar clocks
in website screenshots must read **09:41**. System clock overrides do not change document or certificate
timestamps. Prefer native captures; for existing images, the reviewed native clock crops and exact
edit rectangles in `static/img/screenshot-clocks.json` are applied by
`python3 website/scripts/normalize-screenshot-clocks.py` (Pillow required). `--check` verifies hashes.
The script preserves dimensions, alpha and all pixels outside the declared clock rectangle.
The current iPhone protection screenshots use the native simulator status bar with its clock set to 09:41. Their manifest records identify the refreshed captures.

Crop desktop captures inside the visible app-window bounds: no wallpaper, taskbar, shadow or
rounded-corner background may remain. Windows guide crops are recorded in
`static/img/screenshot-window-crops.json`; annotation coordinates in `docs/user-guide/content/`
are transformed with the same crop, then regenerated with `scripts/docs/organize-user-guides.py`.

`static/img/screenshot-refresh.json` records all 30 reviewed animation captures. Replace the matching
legacy aliases and documentation overview pairs together, including `macos-story.json`. Bump
`src/data/screenshotRevision.json` when replacing image bytes so returning browsers request the
new artwork. Website CI verifies image hashes, dimensions and complete light/dark state coverage.
See `docs/reports/website-screenshots-2026-11-15.md` for capture provenance and visual audit details.

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

Home-page titles/descriptions, platform introductions and the MCP overview are localized for Romanian, English and Russian. The same HTML is delivered to visitors and crawlers, with visible content and links available before JavaScript. Use natural wording around semnătură electronică and carte de identitate; do not add repeated keyword lists, alternate spellings solely for search, hidden instructions or claims of official affiliation. The homepage emits factual SoftwareApplication and WebSite JSON-LD without invented reviews or ratings.

| Search intent | Canonical English entry page (also available under `/ro/` and `/ru/`) |
| --- | --- |
| MoldSign, semnatura, semnatura electronica | `/docs/moldsign/` |
| MoldSign Windows | `/docs/platforms/windows/` |
| MoldSign Mac / macOS | `/docs/platforms/macos/` |
| MoldSign Linux | `/docs/platforms/linux/` |
| MCP MoldSign | `/docs/mcp-moldsign/` |

These are useful existing platform guides and a localized MCP introduction, not duplicate keyword pages. Homepage links and documentation navigation expose them directly. Platform overview titles, descriptions and introductory copy live in `docs/user-guide/content/overview-metadata.json`; run `python3 scripts/docs/organize-user-guides.py` from the repository root after editing that source. Do not hand-edit generated platform indexes.

Docusaurus generates canonical URLs, language alternates and a sitemap for every locale. The build plugin generates `robots.txt` with sitemap links using the actual deployment configuration. Its wildcard allow rule permits search crawlers, including AI search retrieval crawlers. Allowing a crawler does not force indexing, recommendation or training. Keep any CDN/firewall rules consistent with this public access. On GitHub project Pages, `/smartcard/robots.txt` is not the host-root robots file; submit the sitemap URLs directly. On the production domain served at `/`, the generated robots file is at the correct root.

The `search-discovery` build plugin also emits the following at `/`, `/ro/` and `/ru/`:

- `llms.txt`: a compact index with Markdown and canonical HTML links.
- `llms-full.txt`: combined text of the selected public guides.
- `discovery.json`: a versioned, site-specific JSON document catalog; this is not a standardized MCP manifest or a remote MCP endpoint.
- `markdown/<document-id>.md`: plain Markdown alternatives for the eight translated product references and twelve English developer chapters listed in `src/data/search-discovery.json`.

These representations come from the same documentation sources and Docusaurus metadata. Generation fails if a selected product translation is missing; the separate English developer list is exported only in English. All language indexes link to the English developer entry. Markdown links resolve to public URLs; platform exports include their task links. HTML advertises the index and JSON catalog, and selected references advertise their Markdown alternative. Do not maintain a second set of product claims in these files. They are conveniences for tools that use them; Google does not use `llms.txt` as a ranking signal.

The owner runs the verification batch from `website/` after dependencies are installed:

```sh
node --test tests/*.test.mjs
npm run build
npm run verify:seo
```

The existing Website CI also runs these commands. The SEO checker covers 18 localized entry pages: unique titles/descriptions, one main heading, exact canonical/hreflang targets, social images, app/site identity, homepage links and sitemap entries. It also checks the 24 localized product and 12 English developer Markdown exports and their text/JSON discovery links against the generated HTML.

After deployment, verify the live pages and discovery files return 200 over HTTPS. In the owner's verified Google Search Console and Bing Webmaster Tools properties, submit `https://esemnbun.md/sitemap.xml`, `https://esemnbun.md/ro/sitemap.xml`, and `https://esemnbun.md/ru/sitemap.xml`. Inspect the priority URLs and track query impressions, clicks and indexing for the intents above. Account verification, sitemap submission and measured rankings are separate from publishing source changes; do not report them as completed without evidence. Search engines and recommendation systems decide inclusion and ordering, so first position cannot be guaranteed.

References: [Google Search Essentials](https://developers.google.com/search/docs/essentials), [Google's generative AI search guidance](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide), [multilingual URL guidance](https://developers.google.com/search/docs/specialty/international/managing-multi-regional-sites), and [search crawler controls](https://developers.openai.com/api/docs/bots).

## Download catalog

`src/data/release.json` is the download page's single manifest. `platforms` defines card order, IDs/anchors, icons, localized names and short requirements, guide routes, optional store URL/badge paths and optional explanatory translation key. `assets` defines installer URLs, exact versions, formats, architectures, sizes and the owning platform ID. Assets without a platform (checksums/certificates) are not shown as installers. Adding or rearranging cards does not require editing the page component.

`python3 scripts/generate-downloads.py <github-release-response.json>` refreshes release assets while retaining the platform configuration. Missing package/architecture combinations retain the previous working download and its actual version. Website CI already invokes this generator before building. Store URLs also feed the landing-page store widgets. Store versions are not assumed to match the standalone release; availability depends on review and region.

The download page uses official App Store, Google Play and Microsoft Store badges. Microsoft artwork source: https://get.microsoft.com/images/en-us%20dark.svg (usage: https://github.com/microsoft/app-store-badge). Tux is displayed in grayscale in both themes, preserving the artwork and attribution.

Localized badge sources: Apple `https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/{en-us,ro-ro,ru-ru}?size=250x83`, Mac App Store equivalent `download-on-the-mac-app-store`, Microsoft `https://get.microsoft.com/images/{ro,ru}%20dark.svg`. The Romanian Mac API endpoint silently returns English; use the Romanian Mac artwork documented in [`static/img/badges/README.md`](static/img/badges/README.md). Artwork is stored unmodified and selected from release.json.
