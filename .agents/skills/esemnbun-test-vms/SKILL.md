---
name: esemnbun-test-vms
description: Start, stop, snapshot and drive the eSemnBun (smartcard repo) test VMs on the MacBook Air — Fedora 44 GNOME and Windows 11 ARM64 under QEMU+HVF — hand the bit4id miniLector card reader to a VM, ssh/VNC into the guests from the main Mac, build and test the Linux/Windows apps inside them, and rebuild a VM from scratch. Use whenever a Linux or Windows behaviour of eSemnBun must be checked on a real OS with the real card, or the VMs need maintenance.
---

# eSemnBun test VMs on the MacBook Air

Built 2026-10-27. The VMs live on the **MacBook Air** (`ssh user@192.168.50.126`, home `/Users/user`, Apple M2, 24 GB,
macOS 27). The card reader (bit4id miniLector POCKET EVO, USB `25dd:3111`) is plugged into the Air.
Everything below can be done on the Air in Terminal, or remotely from the main Mac with `scripts/air.sh`.

**Rule from the owner:** git push, `gh` and release dispatch run **only from the main MacBook Pro**, never from the Air.
On the main Mac `gh` defaults to another host: always pass `GH_HOST=github.com` and never log out of or switch the other
host's session.

## Layout on the Air

```
~/VMs/bin/vm                  control script (copy: scripts/vm in this skill), on PATH via ~/.zshrc
~/VMs/fedora/                 fedora.qcow2 (64 GB, btrfs), efivars.fd, run.sh, seed.iso (cloud-init), qmp.sock
~/VMs/windows/                windows.qcow2 (80 GB), efivars.fd, run.sh, unattend.iso + unattend/ (autounattend)
~/VMs/images/                 Fedora cloud qcow2, Win11_ARM64_Pro_en-US.iso (EFI-bootable rebuild), virtio-win.iso
efivars.<snapshot>.fd         UEFI vars saved with each snapshot
```

| VM | OS | account | ssh (on the Air) | console VNC (on the Air) | other |
| --- | --- | --- | --- | --- | --- |
| fedora | Fedora 44 Workstation (GNOME, Wayland), aarch64, cloud-init | `user` (wheel, NOPASSWD sudo), autologin | `127.0.0.1:2222` | `127.0.0.1:5901` | Swift 6.4.1 in `/opt/swift`, pcsc-lite + ccid, opensc, Chromium |
| windows | Windows 11 Pro ARM64 (build 26100, unactivated, generic key) | `user` (Administrators), autologon | `127.0.0.1:2223` (OpenSSH, PowerShell) | `127.0.0.1:5902` | RDP `127.0.0.1:33389`, NetKVM driver, no sleep, TZ GTB |

Both accounts use the **Air's login password** (ask the user; it is never stored in this skill or the VMs' files).
Guest ssh trusts the Air's and the main Mac's `id_ed25519` keys. Networking is QEMU user-mode (NAT, outbound
internet, only the forwarded ports above are reachable, all bound to 127.0.0.1).

## Everyday use (Terminal on the Air)

```bash
vm list                                  # state + snapshots
vm start windows --reader                # window opens; the reader is captured for the whole run
vm start fedora                          # without the reader
vm reader attach fedora                  # move the reader into a running VM (detaches it from the other VM)
vm reader detach fedora                  # give it back to macOS (eSemnBun on the Air sees it again)
vm ssh fedora 'opensc-tool -l'           # or: vm ssh windows
vm stop windows                          # ACPI shutdown; `vm kill` = power off
vm snapshot fedora before-x              # VM must be stopped; saves disk + UEFI vars
vm restore fedora os-installed           # roll back (VM stopped)
```

`vm start`/`reader`/`snapshot` use `sudo`: **QEMU runs as root** because macOS only lets root take a USB device
away from its smart-card daemon (`usbsmartcardreaderd`). As a normal user QEMU attaches the device but the guest
gets `can't set config #1, error -32`. Only one VM can own the reader; while a VM has it, the Mac (and eSemnBun on the
Air) does not see it. `libusb_kernel_driver_active: -5 [NOT_FOUND]` lines in `qemu.log` are harmless.

