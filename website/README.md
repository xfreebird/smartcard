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
