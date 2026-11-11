#!/usr/bin/env python3
"""Check after SDK/image installation so emulator startup cannot hide a disk-space failure."""
import os
import shutil

free = shutil.disk_usage(os.path.expanduser('~')).free
if free < 8 * 1024**3:
    raise SystemExit(f'Android emulator needs at least 8 GiB free; found {free / 1024**3:.1f} GiB')
print(f'Android emulator disk preflight: {free / 1024**3:.1f} GiB available')
