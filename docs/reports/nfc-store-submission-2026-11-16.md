# eSemnBun NFC release materials

Prepared for owner review on 16 November 2026. The proposed marketing version is **0.2.12**, following 0.2.11. The candidate is a local materials pack. Release build numbers will be reserved from fresh store maxima when the owner approves proceeding.

## Public listing

- iOS has a localized NFC subtitle, keywords, promotional text, descriptions and What's New. The first iPhone and Duo screenshots introduce both NFC and card-reader signing. The second shows a connected demo card with the reader method selected. Both Apple featured placements show the two methods beside each other. iPad shows the reader workflow.
- Google Play has updated localized short and full descriptions, changelogs, screenshot captions and feature graphics. The first two screenshots and the feature graphic show NFC and a USB card reader. The other screenshots show Verify and Settings. The independent-app disclosure and official service links remain in all three full descriptions.
- macOS and Windows list card-reader signing and the new Settings layout. The Mac App Store name remains **eSemnBun Desktop**. Its English-US and English-GB entries share the refreshed English assets. Microsoft listings cover Romanian, English and Russian with the existing desktop search terms.
- The production privacy, support and terms routes returned HTTP 200. The NFC wording is prepared in the localized public privacy pages and the policy source. Publish the revision with the approved release, then check the live content.

## Screenshot matrix

| Placement | Pixels | Images per language |
|---|---:|---:|
| iPhone | 1320 × 2868 | 5 |
| iPad | 2064 × 2752 | 5 |
| iPhone Duo cover | 1398 × 2034 | 5 |
| iPhone Duo inner landscape | 2853 × 2007 | 5 |
| Mac App Store | 2880 × 1800 | 6 |
| Google Play phone | 1440 × 2560 | 4 |
| Google Play 7-inch tablet | 1440 × 2560 | 4 |
| Google Play 10-inch tablet | 2560 × 1440 | 4 |
| Microsoft Store desktop | 1368 × 909 | 4 |
| Apple product page Header | 3840 × 1646 | 1 |
| Apple Search Results | 3840 × 2560 | 1 |
| Google Play feature graphic | 1024 × 500 | 1 |

These dimensions preserve the prior approved submission set. Captures use fictional cards and sample documents. Apple formatted screenshots and featured assets are opaque PNGs. App Store Connect's product-page preview can confirm the adaptive crops after the owner authorizes a draft upload. [Apple screenshot reference](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) · [Apple featured asset guidance](https://developer.apple.com/app-store/asset-best-practices/) · [Google Play assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en) · [Microsoft images](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/screenshots-and-images)

## Review instructions and NFC evidence

- Apple: [iOS Notes for Review](../../distribution/apple/ios/review-notes-nfc.txt). The reviewer can explore Settings → Demo mode without hardware. A live test uses a supported iPhone, compatible card with an active signing certificate, and its PIN. Tap Continue, confirm the PIN, and hold the card near the phone until signing finishes. The signed IPA should be inspected again for the TAG entitlement and the existing App Groups. [Apple review guidance](https://developer.apple.com/app-store/review/guidelines/)
- Google: [Play Console App Access text](../../distribution/google/review/app-access-console.txt) and [detailed NFC instructions](../../distribution/google/review/nfc-app-access.txt). Keep hardware optional in the manifest and use the production package and established upload key. Review App Access and Data Safety against the signed candidate. [Google Play review preparation](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)
- A physical-device video remains to record for hardware review. Use a synthetic PDF and show document choice, NFC selection, a card presentation and the verified result. Cut away during PIN entry and conceal the real card's printed details and certificate identity. Use separate iPhone and Android clips if requesting review on both. The notes and screenshot pack contain no real PIN or card data.

## Store state read back

| Store | State checked 16 November | Action after approval |
|---|---|---|
| iOS | 0.2.11 (213) ready for sale. No active App Review submission returned. | Create the new version, select the verified replacement build and upload assets. |
| macOS | 0.2.11 (213) waiting for review. | Recheck state, then withdraw this exact pending review if still active and the replacement is ready. |
| Microsoft | Published MSIX 1.2.213.0. No pending submission. | Prepare an update with a higher MSIX package version. |
| Google Play | Personal Play Console sign-in required for Publishing overview. Live review and track state remain unverified. | Check Publishing overview before deciding which pending changes need replacement. Keep currently available test releases accessible. |

The owner requested review of the package before proceeding. There were no cancellations, store uploads, submissions, publishing actions or release dispatches.

## Verification

The local review page groups all localized copy and 126 screenshots with the six Apple creative assets and three Play feature graphics. The validator compared every screenshot grouping to the previous approved dimensions and image counts and recorded SHA-256 for all 135 images. The Apple slot validator, localization completeness check, generated metadata check, and whitespace check passed. Screenshot sources include a simulator build with guarded fictional capture data, the previously reviewed Android debug build, the macOS review build, and a fresh Windows VM build. Signed distribution candidates for 0.2.12 remain a release step.

## 0.2.12 release follow-up

- iOS build 214 is waiting for App Review. App Store Connect verified 60 screenshots in the expected iPhone, iPad and Duo order across three languages. Both silent physical-iPhone clips are inside the single review attachment. The NFC review copy omits PIN entry and obscures printed card identifiers. The USB video shows reader connection and selection.
- Google Play received signed bundle 1793624697 for Alpha. The three localized listings were saved in Play Console and read back by hash. All nine phone and tablet sets lead with NFC, then USB reader, verification and Settings. The case contains the NFC and reader reviewer instructions.
- The macOS build 214 is valid in TestFlight. The preceding Mac App Store review remains pending while a separate Mac hardware video is outstanding.
- The signed Android and Windows package jobs succeeded. The Android CI rerun after updating the native Settings journey passed. The initial Apple hosted runner did not start. The iOS and Mac Store packages were signed and uploaded locally instead.
- The website includes a five-stage iPhone and Android sequence with native light and dark captures, and the localized guides describe both methods. The iPad guide describes the USB reader flow.
