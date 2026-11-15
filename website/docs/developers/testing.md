---
title: Testing and automation
description: Run focused core tests, integration batches and native UI journeys, and understand exactly what each result proves.
---

Start with the smallest layer that can reproduce the change. Most tests use synthetic keys, simulated cards or Debug presentation fixtures. Physical-card tests are a separate, deliberate activity.

## What each test layer proves

| Layer | Typical evidence | Does not establish |
| --- | --- | --- |
| Golden vectors | Exact KDF, CMAC, padding, APDU and session bytes agree | USB drivers or screen behavior |
| Simulated card | Authentication, identity guard, PIN errors and signing sequence | A physical card/reader works on an OS |
| Format / contract integration | Real parsers, generated signatures, CLI JSON or MCP process exchanges | Store signing or native file-picker behavior |
| Application tests | Batch policy, state changes, persistence through injected services | Native layout or gestures |
| Native UI journeys | Actual controls, queue behavior, navigation and fixture outputs | Real signing when the service is mocked |
| Hardware / live PKI | A named card/reader/OS combination and live service response | Every device, every network or future availability |
| Distribution checks | Signature, entitlements, installer and packaged metadata | Store review approval |

## Focused unit and application checks

From the repository root, select the applicable commands:

```sh
# Apple / Swift core and app-level tests
(cd swift/MoldSignKit && swift test)
(cd apple && swift test)

# OpenSSL/POSIX paths on macOS; not GTK UI
bash scripts/test-portable-macos.sh

# Android JVM and application unit tests
(cd android && ./gradlew :core:test :transport-usb:testDebugUnitTest :app:testDebugUnitTest)

# Portable Windows core / CLI tests; not WinUI
(cd windows && dotnet test MoldSign.Portable.slnf)

# Linux application tests, on a host with the GTK development dependencies
(cd linux && swift test)
```

Swift, Kotlin and C# vector tests read `spec/vectors/card-crypto.json`. Preserve one coherent protocol contract across all three ports. A byte change should include an explanation and a vector or simulated-card regression that fails for the old behavior, rather than merely duplicating the implementation.

Network tests are opt-in. `MSIGN_NETWORK_TESTS=1` enables the Swift live PKI cases; leave it off for reproducible offline work. Record skipped tests and distinguish fixture timestamps from live authority responses.

## Batched integration runner

`scripts/run-integration-tests.sh` requires a **fresh** output directory and sets network tests off:

```sh
bash scripts/run-integration-tests.sh apple dist/checks/apple-001
# Or choose one batch for its matching host:
bash scripts/run-integration-tests.sh linux dist/checks/linux-001
bash scripts/run-integration-tests.sh android dist/checks/android-001
bash scripts/run-integration-tests.sh windows-portable dist/checks/windows-001
```

Apple/Linux batches run core/application tests, build CLI/MCP executables and run process-contract checks. Android runs unit tests and assembles app/instrumentation APKs; **it does not run emulator journeys**. The Windows portable batch runs the core test project. On native Windows, `windows/scripts/test-integration.ps1 -Output ...` provides the PowerShell entry point.

Do not reuse an evidence directory from an earlier run. Record source revision, toolchain, target and exit status alongside logs; an old passing report is not proof for edited source.

## Apple native UI automation

First build a Debug app using [Build and run](build-and-run.md). Install `xcodegen` (for example, `brew install xcodegen` on the development Mac); the runners use it to generate an isolated XCTest host. Choose a dedicated booted simulator, not a device holding unrelated work:

```sh
bash apple/scripts/run-mock-ui-tests.sh ios \
  dist/dev-ios/Build/Products/Debug-iphonesimulator/eSemnBun.app \
  SIMULATOR_UUID dist/checks/ios-ui-001
```

Run separately on a phone and tablet. For macOS, in an interactive session with XCTest automation already authorized:

```sh
bash apple/scripts/run-mock-ui-tests.sh macos \
  dist/dev-macos/Build/Products/Debug/eSemnBun.app \
  mac dist/checks/macos-ui-001
```

The wrapper runs verification and mock workflows, with target-specific suites for controls, documents, protection and paging. It checks XCTest result bundles and expected test completions, not only the shell exit code. Inspect `.xcresult` failures and screenshots. `scripts/ci/test-apple-ui.sh` is CI preparation; it is not a general instruction to change a developer machine's security settings.

## Android native UI automation

Build both APKs, then select a dedicated emulator serial from `adb devices -l`:

```sh
(cd android && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest)
bash android/scripts/test-journeys.sh EMULATOR_SERIAL \
  android/app/build/outputs/apk/debug/app-debug.apk \
  android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  dist/checks/android-ui-001
```

Replace `EMULATOR_SERIAL` with a value such as the actual `emulator-...` ID listed on your machine. The runner rejects physical-device serials for this fixture suite. It installs the packages, runs instrumentation and inspects scenario completions because `am instrument` can exit successfully even when an assertion failed. Failure artifacts include available screenshots and system diagnostics. Repeat for phone/tablet configurations relevant to the change.

## Windows native UI automation

Use an interactive Windows desktop and a Debug app with the fixture markers. Close an existing eSemnBun instance first. In PowerShell, replace the app path with the actual new build:

```powershell
./windows/scripts/test-verification-journeys.ps1 `
  -App 'C:\path\to\Debug\eSemnBun.exe' -Output 'C:\checks\verification-001'
./windows/scripts/test-mock-workflows.ps1 `
  -App 'C:\path\to\Debug\eSemnBun.exe' -Output 'C:\checks\workflows-001'
```

These use Windows UI Automation and isolated preference files. They exercise controls and verify fixture state/output. An SSH process in a noninteractive session is not equivalent. Additional scripts cover first launch, insertion helpers, scrolling and demo mode; inspect each script's parameters before use.

## Linux native UI automation

Run inside an isolated GNOME graphical session with Python AT-SPI/GObject bindings available (for example `python3-pyatspi` and `python3-gi` on Debian-family systems):

```sh
python3 linux/scripts/test-ui-journeys.py \
  linux/.build/debug/esemnbun-gnome dist/checks/linux-ui-001
```

The runner accepts repeated `--scenario NAME` selections. It uses the accessibility tree and actual native actions, with injected signing outcomes and isolated data. Mock outputs are explicitly unsigned demonstration files. Do not rename them or present them as real signatures.

## Website and content checks

```sh
python3 scripts/docs/organize-user-guides.py --check
python3 scripts/docs/validate-user-guides.py
cd website
node --test tests/*.test.mjs
npm run build
npm run verify:seo
```

The production build checks Docusaurus links across locales. The SEO verifier checks rendered metadata and discovery/Markdown consistency. Inspect the architecture/sequence diagrams at desktop and phone widths, both appearances, and open the full-size images. Technical prose still needs source review: a passing build cannot tell whether an APDU description is true.

## Real-card validation

Use synthetic documents, explicit reader selection and the owner's per-session authorization. Obtain the PIN through secure runtime input, never a script, test fixture, log or command argument. Stop at the first wrong-PIN, blocked-card or stuck-state error. Do not use failed PIN attempts as test cases on a real card.

Record the reader/card model, OS, app commit/configuration, input/output hashes and independent verification result with personal data removed. A screenshot of the ready card proves display state; a signature checked by a separate verifier proves a different and stronger property. Keep private captures out of the public website.
