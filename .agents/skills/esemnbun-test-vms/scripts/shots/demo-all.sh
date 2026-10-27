#!/bin/bash
# demo-all.sh: capture every macOS demo state (needs SPW exported for the sudo launch)
for spec in "2cards-light:MSIGN_DEMO_CARDS=2" "2cards-expanded-light:MSIGN_DEMO_CARDS=2 MSIGN_DEMO_EXPANDED=1" \
            "3cards-second-selected-light:MSIGN_DEMO_CARDS=3 MSIGN_DEMO_SELECTED=1" "2cards-dark:MSIGN_DEMO_CARDS=2 MSIGN_DEMO_DARK=1" \
            "2cards-expanded-dark:MSIGN_DEMO_CARDS=2 MSIGN_DEMO_EXPANDED=1 MSIGN_DEMO_DARK=1" \
            "3cards-second-selected-dark:MSIGN_DEMO_CARDS=3 MSIGN_DEMO_SELECTED=1 MSIGN_DEMO_DARK=1"; do
  n=${spec%%:*}; e=${spec#*:}
  pids=$(pgrep -f "Debug/eSemnBun.app/Contents/MacOS/eSemnBun"); [ -n "$pids" ] && kill $pids; sleep 3
  ~/VMs/shots/demo-mac.sh "$n" $e
done
pids=$(pgrep -f "Debug/eSemnBun.app/Contents/MacOS/eSemnBun"); [ -n "$pids" ] && kill $pids
ls ~/Desktop/esemnbun-screenshots/macos | grep -c demo-
