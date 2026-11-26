#!/bin/bash
# Drive the eSemnBun test VMs on the MacBook Air from ANOTHER Mac (source this file).
#   source ~/.copilot/skills/esemnbun-test-vms/scripts/air.sh
#   AIR_PW=...            the Air account password (ask the user; never write it to a file)
#   air 'vm list'                       run a command on the Air (non-login shell; PATH fixed below)
#   air_sudo '<cmd>'                    run <cmd> as root on the Air (password via stdin, first line)
#   air_gui '<cmd>'                     run <cmd> as root inside the logged-in GUI session (QEMU windows)
#   vm_ssh fedora|windows '<cmd>'       ssh into a guest through the Air
#   vm_tunnel                           forward guest consoles: VNC 15901 (fedora) / 15902 (windows)
#   vm_shot fedora|windows /tmp/x.png   console screenshot via QEMU's VNC (needs vm_tunnel + vncdotool)
AIR=${AIR:-user@192.168.50.126}
air() { ssh "$AIR" "export PATH=\$HOME/VMs/bin:/opt/homebrew/bin:\$PATH; $*"; }
air_sudo() { printf '%s\n' "${AIR_PW:?set AIR_PW}" | ssh "$AIR" "export PATH=\$HOME/VMs/bin:/opt/homebrew/bin:\$PATH; sudo -S -p '' bash -c $(printf %q "$*")"; }
# The trailing sleep matters: a backgrounded sudo with nothing after it loses stdin and fails.
air_gui() { printf '%s\n' "${AIR_PW:?set AIR_PW}" | ssh "$AIR" "sudo -S -p '' launchctl asuser 501 $* & sleep 6"; }
vm_ssh() { local port; case "$1" in fedora) port=2222 ;; windows) port=2223 ;; *) echo "fedora|windows" >&2; return 2 ;; esac
  shift; ssh -J "$AIR" -p "$port" -o StrictHostKeyChecking=accept-new user@127.0.0.1 "$@"; }
vm_tunnel() { ssh -f -N -o ExitOnForwardFailure=yes -L 15901:127.0.0.1:5901 -L 15902:127.0.0.1:5902 "$AIR"; }
VNCENV=${VNCENV:-$HOME/.cache/esemnbun-vncenv}
vm_shot() { local p; case "$1" in fedora) p=15901 ;; windows) p=15902 ;; esac
  [[ -x "$VNCENV/bin/vncdo" ]] || { python3 -m venv "$VNCENV" && "$VNCENV/bin/pip" -q install vncdotool; }
  "$VNCENV/bin/vncdo" -s "127.0.0.1::$p" capture "${2:-/tmp/$1.png}" 2>/dev/null; }
