#!/usr/bin/env bash
# Ubuntu 24.04 GNOME VM on the Air. Uses the existing VNC tools; no real card/PIN I/O.
# Install the Noble-built debug runtime bundle at ~/.local/opt/esemnbun-ubuntu first.
# CAPTURE_LABELS_ONLY=1 refreshes the 26 language/preferences/PIN captures after text-only changes.
set -euo pipefail
output=${1:-"$HOME/Desktop/esemnbun-screenshots/linux/2026-10-30/ubuntu24.04"}
mkdir -p "$output"
remote() { ssh -o BatchMode=yes -p 2224 user@127.0.0.1 "$@"; }
vnc() { "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/vshot.py" 5903 "$@"; }
scroll() { "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/scroll.py" 5903 5 "$1" "$output/$2.png"; }
run="$(date +%s)-$$"
base="/tmp/esemnbun-ubuntu-captures-$run"
remote "mkdir -p '$base/config' '$base/data'"
trap 'remote "pkill -x esemnbun-gnome || true"' EXIT

launch() {
  local name=$1 scenario=$2 cards=$3 page=$4 language=$5 dark=$6 selected=${7:-0}
  local marker="$base/$name.json" scenario_env=""
  [[ "$scenario" = baseline ]] || scenario_env="MSIGN_DEMO_SCENARIO=$scenario"
  remote "pkill -x esemnbun-gnome || true; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_CONFIG_HOME='$base/config' XDG_DATA_HOME='$base/data' G_DEBUG=fatal-criticals; export LD_LIBRARY_PATH=\"\$HOME/.local/opt/esemnbun-ubuntu/bundle/lib/linux\"; MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_DEMO_WORK_DIR='$base/fixtures' MSIGN_DEMO_RUN_ID=$run MSIGN_DEMO_READY_FILE='$marker' MSIGN_DEMO_LANGUAGE=$language MSIGN_DEMO_CARDS=$cards MSIGN_DEMO_PAGE=$page MSIGN_DEMO_DARK=$dark MSIGN_DEMO_SELECTED=$selected MSIGN_DEMO_WINDOW=1100x780 $scenario_env nohup ~/.local/opt/esemnbun-ubuntu/bundle/bin/esemnbun-gnome >'$base/$name.log' 2>&1 </dev/null &"
  remote "for i in \$(seq 1 150); do test -s '$marker' && exit 0; sleep 0.1; done; tail -20 '$base/$name.log'; exit 1"
  remote "cat '$marker'" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("ready") is True and d.get("scenario")==sys.argv[1] and d.get("run")==sys.argv[2] and d.get("page")==sys.argv[3] and d.get("language")==sys.argv[4], d' "$scenario" "$run" "$page" "$language"
}

if [[ "${CAPTURE_LABELS_ONLY:-0}" != 1 ]]; then
for theme in light dark; do
  dark=0; [[ "$theme" = dark ]] && dark=1
  for state in noreader empty pcscd error 1 2 4; do
    for page in sign card; do
      name="$state-$page-$theme"
      launch "$name" baseline "$state" "$page" en "$dark"
      vnc key esc shot "$output/$name.png"
    done
  done
done
fi

for language in ro en ru; do
  for theme in light dark; do
    dark=0; [[ "$theme" = dark ]] && dark=1
    name="4-selected-middle-$language-$theme"
    launch "$name" baseline 4 sign "$language" "$dark" 2
    vnc shot "$output/$name.png" key ctrl-,
    sleep 1
    vnc shot "$output/preferences-$language-$theme.png"
    scroll 8 "preferences-startup-$language-$theme"
  done
done

scenarios=(documents signing pin pin-error success signing-error verify-checking verify-valid verify-invalid verify-unknown verify-unsigned activity settings)
[[ "${CAPTURE_LABELS_ONLY:-0}" != 1 ]] || scenarios=(pin pin-error settings)
for theme in light dark; do
  dark=0; [[ "$theme" = dark ]] && dark=1
  for scenario in "${scenarios[@]}"; do
    case "$scenario" in verify-*) page=verify;; activity) page=activity;; *) page=sign;; esac
    name="$scenario-$theme"
    launch "$name" "$scenario" 1 "$page" en "$dark"
    case "$scenario" in
      signing|success) scroll 8 "$name";;
      *) vnc shot "$output/$name.png";;
    esac
    case "$scenario" in
      verify-valid|verify-invalid|verify-unknown) scroll 5 "$scenario-checks-$theme";;
      settings) scroll 8 "settings-startup-$theme";;
    esac
  done
done
count=80
[[ "${CAPTURE_LABELS_ONLY:-0}" != 1 ]] || count=26
printf 'Captured %s Ubuntu GNOME screenshots in %s; guest logs and readiness markers: %s\n' "$count" "$output" "$base"
