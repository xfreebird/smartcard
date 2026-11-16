#!/bin/bash
set -euo pipefail
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 DEVICE_SERIAL [DEBUG_PACKAGE]" >&2
  exit 2
fi
serial=$1
package=${2:-md.esemnbun.app.nfctest}
case "$package" in md.esemnbun.app|md.esemnbun.app.nfctest) ;; *) echo "Unsupported package" >&2; exit 2;; esac
repo=$(cd "$(dirname "$0")/../.." && pwd)
mkdir -p "$repo/.local"
destination=$(mktemp -d "$repo/.local/android-nfc-diagnostics-XXXXXXXX")
# run-as succeeds only for a debuggable install. Copy only the metadata directory, not app storage/logcat.
adb -s "$serial" exec-out run-as "$package" tar -cf - -C cache nfc-diagnostics > "$destination/reports.tar"
tar -xf "$destination/reports.tar" -C "$destination"
find "$destination/nfc-diagnostics" -type f -name '*.json' -exec shasum -a 256 {} \; > "$destination/SHA256SUMS.txt"
echo "$destination"
