# eSemnBun for GNOME (Linux desktop app)

The native Linux desktop app: **Swift + GTK 4 + libadwaita**. It calls the GTK/libadwaita C API directly
through SwiftPM system-library targets. There are no wrapper packages, .NET, Electron or Python.
It links the same core as the macOS/iOS apps and the CLI (`../swift/MoldSignKit`).
Behavior mirrors the macOS app (`apple/Apps/Shared/Model/AppModel.swift`). The UI follows the GNOME HIG and
implements docs/10 §0 (status light) and §0.2b ("v3": ID-card face, card and selector as one component).

**Names (UX-12).** The public name is **eSemnBun**: window title, About, `.desktop` / metainfo name, the
`esemnbun-gnome` binary, the `esemnbun` CLI, the `esemnbun` / `esemnbun-cli` packages and the
`esemnbun-server.service` user unit. The codename stays in code and IDs: app ID `md.moldsign.MoldSign` (and the
data file names), the Swift module `MoldSignGnome`, settings/activity paths (`…/moldsign/`), the Secret Service
schema `md.moldsign.pin`, `MSIGN_*` variables. Vendor references stay "MoldSign" (MoldSign Desktop, its bridge protocol).

Plan items: LNX-06…LNX-15, UX-01, UX-02, UX-07, UX-09…UX-12 in [`../PLAN.md`](../PLAN.md) (referenced in code as `TODO(LNX-xx)`).

## Design (docs/10 §0, §0.2b)

* **ID-card face (UX-09).** The inserted card is drawn with cairo + Pango (`UI/CardArt.swift`) as a stylized
  illustration of the Moldovan identity card: pastel paper, guilloche waves and a rosette (hue rotated ±20° per
  card from the certificate SHA-1), "REPUBLICA MOLDOVA / REPUBLIC OF MOLDOVA" and "CARTE DE IDENTITATE / IDENTITY
  CARD", a **neutral shield outline** (never the coat of arms), the gold chip, a grey portrait frame with a
  silhouette, and the fields Numele/Surname, Prenumele/Given name(s), Valabil până la/Valid until (`dd MM yyyy`,
  the certificate's notAfter) and Emitent/Issuer, taken from the signing certificate only (SN/GN, else the CN split
  at the first space). No photo, document number, MRZ or IDNP. A status strip at the bottom: green "Pregătit
  pentru semnare", amber "Se citește cardul…" (placeholder bars instead of values), blue "Se semnează…", red
  problem text, and the reader as a caption on large cards. Fixed colors in light and dark, a hairline and a
  CSS shadow; sizes relative to the width (340 × 214, or 260 × 164 in windows ≤ 420sp).
