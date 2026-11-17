---
name: esemnbun-ui-validation
description: Launch, drive and capture eSemnBun UI on desktop, iPhone/iPad simulators and Android emulators; distinguish mock screenshots from real integration evidence.
---

# Validate UI and capture evidence

Resolve hosts and explicit device IDs using [the environment skill](../esemnbun-dev-environment/SKILL.md). Build/install the requested commit using [the build skill](../esemnbun-build-sign/SKILL.md). When using a computer-use tool, read its current documentation and follow its supported interaction APIs; screenshots are observations, not proof of an action that wasn't exercised.

## Capture tooling

`scripts/capture-screenshots.sh` routes to platform capture scripts. Read the selected script's argument contract before invoking it:

- Apple: `apple/scripts/capture-screenshots.sh macos|ios APP_PATH OUTPUT_DIR [SIMULATOR_UDID]`.
- Android: `android/scripts/capture-screenshots.sh DEBUG_APK OUTPUT_DIR [DEVICE_SERIAL]`; `ADB` overrides the adb path. Its isolated capture requires an emulator.
- Linux/Windows: the wrapper routes to platform scripts; the owner's remote recipes additionally live in the VM skill. Adapt transport and desktop session to the developer's profile.

Apple captures require Debug demo support and use fictional cards, isolated preferences, `MSIGN_QA_NO_HARDWARE` and readiness markers. Android scenarios similarly require a demo Debug APK. Do not remove those guards to capture a release binary. Inspect each resulting image, including light/dark and phone/tablet layouts; file creation alone is not visual QA. Keep outputs outside version control unless they are deliberate sanitized documentation assets.

## Test interaction contracts

- Mobile fixtures start with NFC. Select the reader explicitly before asserting its missing/reading/error states; the empty Sign workspace has an inline card carousel, not a cards button.
- Scroll macOS disclosure rows fully inside the viewport before clicking: XCTest can report a clipped row as hittable while the click lands on the window resize edge.
- Narrow iPad tab strips page horizontally: use their Next/Previous Page controls to reveal the destination. Nested Settings sheets retain parent controls in the accessibility tree. Dismiss the visible Done control and wait for its presenting screen before scrolling or switching tabs. Demo banners are on workspaces; Settings exposes the demo switch itself.
- After rotating a foldable/windowed scene, assert keyboard and control bounds in the actual scene rather than requiring the app width to exceed its height.

- Keep accessibility polling inexpensive: read a control frame once per poll and pass no expectation object when the predicate already captures the element. XCTest otherwise requests a full debug description each time, which can consume a bounded wait on busy runners.

## What to exercise

- Sign: mixed success/failure batch continues, a single human-readable error per failed file, stable card identity throughout inter-document transitions, no retry button, entire success row activates the platform's reveal/open action.
- Verify: filename and status icon on one row, per-signature author/date/identifier and parsed certificate disclosures, full-title disclosure activation, multiple files, remove-file clears its results, clear-all, and replacing inputs clears stale results. Distinguish subject identity from issuer organization ID; do not label an issuer's registration number as a person's IDNP.
- Shared drop zones: matching spacing and dashed rounded borders in both screens, including iOS/iPadOS corners. Test actual drag/drop on iPad split view and Android tablet; choosing a file or seeing a drop delegate is not proof of drag/drop.
- Desktop: clean-profile first launch opens the main window, tray/menu actions work, no trailing Windows flyout gap, macOS About has close-only controls and fixed size, Help opens the configured docs URL.
- Cold launch iOS splash on phone/tablet; iOS may cache launch snapshots, so distinguish cached screens from current resources. Use a dedicated test install if resetting state is needed; do not uninstall a developer's working session without need.

A simulated identity can validate appearance but not reader transport or real signing. The Debug simulator bridge preview is explicitly opt-in and read-only: test certificate listing and denial of signing; never ship mock connected identities in Release. The iOS bridge only serves while the app is foreground/active; split-view/background state can explain an offline connection. Check the macOS bridge process/port ownership too; quitting it changes what Safari on the Mac can reach.

Copy sample files to the chosen simulator app's Documents container (`simctl get_app_container UDID md.esemnbun.ios data`) or to Android Downloads using explicit `adb -s SERIAL push`. File presence does not prove Files-provider visibility or drag/drop. Validate the actual picker/Files path. Do not copy the developer's whole Downloads folder by default.

For evidence, record commit/build, target ID and dimensions, theme/language, real versus demo mode, action performed and observed outcome. Redact real identity/certificate details and private filenames before committing images. Report untested gestures/hardware honestly.
