#!/usr/bin/env python3
"""Send one handled Sentry verification error through an existing Debug macOS app's startup."""
import argparse
import os
import plistlib
from pathlib import Path
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('app', type=Path, help='Debug eSemnBun .app bundle')
args = parser.parse_args()
info = plistlib.loads((args.app / 'Contents/Info.plist').read_bytes())
binary = args.app / 'Contents/MacOS' / info['CFBundleExecutable']
if not binary.is_file() or not os.access(binary, os.X_OK):
    raise SystemExit('Missing app executable.')
# This print marker is compiled only in Debug. Never launch a production app as a test fixture.
strings = b''.join(subprocess.run(['strings', str(path)], check=True, capture_output=True).stdout
                   for path in [binary, *binary.parent.glob('*.debug.dylib')])
if b'SENTRY_APPLE_VERIFICATION_FLUSHED' not in strings:
    raise SystemExit('Use a Debug app with the opt-in verification fixture.')
env = os.environ.copy()
env.update(MSIGN_DEMO_CARDS='none', MSIGN_DEMO_PREVIEW='0', MSIGN_SENTRY_VERIFY='1',
           MSIGN_DEMO_PREFERENCES_SUITE='md.esemnbun.qa.sentry-verification',
           MSIGN_SENTRY_CONSENT_QA='1', NSUnbufferedIO='YES')
env.pop('MSIGN_SENTRY_DISABLED', None)
with tempfile.NamedTemporaryFile(prefix='esemnbun-sentry-verification-', suffix='.log', delete=False) as output:
    log = Path(output.name)
    process = subprocess.Popen([str(binary)], env=env, stdout=output, stderr=subprocess.STDOUT)
    try:
        print('In the isolated QA app, explicitly choose crash reporting in the first-launch consent sheet.')
        deadline = time.monotonic() + 55
        while time.monotonic() < deadline:
            if b'SENTRY_APPLE_VERIFICATION_FLUSHED' in log.read_bytes():
                print('Verification error captured and SDK flush completed; confirm ingestion in Sentry.')
                print(f'Local fixture log: {log}')
                break
            if process.poll() is not None:
                raise SystemExit(f'App exited before verification completed; inspect {log}')
            time.sleep(0.25)
        else:
            raise SystemExit(f'Verification timed out; inspect {log}')
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
