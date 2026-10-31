# Windows platform corrections — 2026-10-31

## Revision 2 — compact cards and accessible Card-page controls

Card faces are capped at 320px on Card and 280px on Sign/tray. The carousel keeps its selected face centered with bounded neighbor previews; narrow trays retain full-card paging. Sign keeps its vertical reader/card then document-drop layout.

Card uses an explicit vertical ScrollViewer. Wheel input over the nested horizontal carousel now routes to the outer page before native horizontal scrolling can change selection. Home/End and Page Up/Down use the same vertical page, including events already handled by WinUI. No controls were removed or hidden. Empty-placeholder icon, message and dotted stroke now resolve their foreground from the element’s `ActualTheme` on load and theme changes, so the dark-theme placeholder retains readable contrast.

Native revision-2 verification passed all four light/dark × 1100 × 720 / 900 × 580 combinations. Real mouse-wheel input over the selected card and Ctrl+End each reached 100% vertical scroll. UI Automation checked that the saved-PIN action and final help text were fully inside the viewport. The selected second card remained full and centered after resizing. The test first uses Ctrl+Home to return to the top; it never activates PIN controls. Debug built with 0 warnings and 0 errors.

Fresh evidence: `~/Desktop/esemnbun-screenshots/windows/2026-10-31/revision2/` contains 10 PNGs (Card top/bottom at both heights in both themes, plus no-reader Sign in both themes), `card-scroll-proof.json`, readiness sidecars and `capture-audit.json`. The 580px dark top/bottom and Sign layout were visually inspected. Reproduce with `windows/scripts/test-card-page-scroll.ps1`. No physical card or PIN was used.

The final revision-2 unsigned Release MSIX rebuilt with 0 errors and the existing optional `mspdbcmf.exe` symbols warning. Retained package: `dist/windows/validation-2026-10-31/revision2/eSemnBun-0.2.0-x64-unsigned.msix`; SHA-256 `ea08b192555a6e1f945cbb6d6ffaa0264462a242c141850197cb43bed0c35539`. Signed installation/Store validation remain separate gates.

The temporary capture task was restored after the final successful native run, and Windows was shut down to restore its initial stopped state. Native keyboard verification uses explicit foreground/focus plus key down/up events, avoiding timing-sensitive SendKeys dispatch.

The earlier evidence later in this report is retained as history; it does not prove the corrected lower controls were accessible.

## Earlier platform work

The signing page keeps a single vertical reading order: a centered card/reader placeholder, then the document drop area. The empty reader has only its dotted rectangle; the duplicate informational surround was removed. Compact artwork and the drop-area height fit the ordinary 1100 × 720 window. The Card page uses a wider viewport with a fully centered selected face and substantial, scaled/faded neighbor peeks instead of thin strips. Narrow tray windows page full cards without sliced previews.

Artwork keeps the golden-ratio card and 3:5 portrait frame. The human silhouette uses a circular head and short curved shoulder dome with a flat base, independent of frame height. Chip contacts are explicitly eight regions: three left, three right, two central. PIN content is wider and its larger input is centered.

## Independent insertion utility

`MoldSign.Watcher` builds `eSemnBun.Watcher.exe`, a separate process with no WinUI, signing service, consent dialog or credential-vault dependency. It observes reader presence without connecting to a card or sending APDUs. Independent reader/card options are persisted in the shared non-secret preferences. Starting the helper establishes a baseline; later insertion edges, card replacement counters and muted-card presence can open the app. Disabling both options stops the helper.

For unpackaged/MSI installations the app configures the helper in the current user's Run key and starts it immediately. It survives closing or quitting the UI. The app itself uses a current-user/session activation broker so another launch opens its main window rather than creating another signing instance. Ordinary launches always show the main window; login launches stay in the tray after first-run completion.

