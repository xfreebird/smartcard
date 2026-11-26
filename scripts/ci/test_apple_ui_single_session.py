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

    def run_batch(self, failure=''):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = root / 'apple/scripts'
            scripts.mkdir(parents=True)
            shutil.copy(ROOT / 'apple/scripts/run-ios-ui-batch.sh', scripts)
            for fixture in ('protection', 'documents'):
                (scripts / f'run-{fixture}-ui-tests.sh').write_text(
                    f'#!/bin/bash\necho "{fixture} $MSIGN_UI_FIXTURE_PHASE $(basename "$(dirname "$4")")" >> "$CALLS"\n'
                    f'[[ "$FAILURE" != "{fixture}-$MSIGN_UI_FIXTURE_PHASE" ]]\n')
            # The first session fails for `native` and every `lost*` case; only `lost-again` fails the rerun too.
            (scripts / 'run-carousel-ui-tests.sh').write_text(
                '#!/bin/bash\nmkdir -p "$3"\nrun=$(basename "$3")\necho "native $run $MSIGN_UI_TEST_SUITES" >> "$CALLS"\n'
                '[[ -z "$MSIGN_UI_SKIP_TESTS" ]] || echo "skip" $MSIGN_UI_SKIP_TESTS >> "$CALLS"\n'
                'if [[ $run == NativeBatch ]]; then [[ "$FAILURE" != native && "$FAILURE" != lost* ]]\n'
                'else [[ "$FAILURE" != lost-again ]]; fi\n')
            ci = root / 'scripts/ci'
            ci.mkdir(parents=True)
            # The checker reads xcresulttool's reports from standard input and records which ones it got.
            (ci / 'check-xctest-result.py').write_text(
                'import os,sys\n'
                'failure = os.environ["FAILURE"]\n'
                'reports = " ".join(sys.stdin.read().split())\n'
                'with open(os.environ["CALLS"], "a") as f: f.write(f"result {sys.argv[1]} <- {reports}\\n")\n'
                'if sys.argv[1] == "--retry-plan": sys.exit(0 if failure.startswith("lost") else 1)\n'
                'if sys.argv[1] == "--skip-list": print("VerificationJourneyUITests/testA\\nMockWorkflowUITests/testB")\n'
                'sys.exit(int(failure == "result" or (failure == "lost-combined" and sys.argv[1] == "--combined")))\n')
            binaries = root / 'bin'
            binaries.mkdir()
            (binaries / 'xcrun').write_text(
                '#!/bin/bash\nif [[ $1 == xcresulttool ]]; then echo "$4:$(basename "$(dirname "$6")")"; exit; fi\n'
                'echo "xcrun $*" >> "$CALLS"\n')
            (binaries / 'xcrun').chmod(0o755)
            calls = root / 'calls'
            result = subprocess.run(['bash', str(scripts / 'run-ios-ui-batch.sh'),
                                     'Fake.app', 'device', str(root / 'out')],
                                    env={**os.environ, 'CALLS': str(calls), 'FAILURE': failure,
                                         'PATH': str(binaries) + os.pathsep + os.environ['PATH']},
                                    capture_output=True, text=True, timeout=10)
            return result, calls.read_text().splitlines()

    def test_all_suites_share_one_session_before_both_postchecks(self):
        result, calls = self.run_batch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[:2], ['protection prepare out', 'documents prepare out'])
        native = [line for line in calls if line.startswith('native ')]
        self.assertEqual(len(native), 1)
        self.assertEqual(native[0].split()[1], 'NativeBatch')
        self.assertEqual(set(native[0].split()[2:]), {
            'VerificationJourneyUITests', 'MockWorkflowUITests', 'CardCarouselUITests',
            'NFCSigningChoiceUITests', 'PINActionsUITests', 'SharedCardPINUITests',
            'SettingsNavigationUITests', 'DemoModeUITests', 'ProtectionFlowUITests',
            'DocumentsUITests', 'FloatingActionUITests'})
        self.assertEqual(calls[-3:], ['result 35 <- summary:NativeBatch', 'protection verify out', 'documents verify out'])

    def test_lost_app_process_reruns_once_on_an_erased_simulator_with_fresh_fixtures(self):
        result, calls = self.run_batch('lost')
        self.assertEqual(result.returncode, 0, result.stderr)
        suites = calls[2].split(' ', 2)[2]
        self.assertEqual(calls[2:], [
            'native NativeBatch ' + suites, 'result --retry-plan <- summary:NativeBatch tests:NativeBatch',
            'result --skip-list <- tests:NativeBatch',
            'xcrun simctl shutdown device', 'xcrun simctl erase device', 'xcrun simctl boot device',
            'xcrun simctl bootstatus device -b', 'xcrun simctl install device Fake.app',
            'protection prepare Rerun', 'documents prepare Rerun',
            'native NativeRerun ' + suites,
            'skip VerificationJourneyUITests/testA MockWorkflowUITests/testB',
            'result --combined <- tests:NativeBatch summary:NativeRerun tests:NativeRerun',
            'protection verify Rerun', 'documents verify Rerun'])

    def test_prepare_native_count_rerun_and_postcheck_failures_cannot_turn_green(self):
        for failure in ('protection-prepare', 'documents-prepare', 'native', 'result', 'lost-again',
                        'lost-combined', 'protection-verify', 'documents-verify'):
            with self.subTest(failure=failure):
                result, calls = self.run_batch(failure)
                self.assertNotEqual(result.returncode, 0)
                if failure in ('native', 'result', 'lost-again', 'lost-combined'):
                    self.assertFalse(any(line.startswith('protection verify') for line in calls))
                if failure == 'native':
                    self.assertIn('result --retry-plan <- summary:NativeBatch tests:NativeBatch', calls)
                    self.assertFalse(any(line.startswith(('native NativeRerun', 'xcrun simctl erase')) for line in calls))
                if failure == 'lost-again':
                    self.assertEqual(calls[-1], 'result --report-failures <- summary:NativeRerun')

