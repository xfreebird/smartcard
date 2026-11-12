# macOS floating Sign — 12 November 2026

The Sign action now stays at the bottom-right of the signing workspace in a large native capsule.
The safe-area inset reserves space beneath the scrolling documents. The count, readiness rules and
Command-Return shortcut remain intact; an empty queue has no action. Enabled and disabled states use
the same native prominent style. The change introduces no signing-model dependency into the design system.

## Local validation

Source: `fc98b4bb08649f8ad92b8af44e05a77159cc57a2` plus this change. Main MacBook Pro runs
macOS 26.7.1 (25G241); builds use `/Applications/Xcode-27.1-rc.app`, macOS SDK 27.0.
The Debug desktop app was ad-hoc signed with its local validation entitlements.

| Check | Result |
| --- | --- |
| macOS Debug app build | Passed |
| iOS Simulator Debug app build | Passed; iOS layout is unchanged |
| `swift test --package-path apple` | 42 tests passed, no failures |
| CI Python guard suite | 56 tests passed |
| All three macOS XCTest suites, `build-for-testing` | Passed; 15 authored methods compile |
| macOS XCTest execution | Blocked before execution by host Automation Mode authentication |
| Native mock Sign click | Two sample results appeared; queue and floating action cleared; no PIN requested |
| Localized native capture review | 12 EN/RO/RU signing, progress, error and stamp images inspected |
| Guide generation/check and validator | 30 guide overviews, 327 task pages, 702 panels; no validation errors |
| Journey catalog | Source paths and mappings pass; the existing 50 partial/runtime journeys remain explicitly incomplete |
| Website tests | 26 passed |
| Production website build and SEO check | Passed in all three locales with `SITE_URL=https://esemnbun.md BASE_URL=/` |
| Native browser review | Updated EN/RO/RU instructions and bottom-right screenshot callout verified |

`MacFloatingActionUITests` checks visible placement while documents actually scroll, window resizing,
minimum dimensions, disabled no-reader/reading/busy states, click and keyboard mock completion,
and absence with an empty queue. The commit runner requires all four methods in addition to the
existing 11 macOS methods, without skips. These new runtime assertions are not yet reported as passing.

The installed `automationmodetool -s` reports:

```text
Automation Mode is disabled.
This device requires user authentication to enable Automation Mode.
```

The Air reports the same prerequisite. Local administrator authentication is required to enable
XCTest automation; no host security setting was changed. Earlier initialization failures and the
authentication boundary are documented in [the native validation report](native-test-validation-2026-11-11.md).
Compilation, screenshots and the native mock click are separate evidence and do not replace the suite run.

After the host is authorized, close the isolated app and run the complete batch with a fresh output directory:

```sh
DEVELOPER_DIR=/Applications/Xcode-27.1-rc.app/Contents/Developer \
  bash apple/scripts/run-mock-ui-tests.sh macos \
  "$PWD/.local/design-system-dd/Build/Products/Debug/eSemnBun.app" mac \
  "$PWD/.local/mac-floating-ui-results"
```

Build logs and result bundles are under `.local/mac-floating-*`. Screenshot source and installed-asset
hashes, crop coordinates and binary provenance are recorded in
[`macos-signing-refresh-evidence.json`](../user-guide/macos-signing-refresh-evidence.json).
The stamp images retain the complete native sheet; the other images retain the main window.
All inputs are fictional and hardware access is denied. No real card, live PKI or distribution signing was tested.

Push and new-head CI validation are pending the requested local XCTest pass. No release or publishing
workflow was dispatched. CI still runs native tests on main commits; app releases remain tag/manual operations.
