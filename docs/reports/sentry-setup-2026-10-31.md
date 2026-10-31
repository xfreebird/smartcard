# Optional desktop Sentry — 31 October 2026

Current scope: **macOS, Windows and Linux desktop apps only**. iOS, Android and CLI tools do not include
Sentry. Organization `personal-kee`, EU/Germany. No app was published or production release dispatched.
No real card, PIN, certificate or document was used for verification.

## Consent and behavior

Each desktop app asks on the first foreground launch, in a native dialog with separate **Send crash reports**
and **Send application metrics** controls, both OFF. Save records the selected categories; Don't send and
closing the prompt record a refusal. Until consent, the SDK does not initialize and no telemetry can upload.
Refusal persists across restarts without repeated prompts. Both options remain in native Settings.

On a category change the previous reporting session is canceled without an opt-out flush, pending local
queues are discarded, and a new session starts only for categories that are now allowed. Revocation cannot
recall reports already received or bytes that already left the device. The dedicated caches keep diagnostic
cleanup separate from documents, saved PINs and ordinary settings.

Application metrics use real SDK counters/distributions, not only trace events. Fixed names include app
launches, operation outcomes and permitted navigation/session metrics; no document, user or card labels.
Crash reports retain technical frames and sanitized error kinds. No screenshots, replay, arbitrary logs,
URLs, document names, certificates, PINs or raw native memory dumps. Sentry may derive approximate geography
from connection IPs; this is disclosed in the local privacy draft.

## SDKs and coverage

| Desktop | SDK/project | Coverage |
| --- | --- | --- |
| macOS | Cocoa9.32.0, `apple` | Consented Cocoa crash/error reports, app/sign counters, safe fixed-operation timings |
| Windows | .NET6.12.1, `esemnbun-windows` | Consented managed unhandled failures, sessions/navigation counters and session-duration distribution |
| Linux | Native0.17.5, `esemnbun-linux` | Consented in-process signal crashes, handled operation diagnostics, app/outcome counters and session duration |

Linux's in-process handler writes sanitized JSON and delivers crash reports on the next opted-in launch.
When only metrics are enabled its crash backend is disabled. The package and Flatpak bundle their SDK at
`lib/esemnbun/libsentry.so`; XDG config/cache locations are respected. The vendored public API header and
MIT license are under `linux/Sources/CSentryRuntime`. The upstream source archive is SHA256-pinned.

## Verification

- Native macOS first-launch dialog: both controls off, decline persists, next launch has no prompt/SDK;
  crash-only and metrics-only choices work, opt-out removes the SDK cache. Thirteen Apple policy tests
  (five new consent tests) pass; macOS and SDK-free iOS Debug builds pass. iOS binary/DSN/privacy audit
  confirms no Sentry. See `sentry-apple.md`.
- Android clean Debug/Release builds and lint pass. Dependency and APK/Dex audits confirm no Sentry or
  verification hooks; all four ABI checks still pass. See `sentry-android.md`.
- Windows native dialog: unknown SDKoff, decline persists across restart, Settings metrics-only and
  opt-out are reflected immediately; explicit native QA consent enables real verification. Fourteen
  policy/privacy tests pass. CLI clean Release build/output audit confirms no Sentry. See `sentry-windows.md`.
- Fedora: native SDK and app Debug/Release builds; thirteen policy tests (four new consent tests). Native
  dialog/default-OFF controls, persisted refusal, SDK absent from process maps before/after declined
  relaunch, metrics-only, both-on, crash-only, opt-out and cache removal verified with actual UI.
- Hosted metrics confirmed via MCP: macOS `app.launch`, Windows `esemnbun.desktop.sessions` and
  `esemnbun.desktop.session_seconds`, Linux `app.launch`.
- An actual controlled mock Linux process abort exited134; the next opted-in app launch delivered
  [ESEMNBUN-LINUX-4](https://personal-kee.sentry.io/issues/ESEMNBUN-LINUX-4):
  **SIGABRT: Desktop application diagnostic**, level fatal, handled no, mechanism signalhandler.
  Frames include `AppMonitoring.start` and `MonitoringCoordinator.restore`. No minidump was produced.
- Shared localization/store export checks, YAML parsing, shell/C/Swift syntax and `git diff --check` pass.
- Ubuntu24.04: in-process SDK and app build passed; thirteen tests passed with a separate clean SwiftPM
  test scratch directory. Actual default-OFF prompt, no SDK in process maps before consent, metrics-only
  opt-in using the default packaged library path and immediate opt-out/cache removal passed. QEMU UI used
  the Cairo renderer. The dialog uses optional newer layout APIs through a compatibility shim, and leaves
  native content sizing to libadwaita; forcing early measurement on1.5 was removed after native reproduction.
  The13 test results are from the successful clean scratch build; earlier mixed static/dynamic test attempts
  failed at toolchain linkage and were superseded.

Earlier onboarding test issues APPLE-1, ESEMNBUN-ANDROID-1 and ESEMNBUN-WINDOWS-1 remain historical;
mobile/CLI reports predate the desktop-only amendment. The Android project is left unused, not deleted.
Current reports and screenshots take precedence over earlier all-platform setup notes.

## Release handoff

The release workflow now uploads **desktop-only** matching dSYMs/PDBs/DWARF, without source context.
Actual uploads and full native file/line symbolication remain gated by GitHub Actions repository secret
`SENTRY_AUTH_TOKEN` for `xfreebird/smartcard`. The interactive OAuth connection cannot be reused by CI.
Create a scoped organization upload token and put it directly in the secret store; do not paste it into chat.
`upload-sentry-ci.sh` verifies official CLI3.8.2 SHA256 digests. Missing-token and installer paths were checked.

Publish the updated local privacy policy and complete desktop portal privacy forms before submission.
`distribution/diagnostics-privacy.json` records category consent and mobile/CLI exclusion. Real public support
and privacy URLs remain placeholders. Confirm the organization's configured retention before policy release.

Native consent evidence is under `~/Desktop/esemnbun-screenshots/{macos,windows,linux}/2026-10-31/`.
Official references: [Apple](https://docs.sentry.io/platforms/apple/),
[.NET](https://docs.sentry.io/platforms/dotnet/), [native backends](https://docs.sentry.io/platforms/native/configuration/backends/).
