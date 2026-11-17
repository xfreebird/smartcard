"""One native session must retain every suite and both filesystem postchecks."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AppleUISingleSessionTests(unittest.TestCase):
    def test_native_assertion_stops_remaining_tests_and_preserves_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            child = Path(directory) / 'native.py'
            child.write_text('import signal,time\n'
                             'signal.signal(signal.SIGINT, lambda *_: exit(0))\n'
                             'print("Test Case example failed (1.0 seconds).", flush=True)\n'
                             'time.sleep(30)\nprint("unexpected later test")\n')
            result = subprocess.run([sys.executable, str(ROOT / 'apple/scripts/capture-test-display.py'),
                                     'device', directory, sys.executable, str(child)],
                                    env={**os.environ, 'MSIGN_UI_STOP_ON_FAILURE': '1', 'MSIGN_CAPTURE_DISPLAY': ''},
                                    capture_output=True, text=True, timeout=5)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('failed', result.stdout)
            self.assertNotIn('unexpected later test', result.stdout)

    def test_boot_preparation_selects_only_the_assigned_family(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ci = root / 'scripts/ci'
            ci.mkdir(parents=True)
            shutil.copy(ROOT / 'scripts/ci/boot-ios-ui-device.sh', ci)
            (ci / 'select_apple_ui_targets.py').write_text('print("iPhone\\tphone-id\\niPad\\ttablet-id")\n')
            binaries = root / 'bin'
            binaries.mkdir()
            tool = binaries / 'xcrun'
            tool.write_text('#!/bin/sh\necho "$*" >> "$CALLS"\necho "{}"\n')
            tool.chmod(0o755)
            calls = root / 'calls'
            for family, device in [('iPhone', 'phone-id'), ('iPad', 'tablet-id')]:
                result = subprocess.run(['bash', str(ci / 'boot-ios-ui-device.sh'), family, str(root / family)],
                                        env={**os.environ, 'PATH': f'{binaries}:{os.environ["PATH"]}', 'CALLS': str(calls)},
                                        capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((root / family / 'device.txt').read_text().strip(), device)
            self.assertEqual([c for c in calls.read_text().splitlines() if c.startswith('simctl boot ')],
                             ['simctl boot phone-id', 'simctl boot tablet-id'])

    def run_batch(self, failure=''):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = root / 'apple/scripts'
            scripts.mkdir(parents=True)
            shutil.copy(ROOT / 'apple/scripts/run-ios-ui-batch.sh', scripts)
            for fixture in ('protection', 'documents'):
                (scripts / f'run-{fixture}-ui-tests.sh').write_text(
                    f'#!/bin/bash\necho "{fixture} $MSIGN_UI_FIXTURE_PHASE" >> "$CALLS"\n'
                    f'[[ "$FAILURE" != "{fixture}-$MSIGN_UI_FIXTURE_PHASE" ]]\n')
            (scripts / 'run-carousel-ui-tests.sh').write_text(
                '#!/bin/bash\necho "native $MSIGN_UI_TEST_SUITES" >> "$CALLS"\n'
                '[[ "$FAILURE" != native ]]\n')
            ci = root / 'scripts/ci'
            ci.mkdir(parents=True)
            (ci / 'check-xctest-result.py').write_text(
                'import os,sys\n'
                'with open(os.environ["CALLS"], "a") as f: f.write("result " + sys.argv[2] + "\\n")\n'
                'sys.exit(int(os.environ["FAILURE"] == "result"))\n')
            calls = root / 'calls'
            result = subprocess.run(['bash', str(scripts / 'run-ios-ui-batch.sh'),
                                     'Fake.app', 'device', str(root / 'out')],
                                    env={**os.environ, 'CALLS': str(calls), 'FAILURE': failure},
                                    capture_output=True, text=True, timeout=10)
            return result, calls.read_text().splitlines()

    def test_all_suites_share_one_session_before_both_postchecks(self):
        result, calls = self.run_batch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[:2], ['protection prepare', 'documents prepare'])
        native = [line for line in calls if line.startswith('native ')]
        self.assertEqual(len(native), 1)
        self.assertEqual(set(native[0].split()[1:]), {
            'VerificationJourneyUITests', 'MockWorkflowUITests', 'CardCarouselUITests',
            'NFCSigningChoiceUITests', 'PINActionsUITests', 'SharedCardPINUITests',
            'SettingsNavigationUITests', 'DemoModeUITests', 'ProtectionFlowUITests',
            'DocumentsUITests', 'FloatingActionUITests'})
        self.assertEqual(calls[-3:], ['result 35', 'protection verify', 'documents verify'])

    def test_prepare_native_count_and_postcheck_failures_cannot_turn_green(self):
        for failure in ('protection-prepare', 'documents-prepare', 'native',
                        'result', 'protection-verify', 'documents-verify'):
            with self.subTest(failure=failure):
                result, calls = self.run_batch(failure)
                self.assertNotEqual(result.returncode, 0)
                if failure in ('native', 'result'):
                    self.assertNotIn('protection verify', calls)
                if failure == 'native':
                    self.assertIn('result --report-failures', calls)
