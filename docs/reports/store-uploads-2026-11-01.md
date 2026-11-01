# Store draft uploads — 1 November 2026

No store certification submission, public release or test rollout has been performed.

## Apple

- iOS/iPadOS app: 6826865290 (`md.esemnbun.ios`), version 0.2.0, build 100 VALID and attached to draft. Release workflow 41315196812.
- macOS app: 6829451042 (`md.esemnbun.mac`), version 0.2.0, sandboxed build 100 VALID and attached. Store package workflow 41315203394, delivery 31be9092-fc37-4188-bdfa-bf32e17d03da.
- iOS screenshot sets: 30 processed images, RO/EN/RU, five iPhone plus five iPad per locale.
- Mac screenshot sets: 18 processed RO/EN/RU images plus six English copies for the record's primary en-GB locale. The separate Mac record requires distinct localized names, `eSemnBun for Mac`.
- Metadata, privacy/support/marketing URLs and copyright uploaded. Owner-provided review contact uploaded to both drafts; the phone number is not stored in the repository.
- Apple's initial release does not display release notes; the localized first-release texts are retained in the repository for stores that support them.

## Windows

- Build workflow 41315520171 packages current application source, marketing 0.2.0 and compliant MSIX identity version 1.2.100.0.
- MSIX identity verified locally against reserved product 9PDPR6RNT42S. Future Store versions use (marketing major + 1).minor.build.0, preserving the upgrade path from 0.x marketing to 1.x.
- Draft 1152921505702227810: updated x64 package marked Validated; all submission sections show Complete. The old 0.2.0.0 package is also retained in the draft; the higher 1.2.100.0 package is present and marked Validated. The package editor remained on Analyzing package with Save disabled even after the overview reported validation; it was refreshed, and no removal of the older fallback package was forced.
- Partner Center import assets must include the selected root folder name in CSV paths. The importer creates RO/EN/RU payloads from the portal's exported schema. Re-export on 1 November verified all three descriptions, localized first-release notes and four uploaded screenshot URLs per locale.

## Android

- Created app 4973211912255144827 (`md.esemnbun.app`) in developer 8344963402071617946.
- Owner explicitly approved Play App Signing terms, Developer Program Policies and export declaration before app creation.
- Signed AAB from workflow 41315200244 accepted as versionCode 100 / marketing 0.2.0, target SDK 36, API 26+, four ABIs.
- Internal release draft saved with first-release notes in RO/EN/RU. No testers added and no rollout started.
- All three listing translations and localized feature graphics are saved. Each locale has four phone, four portrait-tablet and four landscape-tablet promotional screenshots (36 total). The shared icon uses the default-language fallback. Portrait canvases are 1440×2560; landscape 2560×1440, all matching Play aspect ratios.
- Production access requires the account's closed-test prerequisites (portal shows at least 12 opted-in testers for 14 continuous days).

## Submission prerequisites

Reserved esemnbun.md support/privacy/terms pages need published content before review. Apple review-contact information and hardware-review notes are uploaded. Privacy/data-safety and content questionnaires still need final completeness checks; Microsoft runFullTrust capability needs Store approval. Local screenshot provenance remains in the Desktop submission pack; physical card data/PINs were not used in store materials.

## Target-platform description audit

The public Apple and Windows descriptions were read back after upload: seven Apple locale/platform combinations and all three Windows descriptions contain no other OS names. Android's saved descriptions use the target-specific Android exports. The exporter now rejects foreign platform names in generated descriptions and removes all other-platform notes from Microsoft/Huawei JSON payloads. The shared localization source intentionally retains the source notes needed to generate each separate platform.

## Export compliance default

Following the owner's explicit exemption selection, both App Store Connect build 100
records were read back with `usesNonExemptEncryption=false`. iOS was already false;
macOS was unset and was updated to false. Future Mac and iOS/share-extension bundles
carry `ITSAppUsesNonExemptEncryption=false`; macOS distribution validation enforces it.
Plist lint and shell syntax pass, and the uploaded iOS IPA confirms the Boolean flag.
The existing Mac binary was not replaced; its server-side build declaration is saved.