Snapshots today: fedora `os-installed` (GNOME + build deps + Swift, before any eSemnBun code), `esemnbun-built`
(repo copy in `~/smartcard`, app + CLI built and installed via `linux/packaging/install.sh`); windows `os-installed`
(OOBE done, drivers, OpenSSH, RDP). They are qcow2 internal snapshots (`qemu-img snapshot -l <disk>`).

## Remote control from the main Mac

```bash
source ~/.copilot/skills/esemnbun-test-vms/scripts/air.sh     # same file under ~/.claude/skills and ~/.codex/skills
export AIR_PW=...                       # Air password, from the user; keep it in the shell only
air 'vm list'
air_gui '/Users/user/VMs/windows/run.sh -device usb-host,vendorid=9693,productid=12561,id=reader > /Users/user/VMs/windows/qemu.log 2>&1'
vm_ssh fedora 'esemnbun readers'        # ssh -J through the Air
vm_ssh windows 'Get-PnpDevice -Class SmartCardReader -PresentOnly'
vm_tunnel; vm_shot windows /tmp/w.png   # QEMU VNC console screenshot (then view the PNG)
```

- `vm start` from an SSH session needs a tty for sudo; from automation use `air_gui` (root QEMU inside the
  logged-in GUI session via `launchctl asuser 501`) — without it the QEMU window can't open over SSH.
- QMP with root sockets: send the sudo password as the FIRST stdin line, then the JSON:
  `printf '%s\n%s\n%s\n' "$AIR_PW" '{"execute":"qmp_capabilities"}' '{"execute":"device_add","arguments":{"driver":"usb-host","vendorid":9693,"productid":12561,"id":"reader"}}' | ssh user@192.168.50.126 'sudo -S -p "" nc -U -w 3 ~/VMs/fedora/qmp.sock'`
  (`device_del` with `id: reader` to detach).
- Console input: `vncdo -s 127.0.0.1::15901 move X Y click 1`, `key enter`. Typing passwords through vncdotool
  toggled Caps Lock in GNOME — unlock Fedora with `vm_ssh fedora 'sudo loginctl unlock-sessions'` instead.
- The Air's own desktop: macOS Screen Sharing works for the user, but python VNC clients (vncdotool, asyncvnc)
  fail Apple auth (types 30/33/35/36) on macOS 27; `screencapture` over SSH is denied. To see the Air's screen,
  use the Screen Sharing app on the main Mac (screencapture + cliclick work locally) or ask the user.
- PC/SC inside Fedora over SSH needs the polkit rule `/etc/polkit-1/rules.d/90-esemnbun-pcsc.rules` (installed);
  desktop sessions are allowed by default.

## Testing eSemnBun in the VMs

