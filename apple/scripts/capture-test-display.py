#!/usr/bin/env python3
"""Forward a native test command and capture a foldable's active display at stable checkpoints."""
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import uuid

SIMULATOR_UDID = re.compile(r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}")
# `simctl io UDID enumerate` numbers displays from 1; an expanded iPhone Duo uses 3.
DISPLAYS = {"1": "1", "2": "2", "3": "3", "4": "4"}
CHECKPOINT = re.compile(r"MSIGN_UI_CAPTURE ([a-z0-9-]+)\s*")


def allowed_roots(env):
    """The repository, the runner's or user's temporary directory, and /tmp: where callers put results."""
    roots = [Path(__file__).resolve().parents[2], Path(tempfile.gettempdir()).resolve(), Path("/tmp").resolve()]
    if env.get("RUNNER_TEMP"):
        roots.append(Path(env["RUNNER_TEMP"]).resolve())
    return [str(root) for root in roots]


def output_directory(value, env):
    candidate = os.path.realpath(value)
    for root in allowed_roots(env):
        if os.path.commonpath([root, candidate]) == root:
            return Path(candidate)
    raise SystemExit(f"Output directory must be inside the repository, $RUNNER_TEMP or the temporary directory: {value}")


def simulator(value):
    if value == "booted":
        return "booted"
    if not SIMULATOR_UDID.fullmatch(value):
        raise SystemExit(f"Expected a simulator UDID or 'booted', got: {value!r}")
    return str(uuid.UUID(value)).upper()


def display_number(value):
    if value not in DISPLAYS:
        raise SystemExit(f"MSIGN_CAPTURE_DISPLAY must be one of {', '.join(DISPLAYS)}, got: {value!r}")
    return DISPLAYS[value]


def main(argv, env=os.environ):
    if len(argv) < 3:
        raise SystemExit("Usage: capture-test-display.py SIMULATOR_UDID OUTPUT_DIR COMMAND...")
    device, output, *command = argv
    destination = output_directory(output, env)
    requested = env.get("MSIGN_CAPTURE_DISPLAY")
    # Only a capture run passes the device and display to simctl; validate them before any work starts.
    capture = (simulator(device), display_number(requested)) if requested else None
    if capture:
        destination.mkdir(parents=True, exist_ok=True)
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, bufsize=1)
    capture_failed = False
    test_failed = False
    for line in process.stdout:
        print(line, end="", flush=True)
        if (env.get('MSIGN_UI_STOP_ON_FAILURE') == '1' and not test_failed
                and re.match(r"Test Case .+ failed \(", line)):
            # Ask xcodebuild to finish its result bundle instead of running the remaining
            # cases after a known failure. The outer worker still owns bounded cleanup.
            test_failed = True
            try:
                process.send_signal(signal.SIGINT)
            except ProcessLookupError:
                pass
        match = CHECKPOINT.fullmatch(line)
        if capture and match:
            udid, display = capture
            result = subprocess.run(["xcrun", "simctl", "io", udid, "screenshot",
                                     f"--display={display}", str(destination / (match[1] + ".png"))],
                                    capture_output=True, text=True)
            print(result.stdout + result.stderr, end="", flush=True)
            capture_failed |= result.returncode != 0
    process.stdout.close()
    code = process.wait()
    return code or int(capture_failed or test_failed)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
