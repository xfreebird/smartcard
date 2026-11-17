#!/bin/bash
# Start only the assigned family while the app and harness compile.
set -euo pipefail
family=${1:?iPhone|iPad}; out=${2:?Fresh evidence directory}
[[ "$family" == iPhone || "$family" == iPad ]] || exit 2
[[ ! -e "$out" ]] || exit 2
repo=$(cd "$(dirname "$0")/../.." && pwd)
mkdir -p "$out"
xcrun simctl list devices available -j > "$out/devices.json"
xcrun simctl list runtimes -j > "$out/runtimes.json"
python3 "$repo/scripts/ci/select_apple_ui_targets.py" "$out/devices.json" "$out/runtimes.json" \
    "$(xcrun --sdk iphonesimulator --show-sdk-version)" > "$out/targets.tsv"
device=$(awk -F '\t' -v family="$family" '$1 == family { print $2 }' "$out/targets.tsv")
[[ -n "$device" ]] || exit 1
printf '%s\n' "$device" > "$out/device.txt"
xcrun simctl boot "$device"
xcrun simctl bootstatus "$device" -b
