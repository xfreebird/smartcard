# Native application adjustments, 30 October 2026

## Source ownership and dependency boundaries

Platform shells remain grouped under `windows/`, `linux/`, `android/` and `apple/Apps/{macOS,iOS}`.
`apple/Apps/Shared` is shared Apple UI; `swift/MoldSignKit` is the shared Apple/Linux implementation,
including the shared CLI. It deliberately remains one source tree instead of copying cryptographic code
into each platform. `spec/` contains portable contracts; `scripts/` and `distribution/` contain orchestration
and store delivery inputs. SwiftPM, Gradle modules and .NET projects remain the module boundaries.

Responsibilities are now separated within each platform rather than only exposing constructors on a large
controller. The composition roots create concrete adapters; feature coordination depends on narrow ports.

| Platform | Presentation / application | Ports and infrastructure |
|---|---|---|
| Apple | Shared screens, observable AppModel, pure frozen-batch policy | CertificateReading, DocumentSigning, DocumentVerifying, ActivityStoring; file-access/output and activity adapters; standalone macOS reader watcher |
| Windows | WinUI views and feature presenters; separate desktop activation library | Reader source, signing/transport ports, preference/launch state storage, insertion snapshot source and application activator; independent watcher executable |
| Linux | Presentation, Application, Domain, Infrastructure folders | DocumentSigner/Verifier, BatchSigningService, SettingsCoordinator and storage, BridgeHost, LaunchStateStoring and ActivationPolicy |
| Android | Compose UI and presentation/MainViewModel; application coordination | ReaderGateway and DocumentAccess; USB and Storage Access Framework adapters; injectable SigningService; isolated Debug fixtures |

Android core source is grouped into application, card, crypto, formats, network and bridge responsibilities;
Gradle modules continue to enforce the Android-free core and USB adapter boundary. Public Kotlin package names
and platform identifiers stay stable. Apple/Linux cryptography remains one shared Swift package under
`swift/MoldSignKit`; duplicating that implementation per platform would create divergent signing protocols.
`spec/` is the cross-platform contract layer, not an application source folder.

SOLID is applied through focused responsibilities, interface substitution and dependency direction. This is
verified through builds, simulated card tests, frozen-batch tests and insertion-policy tests, rather than a
claim that directory moves alone prove the principles. No real PINs or card certificates are mock fixtures.

## Stable localization identifiers

`localization/catalog.json` owns all translated UI and store copy. Apple/Linux use generated typed `L10n.Key`
identifiers; Android uses native R resource IDs and Windows uses MRT IDs. Wording is never the runtime lookup
key. The exporter's check mode also rejects display-text calls in Swift. Changing copy preserves identifiers.
See `localization/README.md` for individual-platform exports.

## Screenshot drivers

All outputs go to dated subfolders under `~/Desktop/esemnbun-screenshots` on the main Mac. Capture only Debug
builds/explicit mock sources. Example dispatcher commands:

```sh
scripts/capture-screenshots.sh macos /path/to/Debug/eSemnBun.app "$HOME/Desktop/esemnbun-screenshots/macos/2026-10-30"
scripts/capture-screenshots.sh ios /path/to/Debug-simulator/eSemnBun.app "$HOME/Desktop/esemnbun-screenshots/ios/2026-10-30" SIMULATOR_UUID
scripts/capture-screenshots.sh android android/app/build/outputs/apk/debug/app-debug.apk "$HOME/Desktop/esemnbun-screenshots/android/2026-10-30" emulator-5554
```

Run `linux/scripts/capture-mocks-air.sh` on the Air with Fedora running, then copy its dated output back.
Run `windows/scripts/capture-scenarios.ps1 -App <Debug executable> -Output <folder>` in the Windows interactive
session (scheduled task with Interactive logon works). It captures pages as well as reader/card states.
The Linux script requires the existing `~/VMs/shots/v` VNC driver. No new privilege/Screen Recording wrapper
is installed by these drivers.

Coverage is a finite scenario matrix, not a claim that every possible backend/error combination has been
exercised. Apple fixtures include reader/card/loading/PIN/signing/results. Windows and Linux baselines focus
on reader/card/preferences states. Android covers nine wallet/document states across five pages and both themes, with phone and tablet layouts.
Cryptographic validity needs the separate core simulator suites and, when appropriate, a serialized real-card
session. A screenshot does not prove a signature valid. Review image content, not just file counts; a simulator
launch can return a PID while an image still shows SpringBoard.

## Linux HTTPS identity and Ubuntu

Packages bundle the vendor bridge identity (D-03). GUI and standalone CLI packages have separate owned paths,
and relocatable tarballs place the identity at `share/moldsign/localhost.p12` next to the executable tree.
The core resolves both executable-relative and standard XDG/system data locations. User imports can replace
the bundled identity. Localhost private-key material stays in the existing private repository/distribution
boundary and is never copied to a public paste/artifact service.

The Fedora VM verified a relocated CLI HTTPS certificate endpoint with ordinary TLS certificate validation.
Ubuntu 24.04 Noble userspace compiled the native GTK/libadwaita app in a container on Fedora. A real Ubuntu24.04 GNOME/Wayland desktop also runs the final native app and mock matrix; see the Ubuntu report under `docs/reports/`. Actual Flatpak Background portal permission UI and physical-card signing on Ubuntu still need runtime coverage.
Native XDG login-startup enable/disable was tested with isolated config and preserved unrelated autostart files.

## Store preparation

See `distribution/README.md` for listing export and portal state, and `apple/Configuration/README.md` for the
sandboxed Mac App Store candidate. Support/privacy URLs currently use owner-requested `.invalid` placeholders.
No store upload, agreement acceptance or certification submission is part of the export commands.

## Batch authorization

One frozen batch gets one authorization/PIN entry. Reader/certificate, filenames and formats stay bound to that
request. Duplicate starts while authorization is pending are rejected. The first error, cancellation or card
change stops processing without retrying a wrong PIN. Session credentials are released when the batch ends;
only explicit Remember writes to the platform vault. Each file still passes the core card identity check.

Portable Windows tests exercise mixed PDF/XML signatures with simulated cards; Apple policy tests cover pending
prompt overlap and frozen queue/context; Android core tests cover scope binding, independent PIN copies and
terminal cancellation/provider failure. Linux audit and isolated UI scenarios are documented separately.
Managed Swift/.NET strings do not promise physical memory erasure; Android's retained CharArray is wiped on close.
