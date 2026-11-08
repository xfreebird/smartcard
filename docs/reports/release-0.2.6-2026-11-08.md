# eSemnBun 0.2.6 release — 8 November 2026

The release contains the Apple discovery/Shortcuts/Siri work and desktop MCP/signing automation described in `automation-integration-2026-11-07.md`. Android receives release metadata/distribution maintenance; it does not receive the desktop MCP or Apple integration features.

## Delivery status

| Destination | Build | Observed result |
| --- | --- | --- |
| iOS App Store | 0.2.6 (206) | Waiting for review; existing localized screenshots and review details retained. |
| macOS App Store | 0.2.6 (206) | Withdrew the pending 0.2.5 review, attached processed build 206, and submitted the replacement. Waiting for review. |
| Google Play Alpha closed test | 1793624681 | Uploaded AAB and committed 0.2.6 to Alpha; API reads back `completed`. Review/distribution availability is separate. Other tracks preserved. |
| Microsoft Store | 1.2.206.0 | Uploaded the replacement MSIX and committed submission 1152921505702344468. Processing; manual publication retained. |
| Huawei AppGallery | Replacement APK 1793624681 ready | Existing 1793624678 review remains unchanged. Browser verification did not complete through the available controls; a candidate service-account withdrawal route returned HTTP 404. No replacement review claimed. |
| GitHub / website downloads | 0.2.6 | Public installers include macOS DMG and universal CLI archive, Android APK, Windows MSI/certificate, Linux GUI/CLI DEB/RPM/tar archive and Flatpak. |

Release: https://github.com/xfreebird/smartcard/releases/tag/v0.2.6

Apple review IDs: iOS `25c13037-682e-4c0a-b27c-395d502612e7`; macOS `28a2f791-0dd5-400d-bd18-6896ff91b847`. Both were read back with build 206 selected. The first macOS listing does not accept a What's New field; its existing listing and screenshots were preserved. Apple publication remains manual after approval.

## Packaging and automation corrections

- Published the notarized macOS CLI archive as the companion for the sandboxed Mac App Store app; corrected website classification so it appears under macOS.
- Switched the embedded MCP architecture check to `xcrun lipo -archs` and explicit ARM64/x86_64 membership checks. The runner's `lipo -verify_arch` rejected both argument orders.
- Added the multiple-instance manifest attribute required by MakeAppx for the packaged console execution alias. Windows packaging now passes; the installed Store alias still needs a runtime check.
- Android reservations now use GitHub's refs API instead of pushing annotated tags. The replacement workflow successfully reserved 1793624681 and built it.
- Release creation now reserves the exact source ref before publishing instead of asking the releases endpoint to create a tag against a branch commit that may have become older. YAML validation passed; this new-release creation branch has not yet been exercised by another release.
- Canceled the redundant tag-triggered build after manual release creation. It did not replace the selected Apple review builds or the Microsoft draft.

## Evidence

- Full cross-platform CI passed on `e2330c3`: run https://github.com/xfreebird/smartcard/actions/runs/42452349529 (seven jobs).
- Original multi-platform run https://github.com/xfreebird/smartcard/actions/runs/42451847937 supplied iOS and Linux/Flatpak artifacts. Its packaging/publication failures were repaired separately, not hidden.
- macOS App Store upload: https://github.com/xfreebird/smartcard/actions/runs/42451850296.
- Successful notarized standalone macOS release: https://github.com/xfreebird/smartcard/actions/runs/42452823572 (source `0974b2f`).
- Successful Android build: https://github.com/xfreebird/smartcard/actions/runs/42452349543.
- Successful Windows MSI/MSIX package: https://github.com/xfreebird/smartcard/actions/runs/42452418972.
- All 11 public artifact hashes match both GitHub asset digests and the release SHA256SUMS.txt.
- Downloaded macOS app passes strict recursive signature verification; its enclosing DMG has a valid stapled notarization ticket. Bundle version is 0.2.6 (206).
- Downloaded Windows MSIX manifest is 1.2.206.0 and contains `bin/esemnbun.exe`. Public MSI uses the accompanying self-signed certificate; Microsoft signs Store distribution separately.
- Downloaded Android APK identity is `md.esemnbun.app`, version 0.2.6, code 1793624681. SHA-256: `3f02655fce9879f6a461a3bb27c1c22ff5d270c0739fcd6a10ea1f14b7738f58`.
- Linux and macOS archives contain both `esemnbun` and `esemnbun-mcp`.

Live Siri, Spotlight/Handoff behavior, installed Store CLI activation, real credential-provider authorization, and physical-card unattended signing retain the validation limits documented in the implementation report. No real card PIN was used during release verification.