Fedora (repo is private; copy the working tree in, don't clone):
```bash
cd ~/Projects/smartcard && COPYFILE_DISABLE=1 tar czf - --no-xattrs --exclude=.build --exclude='._*' linux swift/MoldSignKit spec \
  | ssh user@192.168.50.126 'ssh -p 2222 user@127.0.0.1 "rm -rf ~/smartcard && mkdir ~/smartcard && tar xzf - -C ~/smartcard"'
vm_ssh fedora 'source /etc/profile.d/swift.sh; cd ~/smartcard/linux && swift build -c release && cd ../swift/MoldSignKit && swift build -c release --product esemnbun && cd ~/smartcard && sudo linux/packaging/install.sh "" /usr all'
vm_ssh fedora 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; nohup esemnbun-gnome >/tmp/gnome.log 2>&1 &'
vm_ssh fedora 'curl -s -H "Origin: https://msign.gov.md" https://localhost.cts.md:18443/certificates | head -c 200'
```
Signing with the real card: the PIN comes from the user, only through stdin/`MSIGN_PIN`, never in files, logs or
commits; never retry after a PIN error (retry counter). Example: `printf '%s\n' "$PIN" | vm_ssh fedora 'esemnbun sign --pin-stdin /tmp/x.pdf'`.
Verified 2026-10-27: Fedora aarch64 build, GNOME app shows the card ready, bridge 200 over TLS, CLI PAdES-B-T VALID.

Windows: the app is x64 (.NET/WinUI) and runs under Windows-on-ARM x64 emulation. Install the MSI/MSIX from a
Release run (download on the main Mac, `scp -J user@192.168.50.126 -P 2223 file.msi user@127.0.0.1:` then
`msiexec /i`). GUI apps must start in the interactive session (scheduled task with `-LogonType Interactive`, as on the
old Windows PC) — not from the SSH session. Reader in Windows: "Microsoft Usbccid Smartcard Reader (WUDF)".

## Screenshots of the apps (all platforms)

Done once on 2026-10-27 → `~/Desktop/esemnbun-screenshots/{macos,linux,windows}` **on the Air** (the main Mac's disk was
full) + `<platform>-<theme>-contact-sheet.png`. Tools live in `~/VMs/shots` on the Air (copies in `scripts/shots/`); run
them **on the Air** so only small previews travel to the main Mac (`/tmp/prev.png`).

- VM consoles: `v <fedora|windows> click X Y | dbl | drag x1 y1 x2 y2 | type TXT | typeenv VAR | key K | sleep S | shot F`
  (QEMU VNC, coords = guest pixels). `sh.sh <vm> <file|-> <crop|full|box> -- <actions>` captures + crops (default
  windows box `138,131,1222,842`, fedora `200,72,1400,960` = app window 1200×888 at 200,72).
  **QEMU's VNC ignores Shift**: capitals and `"` type lowercase — use lowercase paths (symlink `~/d` → document folder).
- Both VMs now use `virtio-gpu-pci,xres=1600,yres=1000`. Windows needs the `viogpudo` ARM64 driver
  (`virtio-win.iso /viogpudo/w11/ARM64`, staged with `pnputil`); ramfb has no size option. GNOME picks 200 % scale:
  apply 100 % per session with Mutter `ApplyMonitorsConfig` method **1** (temporary; method 2 waits for "Keep changes").
- Windows app: launch in the interactive session via scheduled task `esb-launch`; the tray icon was promoted with
  `HKCU:\Control Panel\NotifyIconSettings\*\IsPromoted=1`; UI language follows the user language list (`ro-RO` first,
  keyboard `0418:00000409` = US layout); theme via `HKCU:\...\Themes\Personalize AppsUseLightTheme/SystemUsesLightTheme`.
  Unplug/replug the reader with QMP `device_del`/`device_add id=reader`; PC/SC down = `SCardSvr` disabled + stopped.
  Browser requests: POST `https://localhost.cts.md:18443/sign/data` with `Origin: https://msign.gov.md`, JSON
  `{data, contentType:"Pdf", signFormat:"PAdES"}` → consent/PIN window. Windows has no demo mode and no reader toasts yet.
- Linux: real app via `~/glaunch.sh esemnbun-gnome` (sets Wayland/DBus env; `pkill -x`, never `-f`), demo states via
  `~/demo.sh <MSIGN_DEMO_CARDS> <page>` (debug build in `~/smartcard/linux/.build/debug`). File chooser: `pick.sh <path>`.
  PC/SC down: `systemctl stop pcscd.socket pcscd.service` + `mask --runtime`, undo afterwards.
- macOS (Air desktop, release app from the GitHub release): `/usr/libexec/sshd-keygen-wrapper` has Screen Recording, so
  `screencapture -x -o -l <windowID>` works over SSH; `winlist` lists eSemnBun windows (id x y w h layer title).
  `cliclick` for clicks (menu-bar icon ≈ `c:1059,16`, the popover is layer 101), `osascript … keystroke` for keys
  (⌘↩ signs, ⌘, opens Settings). The NSOpenPanel is out-of-process — AX can't press its buttons; click "Deschideți"
  by coordinates. "No reader" without unplugging: a throw-away root QEMU that grabs the reader
  (`qemu-system-aarch64 -name reader-grab … -device usb-host,vendorid=9693,productid=12561`), kill it to give it back.
  Demo cards: Debug build + `MSIGN_DEMO_CARDS=2|3 MSIGN_DEMO_EXPANDED=1 MSIGN_DEMO_SELECTED=1 MSIGN_DEMO_DARK=1`
  (`demo-all.sh`, SPW exported). **zsh doesn't word-split `$var`** — run such loops in bash.
- PIN entry for screenshots: digits come from the user, sent over stdin, typed in two halves, and the box count is
  checked on a preview before Enter. Never put the PIN in a command line, file or log.

## Rebuilding from scratch

Hypervisor: **plain QEMU from Homebrew** (`brew install qemu xorriso`), `-accel hvf`, edk2 from
`/opt/homebrew/share/qemu`. **UTM 4.7.5 and 5.0.8 crash on macOS 27** (SIGSEGV in `MenuBarClientCore`
`swift_task_isCurrentExecutor` when a VM starts, also from the Play button) — don't go back to UTM until a fixed
release; `utmctl` also refuses to run from SSH.

Fedora: `Fedora-Cloud-Base-Generic-44-*.aarch64.qcow2` → `qemu-img resize` 64G → render `templates/fedora/user-data`
(hash: `openssl passwd -6 -stdin`), `xorriso -as mkisofs -o seed.iso -V cidata -J -r user-data meta-data` →
`cp edk2-arm-vars.fd efivars.fd` → `SEED=1 run.sh`. Then in the guest: `dnf install @workstation-product-environment`
+ `libadwaita-devel libsecret-devel pcsc-lite-devel openssl-devel pcsc-lite pcsc-lite-ccid pcsc-tools opensc git rpm-build`
+ chromium, `systemctl set-default graphical.target`, `systemctl enable pcscd.socket`, GDM autologin in
`/etc/gdm/custom.conf`, gsettings idle-delay 0 / lock off, timezone Europe/Chisinau, polkit rule above.
Swift: **swiftly refuses Fedora 44** ("ca-certificates not installed" even when it is) — use the swift.org tarball
for the newest "Fedora 41" aarch64 platform (`https://www.swift.org/api/v1/install/releases.json`) into `/opt/swift`
+ `/etc/profile.d/swift.sh`, plus `binutils glibc-devel libstdc++-devel libedit-devel libuuid-devel gcc zlib-devel`.

Windows ISO: Microsoft's download API answers **`SentinelReject`** to scripts, headless and even visible
CDP-driven Chrome from this network — use **UUP dump** (`api.uupdump.net/listid.php`, newest retail arm64 build,
`get.php?id=…&pack=en-us&edition=professional` POST `autodl=2&updates=1&cleanup=1`, `brew install aria2 cabextract
wimlib cdrtools minacle/chntpw/chntpw`, run `uup_download_macos.sh`). Its macOS ISO has an **x86-platform El Torito
entry and a hidden ISO9660 tree, so edk2 drops to the UEFI shell** — rebuild it:
`rsync -a --exclude boot.catalog <mounted iso>/ dir/ && mkisofs -eltorito-platform efi -b efi/microsoft/boot/efisys_noprompt.bin -no-emul-boot -c BOOT.CAT -udf -iso-level 3 -J -joliet-long -V <label> -o out.iso dir`
(`efisys_noprompt` also removes the "press any key to boot from CD" prompt).
Unattend: `templates/windows/autounattend.xml` (replace `@@PASSWORD@@`, XML-escaped) + `firstlogon.ps1` +
`authorized_keys` + `drivers/NetKVM` (from `virtio-win.iso` `/NetKVM/w11/ARM64`) on an ISO labelled UNATTEND
(`xorriso -as mkisofs -V UNATTEND -J -joliet-long -r`). It bypasses TPM/SecureBoot/RAM checks (LabConfig) and
BypassNRO, creates `user`, autologon, then first logon installs NetKVM, OpenSSH (needs internet), RDP, no sleep.
Disk NVMe (inbox driver), display `ramfb`, NIC virtio-net-pci. `qemu-img create -f qcow2 windows.qcow2 80G`,
fresh `efivars.fd`, `INSTALL=1 run.sh` — about 35 minutes unattended to the desktop.

## Traps seen while building this

- A backgrounded `sudo -S … &` over SSH with nothing after it fails ("no password was provided"); keep `& sleep N`.
- QEMU's root-owned `qemu.pid`/`qmp.sock`: the script detects running VMs with `pgrep -f "qemu-system-aarch64 -name <title>"`.
- A system HTTP(S) proxy on the Air (e.g. Charles on another Mac) sends browser traffic for `localhost.cts.md`
  off the machine, so the portal sees no bridge: keep the proxy off when testing the browser flow.
- GNOME blanks/locks after idle (disabled for `user`); a VNC "Display output is not active" is just blanking.
- Disk: ~17 GB for both VMs + images; 200 GB free on the Air at creation.
