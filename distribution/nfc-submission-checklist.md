# NFC submission preparation — 16 November 2026

Scope: prepare the next release; no store submission, rollout or metadata upload was performed.

## Apple signing

- Main app `md.esemnbun.ios`, team `H86U5Z8HYB`: Core NFC `TAG` entitlement; NFC Tag Reading enabled on the registered identifier.
- ISO 7816 AIDs and localized NFC purpose strings are in the application Info.plist / InfoPlist.strings. This is a tag reader, not payment card emulation or an NFC & SE Platform entitlement request.
- Main-app App Store, Ad Hoc and Development match profiles were refreshed to include NFC while preserving App Groups. Existing certificates were reused. Extensions do not receive NFC.
- Check the exported release IPA's signed entitlements and embedded profile, plus share/widget profiles, before upload. A development build alone is insufficient proof of distribution signing.
- Localized descriptions, release notes and promotional copy are generated from `localization/catalog.json` by `scripts/prepare-store-metadata.py`. Mobile overrides avoid claiming NFC on desktop or iPad.
- Review instructions: `apple/ios/review-notes-nfc.txt`. Supply a camera video of a physical iPhone and real card; conceal PIN and personal data. The video is still an external submission input, not a fabricated screenshot or demo signing result.

## Google Play

- Package `md.esemnbun.app`; NFC permission with optional hardware feature. USB remains optional. No new runtime permission dialog, NFC payment role or host-card-emulation service is introduced.
- `google/review/nfc-app-access.txt` explains device/card/PIN requirements, demo mode and real signing steps. Use the production package and release signing key for the eventual AAB; the separate NFC Test application is not the store artifact.
- RO/EN/RU full descriptions retain the independence disclosure and official service sources. Release notes describe NFC and the consolidated Settings screen.
- Keep the existing target audience/content-rating and browser/foreground-service declarations accurate; NFC itself does not remove those obligations.

## Privacy / data safety delta

| Data | Processing and storage | Submission consequence |
| --- | --- | --- |
| Card certificate (name, issuer, serial, validity, identity fingerprint) | Read locally over NFC or reader; included in the signed output. Saved certificate metadata is retained locally when a PIN is remembered. | Describe local card processing and deletion in Settings; NFC is another transport for existing signing data. |
| Card PIN | Entered on device; protected card channel; optional OS-protected local vault tied to certificate identity. | Never place a real PIN in reviewer credentials, logs, videos or metadata. |
| Private signing key | Stays inside the card. | Do not claim export or cloud custody. |
| Documents | Local signing/verification; user-controlled save/share/browser operations. | Do not claim all browser or user-initiated transfers stay on device. |
| Timestamp/status traffic | Signature hashes, certificate identifiers and ordinary network metadata to public trust services. | Preserve existing network disclosures; do not answer that every transfer is encrypted because PKI endpoints include HTTP. |
| NFC diagnostics | Debug-only metadata, no PIN/session keys/raw APDU traces. No automatic diagnostics upload. | Do not market developer diagnostic collection as production telemetry. |

The NFC addition does not introduce a developer backend or automatic upload of card data. Review the complete app and its dependencies when answering App Privacy / Data safety; this delta does not replace the existing whole-app declarations. Do not indiscriminately mark every item “not collected” solely because NFC is local.

## Remaining release inputs

- Camera video showing the actual release-candidate NFC hardware flow, supplied by the card owner; no private PIN in the recording.
- Final release version/build identifiers, final production APK/AAB and IPA, refreshed store screenshots, and the usual store review submission. No build number in this preparation reserves a public release.
- Confirm that linked privacy/support pages contain the NFC wording before submission. Source policy changes are local until website deployment is explicitly requested.

## Official references checked

- [Core NFC tag-reader entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.nfc.readersession.formats)
- [Apple: information for a complete review](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/) — required hardware video and reviewer access.
- [Android NFC basics](https://developer.android.com/develop/connectivity/nfc/nfc) — permission and optional feature declaration.
- [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469) — whole-app and third-party data disclosures.
