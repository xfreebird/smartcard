# Ubuntu 24.04 desktop validation — 2026-10-30

Started October 30; completed October 31, 2026 (Europe/Chisinau). Evidence retains the session's October 30 directory.

The native GNOME app was built and exercised in a separate Ubuntu ARM64 virtual machine on the MacBook Air. This extends the earlier Ubuntu container compilation check to a real GNOME/Wayland desktop, including the distro's older GTK and libadwaita versions.

## Environment and provenance

| Component | Verified value |
| --- | --- |
| OS | Ubuntu 24.04.5 LTS, Noble, ARM64 |
| Kernel | 6.8.0-147-generic |
| Desktop | Ubuntu GNOME 46.0, Wayland |
| GTK | 4.14.5+ds-0ubuntu0.10 |
| libadwaita | 1.5.0-1ubuntu2 |
| Compiler | Official Swift 6.2.4, aarch64-unknown-linux-gnu |
| VM | QEMU 11.1.1 + HVF, 4 CPUs, 6 GB RAM, separate 48 GB qcow2 disk |
| Display | 1600 × 1000, scale 1; app fixture window 1100 × 780 |

The base is Canonical's [Noble ARM64 cloud image](https://cloud-images.ubuntu.com/noble/current/), downloaded over HTTPS and checked against its [SHA256SUMS](https://cloud-images.ubuntu.com/noble/current/SHA256SUMS):

```text
50e24e1fb79e89116e939d90aa7738f7af48c442fa1bc2510131e0b39c50348e  noble-server-cloudimg-arm64.img
```

`ubuntu-desktop-minimal`, development dependencies and GNOME were installed from Ubuntu's package repositories. The initial container build used the official `swift:6.2-noble` image (Swift 6.2.4). The final corrected application was compiled directly inside the desktop VM using the [official Swift 6.2.4 Ubuntu 24.04 ARM64 toolchain](https://download.swift.org/swift-6.2.4-release/ubuntu2404-aarch64/swift-6.2.4-RELEASE/swift-6.2.4-RELEASE-ubuntu24.04-aarch64.tar.gz).

Host files are under `/Users/user/VMs/ubuntu`. SSH is `127.0.0.1:2224` on the Air, and the QEMU VNC console is `127.0.0.1:5903`. The VM runs as the normal Air user, with no USB reader attached. Guest administration uses public-key SSH and guest-only passwordless sudo. No new host sudo or Screen Recording wrapper was created.

During cloud-image conversion, the desktop installation introduced NetworkManager alongside networkd. The guest was given explicit static NoCloud networking (`10.0.2.15/24`, gateway `10.0.2.2`, DNS `10.0.2.3`, networkd) and NetworkManager was disabled in this test VM. The GDM autologin configuration was preserved through package configuration. These are guest provisioning details, not application changes.

## Compatibility fix found on the actual desktop

The first native launch produced repeated `g_value_get_int: assertion 'G_VALUE_HOLDS_INT (value)' failed` messages. Running it under GDB with `G_DEBUG=fatal-criticals` traced the failure through `gtk_accessible_update_state_value` to `setAccessibleState` in `linux/Sources/MoldSignGnome/GLib/Gtk.swift`, called for the card disclosure's expanded state.

The helper supplied a boolean `GValue` for every boolean-like state. GTK's `EXPANDED` and `SELECTED` states also represent undefined, and GTK 4.14 expects integer-backed values for them. The helper now calls [`gtk_accessible_state_init_value`](https://docs.gtk.org/gtk4/type_func.AccessibleState.init_value.html) and writes the type GTK initialized. The change preserves card geometry and selection logic while making the accessibility state valid.

The corrected helper was also compiled and run on Fedora with GTK 4.22.5 / libadwaita 1.9.4 under `G_DEBUG=fatal-criticals`, using the four-card selected-middle fixture. It reached its readiness marker and remained alive without GLib criticals.

Visual inspection also found three language gaps: the Card tab and PIN placeholder lacked Linux catalog entries, and libadwaita's preferences title followed the desktop language instead of the app preference. The central catalog now supplies the missing translations, and the preferences dialog explicitly uses the existing localized title. All 26 affected language/preferences/PIN screenshots were refreshed after these text-only changes.

A final bounded copy review localized the no-reader example caption, stored-PIN confirmation, document counts and results, remaining PIN attempts, HTTPS import errors, browser activity summaries and the selected-card announcement. Dynamic values now pass through numbered placeholders instead of being interpolated into Romanian sentences before translation. The 13 new catalog entries were checked in Romanian, English and Russian by a native Swift harness: **39 template checks plus two substitution checks passed**, including a literal percent-placeholder inside a filename. Fourteen existing no-reader/PIN/result/activity screenshots were refreshed on each distro after this pass.

## Verification

