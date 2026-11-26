"""A failing first suite must not hide the second suite or turn the batch green."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AppleUIBatchTests(unittest.TestCase):
    def run_batch(self, fail_first, platform="macos"):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            scripts = root / 'apple/scripts'
            scripts.mkdir(parents=True)
            shutil.copy(ROOT / 'apple/scripts/run-mock-ui-tests.sh', scripts)
            (scripts / 'run-verification-ui-tests.sh').write_text('''#!/bin/bash
name=$(basename "$MSIGN_UI_TEST_SOURCE" .swift)
echo "$name" >> "$CALLS"
if [[ "$PLATFORM" == ios && ${MSIGN_UI_APP_INSTALLED:-0} != 1 ]]; then exit 99; fi
if [[ "$FAIL_FIRST" == 1 && "$name" == VerificationJourneyUITests ]]; then exit 65; fi
''')
            shutil.copy(scripts / 'run-verification-ui-tests.sh', scripts / 'run-protection-ui-tests.sh')
            shutil.copy(scripts / 'run-verification-ui-tests.sh', scripts / 'run-documents-ui-tests.sh')
            checks = root / 'scripts/ci'
            checks.mkdir(parents=True)
            # The runner pipes each suite's xcresulttool summary into the checker with the expected count.
            (checks / 'check-xctest-result.py').write_text(
                'import sys\nassert sys.argv[1] in ("1", "2", "3", "4", "5", "6", "7")\n'
                'assert sys.stdin.read().startswith("summary ")\n')
            binaries = root / 'bin'
            binaries.mkdir()
            installer = binaries / 'xcrun'
            installer.write_text('#!/bin/bash\nif [[ $1 == xcresulttool ]]; then echo "$4 $6"; exit; fi\n'
                                 'printf "%s\\n" "$*" >> "$INSTALLS"\n')
            installer.chmod(0o755)
            installs = root / 'installs'
            calls = root / 'calls'
            resources = root / 'prepared'
            resources.mkdir()
            manifest = resources / 'Host.xctestrun'
            manifest.touch()
            (resources / 'xctestrun-path.txt').write_text(str(manifest) + '\n')
            result = subprocess.run(['bash', str(scripts / 'run-mock-ui-tests.sh'),
                                     platform, '/unused/app', 'mac', str(root / 'results')],
                                    env=dict(os.environ, CALLS=str(calls), INSTALLS=str(installs), PLATFORM=platform,
                                             PATH=str(binaries) + os.pathsep + os.environ['PATH'], FAIL_FIRST=str(int(fail_first)), GITHUB_ACTIONS="true",
                                             MSIGN_UI_RESOURCES_DIR=str(resources), MSIGN_UI_FAIL_FAST="0"),
                                    capture_output=True, text=True)
            self.assertEqual(calls.read_text().splitlines(),
                             ['VerificationJourneyUITests', 'MockWorkflowUITests'] +
                             (['CardCarouselUITests', 'NFCSigningChoiceUITests', 'PINActionsUITests', 'SharedCardPINUITests', 'SettingsNavigationUITests', 'DemoModeUITests', 'ProtectionFlowUITests', 'DocumentsUITests', 'FloatingActionUITests'] if platform == 'ios' else ['MacFloatingActionUITests']))
            if platform == 'ios':
                self.assertEqual(installs.read_text().splitlines(), ['simctl install mac /unused/app'])
            else:
                self.assertFalse(installs.exists())
            if fail_first:
                self.assertIn(f"::error title=Native UI failure::{platform}/VerificationJourneyUITests failed", result.stdout)
            else:
                self.assertNotIn("::error", result.stdout)
            return result.returncode

    def test_all_passing_suites_succeed(self):
        self.assertEqual(self.run_batch(False), 0)

    def test_failure_is_preserved_after_other_suite_runs(self):
        self.assertNotEqual(self.run_batch(True), 0)

    def test_mobile_includes_gestures_and_demo_even_after_failure(self):
        self.assertNotEqual(self.run_batch(True, "ios"), 0)

    def test_mobile_all_suites_succeed(self):
        self.assertEqual(self.run_batch(False, "ios"), 0)
