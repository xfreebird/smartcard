# Cross-platform journey and integration tests

The native suites exercise application interactions against explicit Debug demo services. Core and
workflow suites exercise real policy, persistence and cryptography using synthetic inputs or simulated
cards. A fixture verdict is **not** evidence of a valid cryptographic signature or physical reader support.

Current hosted results are recorded in [commit CI validation](../reports/commit-ci-validation-2026-11-11.md);
the earlier local batch remains in [the validation report](../reports/native-test-validation-2026-11-11.md). The commands below are
repeatable entry points; source checks alone do not establish compilation or runtime behavior.

## Commit validation

`CI` runs the affected platforms on main pushes and pull requests, and every platform on manual dispatch.
Native platform jobs include the mock UI suites listed below, with iPhone and iPad targets for iOS.
CI selects both families within the active SDK's major/minor release line and retains the selection
inventory. Newer runtime compatibility checks use explicitly chosen simulator IDs.
A missing runner prerequisite or failed/incomplete suite fails `CI result`. Logs and XCTest result
bundles are uploaded on failure as well as success. Signed builds and Store uploads are separate
manual workflows; ordinary branch pushes do not publish app versions or reserve version codes.
See [the workflow guide](../14-github-actions.md) for selection and publishing boundaries.

## Run the integration batches

From the repository root, use a fresh output directory for each command:

```sh
bash scripts/run-integration-tests.sh apple .local/tests/apple-integration
bash scripts/run-integration-tests.sh android .local/tests/android-integration
# In a Linux host with the native dependencies documented in linux/README.md:
bash scripts/run-integration-tests.sh linux .local/tests/linux-integration
```

On Windows, from PowerShell:

```powershell
./windows/scripts/test-integration.ps1 -Output .local/tests/windows-integration
```

The Swift batches run core and application tests, then build and exercise the CLI JSON and MCP stdio
contracts. Live PKI tests stay opt-in (`MSIGN_NETWORK_TESTS=0`). Apple includes cancellation and replacement
of verification work, request lifetime, batch policy and document-store switching. The portable core
route remains available through `scripts/test-portable-macos.sh`; it does not replace GNOME UI tests.
Android includes core, CCID/T=1, application unit tests and both instrumentation APK builds. Windows
includes Core/Desktop workflows, CLI/MCP and bridge integration, with TRX output. Native WinUI and
both Apple app targets must also be built with the repository build instructions.

## Run native UI automation

Use fresh output directories and the newly built **Debug** applications. Keep physical readers out of
these fixture sessions. macOS and Windows runners require an interactive, unlocked native desktop;
SSH alone is not a UI session. Linux supports an isolated Xvfb display. Discover device IDs instead
of copying another developer's inventory.

```sh
# Dedicated, already booted iPhone simulator; repeat on iPad and supported wide devices.
bash apple/scripts/run-mock-ui-tests.sh ios /absolute/eSemnBun.app SIMULATOR_UUID .local/tests/iphone
# Close the working desktop app first; target is registered by its bundle identifier.
bash apple/scripts/run-mock-ui-tests.sh macos /absolute/eSemnBun.app mac .local/tests/macos

# Dedicated emulator; runner requires every scenario completion, not just adb's exit status.
bash android/scripts/test-journeys.sh emulator-5554 \
  android/app/build/outputs/apk/debug/app-debug.apk \
  android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk .local/tests/android-ui

# Native Linux GTK app: python3-pyatspi, xdotool and Xvfb required.
# Use the logged-in test user's D-Bus session; Xvfb isolates keyboard input from the desktop.
GDK_BACKEND=x11 xvfb-run -a -s "-screen 0 1440x1080x24" \
  python3 linux/scripts/test-ui-journeys.py /absolute/esemnbun-gnome .local/tests/linux-ui
```

```powershell
./windows/scripts/test-verification-journeys.ps1 -App C:/absolute/eSemnBun.exe -Output .local/tests/windows-verification
./windows/scripts/test-mock-workflows.ps1 -App C:/absolute/eSemnBun.exe -Output .local/tests/windows-workflows
```

### macOS XCTest automation authorization

