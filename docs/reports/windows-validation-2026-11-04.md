# Windows follow-up validation — 4 November 2026

The Windows changes implement Sign/Verify taskbar actions and recent signed documents, both Explorer verbs, immediate language changes, signed-output links, a centered Verify drop zone, more compact centered cards, improved About content and additional spacing below the card expiry date.

Additional findings fixed during validation:

- Sign uses one page scroll area, keeping its file list and controls reachable in short windows.
- Initial window dimensions and minimum size fit the display work area.
- Switching General/About resets the shared scroll position.
- The tray flyout can scroll to its bottom actions on short displays.
- The selected-card caption uses the full bottom edge so the Russian translation fits compact cards.
- Verification-result cards and their icons use dynamic theme resources.

## Build and automated evidence

Validation ran on the owner's UTM Windows 11 ARM64 VM, `WIN-V0N3TNSH01F`, with .NET SDK 10.0.403 x64 and the x64 app under emulation.

| Check | Result |
| --- | --- |
| Core/Desktop test suite | 199 passed, zero failed/skipped; no Core/Desktop implementation changed after this run |
| Final WinUI self-contained Debug publish | Passed; `C:\esb-validation\app-final2026` |
| Native Explorer DLL compilation | Passed, x64 |
| Final MSI build | Passed, zero warnings/errors; `C:\esb-validation\installer-final2026` |
| Final unsigned MSIX build | Passed; optional `mspdbcmf.exe` symbol-package warning only |
| Native taskbar API smoke check | Windows accepted Sign/Verify tasks and a recent document; path history persisted |
| Explorer command COM factory checks | Both Sign and Verify returned S_OK for title, enabled state and invocation |
| Localization export consistency/completeness | Passed for Windows RO/EN/RU |
| Diff whitespace | Passed |

The Explorer checks loaded the built DLL directly through its COM factory, rather than installing shell registrations. They then invoked the real app executable and forwarded a mock document to the existing instance. Sign queued the file and Verify visibly displayed its mock verification result.

## Interactive evidence

Observed in the running validation app:

- Both centered card selections and hover arrows outside the card.
- Signed PDF/XML outputs listed on Sign, with Explorer reveal working; the second card remained selected after the batch.
- Centered full-width Verify area.
- English to Russian switching in the same process, retaining Settings and the selected card.
- Immediate dark appearance, including the final verification-result card.
- Centered high-resolution About icon, version, author and website; the final About title is visible after switching from scrolled General content.
- Native standalone taskbar Sign/Verify entries.

The final tray check confirms the full Russian selected-card caption fits below the expiry date. Scrolling the flyout exposes the browser toggle, Open and Quit actions without cutoff.

## Limits and retained artifacts

The original Store installation was not replaced. The standalone validation MSI is now installed alongside it. Installation of the separate unsigned validation MSIX was rejected with `0x80073CFF`: the VM does not enable developer/sideloading policy. No system policy or certificate trust was changed. Packaged jump-list runtime behavior and MSIX modern Explorer-menu registration still need validation with an installable signed package or an appropriately configured test guest. The current-source MSI was subsequently installed successfully with STARTATLOGIN=0. Both commands visibly appear under Show more options, and clicking Sign launches the installed Program Files executable with the selected mock PDF queued. Registry inspection confirms both installed command paths.

These checks used mock services and fictional files. They do not establish fresh physical-card signing or native ARM64 binary coverage.

Build logs, the TRX and screenshots are saved on the main Mac at `~/Desktop/esemnbun-screenshots/windows/2026-11-04/validation/`. The VM retains the final application and both package outputs. The Desktop MSI is a Debug validation installer, not a Store submission.
