# Windows desktop Sentry and consent — 31 October 2026

**Only the WinUI desktop app has Sentry**. The CLI and signing core remain independent of the SDK.

The app offers a native dialog after its main window is shown. Separate crash-report and application-
metric switches default off. Declining/closing persists both off; later Settings switches apply immediately.
Missing legacy preference fields mean unknown, with no SDK initialization or telemetry requests.
`MonitoringController` separates consent policy/persistence from the SDK runtime, allowing mock policy
checks without hardware or network. Preferences retain both independent flags and the explicit decision.

Every preference change cancels the old SDK transport, closes without flushing, purges the dedicated
SDK cache and enables a new generation only for the permitted signals. Disk cache, process-exit flush,
raw memory dumps, attachments, replay, screenshots and automatic request capture are disabled. A normal
explicit quit may flush currently permitted diagnostics; opt-out does not use that path.

Managed unhandled AppDomain/task exceptions and the explicit WinUI error hook are crash-consent gated.
Error allowlisting retains exception type, generic error text, symbol coordinates and controlled release
metadata while removing raw messages, locals, paths, users, request fields and arbitrary context. Metrics
are actual Sentry SDK counters for monitoring sessions and fixed navigation sections, plus a consenting-
session-duration distribution on normal quit. No document/PIN/card/URL values or arbitrary attributes
enter these calls. SDK metric defaults contain only environment/release/SDK identity attributes.

Project: `personal-kee/esemnbun-windows`, EU. SDK: **6.12.1**. Release/environment/architecture values
are controlled by the app build. No API token is embedded.

## Validation

- Focused native Windows policy/privacy suite: **14 passed, 0 failed** (unknown, decline, restored and
  mixed consent, per-signal routing, revocation without flush, cache-purge callbacks, preference persistence,
  serialized error/context removal and retained symbol coordinates).
- Final consent-enabled Debug and Release WinUI builds: **0 warnings, 0 errors**.
- Clean Release CLI build: **0 warnings, 0 errors**; dependency manifest and output contain **no Sentry**.
- Native UI proof passed: unknown SDK disabled → actual decline → relaunch preserves SDK disabled →
  Settings metrics-only enables SDK without crash permission → Settings opt-out disables SDK.
- Fresh native prompt QA explicitly enabled both switches and saved. The real WinUI app captured its
  handled verification error, exported permitted metrics, flushed on normal quit and exited **0**.
- Evidence: `dist/windows/validation-2026-10-31/sentry-consent/`; three visually reviewed screenshots in
  `/Users/nghimbovschi/Desktop/esemnbun-screenshots/windows/2026-10-31/sentry-consent/`.
- Crash reports are tested with managed exceptions. Raw native dumps are deliberately excluded; the
  WinUI hook marks unhandled errors as terminal/unhandled and preserves that mechanism through filtering.
- Earlier CLI test event `6452918bc1ce44eda29bca6411ac8c19` is historical. The current CLI has no
  instrumentation or diagnostic-test command. No new CLI test event is sent by this revision.

`windows/scripts/test-monitoring-consent.ps1` automates the actual native dialog and Settings toggles
using isolated preferences. Its optional verification selects both switches in a fresh in-app dialog;
it never bypasses consent. The Debug-only error is thrown/captured through the real initialized app,
then flushed while allowed. No physical card, PIN, document signing or portal action is used.

## Release preparation

`windows/scripts/upload-sentry-symbols.ps1` stages only PDB/DLL/EXE files before debug-file upload.
Retain matching x64/ARM64 portable PDBs. The connected MCP OAuth account is not a CI token; symbol upload
remains pending `SENTRY_AUTH_TOKEN`. No deployment, store upload, source publication or release dispatch
has been performed.

References: [Sentry WinUI](https://docs.sentry.io/platforms/dotnet/guides/winui/),
[SDK options](https://docs.sentry.io/platforms/dotnet/configuration/options/),
[metrics](https://docs.sentry.io/platforms/dotnet/metrics/).
