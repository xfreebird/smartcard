# eSemnBun 0.2.13 delivery

The owner approved the document, identity, file-protection and Mac App Store changes and authorized review submissions on 18 November 2026. Huawei's existing review is preserved.

Source commit is 426aff4b. Apple and Windows build number is 215. Android reserves its independent higher version code through the release workflow.

## Validation

- All 75 CI automation and component-boundary tests passed locally.
- The reviewed native Mac Store Debug build passed. The real Settings scene retains icon tabs. Focused Documents search and filtering were checked at 860 and 1200 points.
- Windows's prior native preview build and 14 focused protection tests passed. Android's core protection tests and emulator encryption/storage checks passed.
- Installed MoldSign libraries decrypted the new Swift AES-128/192/256 and RSA recipient fixture envelopes.
- Real RSA card decryption remains unverified. Windows's supplemental native file-picker automation timed out at filename entry. No physical card PIN was used for release preparation.

## Delivery

- Release workflow 44404375392 packages all platforms, uploads iOS to TestFlight and submits the Windows MSIX.
- Mac App Store workflow 44404381423 packages and uploads the sandboxed Mac build.
- App Store 0.2.13 drafts retain the existing localized store screenshots and review contact information. The separate pending iOS review contains four non-version items.
- Documentation screenshots are being refreshed in English, Romanian and Russian for each affected native platform.


- iOS build 215 is WAITING_FOR_REVIEW. Mac build 216 supersedes build 215 and is WAITING_FOR_REVIEW. The separately pending iOS featured-artwork review was preserved.
- Google Play submitted 0.2.13 (1793624699) to the existing alpha closed track. Receipt state is submitted.
- Microsoft accepted submission 1152921505702443596 with the uploaded 0.2.13 MSIX. Its asynchronous certification state is checked separately.
- The documentation refresh contains 363 new native images across Apple (192), Android (120), Windows (24) and Linux (27), in EN/RO/RU. The guides contain 777 numbered panels and 327 task pages.
- Screenshot fixtures use fictional identities and isolated Debug applications. Mobile Apple captures use the approved UI compiled before the marketing-version stamp. Native Romanian/Russian long headings still truncate in two captured controls, and iPad's system weekday follows its English simulator setting.
- CI coverage now includes the disconnected saved-identity regression, bounded repository-verified Kotlin plugin retries, and Linux disclosure/editable-field selectors. All 81 automation checks and the complete local Android journey batch passed.

## Final delivery evidence

- iOS 215 and macOS 216 are waiting for App Review. Windows submission 1152921505702443596 reached Certification. Google Play alpha submission 1793624699 reports submitted. Huawei was not changed.
- Corrected Linux package run 44411269929 and Flatpak run 44406307194 succeeded. The 0.2.11-labeled assets were removed from the 0.2.13 release after their replacements were verified.
- All 15 public payloads match the published SHA256SUMS.txt, including standalone installers, CLI packages and repository definitions.
- Documentation deployment 44408019603 succeeded. English, Romanian and Russian pages and sampled native screenshots were checked on the public site. All 39 website tests and the guide validator passed.
- Hosted CI 44408021026 passed Swift, macOS, Linux, Windows, Android and localization. Its iPhone journey hit an obsolete author-label selector. Test-only correction 960f297f passed all three Documents cases locally with zero failures/skips and preserved filesystem/persistence assertions. The subsequent hosted Apple run validates the corrected selector.
- Final release/download metadata includes version 0.2.13. Native screenshot provenance and remaining presentation limitations are recorded in the Apple and desktop evidence manifests.
