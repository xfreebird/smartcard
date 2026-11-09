#!/bin/bash
# Capture Debug-only fictional scenarios. Never starts a reader monitor or bridge.
set -euo pipefail
platform=${1:?Usage: capture-screenshots.sh macos|ios APP_PATH OUTPUT_DIR [SIMULATOR_UDID]}
app=${2:?APP_PATH required}
out=${3:?OUTPUT_DIR required}
root=$(cd "$(dirname "$0")/../.." && pwd)
files=${MSIGN_CAPTURE_FILES:-"$root/swift/MoldSignKit/Resources/test.pdf"}
# Reject release binaries before launch: mock captures must never fall through to real hardware.
if [[ "$platform" == macos ]]; then binary="$app/Contents/MacOS/eSemnBun"; else binary="$app/eSemnBun"; fi
python3 - "$binary" <<'PYTHON'
import pathlib, sys
binary = pathlib.Path(sys.argv[1])
images = [binary] + list(binary.parent.glob("*.debug.dylib"))
if not any(b"MSIGN_DEMO_SCENARIO" in image.read_bytes() for image in images):
    raise SystemExit("Capture requires a Debug binary with mock scenarios")
PYTHON
mkdir -p "$out"
scenarios=(no-reader empty-reader unavailable reading ready multiple error signing success pin)
if [[ -n "${MSIGN_CAPTURE_SCENARIOS:-}" ]]; then read -r -a scenarios <<< "$MSIGN_CAPTURE_SCENARIOS"; fi
if [[ "$platform" == ios ]]; then
    device=${4:?SIMULATOR_UDID required}
    capture_tmp=$(mktemp -d -t esemnbun-ios-capture)
    trap 'rm -rf "$capture_tmp"' EXIT
    xcrun simctl install "$device" "$app"
    app_container=$(xcrun simctl get_app_container "$device" md.esemnbun.ios data)
    device_data_root="${app_container%/Containers/Data/Application/*}"
    ready_file="$device_data_root$capture_tmp/ready.log"
    trap 'xcrun simctl terminate "$device" md.esemnbun.ios >/dev/null 2>&1 || true; rm -rf "$capture_tmp" "$device_data_root$capture_tmp"' EXIT
    for theme in ${MSIGN_CAPTURE_THEMES:-light dark}; do
        xcrun simctl ui "$device" appearance "$theme"
        for scenario in "${scenarios[@]}"; do
            count=1; [[ "$scenario" == multiple ]] && count=3
            xcrun simctl terminate "$device" md.esemnbun.ios >/dev/null 2>&1 || true
            SIMCTL_CHILD_MSIGN_DEMO_CARDS="$count" SIMCTL_CHILD_MSIGN_SCREENSHOT_CAPTURE=1 SIMCTL_CHILD_MSIGN_QA_NO_HARDWARE=1 SIMCTL_CHILD_MSIGN_DEMO_SCENARIO="$scenario" \
            SIMCTL_CHILD_MSIGN_DEMO_PREFERENCES_SUITE="md.esemnbun.qa.capture" \
            SIMCTL_CHILD_MSIGN_DEMO_TAB="${MSIGN_CAPTURE_TAB:-sign}" \
            SIMCTL_CHILD_MSIGN_DEMO_SELECTED="${MSIGN_CAPTURE_SELECTED:-0}" \
            SIMCTL_CHILD_MSIGN_DEMO_FILES="$files" \
                xcrun simctl launch --stdout="$capture_tmp/ready.log" "$device" md.esemnbun.ios -appTheme "$theme" -appLanguage "${MSIGN_CAPTURE_LANGUAGE:-ro}" -AppleLanguages "(${MSIGN_CAPTURE_LANGUAGE:-ro})"
            ready=0
            for attempt in {1..60}; do
                if [[ -f "$ready_file" ]] && /usr/bin/grep -q MSIGN_DEMO_READY "$ready_file"; then ready=1; break; fi
                sleep 1
            done
            [[ "$ready" == 1 ]] || { echo "Demo did not become ready: $scenario" >&2; exit 1; }
            sleep 2
            xcrun simctl io "$device" screenshot --display="${MSIGN_CAPTURE_DISPLAY:-1}" "$out/$scenario-$theme.png"
            rm -f "$ready_file"
        done
    done
    xcrun simctl terminate "$device" md.esemnbun.ios >/dev/null 2>&1 || true
