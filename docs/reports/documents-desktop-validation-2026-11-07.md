# Desktop Documents validation — 7 November 2026

The recommendation implementation was built and exercised on the MacBook Air's existing Fedora and Windows guests. New isolated source and preference directories preserved installed applications and existing user data. Test documents and historical activity records were synthetic; no real card, PIN or signing operation was used. A historical success record was deliberately attached to an unsigned fixture to prove that details inspect the current file instead of trusting the history icon.

## Native build and regression results

| Target | Result |
| --- | --- |
| Fedora 44 ARM64, Swift 6.4.1, GNOME Debug app | Built; 18 native application tests passed, zero failures |
| Fedora Swift CLI | Built; `capabilities --json` exited 0; unsigned PDF `verify --json` exited 2 and returned structured verification output |
| Windows 11 ARM64, x64 app under emulation, .NET 10.0.403 | Native WinUI Debug build passed with zero warnings/errors |
| Windows CLI capability regressions | 10 passed, zero failures/skips |
| Windows CLI actual process | Capabilities JSON exited 0; unsupported signing JSON exited 1, with a sanitized error and no supplied-argument disclosure |

Four new Fedora regressions exercise actual Store persistence with injected temporary file URLs: legacy migration then history clear/reload, an intentionally empty library remaining empty, a library exceeding the history cap, missing-original presentation remaining incomplete, and independent invalid cryptography or a known digest mismatch taking priority over missing originals. Temporary URLs keep these tests away from the user's XDG profile.

## Runtime results

Windows native UI Automation and actual pointer activation exercised both 1100 × 740 light and 860 × 580 dark windows. A legacy history-only profile migrated into the signed-document library. Clicking the saved document opened the details modal. Clearing History preserved the document, and relaunching retained it. The persisted snapshot contained zero history entries and one library entry, and the file still existed. Inspection did not create a new history event. Closing and reopening the modal yielded a settled unsigned verdict in the new dialog. The fixture completed too quickly to prove cancellation during an observed pending verification; no artificial delay was added. The harness used its own temporary window ordering to prevent an unrelated existing preview window from obscuring captures; no global foreground policy or OS appearance setting changed.

Fedora's real application, using an isolated non-demo XDG profile, migrated a history-only signed-output record. Actual mouse interaction opened its details modal, which correctly reported that the current PDF had no recognized signature. Mouse-driven History cleanup retained Documents, and a fresh process still displayed the saved entry. Disk assertions after relaunch confirmed zero history entries, one saved-document record and an unchanged existing PDF. Separate Debug fixtures verified the 360 × 420-point dark library and modal; GNOME's existing 200% scale makes those windows 720 × 840 physical pixels.

## Defects found and fixed

- Linux whole-row mouse activation did not open details: `GtkListBoxRow::activate` did not cover pointer activation. The list now handles `row-activated` and resolves the activated row's document path. Native pointer activation then opened the modal.
- Windows saved rows displayed the raw resource key `NavVerify.Content`. The action now uses the existing direct `Action_Verify` resource; the native replay displays “Verify”. The empty History label had the same property-resource lookup problem; it now uses the MRT property path `RecentEmpty/Text` and is checked as “No activity yet”.
- Windows modal verification could remain stuck in “Verifying” because the child Page unload event invalidated a result during ContentDialog reparenting. Verification now starts on dialog Opened and cancellation is tied to dialog Closed. The native settled-result guard then passed.
- Windows details and cleanup dialogs did not inherit a dark page's theme. They now explicitly use the page's actual theme.
- Linux copied core verification reports without their new missing-reference metadata. The presentation model now preserves that metadata, returns an incomplete verdict for unavailable originals while preserving an independent invalid-signature/mismatch verdict and shows neutral original-file guidance instead of a content-modified failure. A native regression covers this policy. The existing same-folder original-file workflow remains; a Linux inline companion picker is still follow-up work.

## Evidence and artifacts

Curated screenshots and JSON assertions are in `docs/reports/desktop-documents-validation-2026-11-07/`. Full build/test logs, original captures, readiness records and temporary harnesses are under `/tmp/esemnbun-documents-validation-20261107/` on the main Mac and the same named isolated source root in each guest.

The final Fedora executable SHA-256 is `a2b0107976bf9c0b455d94db002b6de945f12468e84aad76b5507bc912f5e182`. The final Fedora CLI SHA-256 is `403b44640f4c3d26ec32666789d02fd083fcdaa5f2bcbd7509de10ecdaca1086`. The final Windows application DLL SHA-256 is `41e9dfb501aaf363b9a5079d2e0533ea7da5b8f00b48491753040d7e45d1bc99`. Source hashes and capture dimensions are recorded in the evidence manifest.

The Windows CLI process results contain metadata only; capability discovery grants no signing permission. Windows CLI document verification remains unavailable and is accurately advertised as such.

## Limits and cleanup

This validates native Debug source, current-file unsigned-PDF inspection, independent library persistence, modal navigation and representative light/dark sizing. It does not prove physical reader transport, signing, PIN/authentication, revocation/timestamp-chain checks, screen-reader behavior, installers, MSIX/Flatpak sandboxing or every theme/language/size combination. Linux missing-reference UI policy is regression-tested; no inline original-file picker was added there.

Task-owned application processes were stopped after capture and the temporary Windows scheduled task was removed. The isolated source/data directories are retained for review. No reader passthrough, installed-app removal, user preference reset, release, store submission, commit or push was performed.
