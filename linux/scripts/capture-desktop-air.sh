#!/usr/bin/env bash
# Run on the Air with the latest native debug binary already installed in the selected guest.
# Captures 28 scoped states in isolated profiles; uses existing VNC tools, no real card/PIN I/O.
set -euo pipefail
vm=${1:?Usage: capture-desktop-air.sh ubuntu|fedora [output-directory]}
case "$vm" in
  ubuntu) port=2224; vncport=5903; folder=ubuntu24.04; binary='~/.local/opt/esemnbun-ubuntu/bundle/bin/esemnbun-gnome'; runtime='$HOME/.local/opt/esemnbun-ubuntu/bundle/lib/linux';;
  fedora) port=2222; vncport=5901; folder=fedora44; binary='~/smartcard/linux/.build/debug/esemnbun-gnome'; runtime=/opt/swift/usr/lib/swift/linux;;
  *) echo "Unknown VM: $vm" >&2; exit 2;;
esac
output=${2:-"$HOME/Desktop/esemnbun-screenshots/linux/$(date +%F)/$folder"}
mkdir -p "$output"
remote() { ssh -o BatchMode=yes -p "$port" user@127.0.0.1 "$@"; }
vnc() { "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/vshot.py" "$vncport" "$@"; }
scroll() { "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/scroll.py" "$vncport" 5 "$1" "$output/$2.png"; }
run="$(date +%s)-$$"
base="/tmp/esemnbun-ubuntu-captures-$run"
remote "mkdir -p '$base/config' '$base/data'"
trap 'remote "pkill -x esemnbun-gnome || true"' EXIT
vnc key esc

launch() {
  local name=$1 scenario=$2 cards=$3 page=$4 language=$5 dark=$6 selected=${7:-0}
  local marker="$base/$name.json" scenario_env=""
  [ "$scenario" = baseline ] || scenario_env="MSIGN_DEMO_SCENARIO=$scenario"
  remote "pkill -x esemnbun-gnome || true; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_CONFIG_HOME='$base/config' XDG_DATA_HOME='$base/data' G_DEBUG=fatal-criticals; export LD_LIBRARY_PATH=\"$runtime\"; MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_DEMO_WORK_DIR='$base/fixtures' MSIGN_DEMO_RUN_ID=$run MSIGN_DEMO_READY_FILE='$marker' MSIGN_DEMO_LANGUAGE=$language MSIGN_DEMO_CARDS=$cards MSIGN_DEMO_PAGE=$page MSIGN_DEMO_DARK=$dark MSIGN_DEMO_SELECTED=$selected MSIGN_DEMO_WINDOW=1100x780 $scenario_env nohup $binary >'$base/$name.log' 2>&1 </dev/null &"
  remote "for i in \$(seq 1 150); do test -s '$marker' && exit 0; sleep 0.1; done; tail -20 '$base/$name.log'; exit 1"
  remote "cat '$marker'" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("ready") is True and d.get("scenario")==sys.argv[1] and d.get("run")==sys.argv[2] and d.get("page")==sys.argv[3] and d.get("language")==sys.argv[4], d' "$scenario" "$run" "$page" "$language"
}

for language in ro en ru; do
 for theme in light dark; do
  dark=0; [ "$theme" = dark ] && dark=1
  launch "wallet-$language-$theme" baseline 4 sign "$language" "$dark" 2
  vnc shot "$output/wallet-$language-$theme.png"
  launch "card-details-$language-$theme" baseline 1 card "$language" "$dark"
  vnc shot "$output/card-details-$language-$theme.png"
  launch "pin-$language-$theme" pin 1 sign "$language" "$dark"
  vnc shot "$output/pin-$language-$theme.png"
 done
done
for theme in light dark; do
 dark=0; [ "$theme" = dark ] && dark=1
 for scenario in settings pin-error signing success verify-invalid; do
  page=sign; [ "$scenario" != verify-invalid ] || page=verify
  launch "$scenario-en-$theme" "$scenario" 1 "$page" en "$dark"
  case "$scenario" in signing|success) scroll 8 "$scenario-en-$theme";; *) vnc shot "$output/$scenario-en-$theme.png";; esac
 done
done
printf 'Captured 28 final-source mock screenshots; guest evidence: %s\n' "$base"
