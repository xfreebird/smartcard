#!/bin/bash
# Air-side helper: sh.sh <vm> <out-name|-> <crop|full|x1,y1,x2,y2> -- <vshot actions...>
# Runs actions, captures, saves cropped PNG to ~/Desktop/esemnbun-screenshots/<dir>/<out-name>, and writes /tmp/prev.png (downscaled).
vm=$1; name=$2; box=$3; shift 4
D=~/Desktop/esemnbun-screenshots; S=~/VMs/shots
case "$vm" in fedora) dir=linux; def=200,72,1400,960 ;; windows) dir=windows; def=138,131,1222,842 ;; esac
[ "$box" = crop ] && box=$def
$S/v $vm "$@" shot /tmp/raw.png 2>/dev/null
$S/venv/bin/python - "$box" "$name" "$D/$dir" <<'PY'
import sys
from PIL import Image
box, name, out = sys.argv[1], sys.argv[2], sys.argv[3]
im = Image.open('/tmp/raw.png')
if box != 'full': im = im.crop(tuple(int(v) for v in box.split(',')))
if name != '-': im.save(f'{out}/{name}')
w, h = im.size; s = min(1.0, 900 / w)
im.resize((int(w*s), int(h*s))).save('/tmp/prev.png')
PY
