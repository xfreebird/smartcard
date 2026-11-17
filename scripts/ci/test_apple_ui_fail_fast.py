"""Exercise the real shell runners with fake simulators and XCTest processes."""
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AppleUIFailFastTests(unittest.TestCase):
    def run_fixture(self, failure, ci=True, cancel=False, family="iPhone", prepared=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for relative in ('scripts/ci/test-apple-ui.sh', 'apple/scripts/run-mock-ui-tests.sh',
                             'scripts/ci/run-ios-ui-devices.py'):
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, target)
            binaries = root / 'bin'
            binaries.mkdir()
            xcrun = binaries / 'xcrun'
            xcrun.write_text('#!/bin/bash\nprintf "%s\\n" "$*" >> "$CALL_LOG"\necho "{}"\n')
            xcrun.chmod(0o755)
            (root / 'scripts/ci/select_apple_ui_targets.py').write_text(
                'print("iPhone\\tphone-id\\niPad\\ttablet-id")\n')
            checker = root / 'scripts/ci/check-xctest-result.py'
            checker.write_text('''import os, sys
if '--report-failures' in sys.argv:
    print('failure diagnostics retained')
    sys.exit(0)
sys.exit(1 if os.environ['FAILURE'] == 'result' else 0)
''')
            runner = '''#!/bin/bash
set -e
printf 'suite %s %s\n' "$3" "$MSIGN_UI_TEST_SOURCE" >> "$CALL_LOG"
mkdir -p "$4/GestureProof.xcresult"
if [[ "$MSIGN_UI_TEST_SOURCE" == *VerificationJourneyUITests.swift ]]; then
    touch "$SYNC_DIR/$3"
    if [[ "$FAILURE" == cancel ]]; then sleep 30; fi
fi
[[ "$FAILURE" != runner ]]
'''
            for name in ('verification', 'protection', 'documents'):
                (root / f'apple/scripts/run-{name}-ui-tests.sh').write_text(runner)
            (root / 'apple/scripts/run-carousel-ui-tests.sh').write_text('#!/bin/bash\nset -e\nprintf \'host-build %s\\n\' "$2" >> "$CALL_LOG"\n[[ "$FAILURE" != build ]] || exit 1\nmkdir -p "$3/DerivedData/Build/Products"\ntouch "$3/DerivedData/Build/Products/Host.xctestrun"\n')
            (root / 'sync').mkdir()
            env = {**os.environ, 'PATH': f'{binaries}:{os.environ["PATH"]}',
                   'CALL_LOG': str(root / 'calls'), 'FAILURE': failure, 'SYNC_DIR': str(root / 'sync')}
            for key in ('MSIGN_UI_FAIL_FAST', 'MSIGN_UI_RESOURCES_DIR', 'MSIGN_UI_XCTESTRUN', 'MSIGN_UI_DOCUMENT_FIXTURES'):
                env.pop(key, None)
            if prepared:
                resources = root / 'prepared'
                resources.mkdir()
                manifest = resources / 'Host.xctestrun'
                manifest.touch()
                (resources / 'xctestrun-path.txt').write_text(str(manifest) + '\n')
                (resources / 'fixtures').mkdir()
                env['MSIGN_UI_RESOURCES_DIR'] = str(resources)
            if ci:
                args = ['scripts/ci/test-apple-ui.sh', 'ios', 'Fake.app', str(root / 'out'), family]
            else:
                args = ['apple/scripts/run-mock-ui-tests.sh', 'ios', 'Fake.app',
                        'phone-id', str(root / 'out')]
            if cancel:
                process = subprocess.Popen(['bash', *args], cwd=root, env=env,
                                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                deadline = time.monotonic() + 5
                while len(list((root / 'sync').glob('*-id'))) < 1 and time.monotonic() < deadline:
                    time.sleep(0.01)
                process.send_signal(signal.SIGTERM)
                stdout, stderr = process.communicate(timeout=10)
                result = subprocess.CompletedProcess(args, process.returncode, stdout, stderr)
            else:
                result = subprocess.run(['bash', *args], cwd=root, env=env,
                                        capture_output=True, text=True, timeout=15)
            return result, (root / 'calls').read_text().splitlines()

    def test_ci_stops_after_runner_or_result_failure_and_shuts_down(self):
        for failure in ('runner', 'result'):
            with self.subTest(failure=failure):
                result, calls = self.run_fixture(failure)
                self.assertEqual(result.returncode, 1, result.stderr)
                suites = [line for line in calls if line.startswith('suite ')]
                self.assertTrue(suites)
                self.assertEqual(len(suites), 1)
                self.assertTrue(all('VerificationJourneyUITests.swift' in line for line in suites))
                self.assertIn('simctl shutdown phone-id', calls)
                self.assertNotIn('simctl boot tablet-id', calls)
                self.assertIn('failure diagnostics retained', result.stdout)

    def test_each_job_runs_every_suite_on_exactly_its_selected_device(self):
        for family, device, other in [('iPhone', 'phone-id', 'tablet-id'), ('iPad', 'tablet-id', 'phone-id')]:
            result, calls = self.run_fixture('none', family=family)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(sum(line.startswith(f'suite {device} ') for line in calls), 11)
            self.assertIn(f'simctl shutdown {device}', calls)
            self.assertNotIn(f'simctl boot {other}', calls)
            self.assertEqual(sum(line.startswith('suite ') for line in calls), 11)
            self.assertEqual(calls.count(f'host-build {device}'), 1)

    def test_ci_reuses_build_step_resources_without_rebuilding(self):
        result, calls = self.run_fixture('none', prepared=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sum(line.startswith('suite ') for line in calls), 11)
        self.assertFalse(any(line.startswith('host-build ') for line in calls))

    def test_harness_build_failure_stops_before_any_ui_suite(self):
        result, calls = self.run_fixture('build')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertFalse(any(line.startswith('suite ') for line in calls))
        self.assertIn('simctl shutdown phone-id', calls)

    def test_invalid_family_cannot_silently_omit_coverage(self):
        result, calls = self.run_fixture('none', family='phone')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(line.startswith('suite ') for line in calls))

    def test_cancellation_stops_worker_and_descendants_and_shuts_down(self):
        result, calls = self.run_fixture('cancel', cancel=True)
        self.assertEqual(result.returncode, 130, result.stderr)
        self.assertIn('simctl shutdown phone-id', calls)
        self.assertNotIn('simctl boot tablet-id', calls)

    def test_local_investigation_still_collects_all_failures(self):
        result, calls = self.run_fixture('runner', ci=False)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(sum(line.startswith('suite ') for line in calls), 11)

    def test_native_runners_disable_expensive_system_dumps_but_keep_results(self):
        for name in ('carousel', 'verification'):
            script = (ROOT / f'apple/scripts/run-{name}-ui-tests.sh').read_text()
            self.assertIn('-collect-test-diagnostics never', script)
            self.assertIn('-resultBundlePath', script)
