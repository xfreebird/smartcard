# Commit CI validation — 11 November 2026

[CI run 43040752719](https://github.com/xfreebird/smartcard/actions/runs/43040752719)
passed all nine jobs for pushed source commit
`8244e5f42d3327630fa78ec4549c53e213e917c9`. No platform job was skipped.
The aggregate `CI result` completed successfully at 14:58 UTC.

## Hosted results

| Platform | Required validation that passed |
| --- | --- |
| macOS | Debug app, application integration tests, 5 verification + 6 workflow UI methods, unsigned App Store variant and CLI build |
| iPhone and iPad | Simulator build; each device family passed 5 verification + 6 workflow UI methods |
| Android | Debug app and instrumentation APKs; 29 journey completions (21 UI paths and 8 workflow integration cases); JVM suites: core 137 tests with 1 opt-in skip, USB transport 21, application 11, zero failures/errors |
| Linux | Swift core, CLI and application integration tests; 20 GTK UI scenarios under Xvfb/D-Bus; packages |
| Windows | 254 integration tests, zero skips; WinUI build; 4 verification + 8 workflow UI cases; CLI, MSI and MSIX packaging |
| Shared | Swift Apple and portable backends, localization exports, CI routing/result contracts, publisher guards and journey traceability |

The native mock UI suites had no skipped or failed scenarios. Counts are suite-specific:
an XCTest method can exercise multiple paths and is not equivalent to one documented journey.
Downloaded Android, Linux and Windows result artifacts and completed platform logs are retained
locally in `.local/validation-20261111/ci-final-evidence/` and the adjacent `*-ci-final.log` files.
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
- The source commit triggered only the `CI` workflow. No release or store workflow was dispatched.
  Existing documentation deployment behavior is unchanged.

## Fixes established by hosted execution

The final run incorporates native Apple menu/toolbar discovery, macOS click handling, Windows
UI process isolation, deterministic completion gates in Windows bridge/MCP tests, and Linux
dialog-state synchronization. Android now bounds build-process resources, checks emulator
accessibility readiness before installing the app, and tests first-launch disclosure acceptance
and retention explicitly. Its readiness gate permits one initial System UI recovery before app
installation, rejects recurrence or other app errors, and never retries application scenarios.
Linux dependency setup uses explicit container DNS and fails on incomplete package indexes.

## Coverage limits

This establishes the implemented mock UI and integration suites on all supported native platforms.
It does not establish complete acceptance coverage: the catalog's 47 documented journeys plus
3 protection scenarios still have partial status. Physical USB/PCSC behavior, real-card signing,
biometrics, live portal/PKI behavior, installer interaction, OS document providers, drag and drop,
and integrations such as Shortcuts, Spotlight and Handoff retain separate acceptance work.
Opt-in external-service tests remain skipped where their prerequisites are absent.

No real-card PIN, distribution signing or store submission was used. Hosted macOS UI passed;
the earlier local macOS automation authorization limitation remains a local limitation, with
no security setting change left active. The earlier local validation record remains in
[native-test-validation-2026-11-11.md](native-test-validation-2026-11-11.md).
