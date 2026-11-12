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
existing 11 macOS methods, without skips. The first hosted run passed 14 of 15 methods; the resize method required the adjustment below.

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

## Delivery and hosted validation follow-up

Commit `1cb90673c2509bdef61ad874635605de2b8bfa60` was pushed after the owner explicitly requested
commit and push following disclosure of the local XCTest authentication prerequisite.
[Website run 43239840613](https://github.com/xfreebird/smartcard/actions/runs/43239840613) passed.
All 12 deployed screenshot SHA-256 values match the capture manifest, and the live EN/RO/RU signing
guides contain the floating-action instructions. The 15 readback checks are retained locally in
`.local/mac-floating-live-docs.json`.

[The first CI run](https://github.com/xfreebird/smartcard/actions/runs/43239840590) passed Linux,
Android, Swift core/CLI and localization. It exposed two test-driver assumptions:

- The macOS resize test tried to grow beyond the hosted display boundary. It now shrinks from
  900 × 650 toward 860 × 620, retaining actual resize, scroll, placement and margin assertions.
- Windows Home scrolling checked transient UIA properties. It now requires three consecutive
  observations of the top offset and the fully visible selected card, matching the existing
  bottom-of-scroll synchronization.

The adjusted macOS XCTest suites compile locally, and all 56 CI guard tests pass. Local macOS
XCTest execution still requires administrator authentication. The Windows scroll driver passed
on the local Windows 11 ARM64 VM with the x64 Debug app: both 1100 × 720 and 900 × 580 windows,
light and dark themes, native wheel and Home/End input, centered selected card, and fully visible
final controls. Proof and eight screenshots are in `.local/mac-floating-windows-local/`.
The temporary interactive test task was removed after completion. No application source was changed
by this follow-up.

[CI run 43243483172](https://github.com/xfreebird/smartcard/actions/runs/43243483172) passed for
`7629f8e28511f0d488f0df369954ce1d9ead594a`, including the aggregate `CI result`:

| Hosted validation | Result |
| --- | --- |
| macOS app/integration/UI, unsigned App Store variant and CLI build | Passed; all 15 native UI methods, zero failures |
| iOS app/share-extension and native UI | Passed; 22 methods on iPhone and 22 on iPad, zero failures |
| Windows core, native UI, helper and MSI/MSIX packaging | Passed, including the adjusted card scrolling driver |
| Localization and routing/publishing guards | Passed |

The unchanged Linux, Android and Swift core/CLI jobs were correctly omitted from this follow-up;
they passed in the preceding full selection. The hosted macOS pass does not remove the local
Automation Mode authentication prerequisite. CI logs and exact-head result metadata are retained
under `.local/mac-floating-followup-*`.

No release or store-publishing workflow was dispatched. CI still runs native tests on main commits;
app releases remain tag/manual operations.
