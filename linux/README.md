# MoldSign for GNOME (Linux desktop app)

The native Linux desktop app: **Swift + GTK 4 + libadwaita**. It calls the GTK/libadwaita C API directly
through SwiftPM system-library targets. There are no wrapper packages, .NET, Electron or Python.
It links the same core as the macOS/iOS apps and the CLI (`../swift/MoldSignKit`).
Behavior mirrors the macOS app (`apple/Apps/Shared/Model/AppModel.swift`). The UI follows the GNOME HIG and
adapts docs/10's design system to libadwaita idioms.

Plan items: LNX-08…LNX-14 in [`../PLAN.md`](../PLAN.md) (referenced in code as `TODO(LNX-xx)`).

## Build and run on Linux

Requirements: GTK ≥ 4.12 and libadwaita ≥ 1.5 (Ubuntu 24.04, Debian 13, Fedora 40, or newer), plus a
Swift 6 toolchain from [swift.org](https://www.swift.org/install/linux/) or `swiftly`.

```bash
# Debian / Ubuntu
sudo apt install libadwaita-1-dev libsecret-1-dev libpcsclite-dev libssl-dev pkg-config \
                 pcscd libccid gnome-keyring
# Fedora
sudo dnf install libadwaita-devel libsecret-devel pcsc-lite-devel openssl-devel pcsc-lite pcsc-lite-ccid

sudo systemctl enable --now pcscd.socket     # the reader is reached through pcscd

cd linux
swift build                                  # debug
.build/debug/moldsign-gnome
swift build -c release --static-swift-stdlib # self-contained binary
```

The `moldsign` CLI (sign / verify / server from a terminal, spec/cli.md) is built from the core package:
`cd ../swift/MoldSignKit && swift build`. On Linux the core uses OpenSSL and POSIX sockets automatically.

Install the desktop integration for a non-Flatpak build:

```bash
install -Dm755 .build/release/moldsign-gnome ~/.local/bin/moldsign-gnome
install -Dm644 data/md.moldsign.MoldSign.desktop ~/.local/share/applications/md.moldsign.MoldSign.desktop
install -Dm644 data/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg ~/.local/share/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg
install -Dm644 data/icons/hicolor/symbolic/apps/md.moldsign.MoldSign-symbolic.svg ~/.local/share/icons/hicolor/symbolic/apps/md.moldsign.MoldSign-symbolic.svg
```

Flatpak (LNX-13, not built yet): see [`flatpak/md.moldsign.MoldSign.yml`](flatpak/md.moldsign.MoldSign.yml).
It uses `--socket=pcsc` for the reader, `--share=network` for the PKI services and the localhost bridge,
and `--talk-name=org.freedesktop.secrets` for the PIN vault.

## UI development on macOS

Homebrew's GTK stack compiles and runs this app on a Mac. That's handy for layout work. The Mac uses the
real PC/SC reader through PCSC.framework.

```bash
brew install gtk4 libadwaita libsecret pkgconf
brew install adwaita-icon-theme              # optional: symbolic icons (otherwise "missing image" glyphs)
cd linux && swift build && .build/debug/moldsign-gnome
```

* SwiftPM finds the libraries through `pkg-config` in `/opt/homebrew/bin`. No `PKG_CONFIG_PATH` is needed
  with a default Homebrew prefix. For another prefix, export `PKG_CONFIG_PATH=$(brew --prefix)/lib/pkgconfig`.
* `ld: warning: … built for newer version 26.0` lines are expected. Homebrew's bottles target the host
  macOS, while the package keeps MoldSignKit's macOS 14 floor. The app code itself builds warning-free.
* There is no Secret Service on macOS. The PIN vault reports itself unavailable, "Ține minte PIN-ul" is
  disabled, and the PIN is asked every time.
* There is no D-Bus session bus either, so GApplication runs non-unique. A second launch is a second
  process, and its bridge reports the ports as busy. With the bridge on, closing the window keeps the
  process running in the background (as on Linux); quit with Ctrl+Q or from the main menu.
* To keep test runs out of your real settings and history, point `XDG_CONFIG_HOME` / `XDG_DATA_HOME`
  at a scratch directory.
* **A card in the reader is real.** On every launch (and every card insert) the app reads the certificate
  without a PIN. That is a full mutual authentication, the same as the macOS app. Signing asks for the PIN.
  Each wrong PIN costs one attempt from the card's counter.

## Layout

```
Package.swift                 executable product moldsign-gnome; system libraries CAdwaita, CLibSecret
Sources/CAdwaita/             module.modulemap + shim.h (#include <adwaita.h>), pkg-config libadwaita-1
Sources/CLibSecret/           module.modulemap + shim.h (#include <libsecret/secret.h>), pkg-config libsecret-1
Sources/MoldSignGnome/
  main.swift                  --background handling, runs the application
  App.swift                   AdwApplication md.moldsign.MoldSign: actions/accels, window lifetime, background hold
  GLib/Gtk.swift              the thin C-API helper layer (see below)
  GLib/Files.swift            GtkFileDialog, GtkDropTarget (GdkFileList), GtkFileLauncher
  Model/Models.swift          ReaderStatus, SignFormat, Verdict, ActivityItem… (toolkit-free; same copy as macOS)
  Model/AppController.swift   app state + flows: reader, sign, PIN, verify, bridge, activity (mirrors AppModel)
  Services/ReaderMonitor.swift PC/SC polling (LNX-08)
  Services/PinVault.swift     libsecret, schema md.moldsign.pin, attribute cert = SHA-1 (LNX-10)
  Services/Store.swift        settings.json ($XDG_CONFIG_HOME/moldsign), activity.json ($XDG_DATA_HOME/moldsign)
  UI/MainWindow.swift         AdwToolbarView: header + view switcher, banner, toasts, view stack, breakpoint
  UI/SignPage.swift           drop zone, file rows + format chips, step progress, result, primary button
  UI/VerifyPage.swift         drop/choose → AdwStatusPage verdict + one group per signature
  UI/ActivityPage.swift       last 100 entries
  UI/CardPage.swift           certificate, stored PIN, troubleshooting
  UI/Dialogs.swift            PIN, consent, confirmation (AdwAlertDialog), preferences, about
  UI/Style.swift              app CSS on libadwaita named colors
data/                         .desktop, AppStream metainfo, scalable + symbolic icons (LNX-14)
flatpak/                      Flatpak manifest (LNX-13)
```

### The C-API helper layer (`GLib/Gtk.swift`)

Swift imports the GTK headers directly. The helper layer only fills the gaps the importer leaves:

* **Casts.** `GTK_BOX(w)`-style macros don't import. Derivable types arrive as `UnsafeMutablePointer<T>`
  and final types as `OpaquePointer`. `GPointer.cast()` / `.opaque` / `.widget` convert between them,
  unchecked like the C macros.
* **Signals.** `g_signal_connect` is a macro. `onSignal(obj, "clicked") { … }` calls
  `g_signal_connect_data` with a `@convention(c)` thunk and boxes the closure through `Unmanaged`. A
  `GClosureNotify` releases the box. The closure shape must match the signal. Use `{ }` for
  `(instance, data)`, `{ arg in }` for one pointer argument (`response`, `notify::…`, `GSimpleAction::activate`),
  and the dedicated helpers for `close-request`, `drop` and `open`.
* **Main loop.** GLib owns the main loop, so `DispatchQueue.main` is never drained on Linux. Use
  `onMain { }` (`g_idle_add_full`) to get back to the GTK thread from background work.
* **Async GIO calls.** `asyncReady { result in }` makes a one-shot `GAsyncReadyCallback`.
* **Variadic C functions** (`g_object_set`, `secret_password_store_sync`, `adw_breakpoint_add_setters`,
  `gtk_accessible_update_property`) don't import. The code uses their non-variadic forms: GValue setters,
  the `…v_sync` libsecret calls and `gtk_accessible_update_property_value`.
* Recent GLib (2.90 on Homebrew) marks `GApplicationFlags` as a flag enum, which renames its Swift constants. The code passes
  raw values so it builds against every GLib.

## Behavior (contracts from docs/09)

* **Threading.** Everything in the core blocks. Card, vault and validation calls run on background
  queues; UI state lives on the GTK thread. The core serializes card access (one card operation at a time).
* **Reader monitor (LNX-08).** Polls `PCSCTransport.readerStates()` every second without connecting.
  When a card appears, it reads the certificate without a PIN so the UI can greet the holder.
* **PIN (LNX-10).** The PIN dialog takes 4–8 digits and shows the remaining attempts. "Ține minte PIN-ul"
  stores the PIN in the Secret Service, keyed by the certificate SHA-1, and only after the card accepted it.
  A wrong or blocked PIN deletes the stored one, and the PIN is never retried automatically. The Secret
  Service has no per-read user-presence gate, so a stored PIN is always used after a confirmation dialog.
  That dialog is the consent step.
* **Bridge (LNX-11).** `MoldSignServer` starts with the app when the setting is on (Preferences → Conexiune
  browser). Every request shows the consent dialog (origin host, document, format, holder, "Ai încredere în
  site 10 minute"), and the PIN dialog follows unless the page sent a PIN. When the vendor suite holds
  18480/18443, a banner offers "Reîncearcă".
* **Background (LNX-12).** With the bridge running and "Rulează în fundal" on, closing the window hides it
  and `g_application_hold()` keeps the process (and the bridge) alive. Launching the app again shows the
  window. `--background` starts without a window (for autostart). The Background portal and the
  autostart toggle are still TODO.

## Known gaps / TODO

| ID | What |
|---|---|
| LNX-08 | Event-driven monitor: blocking `SCardGetStatusChange` on `\\?PnP?\Notification` + `SCardCancel` instead of 1 s polling. Telling "pcscd not running" from "no reader" needs a core API (`readerStates()` returns `[]` for both). |
| LNX-09 | Detached XAdES: inline picker for signed files that are not next to the `.xml`. Opțiuni avansate (output folder). Translations (`ru`, `en`) via gettext. |
| LNX-10 | Optional per-use gate for the stored PIN (polkit `auth_self`, or a dedicated locked collection). |
| LNX-11 | The bridge can't report a wrong PIN back to the host, so a stored PIN that became wrong (changed elsewhere) is not deleted after a bridge signature. Needs a core callback. |
| LNX-12 | Background portal `RequestBackground` (+ autostart), so GNOME lists the app under Background Apps and Flatpak keeps it alive. |
| LNX-13 | Flatpak: verify the Swift SDK extension, the pcsc-lite module and the checksum; decide how the bridge TLS identity is provided (D-03). |
| LNX-14 | Final icon, screenshots in metainfo, project license. |
