# Commit CI validation — 11–12 November 2026

[Full CI 43176745714](https://github.com/xfreebird/smartcard/actions/runs/43176745714) passed every
platform job and `CI result` on pushed source `d9383ec2395b54412de958b34570ae7f4117723e`.
This includes the final deletion-boundary fixes and protection evidence retention. The earlier
[full baseline 43171823518](https://github.com/xfreebird/smartcard/actions/runs/43171823518) also passed.

## Final hosted validation

| Platform | Required validation |
| --- | --- |
| macOS | Passed: Debug app, 42 application integration cases, 5 verification + 6 workflow UI methods, unsigned App Store variant and CLI build |
| iPhone and iPad | Passed: app/share-extension build and all 18 native UI methods per family, including protection/Documents postchecks; iPhone Duo 27.1 and iPad Pro 13-inch (M5) 27.0 selected within the active SDK release line |
| Android | Passed: Debug app/instrumentation builds, 34 journey completions, storage and separate-process persistence; JVM core 137 tests with 1 opt-in skip, USB transport 21, application 14; zero failures/errors |
| Linux | Passed: Swift core, CLI and 35 application tests, 21 GTK UI scenarios including native protection, and packages |
| Windows | Passed: 257 integration tests with zero skips, WinUI build, 4 verification + 8 workflow UI cases, first launch, demo persistence/isolation, 4 scroll theme/size cases, synthetic reader-helper lifecycle, CLI/MSI/MSIX packaging |
| Shared | Passed: Swift Apple/portable backends, localization, CI routing/result contracts, publisher guards and journey traceability |

Counts are suite-specific: one XCTest method can exercise several paths and is not equivalent to one
catalog journey. Required native suite counts are enforced; a missing result, skipped method or failed
postcheck fails CI. External-service tests remain opt-in where their prerequisites are absent.

Final-source logs and downloaded UI results are retained locally under
`.local/validation-20261111/ci-43176745714/` and adjacent `*-ci-43176745714.log` files.
`verified-results.json` records checked artifact counts and hashes. Earlier baseline evidence remains
under `ci-43171823518/`. GitHub test artifacts have seven-day retention.

## Final deletion review

A copied saved entry could retain its library ID but replace its file location. Apple, Android and
Linux now require the confirmed location to match the stored entry before deletion. Android/Linux
policy lives in application workflows; Windows already compares the complete immutable record.
Regression tests preserve both files for mismatched selections and check valid deletion, foreign/duplicate
selections, missing locations, deletion failure and symlink preservation.

Local follow-up checks passed: 42 Apple application cases, 14 Android application cases and Debug
app/instrumentation builds, and the Fedora app build plus 35 application cases. Evidence and binary/source
hashes are in `.local/validation-20261111/e47b2bc-deletion-validation.json`. The Mac Linux probe lacked
Poppler headers; the Fedora execution supplies the native build/test result. A local incremental Kotlin
symbol-cache error cleared with a full compile; no source workaround was needed.

Baseline artifacts include all 12 required iOS result bundles, verified for exact counts and zero skips.
The protection postchecks passed, but the upload pattern omitted their nested JSON proof. The final
workflow retains each `roundtrip.json`. Both downloaded proofs report two outputs, unchanged source
bytes, private permissions and restored SHA-256
`9a9b6d0344b2f57eba88ed57b5fb1e45ed3cd16dc839950ab4abab2d032b0090`.
All 36 final iPhone/iPad methods passed with no skips, and both Documents postchecks passed.

## Local native checks

- iPhone Duo/iOS 27.1 and iPad mini/iOS 27.0 each passed the protection round trip and all three
  Documents methods. The result-bundle checker confirmed the expected method counts with no skips.
- Postchecks proved exact original/restored bytes, owner-only protection output permissions, migration,
  history clearing that preserves the library, relaunch persistence and detached-original selection.
- Windows 11 ARM64 passed scrolling in light/dark at both 1100×720 and 900×580, including keyboard
  focus, wheel/Home/End, selected-card centering and full visibility of the PIN action and help text.
- Android passed all 34 journeys, storage integration and both persistence launches after the final action-handling change.
- All 52 CI-helper tests, 12 publishing-guard tests, actionlint 1.7.12, shell/Ruby syntax and whitespace checks passed. The temporary Windows test task was removed. Unrelated devices and VM state were preserved.

The local evidence uses `protection-{iphone,ipad}-native-cell-v2/`, `documents-{iphone,ipad}-native-cell-v2/`,
`android-disclosure-v3/`
and `windows-card-scroll-final/` below the same validation directory. `a416d54-validation.json`
records the source revision, Apple binary hashes and file/persistence results.

## Automation fixes and follow-up

The iOS batch now installs once before fixture seeding and keeps one data container through all nested
runners. This removes repeated installation between Files-provider operations. Native Files actions use
public accessibility snapshots; a named subtree supplies attributes omitted from whole-app iPad
snapshots. Grid navigation/selection targets the thumbnail rather than the name/date metadata. Picker
presentation and control readiness are bounded waits; cancellation, dismissal and file-result assertions
remain required. Failed suites emit method/assertion diagnostics before artifact upload.

Android dispatches accessibility actions once and waits for resulting UI/domain state. The driver no longer
queues another toggle on a delayed acknowledgement. Verification uses the shared driver, and returning
to the saved library must reveal a saved document. Hosted Android run
[43170798943](https://github.com/xfreebird/smartcard/actions/runs/43170798943) passed all 34 journeys,
storage integration and separate-process persistence on the same Android source.

Windows waits for native keyboard focus before Home/End and for visible control geometry as well as
scroll percentage before asserting completion. No scenario or assertion was removed to make tests pass.

Earlier hosted failures included remote Files navigation, a stale Windows scroll assertion and test
startup prerequisites. Their fixes and intermediate evidence are recorded in `PLAN.md`. The earlier
all-green run `43040752719` predates the expanded protection/Documents suites and is not used as final
proof for this revision.

## Runtime compatibility limit

The automatic selector previously adopted iOS 27.2 even though the selected build SDK is 27.1.
The same Files driver passed all eight targeted methods on hosted iPhone 27.1 and iPad 27.0 in
[43168468861](https://github.com/xfreebird/smartcard/actions/runs/43168468861). Both coordinate and
native cell activation failed folder navigation on the newer hosted 27.2 combination in
[43165580460](https://github.com/xfreebird/smartcard/actions/runs/43165580460) and
[43168869669](https://github.com/xfreebird/smartcard/actions/runs/43168869669).

**The iOS 27.2 Files automation failure remains unresolved.** SDK-line CI does not establish a fix
or a pass on that runtime. CI now uses runtime/hardware metadata to select the newest available runtime
within the active SDK's major/minor line for each family, including patch releases. It rejects a missing
family, prefers iPhone Duo at the selected version, and retains inventories/targets. All 18 methods per
family remain required. Newer-runtime checks can be run with explicitly selected simulator IDs.

## Commit and publishing behavior

- Main-branch pushes and pull requests run affected-platform validation. Every selected native job
  includes required UI tests and contributes to the stable `CI result` aggregate.
- Documentation-only commits run routing/contract checks; manual CI dispatch selects all platforms.
  The runtime-selection commit selects full CI, including every platform.
- Validation has read-only repository permissions and no distribution signing or Store secrets.
  Evidence is uploaded for failed as well as successful native runs.
- Branch commits do not reserve release version codes or publish app/CLI versions. The signed Android
  builder and Store workflows are manual. Release requires an explicit manual operation or `v*` tag.
- Only validation CI was triggered/dispatched for these source commits. No release, tag, Store
  submission or real-card signing was performed. Existing documentation deployment behavior is unchanged.

## Coverage limits

The reviewed architecture changes and implemented mock UI/integration suites are documented in
[architecture and test review](architecture-and-test-review-2026-11-11.md),
[native provider automation](native-provider-automation-2026-11-11.md) and
[test instructions](../testing/README.md).

Full catalog acceptance remains incomplete. The 47 documented journeys plus 3 protection
journeys retain partial/runtime-required classifications in `tests/journeys/catalog.json`. Physical
USB/PCSC, actual credential/biometric prompts, signed installer/Store interaction, live portal/PKI,
third-party provider and drag/drop combinations, Shortcuts, Spotlight, Handoff and desktop autostart
have separate catalogued runtime checks. Fixtures are not represented as evidence for those OS/hardware
paths. The strict full-automation coverage command still fails until those requirements are covered.
