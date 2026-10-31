# Apple application source ownership

`Apps/Shared` contains the shared Apple presentation layer. `Apps/macOS` and `Apps/iOS`
contain the native application shells and integrations; `Helpers/ReaderWatcher` is the
separate direct-distribution macOS activation utility. The cross-platform Swift protocol
implementation remains in `../swift/MoldSignKit` and is not duplicated into either app.

Responsibilities and dependency boundaries:

- `Shared/Model/AppModel` coordinates observable presentation state and user flows.
- `Shared/Services/Documents` defines independent `CertificateReading`, `DocumentSigning`
  and `DocumentVerifying` ports. Core adapters own security-scoped file access, detached
  file lookup and output policy. A scenario can replace each port independently.
- `Shared/Services/Activity` defines activity persistence independently of signing/UI.
- `Shared/Services/SigningBatchRunner` owns the frozen batch and single-authorization policy.
- `Shared/Services/ReaderMonitor` and `PinVault` expose reader and credential ports.
- `macOS/Startup` manages the system background-item registration, separately from UI and
  signing. The helper observes slot presence only and never constructs a signing service.
- `Shared/Screens` and `Shared/DesignSystem` compose native views and reusable artwork.
- `Shared/Services/L10n.swift` and the string catalog are generated from the shared keyed
  catalog. Use typed `L10n.text(.key)` references; translated prose is never a lookup key.

The app model accepts reader, credential, certificate, signing, verification and activity
implementations through its initializer. Debug demo scenarios bypass hardware and the bridge,
use an in-memory vault/activity store, and optionally use a separate preferences domain.
`MSIGN_DEMO_PREFERENCES_SUITE` must start with `md.esemnbun.qa.`. Release builds ignore it.

See `scripts/README.md` for captures and `Helpers/ReaderWatcher/README.md` for activation.
The App Store configuration excludes the separate helper and uses CryptoTokenKit/container
output/native export. Signing credentials are not part of this source tree.

## Optional macOS diagnostics

Sentry Cocoa9.32.0 is linked only by the macOS target. iOS does not initialize or link Sentry and
its privacy manifest declares no diagnostics collection. Shared signing calls have a no-op mobile
monitoring facade so document behavior is unchanged.

The desktop main window asks every user on the first undecided launch whether to send crash reports
and application metrics. Both choices start **off**. Saving or declining records the decision; a
recorded decline is not requested again. The same independent toggles are in Settings → General.
Unknown or declined consent never initializes the SDK or opens its transport. Enabling crash reports
controls crash/handled-error capture; enabling metrics controls fixed-name counters (`app.launch`,
`document.sign`) and startup/signing duration traces independently. No category enables the other.

Changing either choice first revokes the old generation's event gate, cancels and invalidates its
private ephemeral URLSession, closes SDK integrations with zero shutdown wait, and purges its
isolated cache/queue. A later opt-in uses a new cache epoch; callbacks from a previous generation
cannot acquire the new consent. The SDK's internal close flush has no live transport to deliver on.
No explicit final flush is performed on opt-out. An unchanged prior opt-in may resume only its
consent-compatible crash queue on the next launch.

The privacy boundary strips users, requests, arbitrary extras/contexts, exception descriptions,
frame locals/registers/source excerpts and absolute binary paths. Automatic network/file/UI
instrumentation, memory introspection, breadcrumbs, screenshots, replay, view hierarchy, logs and
sessions are disabled. Only finite diagnostic codes, numeric counters and fixed operation names
are permitted. Metrics attributes are limited to fixed release/environment/platform values.

Screenshot fixtures stay silent and hide the first-launch consent sheet by default. To exercise
consent deliberately, use an isolated `MSIGN_DEMO_PREFERENCES_SUITE=md.esemnbun.qa.<name>` plus
`MSIGN_DEMO_CARDS=none MSIGN_DEMO_PREVIEW=0 MSIGN_SENTRY_CONSENT_QA=1` on a Debug macOS app.
The sheet still requires explicit choices; these flags do not authorize telemetry. Adding
`MSIGN_SENTRY_VERIFY=1` requests one handled verification error **only after crash consent**.
`apple/scripts/verify-sentry-macos.py <Debug-app-bundle>` launches that isolated fixture and waits
for an explicit selection. Never use real card/PIN/document data for verification.

For opted-in release crash symbolication, install `sentry-cli`, inject `SENTRY_AUTH_TOKEN` from the CI
secret store, and run `apple/scripts/upload-sentry-symbols.sh <archive-or-dSYM-directory>`. It uploads
compiled symbols without source context, stores no token, and publishes no app.

## User demo mode

The persistent native setting, disclaimer, hardware interlock, mock output behavior and validation
are documented in [DEMO.md](DEMO.md).