The MSIX manifest declares a separate helper startup executable and retains `runFullTrust`; packaging publishes and includes that helper. Windows permits multiple startup-task executables for packaged desktop apps. Startup permission, user-disabled tasks and policy restrictions remain under Windows control. This is a supported full-trust desktop implementation, not a claim that Store certification or user permission can be bypassed. Reference: [Microsoft StartupTask documentation](https://learn.microsoft.com/en-us/uwp/api/windows.applicationmodel.startuptask).

## Responsibility and injection audit

| Responsibility | Module/boundary | Evidence |
|---|---|---|
| Reader/card insertion decisions | `MoldSign.Desktop/InsertionActivationPolicy` | Reader, card, swap, mute and disabled-option tests |
| Independent utility loop | `InsertionWatcher`, `IReaderSnapshotSource`, `IApplicationActivator` | Real helper process driven by injected snapshots |
| Non-secret preferences | `DesktopPreferenceStore` | Atomic round trip; reader handles permit atomic replacement |
| Existing-instance activation | `DesktopActivationBroker` | Real Windows current-user named-pipe activation test; only `open` messages accepted |
| Frozen batch sequencing, duplicate starts, lifetime | `Core/DocumentBatchSigner` | Independent tests for snapshots, identities, cancellation and first failure |
| Signing vs. verification | `IDocumentSigner` / `IDocumentVerifier` | Batch signer fake implements no unused verification method |
| Credential access | `IPinVault` | OS implementation remains behind the interface |
| Browser lifecycle and identity import | `IBrowserConnectionController` | Extracted from app services; mock lifecycle injectable |
| App composition | `AppServiceDependencies` | Reader, transport, certificate, signer, verifier, credential, authorization and browser substitutions |

`AppServices` now coordinates platform state and maps errors rather than owning the batch algorithm, settings storage and browser lifecycle. `FileRow` is a separate presentation model. Preview activity cannot write the real user's activity log. This is concrete modularization, not a wholesale SOLID certification: views still use `App.Current`, and `AppState.Current` remains a shared UI-state singleton.

## Localization audit

Windows product prose uses MRT resource IDs. Card legends/field labels, XAdES packaging choices, file-size units and the System language option no longer introduce unlocalized C# or unbound XAML prose. The central Romanian/English/Russian catalog owns translations. Product names, language endonyms, device/certificate data, paths, protocol formats and diagnostic text are intentional non-prose values; the printed bilingual card legends retain the shared cross-platform design.

## Validation

- Focused Windows run: **19 passed, 0 failed** — scoped batch consent, batch orchestration, insertion/preferences, muted-card wake and real Windows activation IPC.
- Native Debug app build: **0 warnings, 0 errors**. Independent helper publish succeeded.
- Native ordinary first and subsequent launch: isolated fresh preferences, no demo or force-show flags; both main windows became visible and rendered Sign.
- Independent process proof: the same helper opened a closed mock app on reader insertion, opened it again on card insertion after the first app exited, and stopped after both options were disabled. The test now waits for the helper's initial-baseline handshake before injecting an edge.
- Unsigned native Release MSIX build: **0 errors**, one optional symbols-tool warning (`mspdbcmf.exe` absent). Package inspection confirmed `helper/eSemnBun.Watcher.exe` and the independent `MoldSignInsertionHelper` startup executable in the built manifest.
- Final targeted image audit: **10 PNGs**, with selected-second Card, no-reader Sign, Settings and PIN in light/dark, plus ordinary first launch and helper launch. JSON process/window proof accompanies the images.
- No physical card or PIN was used. Reader/card events in the helper process test come from an injected snapshot source; the ordinary-launch test requires no attached smart-card reader.
- Full MSI/NativeAOT release, signed MSIX installation, Windows startup permission UX, login/reboot activation and Store certification are distinct validation gates; they are not inferred from Debug UI captures.

Final artifacts: `~/Desktop/esemnbun-screenshots/windows/2026-10-31/` (selected-second Card, no-reader Sign, Settings, PIN, ordinary first launch and helper launch, plus JSON proof files).

Retained unsigned validation package (git-ignored, local only):
`dist/windows/validation-2026-10-31/eSemnBun-0.2.0-x64-unsigned.msix`.
SHA-256: `e2a180151b26a8df4a06edf475dfc4ac0cdce95d4abd63815def44a5e76a6b5f`.
Its ZIP contents and built manifest were independently inspected for the helper executable/startup declaration.
The temporary interactive task was restored; no test helper/app process remained. Windows was shut down afterward,
and the Air no longer had a Windows QEMU process, restoring its initially stopped state.
