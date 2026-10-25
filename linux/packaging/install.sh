#!/usr/bin/env bash
# Installs eSemnBun's release binaries and desktop integration into a staging root (LNX-07, LNX-15).
# One install layout for every package: scripts/package-linux.sh, debian/rules, rpm/esemnbun.spec and the
# Flatpak manifest all call this. (Public name eSemnBun, UX-12; app ID and data file names keep the codename
# md.moldsign.MoldSign.)
#
#   linux/packaging/install.sh <destdir> [prefix=/usr] [all|gui|cli]
#
# Expects release builds (override with MOLDSIGN_GUI_BIN / MOLDSIGN_CLI_BIN):
#   gui  linux/.build/release/esemnbun-gnome          swift build -c release --static-swift-stdlib        (in linux/)
#   cli  swift/MoldSignKit/.build/release/esemnbun    swift build -c release --product esemnbun --static-swift-stdlib
#
# The browser bridge's localhost.cts.md TLS identity is vendor-shipped (AGENTS.md §5) and is never packaged:
# each user copies it to ~/.local/share/moldsign/localhost.p12 (Flatpak: ~/.var/app/md.moldsign.MoldSign/data/moldsign/).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
dest="${1?usage: install.sh <destdir> [prefix=/usr] [all|gui|cli]}"   # "" = install for real
dest="${dest%/}"
prefix="${2:-/usr}"
what="${3:-all}"
root="$dest$prefix"

gui_bin="${MOLDSIGN_GUI_BIN:-$repo/linux/.build/release/esemnbun-gnome}"
cli_bin="${MOLDSIGN_CLI_BIN:-$repo/swift/MoldSignKit/.build/release/esemnbun}"

need() {
  [[ -f "$1" ]] || { echo "install.sh: missing $1 ($2)" >&2; exit 1; }
}

install_gui() {
  need "$gui_bin" "build it: cd linux && swift build -c release --static-swift-stdlib"
  install -Dm755 "$gui_bin" "$root/bin/esemnbun-gnome"
  install -Dm644 "$repo/linux/data/md.moldsign.MoldSign.desktop" "$root/share/applications/md.moldsign.MoldSign.desktop"
  install -Dm644 "$repo/linux/data/md.moldsign.MoldSign.metainfo.xml" "$root/share/metainfo/md.moldsign.MoldSign.metainfo.xml"
  install -Dm644 "$repo/linux/data/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg" \
    "$root/share/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg"
  install -Dm644 "$repo/linux/data/icons/hicolor/symbolic/apps/md.moldsign.MoldSign-symbolic.svg" \
    "$root/share/icons/hicolor/symbolic/apps/md.moldsign.MoldSign-symbolic.svg"
}

install_cli() {
  need "$cli_bin" "build it: cd swift/MoldSignKit && swift build -c release --product esemnbun --static-swift-stdlib"
  install -Dm755 "$cli_bin" "$root/bin/esemnbun"
  # systemd --user unit for the browser bridge (LNX-06); not enabled by default. systemd looks in
  # <prefix>/lib/systemd/user for /usr and /usr/local, but in ~/.local/share/systemd/user for a home prefix.
  local unitdir="$root/lib/systemd/user"
  [[ "$prefix" == "$HOME"/* ]] && unitdir="$root/share/systemd/user"
  install -d "$unitdir"
  sed "s|@bindir@|$prefix/bin|g" "$here/systemd/esemnbun-server.service.in" > "$unitdir/esemnbun-server.service"
  chmod 644 "$unitdir/esemnbun-server.service"
}

case "$what" in
  all) install_gui; install_cli ;;
  gui) install_gui ;;
  cli) install_cli ;;
  *) echo "install.sh: unknown component '$what' (all|gui|cli)" >&2; exit 2 ;;
esac
