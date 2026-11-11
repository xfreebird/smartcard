#!/usr/bin/env python3
"""Check disk and memory after SDK installation, before launching the test emulator."""
import os
import shutil
from pathlib import Path

free = shutil.disk_usage(os.path.expanduser('~')).free
if free < 8 * 1024**3:
    raise SystemExit(f'Android emulator needs at least 8 GiB free; found {free / 1024**3:.1f} GiB')
print(f'Android emulator disk preflight: {free / 1024**3:.1f} GiB available')

# A private hosted runner has 8 GiB shared by the build and the emulator.
# Refuse to boot while compiler daemons still consume its working memory.
meminfo = Path("/proc/meminfo")
if meminfo.exists():
    available_kib = int(next(line.split()[1] for line in meminfo.read_text().splitlines()
                             if line.startswith("MemAvailable:")))
    available_gib = available_kib / 1024**2
    if available_gib < 3:
        raise SystemExit(f"Android emulator needs at least 3 GiB available RAM; found {available_gib:.1f} GiB")
    print(f"Android emulator memory preflight: {available_gib:.1f} GiB available")
