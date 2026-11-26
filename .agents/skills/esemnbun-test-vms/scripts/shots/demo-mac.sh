#!/bin/bash
# demo-mac.sh <name-suffix> [env...] — run from the SSH session (has Screen Recording); app launched in the GUI session via sudo
S=~/VMs/shots; D=~/Desktop/esemnbun-screenshots/macos; name=$1; shift
kill $(pgrep -f "Debug/eSemnBun.app/Contents/MacOS/eSemnBun") 2>/dev/null; sleep 1.5
echo "$SPW" | sudo -S -p "" launchctl asuser 501 sudo -u user env "$@" nohup /tmp/sc-dd/Build/Products/Debug/eSemnBun.app/Contents/MacOS/eSemnBun > /tmp/demo-mac.log 2>&1 &
sleep 5
for try in 1 2 3 4 5 6; do
  osascript -e tell application System Events to tell process eSemnBun to set position of window eSemnBun preview to {420, 60} >/dev/null 2>&1
  sleep 1.5
  pop=$($S/winlist | grep "Popover preview" | cut -d" " -f1); main=$($S/winlist | grep "eSemnBun preview" | cut -d" " -f1)
  [[ -n "$main" ]] && screencapture -x -o -l "$main" "$D/demo-$name-main.png" 2>/dev/null && [[ -n "$pop" ]] && screencapture -x -o -l "$pop" "$D/demo-$name-popover.png" 2>/dev/null && break
done
