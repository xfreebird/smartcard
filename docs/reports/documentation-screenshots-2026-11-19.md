# Localized documentation screenshot refresh — 19 November 2026

Refreshed **114 native guide images** in English, Romanian and Russian, using source `4e694f33` plus the scoped capture-fixture changes in this commit. No application release, tag, packaging, Store upload or release workflow was requested or performed.

| Layout | Images | Updated views |
| --- | ---: | --- |
| iPhone | 15 | Preview/Share, Settings, authentication focus, RSA encrypt/decrypt |
| iPad | 9 | Preview/Share and RSA encrypt/decrypt |
| Android phone | 36 | Eight Verify states, browser entry/sheet, RSA encrypt/decrypt |
| Android tablet | 36 | The corresponding native tablet layouts |
| macOS | 6 | RSA encrypt/decrypt sheets |
| Windows | 6 | RSA encrypt/decrypt dialogs |
| Linux | 6 | RSA encrypt/decrypt dialogs |

The existing landing light/dark scenes, unaffected reader/signing/card images and CLI command illustrations still match their owning views or commands and were retained. Existing Apple Verify screenshots already show the current navigation-bar clear action; their numbered instructions now identify it. iPad documentation does not introduce an NFC authentication setting that the device lacks.

## Capture and presentation

Preserved the established approach: actual native translated UI, fictional identities/documents, isolated Debug preferences, no real reader or PIN, and no demo banner. Complete mobile frames use native **09:41** clocks. Native iPad layouts were captured separately. Windows crops exclude desktop, shadows and rounded-corner background; Mac sheets use recorded interior crops and 2:1 Retina downsampling. The focused iPhone authentication crop is declared in its guide caption and evidence.

The canonical sources remain `docs/user-guide/content/<locale>/`. Only affected instructions and target coordinates changed. Native accessibility bounds and OCR positions were used to align the numbered gutter callouts. Added 15 localized panels for authentication and desktop RSA decryption; regenerated all **327 task pages / 792 panels**. Updated the related certificate/public-key compatibility guidance, including the explicit CLI flag, without changing the existing terminal illustrations.

Linux and Windows now select the RSA preview and asymmetric filename for certificate capture scenarios. The Apple capture helper uses an unbuffered readiness pipe; the Android helper explicitly requests a 24-hour clock. These changes support capture fixtures; they do not enable real signing, decryption or NFC hardware.

## Validation

- **39/39 website tests passed**, including image hashes/dimensions, clock/crop inventories and numbered guide/navigation coverage. Updated the expected panel inventory from 777 to 792.
- Docusaurus **English, Romanian and Russian builds passed**.
- Guide regeneration check and localization/asset validator passed: 30 guides, 327 task pages, 792 panels, zero errors.
- **393 clock records verified**, with no normalization edits needed; all 114 refreshed PNGs decoded and matched their recorded dimensions/hashes.
- Enlarged rendered guide panels were reviewed in the local website: English iPhone authentication, Romanian Android authentication/method/card targets, and Russian Windows RSA decryption. Native captures were also inspected across layouts/locales; Windows framing contains no desktop background.
- Local iPhone Settings capture XCTest passed. Android instrumentation captured both phone/tablet browser scenes in all three locales and observed the localized authentication sheet. The normal Android test runner was rebuilt and reinstalled afterward.
- Current local macOS AppStore Debug build passed; the app, Debug dylib and reader helper were development-signed with the existing matching profile and verified Store sandbox/smartcard boundaries. Windows Debug x64 build passed with zero warnings/errors. Linux Debug build and package test command completed successfully.
- The preceding mobile implementation's full local UI results remain documented in [mobile controls validation](mobile-ui-controls-validation-2026-11-19.md): 35/35 iPhone and 35/35 iPad cases plus file postchecks; Android 34 journeys and five integration phases. This documentation refresh did not rerun those complete unchanged mobile suites.

The first capture attempts exposed an obsolete Mac profile, a buffered Apple readiness message and a Windows window-readiness/logging issue; the published assets come from the subsequent successful runs. The full source and asset identities, crop rectangles and per-platform build hashes are in [the refresh manifest](../user-guide/ui-controls-refresh-2026-11-19.json). Existing per-platform evidence points to that scoped refresh; untouched historical records remain available.

Fictional UI captures do not demonstrate physical NFC/USB, saved-PIN reuse, cryptographic validity, card decryption, trust/revocation validation or Siri/Handoff behavior. All simulators, the dedicated emulator and both initially stopped VMs were stopped after capture. Raw captures and local validation logs remain in ignored `.local/docs-screenshots-20261119/`.

## Review samples

- [iPhone Preview/Share](../../website/static/img/guide/iphone/ro/details.png)
- [iPhone authentication](../../website/static/img/guide/iphone/ro/browser-authentication.png)
- [iPad RSA encryption](../../website/static/img/guide/ipad/ro/protect-certificate-light.png)
- [Android Verify](../../website/static/img/guide/android-phone/ro/verify.png)
- [Android saved-card selection](../../website/static/img/guide/android-phone/ro/browser-authentication.png)
- [Android tablet authentication](../../website/static/img/guide/android-tablet/ro/browser-authentication.png)
- [macOS RSA encryption](../../website/static/img/guide/macos/ro/protect-certificate-light.png)
- [Windows RSA decryption](../../website/static/img/guide/windows/ro/protect-rsa-decrypt-light.png)
- [Linux RSA encryption](../../website/static/img/guide/linux/ro/protect-certificate-light.png)
