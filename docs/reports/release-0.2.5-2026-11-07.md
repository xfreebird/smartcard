# eSemnBun 0.2.5 — 7 November 2026

Authorized scope: commit and push the completed changes, refresh supported store artwork, submit new store builds including macOS App Review, publish installers and update the website landing-page scroll transitions.

## Source and verification

- `f1c1521`: adaptive UI, independent document library/history, signature details, PIN/bridge hardening, shortcuts/capability discovery, approved store artwork, and accessible landing transitions.
- `a148eeb`: older-SDK toolbar compilation fallback and combined Microsoft package/artwork staging.
- `4359c58`: pinned Poppler GLib dependencies for Flatpak packaging.
- Apple/Windows build: 205. Android code: 1793624678. Marketing version: 0.2.5.
- Website: 15 tests, all three locale builds, SEO checks, and live Firefox scrolling passed. Reduced-motion behavior was checked in source/tests; the live OS preference was not changed.
- macOS DMG: downloaded from the release build; container signature, stapled notarization, mounted app strict signature, version 0.2.5/build205 and minimum macOS15 verified.

## Delivery tracking

- Release: https://github.com/xfreebird/smartcard/actions/runs/42399324605
- macOS Store upload: https://github.com/xfreebird/smartcard/actions/runs/42399327190
- Android artifact: https://github.com/xfreebird/smartcard/actions/runs/42399317072
- Website: https://github.com/xfreebird/smartcard/actions/runs/42399317089
- Flatpak retry: https://github.com/xfreebird/smartcard/actions/runs/42399783710

## Verified release results

- GitHub release `v0.2.5` contains the notarized macOS DMG, Windows MSI, Android APK, Linux packages and Flatpak. The successful Flatpak retry refreshed `SHA256SUMS.txt`; it includes the APK (`bdc18266…`), Flatpak (`f1b93abd…`), DMG (`490fe31d…`) and MSI (`bc3a1270…`). The subsequent website deployment succeeded, and the live downloads page links the 0.2.5 assets.
- Apple iOS: build 205 is VALID and selected for version 0.2.5. All 78 screenshots across Romanian, English and Russian, including iPhone Duo sizes, were COMPLETE, correctly ordered and checksum matched. The six current featured placements were uploaded and active. Review submission `5fcffce5-a721-47cb-ae3b-5ff19869d8c7` is **WAITING_FOR_REVIEW** with manual release.
- Apple macOS: build 205 is VALID and selected for version 0.2.5. All 24 screenshots across four locales were COMPLETE, correctly ordered and checksum matched. The older review was withdrawn after replacement assets and build were ready. Review submission `f510e264-c31f-4e13-89ab-d564de204373` is **WAITING_FOR_REVIEW** with manual release.
- Microsoft Store: the certified manual 0.2.4 submission `1152921505702336016` was published through Firefox. Store API read back confirms it is the last published submission. New 0.2.5 draft `1152921505702342396` has the CI MSIX version `1.2.205.0` (SHA-256 `8b625463d6b6ab9ce8fae4991e875c0f7f9996bfa380a084a63e3ff08a4aec63`), 12 screenshots and release notes in three locales. It was committed and is in **Certification**, with manual publication retained and no reported errors. The Store signs the unsigned MSIX during ingestion.
- Google Play: Alpha closed testing release 0.2.5, version code `1793624678`, and all 36 refreshed screenshots across phone, seven-inch and ten-inch formats in English, Romanian and Russian were submitted through Firefox. Publishing overview shows the release and nine listing changes under **Changes in review** while quick checks run. The service account accepted uploads in a staging edit but returned 403 on commit, so the console account completed the submission. Production access remains subject to Google's 12-tester/14-day requirement.
- Huawei AppGallery (later 7 November update): the owner requested replacement, so the 0.2.0 review was canceled in AppGallery Connect. Signed 0.2.5 APK `1793624678` (SHA-256 `bdc18266b8f30f986dd5fff46bcbe5af65ec558c6499bfae2725c6bc19cd2311`) was attached and submitted. The read-only API confirms `releaseState=4` for the new build: **Reviewing**.

## Availability boundaries

Apple review acceptance, Microsoft certification and manual publication of 0.2.5, Google review/closed-tester rollout, and Huawei review completion remain external pending steps. Submission is not the same as public availability. No PIN, signing credential or private account material was added to this report.
