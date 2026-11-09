# eSemnBun 0.2.9 release

Production changes: `b125964`. Test-harness follow-up: `6243d63` (no production-code changes).

## Changes

- All native apps: confirmed individual/all saved-document deletion; history clearing remains separate.
- Apple: selected-original XML file access, clearing stale signing banners, and a clearer iOS share-extension handoff.
- Android: repeated original selection refreshes verification and same-name selections replace previous originals.
- Windows: refreshed XML verification replaces the previous rendered report.
- Linux: original-document selection from Verify and saved-document details.
- English, Romanian and Russian release notes are scoped to each platform.

## Validation

- Full CI `42649315944`: passed all platform jobs and aggregate.
- Initial Windows test-harness scheduling failure was corrected with asynchronous entry signaling and a dedicated session task. Cancellation and EOF assertions are retained.
- Release packaging `42648572389`: all platform jobs succeeded, including Flatpak. Public v0.2.9 has 12 installation assets; all GitHub asset digests matched SHA256SUMS. Store-only inputs are excluded.
- Mac App Store upload `42648577958`: succeeded.
- Downloaded macOS DMG: stapler validation and desktop distribution boundary checks passed.
- Downloaded Windows artifact checksums matched.
- Android APK identity: `md.esemnbun.app`, 0.2.9, 1793624690; upload-certificate SHA-256 `0bd6c7ce1a0e57b3f959917d6c166c433184a3101cad5ddd5333b82bce9324cf`.
- No new real-card signing, file deletion on user data, or device interaction tests were performed.

## Store state

- iOS: 0.2.9 build 210, WAITING_FOR_REVIEW; replaced 0.2.8. Review submission `5499243c-5dfc-49d3-8926-c40339360add`.
- macOS: 0.2.9 build 210, WAITING_FOR_REVIEW; replaced 0.2.8. Review submission `bdfd4f02-ab2f-4e33-98f9-09f37aa08777`. This is the first Mac App Store release; Apple rejects editing its What's New field, so the existing first-release listing was preserved.
- Windows: replaced submission `1152921505702353222` with `1152921505702354441`; MSIX 1.2.210.0 is in Certification. Manual release retained.
- Google Play: submitted exact Release AAB 1793624690 to Alpha in workflow `42652851179`; independent hash/track checks passed. Console confirms Changes in review for 0.2.9 (1793624690). Other tracks are unchanged. AAB SHA-256: `acc9b2f4c754f73ec2c551da2137169abc1079f86da8d38161a57641af511de8`.
- Huawei: previous review 1793624688 remains untouched. Browser sign-in requires a new slider CAPTCHA; per-action confirmation requested and still pending.

A review submission is not store availability. Statuses above are checkpoints, not approval claims.

- CLI package repositories workflow `42652831633` passed signed APT/RPM validation and Chocolatey installation/uninstallation. Updated website release data and desktop manifests to 0.2.9.

## Final distribution verification

- Website `42653376230`: succeeded on deployment retry. The first attempt timed out while GitHub Pages synced files; the retry reused the same successful build artifact. Live macOS/Windows/Linux update manifests and package-feed version now report 0.2.9.
- All 15 final release assets, including the signed repositories, definitions and Chocolatey package, match the refreshed SHA256SUMS.
- Live package-definition ZIP SHA-256 matched `packages/version.json`; the Homebrew/Scoop definitions match its contents byte-for-byte. Published to the existing `xfreebird/homebrew-utils` repository as `5f94530`. Ruby syntax and patch checks passed. New local Homebrew/Scoop installation tests were not run; package CI separately passed APT/RPM and Chocolatey checks.
- Huawei read-only recheck still reports build 1793624688 in review; CAPTCHA confirmation remains pending. No Huawei review was withdrawn.
