# eSemnBun 0.2.4 — 6 November 2026

Authorized scope: submit iOS and Windows updates; publish a signed/notarized macOS DMG; upload macOS TestFlight and Android bundle only. No macOS App Review or Android track/review changes.

Source: `242af99`; test-only correction: `84cbaf3`. Author/committer: `xfreebird <xfreebird@gmail.com>`.

App translations and generated store metadata are synchronized in Romanian, English and Russian. Release notes: `docs/releases/0.2.4.md` and localized store exports.

- Apple workflow: https://github.com/xfreebird/smartcard/actions/runs/42266869721
- iOS 0.2.4 (204): processed VALID; selected for version 0.2.4; review submission WAITING_FOR_REVIEW. Existing manual release policy retained.
- macOS TestFlight 0.2.4 (204): processed VALID; localized testing notes updated. Existing App Review submission unchanged.
- Windows submission: package and localized notes uploaded; workflow commit hit a Microsoft ingestion HTTP 500. Read-back confirmed PendingCommit, then a direct commit retry succeeded. Package 1.2.204.0 reached Certification with no submission errors.
- Windows workflow: https://github.com/xfreebird/smartcard/actions/runs/42266875551 (completed).
- macOS DMG packaging correction: hide-extension metadata added FinderInfo to the signed app. Removed that setting in `494e8bb`; verification of a copy without Finder metadata passed strict signature checks. Replacement run: https://github.com/xfreebird/smartcard/actions/runs/42269520335.
- Initial macOS DMG workflow: https://github.com/xfreebird/smartcard/actions/runs/42266880355 (completed).
- Android 0.2.4 / 1793624677: signed AAB uploaded through Play Console and confirmed Inactive. API upload failed on existing halted-track validation; no track/review changes were made. AAB SHA-256: `c845d5c54da8ad525f9937d88196a8c140b6d5966c4cd1a4ca3bd98c3a13b5a1`.
- Android artifact-only workflow: https://github.com/xfreebird/smartcard/actions/runs/42266831586 (API commit failed; Console fallback completed).
- CI after the test correction (all jobs passed): https://github.com/xfreebird/smartcard/actions/runs/42267289747 (completed).

The first CI run exposed an assertion that searched an ASCII-hex encoded PDF appearance stream as plain text. The correction decodes the stream before checking transparency and border commands; release runtime code did not change.

Final replacement DMG: 0.2.4 build 204; container signature, stapled notarization ticket, release checksum, and strict verification of the unmodified mounted app and desktop distribution boundaries passed.
