#!/bin/bash
# Run on the Air. Ubuntu uses the installed release package; Fedora uses the native debug build.
# Isolated XDG state, shell-launched GNOME session, system TLS verification, no card/PIN I/O.
set -euo pipefail
vm=${1:?Usage: verify-first-launch-air.sh ubuntu|fedora [output-directory]}
case "$vm" in ubuntu|fedora) ;; *) exit 2;; esac
if [ "$vm" = ubuntu ]; then port=2224; vncport=5903; folder=ubuntu24.04; binary=/usr/bin/esemnbun-gnome; else port=2222; vncport=5901; folder=fedora44; binary=/home/user/smartcard/linux/.build/debug/esemnbun-gnome; fi
remote() { ssh -p "$port" user@127.0.0.1 "$@"; }
vnc() { "$HOME/VMs/shots/venv/bin/python" "$HOME/VMs/shots/vshot.py" "$vncport" "$@"; }
output=${2:-"$HOME/Desktop/esemnbun-screenshots/linux/$(date +%F)/$folder"}
mkdir -p "$output"
base="/tmp/esemnbun-native-launch-$(date +%s)"
remote "mkdir -p '$base/config/moldsign' '$base/data'"
remote "cat > '$base/config/moldsign/settings.json'" <<'JSON'
{"language":"en","bridgeEnabled":true,"runInBackground":true}
JSON
remote "cat > '$base/run.sh'; chmod +x '$base/run.sh'" <<SCRIPT
#!/bin/bash
export XDG_CONFIG_HOME='$base/config' XDG_DATA_HOME='$base/data' G_DEBUG=fatal-criticals
exec '$binary' "\$@" >>'$base/startup.log' 2>&1
SCRIPT
remote 'pkill -x esemnbun-gnome || true'
vnc key alt-f2 type "$base/run.sh --background" key enter
remote "for i in \$(seq 1 150); do test -s '$base/config/moldsign/launch-state.json' && exit 0; sleep .1; done; exit 1"
sleep 1
vnc shot "$output/native-first-background-launch.png"
remote "cat '$base/config/moldsign/launch-state.json'; curl --noproxy '*' --resolve localhost.cts.md:18443:127.0.0.1 -fsS -H 'Origin: https://msign.gov.md' https://localhost.cts.md:18443/certificates; echo; sha256sum '$binary'; pgrep -a esemnbun-gnome" > "$output/native-first-launch-proof.txt"
remote 'pkill -x esemnbun-gnome || true'
sleep 1
vnc key alt-f2 type "$base/run.sh --background" key enter
sleep 2
vnc shot "$output/native-subsequent-background.png"
remote "curl --noproxy '*' --resolve localhost.cts.md:18443:127.0.0.1 -fsS -H 'Origin: https://msign.gov.md' https://localhost.cts.md:18443/certificates; echo; pgrep -a esemnbun-gnome; cat '$base/config/moldsign/launch-state.json'" > "$output/native-background-proof.txt"
vnc key alt-f2 type "$base/run.sh" key enter
sleep 2
vnc shot "$output/native-explicit-launch.png"
remote "cat '$base/startup.log'" > "$output/native-startup.log"
remote 'pkill -x esemnbun-gnome || true'
printf 'Native first-launch, subsequent-background and explicit-activation evidence: %s (%s)\n' "$output" "$base"
