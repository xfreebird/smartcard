# Windows guide refresh — 2026-11-08

The English, Romanian and Russian Windows desktop guides now cover General settings, browser stamp options and the local MCP approval switch with its private directory. MCP setup uses the installed CLI executable and a narrow document root. Existing unrelated screenshots retain their earlier evidence records.

Native captures use an isolated Debug win-x64 self-contained build on the Windows 11 ARM64 VM, fictional cards/documents and a separate preference file. The demo banner is suppressed only through the guarded screenshot mode. The broker remains disabled; no card, PIN, saved secret or signing request is used. Settings screenshots intentionally show the unavailable MCP toggle in demo mode. The example directory is not an instruction to use the capture profile.

The refresh exposed an unpackaged Windows regression: opening the PDF stamp editor called the OS `Windows.Globalization.ApplicationLanguages.PrimaryLanguageOverride` getter, which raised `InvalidOperationException` (`0x80073D54`) before the editor appeared. The editor now uses `Microsoft.Windows.Globalization.ApplicationLanguages`, matching the Windows App SDK API used during app startup. Capture automation now waits for the localized native editor window and rejects an accidental screenshot of the signing queue.

The capture script supports `-RootPath` for a dedicated stage and `-RefreshOnly` for stamp/settings/About panels. It clears stale completion markers and replaces same-name manifest entries on a rerun.

MCP PDF review and subsequent card authorization are documented from the current application flow. A native MCP approval request was not executed: the demo guard intentionally prevents the broker from handling requests, and this documentation pass does not bypass that guard. Store/MSI installation, physical signing, Windows Hello and PIN access remain outside this evidence.

Validation: the Windows App SDK namespace correction compiled successfully in the native Debug self-contained win-x64 publish on the Windows VM. The original unpackaged locale exception no longer appeared during the subsequent editor-opening attempt. No unit or portable suites were run for this documentation refresh.

Final result: 12 refreshed PNGs (stamp editor, upper/lower General settings and About in each locale) passed native capture and visual inspection. Stamp callouts cover dragging/resizing, page or queue scope, and Apply. `windows-evidence.json` records each image hash, binary hash, native window title and capture process/readiness metadata. The capture process waits on the foreground native window because Windows UI Automation omits owned editor windows from its root child list. The isolated capture scheduled task was removed after completion. Source/asset checks and guide-panel JSON/path checks passed.

## CI follow-up: Windows atomic publication

CI exposed two native Windows issues in MCP publication. Directory handles shared only reads, so `File.Move` hit a sharing violation while publishing child files. Directory handles now also share writes, while continuing to omit delete sharing so the trusted directory components cannot be renamed or replaced. File handles keep their read-only sharing policy; ACL checks and atomic no-replace/explicit-replace behavior are unchanged.

The next native run exposed elevated-token default ownership: newly created responses belonged to Administrators, so the strict current-user ownership check rejected them. `WriteExclusive` now creates new files with an explicit current-user owner and protected owner-only ACL before writing any bytes. It does not mutate existing files or relax private reads. The publication regression asserts private readability, the exact owner and protected ACL.

Validation: on the Windows 11 ARM64 VM using the x64 .NET SDK, `dotnet test tests/MoldSign.Core.Tests --no-restore --filter FullyQualifiedName~WindowsMcp --logger console` passed all **18 tests**, with no failures/skips. This includes immutable approval inputs, bounded jobs, exclusive/explicit replacement, cancellation, private ACL rejection, junction confinement and denial of trusted-root rename. No real card or secret provider was accessed.
