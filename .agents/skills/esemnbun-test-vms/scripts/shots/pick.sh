#!/bin/bash
# pick.sh <path>: in the open GTK file chooser (1200x888 window at 200,72): type the path, Enter selects it, click Open.
S=~/VMs/shots
$S/v fedora key ctrl-l type "$1" sleep 1 key enter sleep 1.5 click 1180 755 sleep 6 move 1590 990 sleep 0.4 2>/dev/null
