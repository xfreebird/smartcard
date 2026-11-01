#!/usr/bin/env bash
# Build the Linux packages into dist/linux/ (LNX-07, LNX-15). Runs on Linux.
#
#   scripts/package-linux.sh                 # everything whose tools are installed
#   MOLDSIGN_PACKAGES="tar deb" scripts/package-linux.sh
#
# Public name eSemnBun (UX-12): packages esemnbun (GNOME app) + esemnbun-cli (the `esemnbun` CLI + user unit);
# the app ID stays md.moldsign.MoldSign.
#   tar      esemnbun-<v>-linux-<arch>.tar.gz   CLI (static Swift stdlib) + systemd user unit
#   deb      esemnbun_<v>-1_<arch>.deb + esemnbun-cli_<v>-1_<arch>.deb    (dpkg-buildpackage, debhelper)
#   rpm      esemnbun-<v>-1.<arch>.rpm + esemnbun-cli-<v>-1.<arch>.rpm    (rpmbuild)
#   flatpak  eSemnBun-<v>.flatpak                                        (flatpak-builder, Flathub runtime)
#
# Needs a Swift 6 toolchain (swift.org / swiftly) and the -dev packages from linux/README.md. A package whose
# tool is missing is skipped with a message; the script fails only if a package it attempts fails.
#   MOLDSIGN_VERSION   default: the newest <release> in linux/data/md.moldsign.MoldSign.metainfo.xml
#   MOLDSIGN_SKIP_BUILD=1  reuse the existing release builds
#   MOLDSIGN_NO_STRIP=1    keep symbols in the staged binaries
# The GUI package ships the bridge's TLS identity (vendor localhost.p12, D-03) in /usr/share/moldsign.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/linux"
WORK="$ROOT/dist/.work-linux"
PACKAGES="${MOLDSIGN_PACKAGES:-tar deb rpm flatpak}"
METAINFO="$ROOT/linux/data/md.moldsign.MoldSign.metainfo.xml"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "package-linux.sh builds Linux packages and runs on Linux only (this is $(uname -s))." >&2
  echo "On macOS: scripts/package-macos.sh; for the Linux UI, see linux/README.md." >&2
  exit 1
fi

