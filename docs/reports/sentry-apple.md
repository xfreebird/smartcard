# Desktop-only Apple Sentry consent — 31 October 2026

This supersedes the initial iOS/macOS setup. Sentry Cocoa9.32.0 is now linked only by the macOS
app. The iOS target has no SDK product dependency or bootstrap, no Sentry SDK symbols/ingest DSN
in its rebuilt executable or Debug dylib, and an empty collected-data privacy manifest. Historical
verification events from the earlier implementation were not deleted.

## Consent and independent categories

- Every undecided desktop user sees a native first-launch sheet in the main window, including users
  who already launched a previous build. Both crash and metrics choices initially read off.
- A recorded decline persists and is not requested on subsequent launches. Settings → General has
  the two independent live toggles. The shared RO/EN/RU catalog supplies all consent strings.
- Unknown consent or both categories off means no SDK initialization, transport, crash delivery or
  metrics collection. Screenshot fixtures hide the sheet and remain silent unless explicit QA
  prompt mode is requested; QA prompt mode does not grant consent.
- Crash consent enables native/handled crash diagnostics only. Wrong PIN, blocked PIN and user
  cancellation do not emit handled signing errors. Metrics consent enables actual SDK fixed-name
  `app.launch`/`document.sign` counters plus fixed startup/signing duration transactions, independently
  of crash consent. Metric names/attributes and event metadata are allowlisted.
- Opt-out first revokes the callback gate and invalidates/cancels the dedicated ephemeral URLSession,
  then closes SDK integrations with zero shutdown wait, deletes the isolated SDK cache and clears
  its epoch. Cocoa's close internally flushes, but its transport is already invalidated. There is no
  explicit flush on revocation and no later opt-in can reuse the revoked generation's queue.
- Same-choice allowed restart preserves only the active consent-compatible cache epoch. A category
  change rotates the epoch, so stale asynchronous callbacks cannot revive old queued reports.

## Validation

- Final macOS Debug build passed: `/tmp/esemnbun-sentry-consent-macos-build.log`.
- Final SDK-free iOS simulator Debug build passed: `/tmp/esemnbun-sentry-desktop-only-ios-build.log`.
  Binary audit found no Sentry SDK symbols or ingest DSN in either executable/Debug dylib.
- All13 Apple policy tests passed, including5new consent persistence/category tests for unknown,
  decline, both enabled, each mixed choice, and revocation to both off:
  `/tmp/esemnbun-monitoring-consent-tests.log`.
- Native macOS fixture `md.esemnbun.qa.consent-native-20261031` displayed both unchecked controls.
  Clicking Don't send dismissed the sheet, persisted `{decided: true, crashes: false, metrics: false}`,
  produced only `MSIGN_DEMO_READY`, and created no SDK cache. Relaunch showed the main window with
  no consent sheet and again no SDK flush or cache (`/tmp/esemnbun-consent-decline-relaunch.log`).
- In native General Settings, crash-only opt-in kept metrics off and sent one explicitly requested
  verification error through real SDK initialization. Turning crash reporting off immediately
  deleted the QA SDK cache. Metrics-only opt-in kept crash reports off and exercised the actual
  fixed metric counter path. Both were then turned off and the queue/cache were absent.
  Fixture runtime log: `/tmp/esemnbun-consent-native.log`.
- No personal preference domain, document, real card or PIN was used. Tests send only deliberately
  selected QA verification telemetry, never production-environment events.
- Plist, shell/Python syntax and whitespace checks passed. Production signing, symbol upload and
  production stack-symbolication acceptance remain pending external release credentials; no release
  was published. The existing `apple/scripts/upload-sentry-symbols.sh` uploads only compiled dSYMs
  and requires a CI `SENTRY_AUTH_TOKEN`.

Official references:

- https://docs.sentry.io/platforms/apple/configuration/options/
- https://docs.sentry.io/platforms/apple/dsym/
- https://github.com/getsentry/sentry-cocoa/releases/tag/9.32.0

## Native consent screenshots

Saved from the existing final Debug app, using isolated suite
`md.esemnbun.qa.consent-screenshots-20261031`, with no pre-granted consent:

- [First launch, both unchecked](/Users/nghimbovschi/Desktop/esemnbun-screenshots/macos/2026-10-31/sentry-consent/first-launch-both-off.png)
- [Settings after decline, both off](/Users/nghimbovschi/Desktop/esemnbun-screenshots/macos/2026-10-31/sentry-consent/settings-both-off.png)
- [Capture proof and hashes](/Users/nghimbovschi/Desktop/esemnbun-screenshots/macos/2026-10-31/sentry-consent/capture-proof.json)

Both controls and explanatory text fit the native sheet/settings layout. The QA user declined via
the native button; SDK cache remained absent and telemetry stayed disabled. The QA app was stopped
after capture. No rebuild or test repetition was needed for these screenshots.
