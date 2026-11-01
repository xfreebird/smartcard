# Store draft uploads — 1 November 2026

No store certification submission or public release has been performed in this work.

## Apple

- iOS/iPadOS app: 6826865290 (`md.esemnbun.ios`), version 0.2.0, build 100 VALID and attached to draft. Release workflow 41315196812.
- macOS app: 6829451042 (`md.esemnbun.mac`), version 0.2.0, sandboxed build 100 VALID and attached. Store package workflow 41315203394, delivery 31be9092-fc37-4188-bdfa-bf32e17d03da.
- iOS screenshot sets: 60 COMPLETE and ordered images, RO/EN/RU: five framed iPhone, five iPad, five compact Duo and five expanded Duo per locale. Duo uses the dedicated APP_IPHONE_DUO slot; its earlier supplemental-only classification was incorrect.
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

## Framed screenshots and reader artwork refresh

All 78 Apple exports pass RGB/PNG and exact-dimension validation, including Duo compact 1398×2034 and expanded 2853×2007. The upload script includes both Duo folders and has explicit screenshot-only/replacement switches. Read-back verifies all nine iOS screenshot sets COMPLETE and ordered (60 images); Mac screenshots retain the previous verified upload. Native captures remain unchanged.

Header/Search Results artwork uses fictional identity details and the actual slim white reader form, with the physical chip covered by the sleeve and a continuous USB-C connection. The three opaque 5244×2950 localized exports are separate promotional illustrations. All three Asset Library images reached PREPARE_FOR_SUBMISSION and all six localized Header/Search Results placements read back ACTIVE, linked to the expected artwork. Rerunning the uploader reused the same assets and placements. Receipts are in the local pack's upload folder. No assets or app version have been submitted for review by this refresh.

Subsequent portal observation: Google internal testing showed 0.2.0 (100) available to internal testers, released on 1 November at 17:34. This artwork refresh did not initiate that rollout.

## Official product frame correction

The generic drawn hardware outlines were removed. Standard iPhone uses Apple's original iPhone 17 Pro Max Deep Blue portrait PNG; Duo uses Night Sky outer closed portrait and inner open landscape PNGs. The owner explicitly authorized the Design Resources License. Licensed originals stay in the local cache and are not redistributed in source control. Native screen dimensions match each display opening exactly; the complete device is scaled uniformly, retaining Apple's camera, corners, controls and hinge. All 78 Apple exports pass format/dimension validation; 45 iPhone/Duo replacements are uploaded with selective set refresh. The existing 15 iPad screenshots were skipped by checksum comparison. Final API read-back passes for all nine iOS sets: 60 COMPLETE images, correct story order and exact local/server source-file checksum matches. Receipts are in the refreshed pack. No review submission was made.

## Native usage illustration with localized marketing

Header/Search Results creative now combines the app's actual batch-screen capture and actual IDCardFace image with an official Apple product frame, an empty reader/adapter cutout and a deterministic cable path. The cable leaves the phone vertically downward in the flat image plane before turning right; the reader fully occludes the physical contact chip. App/card text and avatar pixels are retained from native captures.

The RO/EN/RU headline, feature summary, three usage steps and key-privacy line live under stable keys in `localization/catalog.json/storeCreative`. The generator records source hashes, crop coordinates and frame provenance, validates input dimensions and chip occlusion, and exports opaque 5244×2950 PNGs. The default Apple screenshot pipeline includes composition and export.

All three marketing images are saved in Asset Library with six ACTIVE Header/Search Results draft placements linked to the new image IDs. The replacement uploader retains prior images, supports explicit placement replacement with rollback, uses content-versioned reference names, follows collection pagination and handles HTTP 204 empty bodies. It does not submit assets or the app for review.
