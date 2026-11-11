# Native provider automation follow-up

This batch makes the seeded iOS Documents and protection suites usable across native Files layouts,
adds a Linux protection journey, and corrects Android emulator readiness before app installation.
It follows the architecture, service-provider and native-component refactors already on main.

## Changes

- iOS picker cancellation targets the native phone or sidebar toolbar and verifies dismissal.
  Folder navigation taps the observed icon; the surrounding cell can include noninteractive metadata.
  Demo activation waits for its asynchronous state change. Simulator post-checks resolve the current
  data container after installation and compare relative output identities.
- Linux's isolated preview opens the real protection dialog. The test uses native open/save controls
  and the production password processor. It checks absent input, mismatched confirmation, source/save
  cancellation, retained pending results, exact decrypted bytes, unchanged originals, private output
  permissions, and removal only after explicit confirmation. Native-driver helpers are separate from
  journey assertions. GTK path fields are set atomically to avoid autocomplete changing synthetic input.
- Android permits one framework cold-boot Wait action before installation, followed by three healthy
  launcher observations. Pre-install accessibility connection failures reset the healthy count and
  have at most three attempts. App ANRs, recurrence and a second framework failure remain fatal.

## Executed evidence

| Check | Result |
| --- | --- |
| Final Linux GTK batch on Fedora 44, isolated Xvfb | 21 scenarios passed |
| Final iPad protection runner, iOS 26.5 | Native test and source/output byte/permission post-checks passed |
| Final iPad Documents runner, iOS 26.5 | All 3 methods and migration/history/fixture post-checks passed |
| iPad demo activation/share/relaunch test | Passed after adding the state wait |
| iPhone provider checks, iOS 26.5 | Protection and 3 Documents methods passed; byte/persistence checks passed after resolving the relocated container |
| CI helper regressions | 41 passed |
| Script syntax, journey references, diff whitespace | Passed |

The final folder-icon adjustment was rechecked on iPad. Hosted validation must still check the final
commit on both phone and tablet runtimes. Local evidence is under the ignored
`.local/validation-20261111/` directory. The earlier hosted run
[43060649454](https://github.com/xfreebird/smartcard/actions/runs/43060649454) passed macOS, Windows,
Linux and shared core checks; its Android boot and iOS driver failures prompted these corrections.

Commit CI keeps native suites required and read-only. Branch pushes do not create app releases,
reserve distribution versions, or upload to stores. Release workflows remain tag/manual operations.

The journey catalog retains explicit partial coverage for remaining OS/hardware acceptance paths.
GTK fallback pickers do not establish sandbox portal behavior; simulated signing and synthetic files
are not physical-card, credential-prompt, Store installation or live-government-portal evidence.

The subsequent hosted run [43069650641](https://github.com/xfreebird/smartcard/actions/runs/43069650641)
passed Windows and shared checks. Its Linux removal test correctly encountered the container's unsupported
overlay filesystem; the fixture now uses tmpfs, matching the core removal test, and passes locally there.
Android's UiAutomation connection timed out before installation; bounded readiness retries now cover
that startup state without counting it as a healthy check. The failed validation run was canceled while
Apple was still queued, before starting a fresh run with these fixes.
