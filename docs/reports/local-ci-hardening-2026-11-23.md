# Local CI validation — scanner hardening and Android optimization

Validation started 22 November and continued 23 November 2026 on branch `ai/scanner-hardening-r8`, based on `ce6f4acb113c628e9c5f0c99f73456e74c04359c`. This report covers the reviewed scanner recommendations, AGP 9 migration and shared Android Actions optimization gate. No release, Store submission, publishing dispatch, tag or merge is authorized by this validation.

Raw logs, source manifests, XCTest results and synthetic screenshots remain in ignored `.local/validation/local-ci-2026-11-22/` and corresponding fresh private host workspaces. No card PIN, real document, protocol trace or distribution credential was used. Signing/batch UI fixtures are explicitly synthetic; password protection exercises real local transformations of disposable files.

## Shared CI and tooling

- 90 CI guard tests passed under CPython 3.12, including the Android optimization policy, workflow routing, permissions, version reservations, retry boundaries and required UI completion checks.
- 12 mocked Play publisher tests and 6 mocked AppGallery tests passed. Their simulated upload messages do not represent a network upload.
- Localization completeness, browser-service exports, Store metadata, guide organization and illustrated-guide validation passed. Journey coverage is a static mapping and does not establish hardware acceptance.
- Actionlint 1.7.12, shell/Ruby syntax checks and whitespace checks passed.
- Locked Ruby dependencies installed with Addressable 2.9.2; fastlane loaded/listed lanes without executing a lane.
- Publisher CPython 3.12 Linux x86_64 wheels were downloaded with pinned hashes. A separate native macOS wheel set was verified against primary registry hashes and installed offline for mocked publisher tests; the committed Linux lockfile was not weakened.

## Android

Passed on the main Apple Silicon Mac: Gradle 9.1.0, JDK 17, AGP 9.0.1 and Kotlin/Compose compiler 2.2.10, with dependency verification enabled.

- 245 unit cases: core 167, transport 42, app 36; zero failures and one opt-in live TSA skip.
- Debug app/test APKs, optimized unsigned Release APK/AAB, Debug and Release lint, and all four native ABI checks passed.
- A fresh Android 16/API 36 ARM64 emulator passed all 34 native journeys and all six integration phases, including light/dark edge-to-edge checks, saved identities, browser authentication and file-protection round trips.
- Corrected the edge test to measure the semantic toolbar title rather than an identically named navigation-rail destination. Assertions are retained.
- Final AAB SHA-256: `65b61cd743a6687a860a2534aea52859f48d776eb3d2591268a21253fcb9b0d0`. Actual bundle metadata records R8 9.0.32, all three optimization options and optimized resource shrinking enabled. Unobfuscated/unoptimized/unshrunk percentages are 3.45/4.69/3.61. These are build metadata, not measured device memory/performance or Play Console clearance.

No upload key, version reservation or publisher was used. Physical optimized-Release USB/NFC and minimum-API TLS acceptance remain open.

## macOS

Passed using Xcode 27.1 RC on Apple Silicon, with the native app built on the MacBook Air:

- Apple backend: 138 core tests, zero failures, five opt-in skips; MCP stdio process checks passed.
- OpenSSL/POSIX portable backend: 129 tests, zero failures, six opt-in skips.
- 33 app integration tests, DesignSystem build, Debug native app, unsigned Store target and ad-hoc CLI build passed.
- All 15 required macOS UI cases passed: verification 5, mock workflows 6 and floating actions 4. Exact XCTest counts were checked. English light and Russian dark screenshots were inspected.
- Fixed the generated macOS test harness to launch the supplied app path instead of the installed app with the same bundle identifier. Captures use the native window for a menu-bar app; resize gestures use straight window edges. No assertions or required case counts were removed.

The installed normal app was restored after isolated tests. No authentication policy was changed. A signed Store installation, reader operations and external-browser portal acceptance remain open.

## iOS

The app built for arm64 simulator with Xcode 27.1 RC/SDK 27.1 and was locally ad-hoc signed. Runtime coverage uses iOS 27.0, differing from the hosted runner image.

- iPhone 17 Pro: all 35 required UI cases passed, zero skips. Filesystem postchecks verified protection round trips, private permissions, unchanged originals, Documents migration and output preservation after history clear.
- iPad Pro 11-inch (M4): all 35 required UI cases passed, zero skips. Exact XCTest count and the same filesystem postchecks passed. The restored protection fixture SHA-256 is `9a9b6d0344b2f57eba88ed57b5fb1e45ed3cd16dc839950ab4abab2d032b0090` on both devices. A carousel failure during the disk-affected first run passed a focused two-case warm retry and the complete 35-case rerun without a source/assertion change.

With owner authorization, the main simulator service was restarted to recover startup. Existing simulator data was preserved. First attempts affected by cold startup or disk exhaustion remain retained as failed/incomplete attempts, rather than counted as passes.

## Linux

