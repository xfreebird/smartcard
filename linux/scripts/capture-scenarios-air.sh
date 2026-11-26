#!/usr/bin/env bash
# Run on Air with Fedora running. Strict Debug fixtures, never real signing/card/PIN/network operations.
set -euo pipefail
output=${1:-"$HOME/Desktop/esemnbun-screenshots/linux/2026-10-30/scenarios"}
mkdir -p "$output"
remote() { ssh -o BatchMode=yes -p 2222 user@127.0.0.1 "$@"; }
run="$(date +%s)-$$"
base="/tmp/esemnbun-scenarios-$run"
remote "mkdir -p '$base/config' '$base/data'"
trap 'remote "pkill -x esemnbun-gnome || true; rm -rf '\''$base'\''"' EXIT
"$HOME/VMs/shots/v" fedora key esc
scenarios=(documents signing pin pin-error success signing-error verify-checking verify-valid verify-invalid verify-unknown verify-unsigned activity settings)
for theme in light dark; do
  dark=0; [[ "$theme" = dark ]] && dark=1
  for scenario in "${scenarios[@]}"; do
    ready="$base/$scenario-$theme.json"
    case "$scenario" in verify-*) page=verify;; activity) page=activity;; *) page=sign;; esac
    remote "pkill -x esemnbun-gnome || true; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_CONFIG_HOME='$base/config' XDG_DATA_HOME='$base/data'; MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_DEMO_WORK_DIR='$base/fixtures' MSIGN_DEMO_SCENARIO=$scenario MSIGN_DEMO_LANGUAGE=en MSIGN_DEMO_DARK=$dark MSIGN_DEMO_WINDOW=1100x780 MSIGN_DEMO_RUN_ID=$run MSIGN_DEMO_READY_FILE='$ready' nohup ~/smartcard/linux/.build/debug/esemnbun-gnome >'$base/$scenario-$theme.log' 2>&1 </dev/null &"
    # A missing/failed/stale scenario never produces a screenshot with the wrong filename.
    remote "for i in \$(seq 1 150); do test -s '$ready' && exit 0; sleep 0.1; done; tail -15 '$base/$scenario-$theme.log'; exit 1"
    remote "cat '$ready'" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("ready") is True and d.get("scenario")==sys.argv[1] and d.get("run")==sys.argv[2] and d.get("page")==sys.argv[3] and d.get("language")=="en", d' "$scenario" "$run" "$page"
    case "$scenario" in
      signing|success)
        "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/scroll.py" 5901 5 8 "$output/$scenario-$theme.png";;
      *) "$HOME/VMs/shots/v" fedora shot "$output/$scenario-$theme.png";;
    esac
    case "$scenario" in
      verify-valid|verify-invalid|verify-unknown)
        "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/scroll.py" 5901 5 5 "$output/$scenario-checks-$theme.png";;
    esac
    if [[ "$scenario" = settings ]]; then
      "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/scroll.py" 5901 5 8 "$output/settings-startup-$theme.png"
    fi
    printf 'Captured %s %s\n' "$scenario" "$theme"
  done
 done
printf 'Captured 34 representative scenario screenshots: %s\n' "$output"