VERSION="${MOLDSIGN_VERSION:-$(sed -n 's/.*<release version="\([^"]*\)".*/\1/p' "$METAINFO" | head -1)}"
[[ -n "$VERSION" ]] || { echo "Cannot read the version from $METAINFO (set MOLDSIGN_VERSION)." >&2; exit 1; }
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "MOLDSIGN_VERSION must use x.y.z." >&2; exit 1; }
ARCH="$(uname -m)"

wants() { [[ " $PACKAGES " == *" $1 "* ]]; }
skip() { echo "⏭  $1: skipped: $2"; }
have() { command -v "$1" >/dev/null 2>&1; }

rm -rf "$OUT" "$WORK"
mkdir -p "$OUT" "$WORK"
built=()


# ── Build (release, static Swift stdlib: no Swift runtime package needed on the target) ──────────────────
if [[ "${MOLDSIGN_SKIP_BUILD:-0}" != 1 ]]; then
  have swift || { echo "swift not found: install a Swift 6 toolchain (https://www.swift.org/install/linux/)." >&2; exit 1; }
  echo "▸ Building the esemnbun CLI (release, static stdlib)"
  (cd "$ROOT/swift/MoldSignKit" && swift build -c release --product esemnbun --static-swift-stdlib)
  echo "▸ Building the GNOME app (release, static stdlib)"
  (cd "$ROOT/linux" && swift build -c release --static-swift-stdlib)
fi

# ── Stage: one install layout (/usr) for every package ──────────────────────────────────────────────────
STAGE="$WORK/stage"
# Preserve matching DWARF before stripping the package executable.
mkdir -p "$OUT/symbols"
if have objcopy; then
  objcopy --only-keep-debug "$ROOT/linux/.build/release/esemnbun-gnome" "$OUT/symbols/esemnbun-gnome.debug"
fi
echo "▸ Staging into $STAGE"
"$ROOT/linux/packaging/install.sh" "$STAGE" /usr all
# About and the standalone updater read this installed marketing version.
python3 - "$STAGE/usr/share/metainfo/md.moldsign.MoldSign.metainfo.xml" "$VERSION" <<'PYMETA'
from pathlib import Path
import re
import sys
path = Path(sys.argv[1])
source, count = re.subn(r'(<release\s+version=")[^"]+', lambda match: match[1] + sys.argv[2], path.read_text(), count=1)
if count != 1:
    raise SystemExit('Missing release version in staged AppStream metadata')
path.write_text(source)
PYMETA
if [[ "${MOLDSIGN_NO_STRIP:-0}" != 1 ]] && have strip; then
  strip --strip-unneeded "$STAGE/usr/bin/esemnbun" "$STAGE/usr/bin/esemnbun-gnome"
fi
"$STAGE/usr/bin/esemnbun" --version

# Metadata checks (when the validators are installed: desktop-file-utils, appstream)
if have desktop-file-validate; then
  desktop-file-validate "$STAGE/usr/share/applications/md.moldsign.MoldSign.desktop"
fi
if have appstreamcli; then
  # warnings (e.g. no screenshots yet, LNX-14) are reported, not fatal
  appstreamcli validate --no-net "$STAGE/usr/share/metainfo/md.moldsign.MoldSign.metainfo.xml" ||
    echo "⚠  appstreamcli reported problems in the metainfo (see above)"
fi

# ── tar.gz: the CLI on its own (LNX-07) ─────────────────────────────────────────────────────────────────
if wants tar; then
  echo "▸ CLI tarball"
  tarroot="$WORK/tar/esemnbun-$VERSION"
  install -Dm755 "$STAGE/usr/bin/esemnbun" "$tarroot/esemnbun"
  install -Dm644 "$ROOT/swift/MoldSignKit/Resources/localhost.p12" "$tarroot/share/moldsign/localhost.p12"
  install -Dm644 "$STAGE/usr/lib/systemd/user/esemnbun-server.service" "$tarroot/esemnbun-server.service"
  tar -C "$WORK/tar" -czf "$OUT/esemnbun-$VERSION-linux-$ARCH.tar.gz" "esemnbun-$VERSION"
  built+=("tar")
fi

# ── .deb (debhelper, cut from the staging root) ─────────────────────────────────────────────────────────
if wants deb; then
  if have dpkg-buildpackage && have dh; then
    echo "▸ Debian packages"
    src="$WORK/deb/esemnbun-$VERSION"
    mkdir -p "$src"
    cp -a "$ROOT/linux/packaging/debian" "$src/debian"
    # changelog version follows the release version
    sed -i "1s/^esemnbun ([^)]*)/esemnbun ($VERSION-1)/" "$src/debian/changelog"
    # -d: the Swift toolchain is not a Debian package; -b: binary packages only
    (cd "$src" && MOLDSIGN_STAGE="$STAGE" dpkg-buildpackage -us -uc -b -d)
    cp "$WORK"/deb/*.deb "$OUT/"
    for deb in "$OUT"/*.deb; do dpkg-deb --info "$deb" | sed -n '/Package:/p;/Depends:/p'; done
    built+=("deb")
  else
    skip deb "dpkg-buildpackage/debhelper not found (apt install dpkg-dev debhelper)"
  fi
fi

# ── .rpm (rpmbuild, cut from the staging root) ──────────────────────────────────────────────────────────
if wants rpm; then
  if have rpmbuild; then
    echo "▸ RPM packages"
    # --nodeps: BuildRequires are for source builds; here the binaries are prebuilt (and the build host may
    # not even be RPM-based). Automatic soname Requires are still generated from the binaries.
    rpmbuild -bb --nodeps \
      --define "_topdir $WORK/rpm" \
      --define "moldsign_version $VERSION" \
      --define "moldsign_stage $STAGE" \
      "$ROOT/linux/packaging/rpm/esemnbun.spec"
    find "$WORK/rpm/RPMS" -name '*.rpm' -exec cp {} "$OUT/" \;
    for rpm in "$OUT"/*.rpm; do rpm -qp --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' "$rpm"; done
    built+=("rpm")
  else
    skip rpm "rpmbuild not found (apt install rpm / dnf install rpm-build)"
  fi
fi

# ── Flatpak bundle (GNOME runtime + Swift SDK extension from Flathub) ───────────────────────────────────
if wants flatpak; then
  if have flatpak-builder && have flatpak; then
    echo "▸ Flatpak bundle"
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak-builder --user --install-deps-from=flathub --force-clean --disable-rofiles-fuse \
      --state-dir="$WORK/flatpak-state" --repo="$WORK/flatpak-repo" \
      "$WORK/flatpak-build" "$ROOT/linux/flatpak/md.moldsign.MoldSign.yml"
    flatpak build-bundle --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
      "$WORK/flatpak-repo" "$OUT/eSemnBun-$VERSION.flatpak" md.moldsign.MoldSign
    built+=("flatpak")
  else
    skip flatpak "flatpak-builder not found (apt install flatpak flatpak-builder; needs a host or a privileged container)"
  fi
fi

echo "✔ built: ${built[*]:-nothing}"
ls -l "$OUT"
