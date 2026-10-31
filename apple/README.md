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

## User demo mode

The persistent native setting, disclaimer, hardware interlock, mock output behavior and validation
are documented in [DEMO.md](DEMO.md).
