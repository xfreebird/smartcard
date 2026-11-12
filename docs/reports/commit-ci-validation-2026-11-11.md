# Commit CI validation — 11 November 2026

[CI run 43088408745](https://github.com/xfreebird/smartcard/actions/runs/43088408745)
validates pushed source commit `b61890f577eb8a0b298b377859a83b14ef54a23f`.
Seven jobs passed. The iOS native test and evidence-upload steps failed. The job/log APIs subsequently returned repeated HTTP 502 errors with inconsistent run status. The assertions were later recovered: Files navigation failed in protection and detached-original selection. This revision is not reported as green.

The follow-up [run 43098447037](https://github.com/xfreebird/smartcard/actions/runs/43098447037) at `0a706bc26389bebf091ecbb6ea0ee2012cfcac87` passed macOS, Android, Linux and shared validation. Windows failed a native scroll-visibility assertion, and iOS failed four Files methods across phone/tablet. Their logs and result bundles were recovered. A new validation is required after the setup and synchronization fixes below.

The earlier [run 43040752719](https://github.com/xfreebird/smartcard/actions/runs/43040752719)
passed all nine jobs for `8244e5f42d3327630fa78ec4549c53e213e917c9` at 14:58 UTC.
The current run includes the subsequent lifecycle, protection, import and Files automation changes.

## Hosted results

| Platform | Required validation that passed |
| --- | --- |
| macOS | Debug app, application integration tests, 5 verification + 6 workflow UI methods, unsigned App Store variant and CLI build |
| iPhone and iPad | App/share-extension build passed; native batch failed in Files navigation; 18 methods are required per family |
| Android | Debug app and instrumentation APKs; 34 journey completions (21 UI paths and 13 workflow integration cases), plus storage and separate prepare/verify launches; JVM suites: core 137 tests with 1 opt-in skip, USB transport 21, application 11, zero failures/errors |
| Linux | Swift core, CLI and application integration tests; 21 GTK UI scenarios, including native protection under Xvfb/D-Bus; packages |
| Windows | 257 integration tests, zero skips; WinUI build; 4 verification + 8 workflow UI cases, first launch, isolated demo persistence, card scrolling and synthetic reader helper; CLI, MSI and MSIX packaging |
| Shared | Swift Apple and portable backends, localization exports, CI routing/result contracts, publisher guards and journey traceability |

Completed native mock UI suites had no skipped or failed scenarios. Counts are suite-specific:
an XCTest method can exercise multiple paths and is not equivalent to one documented journey.
Downloaded Android, Linux and Windows result artifacts and completed platform logs are retained
locally in `.local/validation-20261111/ci-43088408745/` and the adjacent `*-ci-43088408745.log` files.
GitHub test artifacts have seven-day retention.

## Commit and publishing behavior

- Main-branch pushes and pull requests run validation for affected platforms. Every selected
  native platform job includes its mock UI suite and is required by `CI result`.
- Documentation-only changes run routing and contract checks without rebuilding native apps.
  Manual CI dispatch selects all platforms.
- Validation has read-only repository permissions and no distribution secrets. Test failures
  propagate to the aggregate; test evidence is uploaded on failure as well as success.
- The signed Android builder is manual-only. Branch commits do not reserve Android version codes
  or trigger release/store publishing. Release remains an explicit manual operation or `v*` tag push.
- The source commit triggered only the `CI` workflow; the manual full validation superseded its affected-platform run. No release or store workflow was dispatched.
  Existing documentation deployment behavior is unchanged.

## Fixes established by hosted execution

The final run incorporates native Apple menu/toolbar discovery, macOS click handling, Windows
UI process isolation, deterministic completion gates in Windows bridge/MCP tests, and Linux
dialog-state synchronization. Android now bounds build-process resources, checks emulator
accessibility readiness before installing the app, and tests first-launch disclosure acceptance
and retention explicitly. Its readiness gate permits one initial framework/System UI recovery before app
installation, bounds accessibility connection failures, rejects recurrence or application errors,
and never retries application scenarios.
Linux dependency setup uses explicit container DNS and fails on incomplete package indexes.
The native protection fixture uses tmpfs because production removal refuses unknown filesystems.

Files automation now resolves native controls from a single public XCTest snapshot, with a named
subtree fallback for incomplete iPad snapshots. It verifies dismissal, output bytes, private permissions
and persistence. Protection and three Documents methods pass locally on iPhone Duo/iOS 27.1 and on
iPad/iOS 26.5 and 27.0. Task-owned simulators are used for the follow-up; unrelated devices are preserved.

## 12 November follow-up

The iOS batch installs once before fixture seeding and keeps the same data container across its suites. Nested runners no longer reinstall after seeding. Picker presentation has a bounded 30-second wait, and app taps require enabled, stable, hittable controls. Updated protection passes on iPad/iOS 27.0 with byte and permission postchecks. The preceding complete local iPhone/iOS 27.1 batch passed all 18 methods. Updated Documents and hosted execution remain pending.

Windows waits for native keyboard focus before Home/End and for both scroll percentage and visible control geometry before asserting completion. The updated runner passes all four theme/window-size combinations on Windows 11 ARM64. All 43 CI-helper tests and shell syntax checks pass.

## Coverage limits

This establishes the implemented mock UI and integration suites on all supported native platforms.
It does not establish complete acceptance coverage: the catalog's 47 documented journeys plus
3 protection scenarios still have partial status. Physical USB/PCSC behavior, real-card signing,
biometrics, live portal/PKI behavior, installer interaction, third-party document-provider combinations, drag and drop,
and integrations such as Shortcuts, Spotlight and Handoff retain separate acceptance work.
Opt-in external-service tests remain skipped where their prerequisites are absent.

No real-card PIN, distribution signing or store submission was used. Hosted macOS UI passed;
the earlier local macOS automation authorization limitation remains a local limitation, with
no security setting change left active. The earlier local validation record remains in
[native-test-validation-2026-11-11.md](native-test-validation-2026-11-11.md).
