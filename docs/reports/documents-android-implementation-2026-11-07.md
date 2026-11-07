# Android Documents implementation — 7 November 2026

Document taps now open an in-app signature-details modal. Clearing activity history no longer empties the signed-document library.

## Changes

- `ActivityLog` persists signed outputs under a separate `signedDocuments` preference key. The first upgrade seeds it from eligible existing history entries, keeping the newest successful output per URI. New saved outputs enter both collections, but the library does not inherit history's 100-entry limit.
- History clearing and reachability pruning affect history only. Missing or inaccessible saved files remain listed so opening them can show an access error; neither cleanup nor inspection deletes document bytes.
- Documents uses the independent library flow. Its clear-history action is available only in History.
- Tapping a document row opens a bounded, scrollable details modal with current validation results, signer and certificate details, and technical disclosures reused from Verify. Loading, read errors and missing detached-XAdES companion documents are handled in the modal. Companion files can be chosen through the system picker.
- Changing companion-file selections clears the previous verdict immediately. Cancelled or obsolete reads cannot publish a stale result/error or clear a newer loading indicator.
- Inspection reads the current file and does not change the Verify workspace, append history, invoke card signing, or request a PIN. Existing Open, Verify, Share and Save As actions remain in the overflow menu.
- The shared signature cards now use localized resources for Author, Signature and Certificate details. New modal text was supplied for Romanian, English and Russian through the shared catalog workflow.

## Validation and remaining checks

`git diff --check -- android` passed. Two focused regression tests were added for migration filtering/deduplication and library independence from the history cap. Native builds, test execution, emulator interaction, rotation/accessibility layout and provider-permission scenarios were not run for this implementation; the project instructions leave builds and tests to the owner.

Suggested owner validation: upgrade an installation containing signed and verified history; clear History and restart; confirm Documents still contains signed outputs; tap a PDF and inspect certificate details; test missing/revoked files and detached XML with and without its original; confirm the Verify workspace and history remain unchanged by inspection.

Previously cleared history metadata cannot be reconstructed automatically. Existing files in Downloads or app storage are untouched. This change neither implements a new signing integration nor changes the earlier security-review validation limits.

## Subsequent native validation

The next validation pass built the application, ran the core/PIN-record tests, exercised Documents/history migration and clear/restart behavior, and reviewed native modal layouts. It also corrected Debug fixture flags, modal sizing and unavailable-file error presentation. See [Android validation report](documents-android-validation-2026-11-07.md) for exact evidence and remaining limits.
