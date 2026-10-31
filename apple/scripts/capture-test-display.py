#!/usr/bin/env python3
"""Forward a native test command and capture a foldable's active display at stable checkpoints."""
import os
from pathlib import Path
import re
import subprocess
import sys

device, output, *command = sys.argv[1:]
display = os.environ.get("MSIGN_CAPTURE_DISPLAY")
destination = Path(output)
if display:
    destination.mkdir(parents=True, exist_ok=True)
process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           text=True, bufsize=1)
capture_failed = False
for line in process.stdout:
    print(line, end="", flush=True)
    match = re.fullmatch(r"MSIGN_UI_CAPTURE ([a-z0-9-]+)\s*", line)
    if display and match:
        result = subprocess.run(["xcrun", "simctl", "io", device, "screenshot",
                                 f"--display={display}", str(destination / (match[1] + ".png"))],
                                capture_output=True, text=True)
        print(result.stdout + result.stderr, end="", flush=True)
        capture_failed |= result.returncode != 0
code = process.wait()
sys.exit(code or int(capture_failed))
