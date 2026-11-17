#!/usr/bin/env python3
"""Run both required device families on one billed runner; stop both on failure."""
from concurrent.futures import ThreadPoolExecutor
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]


def worker(app, device, out):
    subprocess.run(['xcrun', 'simctl', 'boot', device], check=True)
    subprocess.run(['xcrun', 'simctl', 'bootstatus', device, '-b'], check=True)
    return subprocess.call(['bash', str(ROOT / 'apple/scripts/run-mock-ui-tests.sh'),
                            'ios', app, device, out],
                           env={**os.environ, 'MSIGN_UI_FAIL_FAST': '1'})


def stop_groups(processes):
    # XCTest launches child processes: terminate the group, not just its shell.
    processes = [process for process in processes if process.poll() is None]
    for process in processes:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    deadline = time.monotonic() + 2
    while any(p.poll() is None for p in processes) and time.monotonic() < deadline:
        time.sleep(0.05)
    for process in processes:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def shutdown(device):
    try:
        subprocess.run(['xcrun', 'simctl', 'shutdown', device], timeout=20, check=False)
    except subprocess.TimeoutExpired:
        print(f'::warning::Simulator shutdown timed out: {device}', flush=True)


def run(app, targets_path, out):
    targets = [line.split('\t') for line in Path(targets_path).read_text().splitlines() if line]
    if (len(targets) != 2 or any(len(row) != 2 for row in targets)
            or {row[0] for row in targets} != {'iPhone', 'iPad'}
            or len({row[1] for row in targets}) != 2):
        raise ValueError('Exactly one distinct iPhone and iPad target are required')
    processes = []

    def cancelled(signum, frame):
        raise KeyboardInterrupt

    previous = {sig: signal.signal(sig, cancelled) for sig in (signal.SIGINT, signal.SIGTERM)}
    try:
        for family, device in targets:
            print(f'Starting {family} UI suites on {device}', flush=True)
            processes.append(subprocess.Popen(
                [sys.executable, __file__, '--worker', app, device, str(Path(out) / family)],
                start_new_session=True))
        while True:
            states = [process.poll() for process in processes]
            if any(state is not None and state != 0 for state in states):
                print('::error::A required iOS device failed; stopping the other device to conserve runner minutes.', flush=True)
                return 1
            if all(state == 0 for state in states):
                return 0
            time.sleep(0.2)
    except KeyboardInterrupt:
        return 130
    finally:
        for sig in previous:
            signal.signal(sig, signal.SIG_IGN)
        stop_groups(processes)
        with ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(shutdown, [device for _, device in targets]))
        for sig, handler in previous.items():
            signal.signal(sig, handler)


if __name__ == '__main__':
    if sys.argv[1] == '--worker':
        sys.exit(worker(*sys.argv[2:]))
    sys.exit(run(*sys.argv[1:]))