- Native Ubuntu debug app compilation passed in 5.79 seconds after installing the required development tools.
- The final language corrections rebuilt successfully in 1.87 seconds. Fedora's matching final source rebuilt in 1.63 seconds.
- Native Ubuntu core tests: **38 discovered, 31 passed, 7 skipped, 0 failures**, in 3.78 seconds. Three opt-in live PKI tests were skipped; four tests required vendor signature fixtures absent from the copied source snapshot.
- The non-demo GNOME app automatically found the bundled HTTPS identity. A request to `https://localhost.cts.md:18443/certificates` with the allowed portal origin returned **200** and `{"certificateModel":[]}`. Curl used normal system CA and hostname verification, with no insecure flag or custom trust override. A disallowed origin returned **403**.
- The CLI reported that no card reader was present, matching the VM configuration.

The final Ubuntu debug GNOME executable SHA-256 used for the affected screenshot refresh is:

```text
21b16a869b0d8298afd60b2f3a43748b8ae25d62008c1ea3a7b5eca2c780b67a
```

The screenshot runner is `linux/scripts/capture-ubuntu-air.sh`. It uses a new isolated configuration/data directory for each run, checks each app readiness marker against the requested scenario, language, page and run identifier, and enables `G_DEBUG=fatal-criticals`. Its matrix covers no-reader/no-card/service/error states, one/two/four cards, selected-middle centering, Romanian/English/Russian preferences, both themes, document queues, PIN/error dialogs, signing outcomes, verification outcomes and activity.

The complete Ubuntu run produced **80 mock screenshots plus one native no-reader/bridge screenshot**, with no GLib criticals across its 60 scenario launches. The targeted 26-image language refresh also completed under `G_DEBUG=fatal-criticals`. Screenshots and build/test/runtime evidence are saved locally at `/Users/nghimbovschi/Desktop/esemnbun-screenshots/linux/2026-10-30/ubuntu24.04/`; the `evidence` directory contains the logs, readiness markers and source-input hashes. Hashes of Linux and core source files, manifests, tests and specs were compared with the current main working tree and matched exactly.

Fedora's matching 26 affected screenshots were also rebuilt and refreshed under `G_DEBUG=fatal-criticals`, overwriting their existing paths. Its set remains 80 screenshots; Ubuntu's set remains 81. The three reviewed language gaps are corrected in both sets.

## Debian package build and installation

The final Debian control file passed `dpkg-checkbuilddeps` on Ubuntu. The package metadata now explicitly requires GTK 4.14 and libadwaita 1.5 for the GUI and their development packages at build time.

Release CLI and GNOME builds with `--static-swift-stdlib` passed in 9.62 and 15.25 seconds respectively; the final GUI localization update rebuilt in 6.61 seconds. `MOLDSIGN_PACKAGES=deb MOLDSIGN_SKIP_BUILD=1 scripts/package-linux.sh` successfully produced both ARM64 packages through `dpkg-buildpackage`. They were installed together using apt, and `dpkg --audit` reported no problems. The final localization packages were regenerated and reinstalled, then checked again through GNOME Shell and trusted HTTPS.

The installed `/usr/bin/esemnbun-gnome` was launched with `LD_LIBRARY_PATH` and `MSIGN_TLS_P12` unset. Its shared libraries resolved from the Ubuntu system, with no separately installed Swift runtime required. Its bundled identity again served trusted HTTPS **200** for the allowed origin and **403** for a disallowed origin. The optional CLI systemd user unit remained disabled. The Release app ignored `MSIGN_DEMO_CARDS=4` and emitted no demo-mode log.

Ubuntu's PC/SC policy rejected the installed app when it was spawned from SSH, as confirmed by the pcscd journal. The final native check instead launched it through GNOME Shell, which ran it in the normal desktop application scope and displayed the real no-reader state. No PC/SC policy override was added. The cloud-to-desktop installation also needed Ubuntu's recommended `yaru-theme-icon` package for the default desktop icon theme. The native screenshot is from the installed Release build launched through GNOME Shell, with normal icons and trusted HTTPS still responding.

Local package artifacts: `/Users/nghimbovschi/Projects/smartcard/dist/linux/ubuntu24.04-arm64/`.

| Artifact | SHA-256 |
| --- | --- |
| `esemnbun_0.2.0-1_arm64.deb` | `e53867961e1eaf490b602b2b55e6306c8454343817dc9444412ebbee1a9cab47` |
| `esemnbun-cli_0.2.0-1_arm64.deb` | `b8e83a658a2c5e97ed53807b316b27f6f3f2c6e6331069b20a0b2c4bc38b0a17` |
| Installed GNOME executable | `5227060750c600b45a30f93555ba2be2ab06d4e85436bc86060f793723921a9c` |

## Validation boundaries

Mock screenshots use visibly fictional cards and unsigned demonstration files. They do not prove physical-reader operation, PIN verification, real signing or portal signing. No physical reader or real PIN was used. Live TSA/OCSP/CRL tests were not run.

QEMU's unaccelerated graphics path reports Mesa/EGL fallback warnings, and the unsandboxed app's optional background-portal status request is denied by GNOME. The app renders successfully; its status remains visible inside the window. These messages are retained in the runtime logs.

Both Fedora and Ubuntu test guests were shut down gracefully after their evidence was copied. Their disks remain available for subsequent testing; the Windows VM was not modified by this work.
