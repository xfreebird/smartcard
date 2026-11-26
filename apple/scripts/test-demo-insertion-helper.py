#!/usr/bin/env python3
"""Check the existing Debug helper with fake snapshots and an isolated preferences domain."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import time

SUITE = 'md.esemnbun.qa.helper-demo-policy'
APP_IDENTIFIER = 'md.esemnbun.mac'
HELPER = 'Contents/Helpers/esemnbun-reader-watcher'


def defaults_choice(enabled):
    subprocess.run(['defaults', 'write', SUITE, 'demoModeEnabled', '-bool', 'true' if enabled else 'false'], check=True)


def defaults_cleanup():
    subprocess.run(['defaults', 'delete', SUITE], capture_output=True)


def wait_for(log, process, predicate, timeout=15):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate(log.read_text()):
            return
        if process.poll() is not None:
            raise AssertionError('Helper exited prematurely: ' + log.read_text())
        time.sleep(0.1)
    raise AssertionError('Helper state timed out: ' + log.read_text())


def bundled_helper(app):
    """The reader watcher inside a macOS eSemnBun .app bundle; anything else is refused."""
    bundle = os.path.realpath(app)
    if not bundle.endswith('.app') or not os.path.isdir(bundle):
        raise SystemExit(f'Pass the Debug eSemnBun.app bundle, not: {app}')
    try:
        info = plistlib.loads(Path(bundle, 'Contents/Info.plist').read_bytes())
    except (OSError, plistlib.InvalidFileException):
        info = {}
    if info.get('CFBundleIdentifier') != APP_IDENTIFIER:
        raise SystemExit(f'{app} is not the macOS eSemnBun app ({APP_IDENTIFIER}).')
    helper = os.path.realpath(os.path.join(bundle, HELPER))
    if os.path.commonpath([bundle, helper]) != bundle or not os.path.isfile(helper):
        raise SystemExit(f'{app} has no reader watcher inside the bundle.')
    return Path(helper)


def run(app, choice=defaults_choice, cleanup=defaults_cleanup, quiet_interval=1.1):
    helper = bundled_helper(app)
    # The fixture string is a literal in the Debug executable (what `strings` would list).
    if b'MOCK_WATCHER_DEMO_SUPPRESSED' not in helper.read_bytes():
        raise SystemExit('Use the current Debug helper with its mock-only fixture.')
    with tempfile.TemporaryDirectory(prefix='esemnbun-demo-helper-') as directory:
        directory = Path(directory)
        snapshot = directory / 'snapshot.json'
        log = directory / 'watcher.log'
        snapshot.write_text('{}')
        choice(True)
        env = dict(os.environ, MSIGN_DEMO_PREFERENCES_SUITE=SUITE)
        with log.open('wb') as output:
            # BundleProgram starts the executable with a relative argv[0] under launchd.
            process = subprocess.Popen([HELPER, '--mock-snapshot', str(snapshot)],
                                       executable=str(helper), env=env, stdout=output, stderr=subprocess.STDOUT)
            try:
                wait_for(log, process, lambda text: 'MOCK_WATCHER_DEMO_SUPPRESSED' in text)
                before = log.read_text().count('MOCK_WATCHER_DEMO_SUPPRESSED')
                snapshot.write_text(json.dumps({'fake-reader': False}))
                wait_for(log, process, lambda text: text.count('MOCK_WATCHER_DEMO_SUPPRESSED') > before)
                assert 'MOCK_WATCHER_OPENED' not in log.read_text()
                choice(False)
                time.sleep(quiet_interval)  # Two bounded sampling intervals establish no deferred launch on exit.
                assert 'MOCK_WATCHER_OPENED' not in log.read_text()
                snapshot.write_text(json.dumps({'fake-reader': True}))
                wait_for(log, process, lambda text: 'MOCK_WATCHER_OPENED' in text)
                print('PASSED: demo suppresses insertion launches; exit is quiet; next fake insertion opens the isolated app.')
            finally:
                process.terminate()
                process.wait(timeout=5)
                cleanup()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    run(parser.parse_args().app)
