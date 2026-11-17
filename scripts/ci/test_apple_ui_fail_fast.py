"""Exercise the real shell runners with fake simulators and XCTest processes."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AppleUIFailFastTests(unittest.TestCase):
    def run_fixture(self, failure, ci=True):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for relative in ('scripts/ci/test-apple-ui.sh', 'apple/scripts/run-mock-ui-tests.sh'):
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, target)
            binaries = root / 'bin'
            binaries.mkdir()
            xcrun = binaries / 'xcrun'
            xcrun.write_text('#!/bin/bash\nprintf "%s\\n" "$*" >> "$CALL_LOG"\necho "{}"\n')
            xcrun.chmod(0o755)
            (root / 'scripts/ci/select_apple_ui_targets.py').write_text(
                'print("iphone\\tphone-id\\nipad\\ttablet-id")\n')
            checker = root / 'scripts/ci/check-xctest-result.py'
            checker.write_text('''import os, sys
if '--report-failures' in sys.argv:
    print('failure diagnostics retained')
    sys.exit(0)
sys.exit(1 if os.environ['FAILURE'] == 'result' else 0)
''')
            runner = '''#!/bin/bash
printf 'suite %s %s\n' "$3" "$MSIGN_UI_TEST_SOURCE" >> "$CALL_LOG"
mkdir -p "$4/GestureProof.xcresult"
[[ "$FAILURE" != runner ]]
'''
            for name in ('verification', 'protection', 'documents'):
                (root / f'apple/scripts/run-{name}-ui-tests.sh').write_text(runner)
            env = {**os.environ, 'PATH': f'{binaries}:{os.environ["PATH"]}',
                   'CALL_LOG': str(root / 'calls'), 'FAILURE': failure}
            env.pop('MSIGN_UI_FAIL_FAST', None)
            if ci:
                args = ['scripts/ci/test-apple-ui.sh', 'ios', 'Fake.app', str(root / 'out')]
            else:
                args = ['apple/scripts/run-mock-ui-tests.sh', 'ios', 'Fake.app',
                        'phone-id', str(root / 'out')]
            result = subprocess.run(['bash', *args], cwd=root, env=env,
                                    capture_output=True, text=True, timeout=15)
            return result, (root / 'calls').read_text().splitlines()

    def test_ci_stops_after_runner_or_result_failure_and_shuts_down(self):
        for failure in ('runner', 'result'):
            with self.subTest(failure=failure):
                result, calls = self.run_fixture(failure)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertEqual(sum(line.startswith('suite ') for line in calls), 1)
                self.assertNotIn('simctl boot tablet-id', calls)
                self.assertEqual(calls[-1], 'simctl shutdown phone-id')
                self.assertIn('failure diagnostics retained', result.stdout)

    def test_success_still_requires_every_suite_on_both_devices(self):
        result, calls = self.run_fixture('none')
        self.assertEqual(result.returncode, 0, result.stderr)
        for device in ('phone-id', 'tablet-id'):
            self.assertEqual(sum(line.startswith(f'suite {device} ') for line in calls), 11)
            self.assertIn(f'simctl shutdown {device}', calls)

    def test_local_investigation_still_collects_all_failures(self):
        result, calls = self.run_fixture('runner', ci=False)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(sum(line.startswith('suite ') for line in calls), 11)
