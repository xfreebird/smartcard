# eSemnBun 0.2.14 delivery

The owner authorized the iOS release, replacement of the pending Mac app, Play closed alpha, replacement Huawei update, Windows release and Downloads refresh. The owner subsequently requested Firefox and explicitly retained **Collect personal data: No** on Huawei.

Application source is `62f710325bfff9d96d7b4dcee226f74fe321e626`, tagged `v0.2.14`. Apple/Windows build is **217**; Android version code is **1793624700**. Later commits `c93f0085` and `08ad0147` repair the generated Mac QA runner and its resize assertion, without changing the released application binaries.

## Delivery state

| Destination | Result observed on 19 November 2026 |
| --- | --- |
| GitHub/direct downloads | [0.2.14 published](https://github.com/xfreebird/smartcard/releases/tag/v0.2.14), including signed Windows MSI, notarized macOS DMG/CLI, Android APK and Linux/CLI packages. |
| iOS | 0.2.14 build 217 is **WAITING_FOR_REVIEW**, automatic release after approval. The independent four-item featured-artwork review remains intact. |
| Mac App Store | Validated build 217 before withdrawing the pending 0.2.13 app review. Its version resource now contains 0.2.14/217 and is **WAITING_FOR_REVIEW**, retaining existing screenshots, localizations, review attachments and automatic release settings. |
| Google Play | Exact signed AAB submitted to the existing **alpha** closed track; publisher receipt reports **submitted**. Internal remains 1793624673; other tracks were preserved. Submission does not establish tester availability. |
| Huawei | Existing application/update replaced with 0.2.14/1793624700, then submitted through Firefox. Console shows **Reviewing**, API release state **5**. **Collect personal data: No** was selected before submission and remained selected/disabled afterwards. |
| Microsoft Store | MSIX **1.2.217.0** accepted with no submission errors. Submission **1152921505702453185** reached **Published**, with no errors, at 21:19 UTC. Both the Store update and the independently verified direct MSI are released. |

Apple review submissions: iOS `e2fc4db2-12e1-446e-9e52-a3332664362a`; Mac replacement `9b3b3b46-964d-4963-b9b8-1a9fb794cf7b`. Windows submission: `1152921505702453185`. Huawei app/version IDs: `119651007` / `2083843062928299200`.

Huawei retained its existing countries, immediate full release on approval, privacy/support URLs and data-collection answer. Reviewer remarks explain local signing/PIN storage, absence of developer accounts/ads/analytics/app servers, user-authorized websites and PKI requests, and Demo mode access without hardware. English release notes were updated and read back. The API reported Romanian/Russian language records absent; no new Huawei locales or listing assets were introduced. The previous update was rejected, rather than actively in review. No CAPTCHA was solved or bypassed; Firefox used its existing authenticated session.

## Build and publishing evidence

- [Desktop release 44609090476](https://github.com/xfreebird/smartcard/actions/runs/44609090476): succeeded, including Flatpak and Windows Store submission.
- [Apple uploads 44609097000](https://github.com/xfreebird/smartcard/actions/runs/44609097000): both build 217 uploads succeeded and processed **VALID** before review mutation.
- [Signed Android build 44609102587](https://github.com/xfreebird/smartcard/actions/runs/44609102587): succeeded; reused its exact artifacts across the destinations.
- [Play alpha 44609947847](https://github.com/xfreebird/smartcard/actions/runs/44609947847): succeeded, selected closed track only.
- [Huawei draft upload 44609953761](https://github.com/xfreebird/smartcard/actions/runs/44609953761): succeeded; final submission was subsequently performed in Firefox.
- [CLI package repositories 44613249817](https://github.com/xfreebird/smartcard/actions/runs/44613249817): succeeded.
- [Pages 44617283130](https://github.com/xfreebird/smartcard/actions/runs/44617283130): succeeded for the pushed download metadata and delivery record, including localized tests/builds, guide checks and SEO verification. The preceding public asset/checksum deployment 44614198530 also passed.

No private IPA, AAB, MSIX or PKG was added to the public release. Its 15 payloads match the final `SHA256SUMS.txt`. The eight files staged by the website Downloads generator were downloaded and checked against their expected sizes and SHA-256 hashes. Desktop update feeds and generated release metadata now advertise 0.2.14. Live English, Romanian and Russian Downloads pages returned HTTP 200 and linked the new installers; all three public update feeds returned 0.2.14. The APK and Windows MSI fetched through the public website matched their signed artifact hashes.

| Artifact | SHA-256 |
| --- | --- |
| Android APK | `3657d71c220c7222da567e37a5fa65648bad9a7916a4d6577a08343f50127efc` |
| Android AAB | `6c4b1542964b024787c944e025ffb9330e0db2512790967534fcaa0a79d4dcd7` |
| Windows MSI | `e7c4337f1212ca1ac74efb6867aa0fc77e5575db1c843aea4a045b67eb70a99b` |
| macOS DMG | `d48c8e33bb79f57f31e445c23272fcbf9480a55ec9c749bc85479753288d17f3` |

Android package/version and signing certificate were independently checked with Android SDK tools. The APK certificate matched the expected upload identity.

## Validation

- The mobile UI change passed local iPhone **35/35**, iPad **35/35**, Android **34 journeys plus 5 phases**; see [mobile validation](mobile-ui-controls-validation-2026-11-19.md).
- Refreshed 114 affected documentation images using the established native fixture/crop/clock approach across seven layouts and EN/RO/RU; see [screenshot validation](documentation-screenshots-2026-11-19.md). Prior source CI 44606760938 passed.
- Release preparation: **85 CI contract**, **12 Play publisher**, **6 Huawei** tests passed locally, together with localization/metadata checks and Fastlane Ruby syntax.
- Website: **39/39 tests**, and production builds for English, Romanian and Russian passed locally.
- Release-source CI 44609029371 passed its Swift, Android, Linux, Windows and localization jobs. Its Mac UI runner dropped fixture launch settings because Xcode copied a sandboxed XCTest runner; its screenshots showed the ordinary Sign screen. The superseded validation run was stopped; publishing runs were preserved.
- `c93f0085` builds the temporary Mac harness before testing, asserts its QA bundle identity, removes only the generated runner's sandbox entitlement, re-signs/verifies it and uses test-without-building. The tested application and host security settings are unchanged. Local build/signature validation and all 85 CI contract tests passed. [CI 44613540650](https://github.com/xfreebird/smartcard/actions/runs/44613540650) passed all five verification, six workflow and three of four floating-action tests. The remaining Russian resize case actually reached the expected minimum width; native drag rounding reduced the preceding window to 894 points and the final one to 865, a 29-point shrink against a greater-than-30 assertion. Its follow-up starts at 940 points and requires a greater-than-50 shrink plus the near-minimum final width, preserving the layout assertions. The owner's running installed app was preserved locally. Follow-up [CI 44617283624](https://github.com/xfreebird/smartcard/actions/runs/44617283624) passed **15/15 native Mac UI tests**, with exact expected counts and zero skipped tests independently checked in the downloaded XCTest bundles. Its complete Mac job also passed the integration suite, unsigned sandboxed Store variant and CLI build. The modified Mac harness also compiled and passed signature verification locally; all 85 automation contracts passed again.

Store review/rollout is asynchronous. Submission and upload success do not establish public approval. Private receipts and browser evidence are under ignored `.local/release-0.2.14/`; no credentials or browser/account screenshots are committed.
