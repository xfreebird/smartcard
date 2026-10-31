# Windows desktop diagnostics

The WinUI desktop application uses the official Sentry .NET SDK 6.12.1 through an isolated
`MoldSign.Diagnostics` boundary. The CLI and signing core do not reference or initialize Sentry.
Destination: organization `personal-kee`, project `esemnbun-windows`, EU region. The public ingestion DSN
is not an API credential; never put `SENTRY_AUTH_TOKEN` in an application or repository.

## Consent

On first main-window activation a native dialog offers separate **crash reports** and **application
metrics** switches, both off. Closing/declining records a decision with both disabled. Settings exposes
the same independent switches and applies changes immediately. The preferences store persists the
three decision/crash/metrics flags; missing old fields are unknown and grant no consent.

Unknown or declined consent does not initialize the SDK. User demo mode suspends the controller even
when saved real-mode consent is enabled; switching into demo cancels without flushing, and leaving
restores the existing choices. The first consent prompt is deferred while demo is active. Each consent change revokes the old SDK
transport, cancels pending/in-flight requests, closes without flushing, purges the dedicated SDK cache
and starts a fresh SDK generation only when at least one signal is enabled. Disk caching is disabled.
A normal explicit application quit may flush only the currently permitted signals. OS process-exit
flush is disabled.

The crash switch governs managed unhandled AppDomain/task exceptions and the app's explicit WinUI
unhandled-exception hook. Error events are rebuilt from an allowlist of exception type, generic message,
sanitized code/symbol frames, debug IDs and controlled release metadata. Raw exception messages,
requests, users, paths, locals, source context, arbitrary extras/tags/breadcrumbs are discarded.

The metrics switch governs actual SDK counters for monitoring sessions and fixed-name navigation
sections, and a distribution of seconds in a consenting monitoring session on normal quit. Metrics
carry numeric values and only the SDK's controlled release/environment/version attributes. No document
name, PIN, cardholder, certificate, URL or arbitrary attribute is supplied. Automatic HTTP tracing,
logs, replay, screenshots, view hierarchy, raw native memory dumps and attachments are disabled.

## Hardware-free verification

Run `windows/scripts/test-monitoring-consent.ps1` in the interactive desktop against a Debug app. It
uses an isolated normal-mode Debug app (no reader attached) and native UIAutomation controls to verify unknown state, decline, restoration,
metrics-only opt-in and opt-out. Add `-SendVerification` to explicitly switch on both signals in a fresh
native consent dialog and verify a handled error from the real WinUI application. The QA environment
flag never grants consent and Release binaries contain no test-error path. No card or PIN is used.

An event ID or process exit alone is not ingestion proof; confirm
`esemnbun-sentry-verification-windows` in Sentry. Earlier CLI verification events are historical and
predate the desktop-only amendment.

Environment-driven Debug previews normally do not save preferences. User demo mode does persist its
choice in all build configurations. Setting `MSIGN_TEST_PREFERENCES` selects an isolated
persistent store for consent QA; it does not affect the user's normal preferences.

## Production symbols

Events use `esemnbun-windows@<assembly version>`, development/production per build configuration, and
process architecture as distribution. Keep corresponding portable PDBs with x64 and ARM64 Release builds.
From CI, call `windows/scripts/upload-sentry-symbols.ps1 -SymbolsPath <build-output>` with
`SENTRY_AUTH_TOKEN` supplied through the CI secret store. The script stages only PDB/DLL/EXE files;
there is no source inclusion and no upload of bridge identity, logs or documents. Actual upload remains
pending that CI token; MCP OAuth does not provide one.

References: [Sentry WinUI](https://docs.sentry.io/platforms/dotnet/guides/winui/),
[SDK options](https://docs.sentry.io/platforms/dotnet/configuration/options/),
[metrics](https://docs.sentry.io/platforms/dotnet/metrics/).
