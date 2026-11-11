"""Instrumentation's shell exit code does not establish suite completion."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AndroidSuiteBatchTests(unittest.TestCase):
    def run_batch(self, failure=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            adb = root / 'adb'
            adb.write_text('''#!/usr/bin/env python3
import os, sys
from pathlib import Path
args = sys.argv[1:]
if 'instrument' not in args:
    sys.exit(0)
phase = 'journeys' if 'journeys' in args else args[args.index('phase') + 1] if 'phase' in args else 'storage'
with Path(os.environ['CALLS']).open('a') as stream:
    stream.write(phase + '\\n')
if os.environ.get('FAIL_PHASE') == phase:
    print('INSTRUMENTATION_CODE: 0')
elif phase == 'journeys':
    print('INSTRUMENTATION_RESULT: result=' + '\\n'.join(f'case-{i}:pass' for i in range(33)))
    print('INSTRUMENTATION_CODE: -1')
else:
    print('INSTRUMENTATION_RESULT: result=PASS: complete')
    print('INSTRUMENTATION_CODE: -1')
''')
            adb.chmod(0o700)
            calls = root / 'calls'
            result = subprocess.run(['bash', str(ROOT / 'android/scripts/test-journeys.sh'),
                                     'emulator-5554', 'app.apk', 'tests.apk', str(root / 'evidence')],
                                    env=dict(os.environ, ADB=str(adb), CALLS=str(calls), FAIL_PHASE=failure or ''),
                                    capture_output=True, text=True)
            return result.returncode, calls.read_text().splitlines()

    def test_all_suites_are_required_including_both_restart_phases(self):
        status, calls = self.run_batch()
        self.assertEqual(status, 0)
        self.assertEqual(calls, ['journeys', 'storage', 'prepare', 'verify'])

    def test_instrumentation_failure_fails_even_when_adb_returns_success(self):
        for phase in ['journeys', 'storage', 'prepare', 'verify']:
            with self.subTest(phase=phase):
                status, calls = self.run_batch(phase)
                self.assertNotEqual(status, 0)
                self.assertEqual(calls[-1], phase)
