# Website, browser and Huawei update — 14 November 2026

## Implemented in the working tree
- Store links precede standalone apps, CLI downloads and MCP instructions. Huawei AppGallery is next to Google Play on Android. The landing macOS calls to action now use the same priority.
- Downloads are deduplicated by distribution kind, package format and architecture. Removed the repeated Linux CLI archive link and prevent duplicates when retaining older release packages.
- Landing scroll progress uses frame-rate-independent easing and stops scheduling frames when settled; reduced-motion support remains.
- iOS initializes MSign's origin-specific persisted locale from the app preference and supplies Accept-Language when opening URLs. Browser controls have added vertical spacing above the tab bar.
- Four documentation ready/light image files now use the approved 13 November native macOS, iPhone, Android and Windows captures. Source hashes are in website/static/img/screenshot-refresh.json. Landing animation images retain their matching original canvas dimensions; a complete fresh matching set is still needed.

## Huawei delivery
- App ID: 119651007.
- Verified signed APK: 0.2.11, build 1793624694, package md.esemnbun.app.
- APK SHA-256: 587d229f39bcfc1fff7532b41e8ecd80b7be33df5cdbb24acd01f27345119cca.
- Signing certificate SHA-256: 0bd6c7ce1a0e57b3f959917d6c166c433184a3101cad5ddd5333b82bce9324cf.
- Four English phone screenshots were visually inspected, uploaded, attached and read back.
- Submission accepted; API releaseState 5 means pending update review. Previous on-shelf build remains 1793624688. This is not yet a public rollout.
- Used the documented upload-url/for-obs binary upload API; legacy image attachment failed before this successful update.
- Python requests inherited a stale macOS loopback proxy. Direct sessions with trust_env=False reached Huawei. Credentials stayed in the existing private store.
- Google Play alpha was left unchanged.

## Verification and remaining work
- Edited JavaScript/JSX files passed parser checks. Whitespace check passed.
- No local app build, website build, test suite or live iOS interaction verification has been run under the owner's standing build/test convention. The authorized Website workflow passed tests, guide validation, build and SEO checks; Pages deployment succeeded.
- Refresh dark-mode, disconnected/reading and Linux screenshots with current Debug demo builds before calling the full screenshot refresh complete.
- Run the website verification batch from website/: node --test tests/*.test.mjs; npm run build; npm run verify:seo.
- Build and exercise the iOS browser in EN/RO/RU, verify controls on iPhone/iPad and reset-data behavior.
- Website source is committed on main: 972d2695f0ff24ad7ce5af460e445736d488a7b0. Website workflow: https://github.com/xfreebird/smartcard/actions/runs/43634978947. Deployment succeeded; the live download page was verified to include Huawei AppGallery and the new download groups. Native iOS changes remain in the main Mac working tree and are not included in this website commit. GitHub CLI returns HTTP 401; repository publication used the connected GitHub integration.
- Unrelated pre-existing untracked reports were preserved.

Huawei status reference: https://developer.huawei.com/consumer/en/doc/AppGallery-connect-References/agcapi-app-info-query-0000001158365045/