elif [[ "$platform" == macos ]]; then
    # Screen Recording must already be granted to the invoking process. No permission changes are made.
    helper_dir=$(mktemp -d -t esemnbun-window-list)
    helper="$helper_dir/window.swift"
    trap 'rm -rf "$helper_dir"; if [[ -n "${app_pid:-}" ]]; then kill "$app_pid" 2>/dev/null || true; fi' EXIT
    cat > "$helper" <<'SWIFT'
import Foundation
import CoreGraphics
let pid = Int(CommandLine.arguments[1])!
let pin = CommandLine.arguments[2] == "pin"
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for item in list where item[kCGWindowOwnerPID as String] as? Int == pid {
    guard let id = item[kCGWindowNumber as String] as? Int else { continue }
    let title = item[kCGWindowName as String] as? String ?? ""
    let layer = item[kCGWindowLayer as String] as? Int ?? 0
    let bounds = item[kCGWindowBounds as String] as? [String: Double] ?? [:]
    guard pin ? layer == 3 : (title == "eSemnBun preview" || (layer == 0 && (bounds["Width"] ?? 0) > 600)) else { continue }
    print(id)
    break
}
SWIFT
    swiftc "$helper" -o "$helper_dir/window-list"
    for theme in ${MSIGN_CAPTURE_THEMES:-light dark}; do
        for scenario in "${scenarios[@]}"; do
            count=1; [[ "$scenario" == multiple ]] && count=3
            dark=; [[ "$theme" == dark ]] && dark=1
            if [[ -n "$dark" ]]; then
                MSIGN_DEMO_PREFERENCES_SUITE=md.esemnbun.qa.capture MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_QA_NO_HARDWARE=1 MSIGN_DEMO_DARK=1 MSIGN_DEMO_CARDS="$count" MSIGN_DEMO_SCENARIO="$scenario" \
                MSIGN_DEMO_SELECTED="${MSIGN_CAPTURE_SELECTED:-0}" MSIGN_DEMO_FILES="$files" "$app/Contents/MacOS/eSemnBun" -mainSection "${MSIGN_CAPTURE_TAB:-sign}" -appTheme "$theme" -appLanguage "${MSIGN_CAPTURE_LANGUAGE:-ro}" -AppleLanguages "(${MSIGN_CAPTURE_LANGUAGE:-ro})" &
            else
                MSIGN_DEMO_PREFERENCES_SUITE=md.esemnbun.qa.capture MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_QA_NO_HARDWARE=1 MSIGN_DEMO_CARDS="$count" MSIGN_DEMO_SCENARIO="$scenario" \
                MSIGN_DEMO_SELECTED="${MSIGN_CAPTURE_SELECTED:-0}" MSIGN_DEMO_FILES="$files" "$app/Contents/MacOS/eSemnBun" -mainSection "${MSIGN_CAPTURE_TAB:-sign}" -appTheme "$theme" -appLanguage "${MSIGN_CAPTURE_LANGUAGE:-ro}" -AppleLanguages "(${MSIGN_CAPTURE_LANGUAGE:-ro})" &
            fi
            app_pid=$!
            window=
            for attempt in {1..30}; do
                window=$("$helper_dir/window-list" "$app_pid" "$scenario")
                [[ -n "$window" ]] && break
                sleep 1
            done
            sleep 1
            [[ -n "$window" ]] || { echo 'Preview window unavailable; use a Debug app.' >&2; exit 1; }
            if [[ "$scenario" == signing ]]; then sleep 8; fi
            /usr/sbin/screencapture -x -o -l "$window" "$out/$scenario-$theme.png"
            kill "$app_pid"; wait "$app_pid" 2>/dev/null || true; app_pid=
        done
    done
else
    echo 'Expected macos or ios' >&2; exit 1
fi
