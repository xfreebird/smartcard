# Corrective acceptance pass — 31 October 2026

The owner rejected the earlier screenshot acceptance and architecture assessment. This pass addresses those
specific gaps; the older 30 October matrix remains historical evidence rather than proof that the revised
screens are correct. Current screenshots are stored in the 31 October platform folders on the Desktop.

## Shared source and localization

The single catalog now uses stable semantic app identifiers throughout. Apple/Linux generated typed keys
replace display-text lookups; Android uses R resources and Windows uses native MRT IDs. Formatting arguments
and all Romanian/English/Russian translations remain in the catalog. Store copy is in its storeMetadata
section. Check mode validates native exports and rejects Swift prose lookup calls and unkeyed SwiftUI labels.
Copy edits do not regenerate identifiers. Export remains selectable per platform.

Platform code is grouped by responsibility with application-owned ports and platform adapters. The exact
roles and dependency direction are documented in docs/12-platform-adjustments.md; Android core remains
Android-free, and the shared Swift signing implementation is retained once for Apple/Linux. Refactoring
preserves certificate identity checks, serialized card access, frozen batch scopes and stop-on-first-error.

## Evidence and execution boundaries

Android's final Debug/Release/AAB/lint build passes. Core 117 tests have zero failures and one opt-in skip;
USB 21 tests have zero failures. All four native ABIs pass package audits. Twenty-four targeted ARM64 runtime
captures cover phone and both tablet orientations, light/dark, cards/no-reader/batch/blank PIN. Separate
Android report records the source boundaries and logs. x86-64 runtime execution is not inferred from ELF audits.

The native platform reports record helper-process, first-launch, artwork, layout and PIN acceptance evidence.
Real physical card PINs are not test fixture data. This pass does not type a PIN or retry a failed card attempt.
No new privileged automation wrapper, credential change, commit, push, store submission or agreement acceptance
is part of this pass. Store support/privacy URLs remain placeholders by owner instruction.

Signed macOS Store delivery requires the owner-approved use of the installed distribution private key.
The local archive attempt reached codesign and macOS requested login-keychain authorization; no password was
supplied and no security setting was relaxed. Unsigned candidate builds do not prove signed sandbox runtime
or App Store certification. The native reports below distinguish those gates from completed code, UI and process checks.

## Native policy and process checks

- Apple: four frozen-batch tests and four watcher transition tests pass. The actual standalone Debug helper
  reopened a terminated app first on a simulated reader insertion and again on simulated card insertion,
  with distinct app processes and visible windows. An isolated first launch without a forced-show argument
  also presented the window. The synthetic helper path does not construct a smart-card manager.
- Windows: nineteen focused tests cover batch scope/runner, insertion preferences and real named-pipe
  activation IPC. Native WinUI build reports zero warnings/errors. Separate helper process wake checks and
  current-source screenshots are recorded in the Windows report.
- Linux: nine policy tests pass on both Ubuntu and Fedora. They cover first-run/background state, corrupt
  or missing launch state, explicit activation, settings invariants, frozen batch identity, stop/delete on
  wrong PIN without retry, one vault-save attempt and keyed formatting. Ubuntu's installed release shows
  its first background launch, hides a later background launch and shows on explicit activation, using an
  isolated profile. The background instance also serves trusted localhost HTTPS.

Normal OS startup/background permission can still be disabled by the owner or system. The settings expose
that state; passing insertion policy tests does not bypass OS approval. Flatpak's real Background portal
permission UI, hardware insertion and biometric acceptance remain separately identified execution gates.


## Final delivered evidence

| Platform | Fresh PNGs | Focused acceptance |
|---|---:|---|
| macOS | 9 | Card/no-reader/PIN, separate helper cold starts, first launch, isolated ad-hoc Store sandbox |
| iOS | 12 | iPad and expanded Duo gutters, centered selection/CTA, PIN and document operations |
| Android | 40 | Phone and both tablet orientations; cards/no-reader/batch/PIN; final namespaced app launches |
| Windows | 10 | Centered second card, vertical reader/drop area, PIN/settings, ordinary first launch and helper wake |
| Fedora + Ubuntu | 62 | 31 per distribution; all three locales, PIN/errors/signing/results/verification and startup transitions |
| Total | 133 | Final index includes image dimensions and SHA-256 |

The dated folders and `2026-10-31-index.json` are under `~/Desktop/esemnbun-screenshots`.
Earlier 30 October captures remain before-change evidence. Linux's final saved-PIN guidance now accurately says
one confirmation for the entire batch. Every final Linux image was recaptured after that correction;
Android images identify the actual APK SHA-256 in their manifests. Windows validates actual page/window
and blank PIN state; Apple process and sandbox JSON records accompany the layout images.

Completed final checks: localization exports/source usage and Windows literal resource-ID coverage; store
metadata drift; Python and screenshot-driver syntax; macOS privacy/entitlement plist validation; diff whitespace.
Native Windows unsigned Release MSIX packaging passes and contains the independent helper startup executable.
The isolated macOS Store app is demonstrably sandboxed, with helper excluded and privacy manifest bundled;
Distribution export, production identity/keychain access, file export and loopback HTTPS are separate gates.

Platform evidence:

- [Apple validation](apple-adjustments-validation-2026-10-31.md)
- [Windows validation](windows-platform-corrections-2026-10-31.md)
- [Linux validation](linux-desktop-correction-2026-10-31.md)
- [Android validation](android-corrections-2026-10-31.md)

Tablet desktop-layout amendment: 32 tablet images now cover 600dp portrait and 1707dp landscape; 16 previous
signing images were refreshed and 16 destination images added. See android-tablet-desktop-layout-2026-10-31.md.