* **Card + selector = one component (UX-10, revised).** Nothing sits outside the card. Collapsed, the
  component shows only the selected card. With more than one card, a round disclosure button sits inside the
  card (right edge, vertically centred; field values stop at 0.88 W). It expands the component in place (each
  card in a `GtkRevealer`, slide-down 250 ms, no motion when animations are off) into a vertical list of every
  card: same size, 12 px apart, reader order. The selected card keeps an accent outline and the disclosure (now
  pointing down), and its status strip reads "✓ Folosit pentru semnare" in brand blue (the others keep
  "● Pregătit pentru semnare"). Click a card → it signs from now on and the list
  collapses; the disclosure, Escape or a click on the selected card collapse without a change. ↑/↓ move between
  the listed cards; ←/→/Home/End switch cards while collapsed. Right-click, long-press, Menu or Shift+F10 open
  "Recitește cardul" plus "Semnează cu {holder}" for the other cards. A click on the collapsed card opens the Card
  page. Accessibility: collapsed, the card is one element ("{holder}, card de identitate, valabil până la …, {i}
  din {n}"); the disclosure is "Alege cardul ({n} carduri)" with the expanded state; expanded, each card is a
  button "Semnează cu {holder}" and the selected one reports *selected*. A change of card is announced. The header
  bar has a re-read button.
* **Empty states are cards too.** Reader without a card: dashed "Introdu cardul". No reader: reader + cable
  "Conectează cititorul". PC/SC down or a mute card: a red-tinted card with the recovery text and "Reîncearcă".
  On the Card page these are `AdwStatusPage`s with the card illustration. (These follow the theme.)
* **Status (UX-01, UX-11).** GNOME has no tray. The Background portal (`org.freedesktop.portal.Background.SetStatus`,
  Quick Settings → Background Apps) gets the two-state text: "Card conectat · {holder}" while at least one card
  is inserted (reading, ready or signing), otherwise "Niciun card conectat" or the error's one-liner. The window
  keeps the five-state light in the Semnează action bar: green ready, amber reader only / reading, blue signing
  (also a browser request), red error, no dot when nothing is connected. Without a session bus or portal (macOS,
  old portals) the portal part is logged once and skipped.
* **Documents (Semnează).** The list of added documents comes first; the drop zone ("Trage documentele aici" +
  "Alege fișiere…") is large while the list is empty and stays, compact, under it afterwards. Every PDF row offers
  PAdES-T (default), XAdES-BES, XAdES-T and XAdES-C (detached XAdES over the PDF bytes → `<name>-semnat.xml`);
  other files offer the XAdES levels. "Semnează" drops `suggested-action` while it is disabled.
* **Activity.** File entries show only while the file still exists (pruned on load, re-checked whenever the page
  is shown and once a minute); browser requests (no file) always stay. "Golește lista" asks first
  (`AdwAlertDialog`, destructive); signed documents stay on disk.
* GNOME HIG: `AdwToast` for outcomes ("Document semnat" · "Arată"), one suggested-action pill (Semnează),
  `AdwPreferencesDialog`, `AdwAlertDialog` for PIN and consent, `AdwBanner` only for the bridge's busy ports.

### Demo mode (debug builds only)

`MOLDSIGN_DEMO` is defined for `swift build` (debug) only, so release builds and packages don't contain it.

```bash
MSIGN_DEMO_CARDS=2 .build/debug/esemnbun-gnome          # two fake, readable cards (1…4)
MSIGN_DEMO_CARDS=empty|noreader|error|pcscd …           # the empty / error states
MSIGN_DEMO_PAGE=card MSIGN_DEMO_WINDOW=400x760 …        # open a page, set the window size (screenshots)
ADW_DEBUG_COLOR_SCHEME=prefer-dark …                    # dark style (libadwaita)
```

The fake cards carry self-made EC test certificates of fictional people (`Model/DemoMode.swift`). Demo mode never touches PC/SC,
the keyring or the network: the bridge does not start and "Semnează" only shows a toast.

## Build and run on Linux

Requirements: GTK ≥ 4.14 and libadwaita ≥ 1.5 (Ubuntu 24.04, Debian 13, Fedora 40, or newer), plus a
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
.build/debug/esemnbun-gnome
swift build -c release --static-swift-stdlib # self-contained binary
```

The `esemnbun` CLI (sign / verify / server from a terminal, spec/cli.md) is built from the core package:
`cd ../swift/MoldSignKit && swift build`. On Linux the core uses OpenSSL and POSIX sockets automatically.

Install a local build into `~/.local` (same layout as the packages; the GNOME app needs both release builds
only for `all`):

```bash
(cd ../swift/MoldSignKit && swift build -c release --product esemnbun --static-swift-stdlib)
swift build -c release --static-swift-stdlib
packaging/install.sh "" ~/.local all          # bin/, share/{applications,metainfo,icons,systemd/user}
```

## Packages (LNX-07, LNX-13, LNX-15)

`scripts/package-linux.sh` (run on Linux, from the repository root) builds the CLI and the GNOME app in
release mode with the static Swift stdlib, stages them with [`packaging/install.sh`](packaging/install.sh), and
writes `dist/linux/`. A package whose tool is missing is skipped with a message. CI (`linux` job) runs it and
uploads the tarball, `.deb` and `.rpm` as artifacts.

| Package | Contents | Built with |
|---|---|---|
| `eSemnBun-<v>.flatpak` | the GNOME app (primary for GNOME), app ID `md.moldsign.MoldSign` | `flatpak-builder`, [`flatpak/md.moldsign.MoldSign.yml`](flatpak/md.moldsign.MoldSign.yml) |
| `esemnbun_<v>-1_<arch>.deb` | GNOME app `esemnbun-gnome`; Depends pcscd, libccid, libpcsclite1, libadwaita-1-0, libsecret-1-0, libssl3t64 \| libssl3 | `dpkg-buildpackage`, [`packaging/debian/`](packaging/debian) |
| `esemnbun-cli_<v>-1_<arch>.deb` | `esemnbun` CLI + `esemnbun-server.service` (systemd user unit) | same |
| `esemnbun-<v>-1.<arch>.rpm`, `esemnbun-cli-…rpm` | same split, Fedora names (pcsc-lite, pcsc-lite-ccid, libadwaita, libsecret, openssl-libs) | `rpmbuild`, [`packaging/rpm/esemnbun.spec`](packaging/rpm/esemnbun.spec) |
| `esemnbun-<v>-linux-<arch>.tar.gz` | the CLI (static Swift stdlib) + the user unit | `tar` |

```bash
sudo apt install dpkg-dev debhelper rpm flatpak flatpak-builder   # whichever packages you want
scripts/package-linux.sh                                          # or MOLDSIGN_PACKAGES="deb rpm" …
```

The packaging definitions also work on their own: `cp -r linux/packaging/debian . && dpkg-buildpackage -us -uc -b -d`
from the repository root, or `rpmbuild -bb --define "moldsign_src $PWD" linux/packaging/rpm/esemnbun.spec`
(`swift` on `PATH`; the swift.org toolchain is not a distro package, hence `-d` / `--nodeps`).
The RPMs that CI builds on Ubuntu link against Ubuntu 24.04's libraries. Fedora users should build them on
Fedora (glibc ≥ 2.39, same sonames).

### Flatpak

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak-builder --user --install-deps-from=flathub --force-clean --install build-dir linux/flatpak/md.moldsign.MoldSign.yml
flatpak run md.moldsign.MoldSign
```

Runtime `org.gnome.Platform//51` (freedesktop-sdk 26.08) with the `org.freedesktop.Sdk.Extension.swift6` toolchain
(same branch). pcsc-lite's client library is built as a module (the runtime does not ship it; pcscd is the
host's). Permissions: `--socket=pcsc` (reader), `--share=network` (TSA/OCSP/CRL and the loopback bridge),
`--talk-name=org.freedesktop.secrets` (PIN vault), `--filesystem=xdg-documents` (fallback output folder).
The Background portal needs no permission.

### Browser bridge as a user service (LNX-06)

`esemnbun-cli` ships `esemnbun-server.service`, **not enabled by default**:

```bash
systemctl --user enable --now esemnbun-server.service
journalctl --user -u esemnbun-server.service -f
```

It has no consent or PIN dialog (headless): a page that does not send the PIN gets an error. For consent
and PIN dialogs, use the GNOME app's "Conexiune browser" instead. Run one or the other, never both, and not
alongside MoldSign Desktop: they all need 18480/18443.

### Bridge TLS identity

The HTTPS listener (`localhost.cts.md:18443`) needs the vendor's `localhost.p12` (see AGENTS.md §5). It is never
packaged. In the GNOME app, use **Preferences → Conexiune browser → Identitate HTTPS MoldSign → Importă…**,
or the **Importă…** button in the setup banner. Select the `localhost.p12` exported from MoldSign Desktop
(not a personal signing certificate). The app validates it before replacing the installed copy, stores it
with mode 0600, and restarts an enabled bridge. The file picker also works inside Flatpak.

Alternatively, copy it to `~/.local/share/moldsign/localhost.p12`, or for Flatpak to
`~/.var/app/md.moldsign.MoldSign/data/moldsign/localhost.p12`. `MSIGN_TLS_P12=<path>` overrides the location.
The GUI now requires a usable HTTPS identity instead of claiming the browser connection is active with
only HTTP. The CLI server can still run HTTP-only (127.0.0.1:18480), but that is not enough for msign.gov.md.
Run the browser on the same Linux machine as the app: `localhost.cts.md` points to that machine's loopback.

### Reader setup (pcscd, udev)

* Install `pcscd` + `libccid` (Fedora: `pcsc-lite` + `pcsc-lite-ccid`) and enable socket activation:
  `sudo systemctl enable --now pcscd.socket`. The packages depend on both.
* No custom udev rule is needed. The bit4id miniLector is a CCID reader, and libccid's own udev rules plus pcscd's
  polkit policy give the active local session access. Over SSH or in a container, polkit refuses the access
  (`pcsc_scan` from `pcsc-tools` shows that). Run from the desktop session, or adjust
  `org.debian.pcsc-lite.access_pcsc` / `access_card` in polkit.
* Flatpak and Snap-confined browsers: the bridge is plain loopback TCP and needs nothing extra.
* The app shows "Serviciul PC/SC nu rulează" when pcscd doesn't answer, and "Conectează cititorul" when it runs
  without a reader.

## UI development on macOS

Homebrew's GTK stack compiles and runs this app on a Mac. That's handy for layout work. The Mac uses the
real PC/SC reader through PCSC.framework.

```bash
brew install gtk4 libadwaita libsecret pkgconf
brew install adwaita-icon-theme              # optional: symbolic icons (otherwise "missing image" glyphs)
cd linux && swift build && .build/debug/esemnbun-gnome
```

* Run with `MSIGN_DEMO_CARDS=2` for UI work without touching the cards (see Demo mode).
* GTK on macOS runs at 72 dpi, so `sp` breakpoints trigger at 0.75× the Linux pixel width (the 420sp compact
  cards need a 315 px window there, below the 360 px minimum).
* SwiftPM finds the libraries through `pkg-config` in `/opt/homebrew/bin`. No `PKG_CONFIG_PATH` is needed
  with a default Homebrew prefix. For another prefix, export `PKG_CONFIG_PATH=$(brew --prefix)/lib/pkgconfig`.
* `ld: warning: … built for newer version 26.0` lines are expected. Homebrew's bottles target the host
  macOS, while the package keeps MoldSignKit's macOS 14 floor. The app code itself builds warning-free.
* There is no Secret Service on macOS. The PIN vault reports itself unavailable, "Ține minte PIN-ul" is
  disabled, and the PIN is asked every time.
* There is no D-Bus session bus either, so GApplication runs non-unique and the Background portal is skipped. A second launch is a second
  process, and its bridge reports the ports as busy. With the bridge on, closing the window keeps the
  process running in the background (as on Linux); quit with Ctrl+Q or from the main menu.
* To keep test runs out of your real settings and history, point `XDG_CONFIG_HOME` / `XDG_DATA_HOME`
  at a scratch directory.
* **A card in the reader is real.** On every launch (and every card insert) the app reads the certificate
  without a PIN. That is a full mutual authentication, the same as the macOS app. Signing asks for the PIN.
  Each wrong PIN costs one attempt from the card's counter.

## Layout

```
Package.swift                 executable product esemnbun-gnome; system libraries CAdwaita, CLibSecret;
                              MOLDSIGN_DEMO defined for debug builds
Sources/CAdwaita/             module.modulemap + shim.h (#include <adwaita.h>), pkg-config libadwaita-1
Sources/CLibSecret/           module.modulemap + shim.h (#include <libsecret/secret.h>), pkg-config libsecret-1
Sources/MoldSignGnome/
  main.swift                  --background handling, runs the application
  App.swift                   AdwApplication md.moldsign.MoldSign: actions/accels, window lifetime, background hold
  GLib/Gtk.swift              the thin C-API helper layer (see below)
  GLib/Files.swift            GtkFileDialog, GtkDropTarget (GdkFileList), GtkFileLauncher
  Model/Models.swift          ReaderStatus, SignFormat, Verdict, ActivityItem… (toolkit-free; same copy as macOS)
  Model/AppController.swift   app state + flows: reader, sign, PIN, verify, bridge, activity (mirrors AppModel)
  Model/DemoMode.swift        MSIGN_DEMO_CARDS fake cards (debug builds only)
  Services/ReaderMonitor.swift PC/SC polling (LNX-08)
  Services/BackgroundPortal.swift  GDBus: Background portal SetStatus (status light) + RequestBackground
  Services/PinVault.swift     libsecret, schema md.moldsign.pin, attribute cert = SHA-1 (LNX-10)
  Services/Store.swift        settings.json ($XDG_CONFIG_HOME/moldsign), activity.json ($XDG_DATA_HOME/moldsign)
  UI/MainWindow.swift         AdwToolbarView: header (re-read, view switcher, menu), banner, toasts, view stack, breakpoints
  UI/CardWallet.swift         card + selector component: revealer list, disclosure, check badge, menus, keys, placeholders
  UI/CardArt.swift            cairo + Pango: the ID-card face (§0.2b) and the placeholder cards
  UI/SignPage.swift           wallet, drop zone, file rows + format chips, step progress, result, status light, primary button
  UI/VerifyPage.swift         drop/choose → AdwStatusPage verdict + one group per signature
  UI/ActivityPage.swift       last 100 entries
  UI/CardPage.swift           wallet + selected card's certificate, stored PIN, troubleshooting; AdwStatusPage when empty
  UI/Dialogs.swift            PIN, consent, confirmation (AdwAlertDialog), preferences, about
  UI/Style.swift              app CSS on libadwaita named colors
data/                         .desktop, AppStream metainfo, scalable + symbolic icons (LNX-14)
flatpak/                      Flatpak manifest (LNX-13)
packaging/install.sh          staging installer shared by every package
packaging/debian/             Debian packaging: esemnbun + esemnbun-cli (LNX-15)
packaging/rpm/esemnbun.spec   RPM packaging: esemnbun + esemnbun-cli (LNX-15)
packaging/systemd/            esemnbun-server.service.in, the bridge as a systemd --user unit (LNX-06)
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
  and the dedicated helpers for `close-request`, `drop`, `open`, gestures (`onClickPressed`, `onLongPressed`)
  and keys (`onKeyPressed`). Signals with integer arguments need their own thunk (the upper half of a pointer
  register is undefined).
* **Drawing.** `setDrawFunc(area) { cr, w, h in }` wraps `gtk_drawing_area_set_draw_func` (cairo calls are plain C).
* **GVariant / GDBus.** `g_variant_new` is variadic: build values with the typed constructors and a
  `GVariantBuilder` (see `BackgroundPortal.swift`). `GDBusCallFlags` is a flag enum too: raw values.
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
* **Background (LNX-12).** With the bridge running and "Rulează în fundal" on, closing the window hides it,
  `g_application_hold()` keeps the process (and the bridge) alive, and the app asks the Background portal
  (`RequestBackground`, no autostart). Launching the app again shows the window. `--background` starts without
  a window (for autostart). The autostart toggle is still TODO.
* **Status (UX-11).** The two-state text goes to the Background portal's `SetStatus` on every change
  (deduplicated, ≤ 96 characters).

## Known gaps / TODO

| ID | What |
|---|---|
| LNX-08 | Event-driven monitor: blocking `SCardGetStatusChange` on `\\?PnP?\Notification` + `SCardCancel` instead of 1 s polling. |
| LNX-09 | Detached XAdES: inline picker for signed files that are not next to the `.xml`. Opțiuni avansate (output folder). Translations (`ru`, `en`) via gettext. |
| LNX-10 | Optional per-use gate for the stored PIN (polkit `auth_self`, or a dedicated locked collection). |
| LNX-12 | Autostart toggle (`RequestBackground` with `autostart: true` + `--background`). |
| LNX-13 | First real Flatpak build (CI has no privileged container for `flatpak-builder` yet). Check that Swift 6.4's static Foundation links in the 26.08 SDK and that `--socket=pcsc` reaches the reader. |
| LNX-14 | Final icon, screenshots in metainfo, project license (also `debian/copyright`, the spec's `License:`, the maintainer address). |
| LNX-15 | Run the `.deb`/`.rpm` on Ubuntu 24.04 and Fedora: install, launch from the overview, `systemctl --user start esemnbun-server`. Build the RPM on Fedora itself. Sign the packages / publish a repository. |
| UX-01 | Blue status light for bridge requests starts when the request is approved, not when it arrives. On host (non-Flatpak) installs the Background Apps list may not show the app (GNOME lists sandboxed apps there). |
| UX-09 | The headings shrink to fit the system font next to the chip (Cantarell/Inter are wider than the spec's reference); long field values shrink (to 70 %) before they are cut. |
| UX-10 | GTK has no "adjustable" accessible role, so increment/decrement on the collapsed card is not exposed: ←/→ and the disclosure list are the accessible ways to change cards. |