If the runner times out **before the first test**, inspect `/usr/bin/automationmodetool` and the
macOS test-manager logs before changing application code. Terminal's Developer Tools permission is
separate from XCTest Automation Mode authorization. A locally authenticated administrator may use
Apple's supported `sudo /usr/bin/automationmodetool enable-automationmode-without-authentication`
for an authorized unattended test session, then restore the original requirement with
`sudo /usr/bin/automationmodetool disable-automationmode-without-authentication`.
Record the initial state and restore it after testing; these runners never change security settings.
See the installed `man automationmodetool` and [Apple's documented support guidance](https://developer.apple.com/forums/thread/693850).
Never put an administrator password in a script, test artifact or chat.

The mock suites press native controls and assert the resulting state. The signer is replaced through
`DocumentSigning` (Apple/Linux), `SigningService` (Android), or `IDocumentSigner` (Windows). Live and mock
signing use the same platform batch runner. Scenario selection belongs to Debug composition; sample
outputs are explicitly unsigned and no physical reader, network signing service or stored PIN is used.

| Platform | Authored scenarios | Native interactions |
| --- | --- | --- |
| macOS / iOS | 24 scenario paths across two XCTest suites | Six verification verdicts and clear, loading clear, certificate/technical disclosure, five reader states, two PIN cancellations; signing success/mixed/fatal, queue removal, format change, stamp cancellation, history cancel/clear preserving the library, single/batch website refusal |
| Android | 34 completions: 21 UI paths and 13 integration cases, plus three storage/persistence launches | First-launch disclosure acceptance and activity relaunch; six verdict/clear flows, four reader states, result hiding, signing success/mixed/fatal with stored-output assertions, format/removal, stamp cancellation, history cancel/clear, two PIN cancellations, certificate/technical disclosures; demo-storage integration, seven batch policy cases, four protection workflow cases and duplicate import handling |
| Linux | 21 scenarios | Existing 13 fixtures (including clear, PIN cancel and signed-detail disclosures), plus signing success/mixed/fatal, removal, format change, stamp cancellation and history cancel/clear with unchanged output bytes; native protection picker/save cancellation, mismatch rejection, encrypt/decrypt byte round trip, private permissions and confirmed removal |
| Windows | 12 scenarios across two runners | Four choose/verify/clear flows with signed-detail disclosures; signing success/mixed/fatal, removal, format change, stamp cancellation, history cancel/clear preserving saved names, and empty-PIN cancellation |

Apple launches use independent preferences and disable hardware. Android uses a dedicated emulator,
restores the demo preference and replaces its service graph between mock cases; fictional outputs may
remain on that emulator. Linux uses temporary XDG and fixture directories and matches the readiness
token and process ID. Windows uses separate preferences for each case and controls only its own app
process. These runners fail on missing controls, unexpected outcomes or absent completion evidence.
See the validation report for executed targets, skips and outstanding prerequisites. Existing
noninteractive Linux fixtures remain presentation checks; the table does not turn them into
end-to-end signing tests. Linux accepts repeated `--scenario NAME` arguments for focused retries;
omitting them runs all 21 cases. Its GTK disclosure fallback uses native X11 keyboard input because
GTK exposes expansion state without an AT-SPI activation action. An isolated Xvfb display avoids
Wayland input-portal restrictions; this validates GTK controls, not GNOME shell integration.
The isolated runner sets `GDK_DEBUG=no-portals` so file dialogs stay inside its Xvfb session;
[GTK documents this portal override](https://docs.gtk.org/gtk4/func.disable_portals.html).
The protection fixture opens the real dialog, then uses native controls and the production processor.
File and save selections remain inside the temporary fixture directory. The removal fixture uses
`/dev/shm` (tmpfs), matching the core tests; production removal deliberately refuses unknown filesystems
such as a container overlay. The packaged app retains normal portal behavior.

Additional suites required by commit CI include iOS `CardCarouselUITests`, `DemoModeUITests`, `ProtectionFlowUITests` and seeded `DocumentsUITests` on both phone and tablet; Android crypto/storage and separate `prepare`/`verify` processes; and Windows first-launch, demo-mode, card-scroll and synthetic reader-helper scripts. The protection suite drives the native Files picker and checks restored bytes and private permissions. The Documents runner generates a genuine detached signature using the simulated card, seeds isolated legacy history, and checks migration, history clear/relaunch and original-file selection. Screenshot presentation suites retain their own prerequisites below.

Existing UI suites remain part of the review:

- iOS `DocumentsUITests`, `CardCarouselUITests`, `DemoModeUITests` and `ScreenshotReviewUITests` run through
  `apple/scripts/run-carousel-ui-tests.sh` with `MSIGN_UI_TEST_SOURCE` set to one suite. Read each suite's
  fixture prerequisites first. Screenshot capture checks are labelled presentation, not end-to-end signing.
- Windows `test-first-launch.ps1`, `test-demo-mode.ps1`, `test-card-page-scroll.ps1` and
  `test-insertion-helper.ps1` cover native launch, demo transitions, input scrolling and helper behavior.
- Android `FileProtectionInstrumentation` retains its default crypto/storage suite and two-process
  `phase=prepare` / `phase=verify` persistence checks. The new `suite=journeys` is independent.
- Apple reader transition scripts and Android demo-mode scripts remain available for their documented
  dedicated-device checks.

Retain xcresult, TRX, instrumentation logs and JSON outcomes. An absent artifact or skipped prerequisite
is not a pass. Record the source revision **and local modifications**, binary hash, device/OS, locale,
theme and command with each execution. Repeat on EN/RO/RU, light/dark and compact/wide form factors for
visual review; new native journey assertions deliberately use stable English fixtures.

## Traceability and completeness

[`tests/journeys/catalog.json`](../../tests/journeys/catalog.json) maps every G/M/A/D/L/C journey from the
[user-guide inventory](../user-guide/journey-inventory.md), plus the current password-protection/removal
journeys P01–P03. Each row includes applicable platforms, test-suite paths, acceptance criteria, edge
cases and the remaining native runtime check. The `mock_scenarios` section maps eight shared scenario
groups to the five native targets, plus the iOS/Linux password round trip, and records their actual assertions. The coverage classification is conservative: a unit test
or screenshot cannot stand in for the whole user journey.

```sh
python3 scripts/check-journey-coverage.py
# Deliberately fails while any required journey has partial or manual coverage:
python3 scripts/check-journey-coverage.py --require-full-automation
```

The checker validates traceability and source paths only. It does not execute or certify tests. Full
UI automation coverage is **not yet established**. Real USB/PCSC access, OS credential dialogs, signed
installers, actual drag/drop/providers, system sharing, Shortcuts, Spotlight, Handoff, desktop autostart
and live portal integration still need their catalogued runtime checks. Do not report these as covered
by demo fixtures. No PIN guessing, real wrong-PIN attempt, credential capture or publishing belongs in
the automated baseline.

The iOS batch additionally runs `ProtectionFlowUITests` using the real Files picker and a synthetic PDF, with post-run plaintext and file-permission checks. Android adds four injected protection workflow cases and requires separate-process storage persistence. The legacy vendor CBC envelope cannot authenticate passwords or content; tests must not assert that every wrong password necessarily fails padding.
