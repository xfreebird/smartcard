#!/usr/bin/env bash
# Run on the MacBook Air. Requires the running Fedora VM and existing VNC screenshot tools.
# Debug scenarios never connect to the reader, keyring or browser bridge.
set -euo pipefail
output=${1:-"$HOME/Desktop/esemnbun-screenshots/linux/2026-10-30"}
mkdir -p "$output"
remote() { ssh -o BatchMode=yes -p 2222 user@127.0.0.1 "$@"; }
run="$(date +%s)-$$"
base="/tmp/esemnbun-baseline-$run"
remote "mkdir -p '$base/config' '$base/data'"
trap 'remote "pkill -x esemnbun-gnome || true; rm -rf '\''$base'\''"' EXIT
wait_ready() {
  local marker=$1 page=$2 language=$3
  remote "for i in \$(seq 1 150); do test -s '$marker' && exit 0; sleep 0.1; done; exit 1"
  remote "cat '$marker'" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("ready") is True and d.get("scenario")=="baseline" and d.get("run")==sys.argv[1] and d.get("page")==sys.argv[2] and d.get("language")==sys.argv[3], d' "$run" "$page" "$language"
}
for theme in light dark; do
  dark=0; [ "$theme" = dark ] && dark=1
  for state in noreader empty pcscd error 1 2 4; do
    for page in sign card; do
      marker="$base/$state-$page-$theme.json"
      remote "pkill -x esemnbun-gnome || true; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_CONFIG_HOME='$base/config' XDG_DATA_HOME='$base/data'; MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_DEMO_RUN_ID=$run MSIGN_DEMO_READY_FILE='$marker' MSIGN_DEMO_LANGUAGE=en MSIGN_DEMO_CARDS=$state MSIGN_DEMO_PAGE=$page MSIGN_DEMO_DARK=$dark MSIGN_DEMO_WINDOW=1100x780 nohup ~/smartcard/linux/.build/debug/esemnbun-gnome >/tmp/esemnbun-demo.log 2>&1 </dev/null &"
      wait_ready "$marker" "$page" en
      "$HOME/VMs/shots/v" fedora key esc
      "$HOME/VMs/shots/v" fedora shot "$output/$state-$page-$theme.png"
    done
  done
 done
# Prove centering and preferences in all three languages and both themes.
for language in ro en ru; do
  for theme in light dark; do
    dark=0; [ "$theme" = dark ] && dark=1
    marker="$base/middle-$language-$theme.json"
    remote "pkill -x esemnbun-gnome || true; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_CONFIG_HOME='$base/config' XDG_DATA_HOME='$base/data'; MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_DEMO_RUN_ID=$run MSIGN_DEMO_READY_FILE='$marker' MSIGN_DEMO_LANGUAGE=$language MSIGN_DEMO_DARK=$dark MSIGN_DEMO_CARDS=4 MSIGN_DEMO_SELECTED=2 MSIGN_DEMO_WINDOW=1100x780 nohup ~/smartcard/linux/.build/debug/esemnbun-gnome >/tmp/esemnbun-demo.log 2>&1 </dev/null &"
    wait_ready "$marker" sign "$language"
    "$HOME/VMs/shots/v" fedora shot "$output/4-selected-middle-$language-$theme.png"
    "$HOME/VMs/shots/v" fedora key ctrl-,
    sleep 1
    "$HOME/VMs/shots/v" fedora shot "$output/preferences-$language-$theme.png"
    "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/scroll.py" 5901 5 8 "$output/preferences-startup-$language-$theme.png"
  done
 done
printf 'Captured 46 screenshots: %s\n' "$output"
