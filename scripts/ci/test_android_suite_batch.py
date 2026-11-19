"""Instrumentation's shell exit code does not establish suite completion."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AndroidSuiteBatchTests(unittest.TestCase):
    def run_batch(self, failure=None, wrong_identity_marker=False, wrong_browser_marker=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            adb = root / 'adb'
            adb.write_text('''#!/usr/bin/env python3
import os, sys
from pathlib import Path
args = sys.argv[1:]
if 'instrument' not in args:
    sys.exit(0)
phase = 'browser-authentication' if 'browser-authentication' in args else 'saved-identities' if 'saved-identities' in args else 'journeys' if 'journeys' in args else args[args.index('phase') + 1] if 'phase' in args else 'storage'
with Path(os.environ['CALLS']).open('a') as stream:
    stream.write(phase + '\\n')
if os.environ.get('FAIL_PHASE') == phase:
    print('INSTRUMENTATION_CODE: 0')
elif phase == 'saved-identities':
    print('INSTRUMENTATION_RESULT: result=PASS: ' + ('storage' if os.environ.get('WRONG_IDENTITY') else 'saved-identities'))
    print('INSTRUMENTATION_CODE: -1')
elif phase == 'browser-authentication':
    print('INSTRUMENTATION_RESULT: result=PASS: ' + ('storage' if os.environ.get('WRONG_BROWSER') else 'browser-authentication'))
    print('INSTRUMENTATION_CODE: -1')
elif phase == 'journeys':
    print('INSTRUMENTATION_RESULT: result=' + '\\n'.join(f'case-{i}:pass' for i in range(34)))
    print('INSTRUMENTATION_CODE: -1')
else:
    print('INSTRUMENTATION_RESULT: result=PASS: complete')
    print('INSTRUMENTATION_CODE: -1')
''')
            adb.chmod(0o700)
            calls = root / 'calls'
            result = subprocess.run(['bash', str(ROOT / 'android/scripts/test-journeys.sh'),
                                     'emulator-5554', 'app.apk', 'tests.apk', str(root / 'evidence')],
                                    env=dict(os.environ, ADB=str(adb), CALLS=str(calls), FAIL_PHASE=failure or '',
                                             WRONG_IDENTITY='yes' if wrong_identity_marker else '',
                                             WRONG_BROWSER='yes' if wrong_browser_marker else ''),
                                    capture_output=True, text=True)
            return result.returncode, calls.read_text().splitlines()

    def test_all_suites_are_required_including_both_restart_phases(self):
        status, calls = self.run_batch()
        self.assertEqual(status, 0)
        self.assertEqual(calls, ['journeys', 'storage', 'prepare', 'verify', 'saved-identities', 'browser-authentication'])

    def test_saved_identity_cannot_pass_with_another_suites_result(self):
        status, calls = self.run_batch(wrong_identity_marker=True)
        self.assertNotEqual(status, 0)
        self.assertEqual(calls[-1], 'saved-identities')

    def test_instrumentation_failure_fails_even_when_adb_returns_success(self):
        for phase in ['journeys', 'storage', 'prepare', 'verify', 'saved-identities', 'browser-authentication']:
            with self.subTest(phase=phase):
                status, calls = self.run_batch(phase)
                self.assertNotEqual(status, 0)
                self.assertEqual(calls[-1], phase)

    def test_browser_authentication_requires_its_own_completion_marker(self):
        status, calls = self.run_batch(wrong_browser_marker=True)
        self.assertNotEqual(status, 0)
        self.assertEqual(calls[-1], 'browser-authentication')
