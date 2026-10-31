#!/usr/bin/env python3
"""Check the existing Debug helper with fake snapshots and an isolated preferences domain."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('app', type=Path)
args = parser.parse_args()
helper = args.app / 'Contents/Helpers/esemnbun-reader-watcher'
if b'MOCK_WATCHER_DEMO_SUPPRESSED' not in subprocess.check_output(['strings', str(helper)]):
    raise SystemExit('Use the current Debug helper with its mock-only fixture.')
suite = 'md.esemnbun.qa.helper-demo-policy'
def choice(enabled):
    subprocess.run(['defaults', 'write', suite, 'demoModeEnabled', '-bool', 'true' if enabled else 'false'], check=True)
with tempfile.TemporaryDirectory(prefix='esemnbun-demo-helper-') as directory:
    directory = Path(directory)
    snapshot = directory / 'snapshot.json'
    log = directory / 'watcher.log'
    snapshot.write_text('{}')
    choice(True)
    env = dict(os.environ, MSIGN_DEMO_PREFERENCES_SUITE=suite)
    with log.open('wb') as output:
        process = subprocess.Popen([str(helper), '--mock-snapshot', str(snapshot)], env=env, stdout=output, stderr=subprocess.STDOUT)
        try:
            def wait_for(predicate, timeout=15):
                deadline = time.monotonic() + timeout
                while time.monotonic() < deadline:
                    if predicate(log.read_text()):
                        return
                    if process.poll() is not None:
                        raise AssertionError('Helper exited prematurely: ' + log.read_text())
                    time.sleep(0.1)
                raise AssertionError('Helper state timed out: ' + log.read_text())
            wait_for(lambda text: 'MOCK_WATCHER_DEMO_SUPPRESSED' in text)
            before = log.read_text().count('MOCK_WATCHER_DEMO_SUPPRESSED')
            snapshot.write_text(json.dumps({'fake-reader': False}))
            wait_for(lambda text: text.count('MOCK_WATCHER_DEMO_SUPPRESSED') > before)
            assert 'MOCK_WATCHER_OPENED' not in log.read_text()
            choice(False)
            time.sleep(1.1)  # Two bounded sampling intervals establish no deferred launch on exit.
            assert 'MOCK_WATCHER_OPENED' not in log.read_text()
            snapshot.write_text(json.dumps({'fake-reader': True}))
            wait_for(lambda text: 'MOCK_WATCHER_OPENED' in text)
            print('PASSED: demo suppresses insertion launches; exit is quiet; next fake insertion opens the isolated app.')
        finally:
            process.terminate()
            process.wait(timeout=5)
            subprocess.run(['defaults', 'delete', suite], capture_output=True)
