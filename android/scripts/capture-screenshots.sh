#!/bin/bash
# Debug emulator screenshots. Does not require or access physical cards.
set -euo pipefail
adb=${ADB:-${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb}
apk=${1:?Usage: capture-screenshots.sh DEBUG_APK OUTPUT_DIR [DEVICE_SERIAL]}
out=${2:?OUTPUT_DIR required}
serial=${3:-emulator-5554}
[[ "$serial" == emulator-* ]] || { echo 'Use an emulator for isolated mock capture.' >&2; exit 1; }
apk_hash=$(python3 - "$apk" <<'PYTHON'
import sys,zipfile,hashlib
with zipfile.ZipFile(sys.argv[1]) as z:
    if not any(b'demo scenario:' in z.read(n) for n in z.namelist() if n.endswith('.dex')):
        raise SystemExit('Debug demo APK required.')
print(hashlib.sha256(open(sys.argv[1], 'rb').read()).hexdigest())
PYTHON
)
mkdir -p "$out"
run_id=$(uuidgen)
read -r -a scenarios <<< "${MSIGN_CAPTURE_SCENARIOS:-one cards documents batch reading error empty permission noreader}"
read -r -a pages <<< "${MSIGN_CAPTURE_PAGES:-sign verify browser activity card}"
read -r -a themes <<< "${MSIGN_CAPTURE_THEMES:-light dark}"
expected=$((${#scenarios[@]} * ${#pages[@]} * ${#themes[@]}))
"$adb" -s "$serial" wait-for-device
for attempt in $(seq 1 120); do
    boot=$("$adb" -s "$serial" shell getprop sys.boot_completed | tr -d '\r')
    [[ "$boot" == 1 ]] && break
    sleep 0.25
done
[[ "$boot" == 1 ]] || { echo 'Test emulator did not finish booting.' >&2; exit 1; }
users=$("$adb" -s "$serial" shell dumpsys user)
[[ "$users" == *RUNNING_UNLOCKED* ]] || { echo 'Unlock the dedicated test emulator before capturing.' >&2; exit 1; }
"$adb" -s "$serial" install -r "$apk" >/dev/null
old_theme=$("$adb" -s "$serial" shell cmd uimode night | tr -d '\r')
old_theme=${old_theme##*: }
case "$old_theme" in yes|no|auto|custom_schedule|custom_bedtime) ;; *) old_theme=auto ;; esac
trap '"$adb" -s "$serial" shell am force-stop md.esemnbun.app >/dev/null; "$adb" -s "$serial" shell cmd uimode night "$old_theme" >/dev/null' EXIT
"$adb" -s "$serial" shell am force-stop md.esemnbun.app
for theme in "${themes[@]}"; do
    mode=no; [[ "$theme" == dark ]] && mode=yes
    "$adb" -s "$serial" shell cmd uimode night "$mode" >/dev/null
    for scenario in "${scenarios[@]}"; do
        for page in "${pages[@]}"; do
            "$adb" -s "$serial" logcat -c
            "$adb" -s "$serial" shell am start -W -n md.esemnbun.app/md.moldsign.app.MainActivity --es demo "$scenario" --es demo_page "$page" >/dev/null
            ready=false
            for attempt in $(seq 1 80); do
                logs=$("$adb" -s "$serial" logcat -d -s MoldSignDemo:I)
                if [[ "$logs" == *"ready:$page"* ]]; then ready=true; break; fi
                sleep 0.25
            done
            [[ "$ready" == true ]] || { echo "UI did not render: $scenario/$page" >&2; exit 1; }
            sleep 0.9
            if [[ "$scenario" == pin ]]; then
                python3 "$(dirname "$0")/verify-pin-visibility.py" "$serial" "$out/$scenario-$page-$theme-layout.json"
            fi
            "$adb" -s "$serial" exec-out screencap -p > "$out/$scenario-$page-$theme.png"
            python3 - "$out/$scenario-$page-$theme.json" "$run_id" "$scenario" "$page" "$theme" "$apk_hash" <<'PYTHON'
import json,sys,time
from pathlib import Path
Path(sys.argv[1]).write_text(json.dumps({'run':sys.argv[2], 'scenario':sys.argv[3], 'page':sys.argv[4],
    'theme':sys.argv[5], 'ready':'compose-frame-marker', 'apkSha256':sys.argv[6], 'capturedAt':time.time()},indent=2)+'\n')
PYTHON
        done
    done
done

printf "Captured %s ready-checked Android mock screenshots: %s\n" "$expected" "$out"
