# Native build and test validation — 11 November 2026

Subsequent committed-source validation passed on every hosted platform, including macOS UI:
see [commit CI validation](commit-ci-validation-2026-11-11.md). The local results below are
preserved as the earlier execution record.

The owner explicitly authorized executing builds and tests after the earlier source-only reviews.
This validates the uncommitted working tree based on `5d03deb05cfe0509744ca7b33addbf0b569f6661`;
it is not a release, a clean-HEAD CI result, or proof of complete documented journey coverage.
Local evidence is retained under `.local/validation-20261111/`, including
`final-source-manifest.json`. Linux and Windows used isolated source copies on the existing test VMs.

## Results

| Target | Build / integration | Native UI execution |
| --- | --- | --- |
| macOS | Debug app built; core 97 tests with 5 skips, MCP 21, application packages 41, CLI JSON 7 and MCP process contract passed | XCTest runner cannot initialize automation mode; no macOS UI pass claimed |
| iPhone, iOS 26.3 | Debug simulator app built with Xcode 27.1 (27A9275) | Verification and mock workflows: 11 test methods / 24 scenario paths passed; carousel 2 tests and demo-mode/share/persistence regression 1 test passed |
| iPad, iOS 26.3 | Same simulator build | Both verification and mock workflow suites passed: 11 methods / 24 scenario paths |
| Android emulator | Debug application and instrumentation APKs, Release APK and release vital lint passed; core 137 tests with 1 skip, USB transport 42, application 11, zero failures | All 28 journey completions passed twice after the driver fix (20 UI paths plus 8 workflow integration cases); protection crypto/storage and two-process persistence checks passed |
| Linux, Fedora 44 aarch64 | Native GTK app and CLI/MCP built; core 77 with 7 skips, MCP 21, application 31 with no skips, CLI JSON 7 and MCP process checks passed | Final complete 20-scenario GTK UI batch passed |
| Windows 11 ARM64, x64 app | WinUI Debug build: zero errors/warnings; .NET integration 254 passed, no skips | Four verification and eight mock workflow cases passed in the interactive desktop session |

Apple UI fixtures used English and isolated preferences. Linux UI ran the native GTK binary under
an isolated Xvfb X11 display on Fedora, with AT-SPI assertions and native keyboard input for disclosure
rows. This does not establish GNOME shell/Wayland integration. Windows tests ran in the logged-in
console session through a task-owned scheduled task, removed after completion. No physical-card credential was used.

The macOS build used disabled Xcode signing followed by a verified ad-hoc signature with smartcard
and debugging entitlements for isolated mock execution. Distribution signing and iCloud entitlements
were not validated. iOS was built for the simulator, not archived for device distribution. Windows
and Linux were native Debug builds; no installer or store submission was performed.

## Fixes discovered by execution

- Corrected shared Swift bridge calls left pointing at methods moved to `BridgeWireFormat`.
- Enabled Android BuildConfig generation and removed an orphan annotation from the extracted browser
  screen, resolving compilation failures.
- Guarded Android startup navigation until NavHost installs its graph. The earlier effect could
  navigate before `setGraph`, crashing the scenario activity. Shortcut navigation also re-evaluates
  when the graph becomes ready.
- Made the Android sign automation identifier available in compact and wide layouts; reused the
  existing sign-action component. Updated the native driver to traverse Compose accessibility nodes,
  re-query after rejected clicks during node replacement, and wait for the format menu to close before
  asserting the selected format. Instrumentation failures now retain their stack traces.
- Added an explicit Apple history-clear cancel action and handled native popover dismissal in tests.
- Updated the older iPhone demo regression to scroll the settings form and expand the document stack;
  it now validates sharing, relaunch persistence and return to live mode successfully.
- Prevented the macOS test preflight from mistaking an iOS simulator process for the desktop app.
- Fixed a Windows test-runner Base64 environment serialization call.
- Fixed Linux menu activation, avoided ancestor window actions, disabled stale AT-SPI caching in the
  polling driver, and waited for format rendering before reopening a replaced menu. GTK disclosure
  tests use the keyboard focus chain on X11; focused retries are selectable with `--scenario`.

## Evidence and exclusions

Passing evidence, relative to `.local/validation-20261111/`:

- `apple-integration-r2/`, `mac-build-r3.log`, `ios-build-r2.log`.
- `iphone-ui-r2/VerificationJourneyUITests/GestureProof.xcresult`,
  `iphone-workflows-r3/GestureProof.xcresult`, `iphone-carousel/GestureProof.xcresult`,
  `iphone-demo-r3/GestureProof.xcresult` and `ipad-ui/` (both result bundles).
- `android-final-build.log`, `android-test-runner-r4.log`, `android-ui-final-r3/journeys.log`,
  `android-ui-repeat/journeys.log`,
  `android-protection.log`, `android-persistence-prepare.log`, `android-persistence-verify.log`.
- `linux/results/`, `linux/app-tests-r2.log`, `linux/ui-results-final/results.json`.
- `windows/app-build.log`, `windows/results/integration.trx`,
  `windows/ui-verification-journeys-r2/results.json`, `windows/ui-mock-workflows-r2/results.json`.

Swift skips are three opt-in live PKI checks and two absent vendor XML debug references on macOS;
Linux additionally lacks two `re/sig1.der` vendor-reference checks. Android has one opt-in live timestamp-authority
case. These are excluded, not passes. The earlier Linux bridge-port test skip was resolved by closing
the old test app and rerunning all 31 application tests, which passed without skips.

macOS failed before the first test with **Timed out while enabling automation mode** on both installed
Xcode versions, including when launched from Terminal. The owner authorized temporary security-setting
changes. The Terminal Developer Tools toggle briefly displayed on, but a subsequent inspection found
an unresolved System Settings authentication sheet; that display did not prove the permission was
applied. `mac-ui-r5.log` records another initialization timeout without a confirmed grant.

The installed `/usr/bin/automationmodetool` reports Automation Mode disabled and authentication
required. Its man page documents an administrator-authorized unattended-testing setting; both
noninteractive and interactive sudo attempts required a local administrator password. The owner is
away from the machine, so the Terminal password prompt and System Settings authentication sheet were
cancelled. System Settings now confirms Terminal Developer Tools is off, its original state; automation
mode remains disabled with authentication required. No security change remains pending or enabled,
and no password was accessed or stored. macOS UI execution remains blocked until local administrator
authentication is available. Evidence: `mac-ui-r5/VerificationJourneyUITests/Journeys.xcresult`,
`mac-ui-r5.log`, and `testmanager.log`.

The strict journey-coverage gate intentionally remains incomplete for all 50 documented/supplemental
journeys: this batch establishes the listed service-driven paths, not every OS/hardware acceptance
criterion. Existing seeded `DocumentsUITests`, the full screenshot-review matrix, unrelated desktop
lifecycle suites, real USB/PCSC, biometrics, installers, drag/drop/providers, portal transport and
Shortcuts/Spotlight/Handoff are not newly validated by this batch. Earlier failed attempts remain
in the local evidence folder; only the final passing paths above are used as passing evidence.