Native Fedora 44 ARM64 passed core/MCP checks, the GTK build, design checks, all 40 app tests, and tar/RPM packaging. The CI-equivalent Ubuntu validation uses the actual `swift:6.2-noble` image (Swift 6.2.4), running ARM64 inside the Fedora VM. Hosted CI runs x86_64.

The container workspace and temporary directory are bind mounts: Swift 6.2 Foundation copying on the SELinux overlay filesystem failed independently on extended attributes; the same copy succeeds on the bind-mounted workspace. Host security policy remains enabled.

Ubuntu core passed 122 cases with seven opt-in skips; app build, MCP, design checks and all 40 app tests passed. Release CLI/MCP/GNOME builds and tar, Debian and RPM packaging passed. All 21 required native UI scenarios passed together with the final runner, including the real password encrypt/save/decrypt byte round trip, cancellation, mismatch rejection, private permissions and confirmed removal. All 286 tracked Linux/Swift/spec source hashes matched the staged tree.

The Linux accessibility runner now bounds event draining, ignores defunct/closed windows, tracks stable remote accessible paths and checks native chooser windows directly. Required scenarios and filesystem/security assertions are retained.

## Windows

Windows 11 ARM64 VM, using .NET SDK 10.0.404 and a real interactive desktop. Core tests ran with the x64 SDK under emulation; after a slow first WinUI compilation, the app build driver switched to the native ARM64 SDK while retaining the x64 app target. Visual Studio 2022 Build Tools and portable PowerShell 7.7.0 were provisioned locally. Hosted CI uses native x64 Windows.

All 290 core/integration tests passed, zero skips. One initial cold TLS loopback timeout passed both a focused retry and a complete warm 290-case rerun without changing the timeout or source. Corrected the portable solution filter's project separators for Windows SDK resolution.

Both x64 and native ARM64 WinUI Debug builds passed with zero warnings/errors. The first UI invocation correctly refused to run alongside the installed auto-start app. The x64 Debug app reached a rendered Verify page after about 118 seconds under ARM emulation, exceeding the unchanged 25-second UI guard; this local x64 UI attempt is not a pass.

All six native ARM64 UI suites and the Debug watcher build passed in the final sequence:

- Verification: all 4 verdict/expand/collapse/clear scenarios.
- Mock workflows: all 8 signing, cancellation, format, stamp and history scenarios.
- Genuine fresh and subsequent ordinary launches, including onboarding and persisted completion.
- Production demo switching, confirmation cancellation, persistence, isolated unsigned outputs and return to normal mode.
- All 20 Settings navigation records across the required window sizes/themes.
- Synthetic reader/card insertion, closed-app activation and helper shutdown; no hardware or PIN used.

Exact filesystem/JSON completion proofs were checked. The Windows drivers now scope queries to app-owned top-level windows, including separate popup roots, instead of enumerating every desktop descendant.

A second harness defect was reproduced on PowerShell 7.7: its .NET string binding converted `$null` into an empty value during reset/restore. [.NET 9+ preserves empty environment values](https://learn.microsoft.com/en-us/dotnet/core/compatibility/core-libraries/9.0/empty-env-variable), so debug scenario switches leaked between suites. The shared environment helper now removes absent variables through the provider and restores actual values. Ordinary-launch and demo-switch tests clear all fixture switches. Earlier purported ordinary-startup probes affected by empty demo switches are not acceptance evidence. The complete Windows sequence passed after this repair, with no assertions or deadlines removed.

Unsigned x64 Native AOT CLI, helper, self-contained app, MSI, MSIX, CLI ZIP and winget manifests built successfully; package checks exited zero and no upload ran. The native x64 CLI executed `--help` and `capabilities --json` successfully without card or PIN access. All 301 tracked Windows/spec source hashes matched the staged tree. The installed app and initially stopped VM state are restored after validation; temporary validation tasks are removed.

## Website

On the MacBook Air with Node 22.23.5: clean `npm ci --ignore-scripts`, all 39 Node tests, the full EN/RO/RU Docusaurus build and SEO/discovery verification passed. The worker-enabled SSG path used Tinypool 2.1.2 and Serialize JavaScript 7.1.3 overrides. No deployment ran.

Current npm audit: zero high/critical findings and 18 moderate findings in upstream development/tooling dependencies. The original review records reachability and deferred parent upgrades; this does not claim zero vulnerabilities or cleared GitHub alerts.

## Remaining acceptance and delivery limits

Physical reader/NFC signing, saved-PIN/biometric reuse, real portal interoperability, live PKI, signed installer/Store runtime and all-device/all-architecture acceptance remain open. Refreshed SonarCloud/Dependabot findings and the external new-code quality gate must be checked against the eventual pushed commit. This report does not claim the original ratings, alerts or uploaded Play warnings are cleared.

Hosted CI is a separate check of the eventual PR head. No release/Store workflow may be dispatched, and the PR must not be merged as part of this task.
