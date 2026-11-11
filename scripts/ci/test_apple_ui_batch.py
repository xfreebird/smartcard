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
if [[ "$FAIL_FIRST" == 1 && "$name" == VerificationJourneyUITests ]]; then exit 65; fi
''')
            shutil.copy(scripts / 'run-verification-ui-tests.sh', scripts / 'run-protection-ui-tests.sh')
            shutil.copy(scripts / 'run-verification-ui-tests.sh', scripts / 'run-documents-ui-tests.sh')
            checks = root / 'scripts/ci'
            checks.mkdir(parents=True)
            (checks / 'check-xctest-result.py').write_text('import sys\nassert sys.argv[2] in ("1", "2", "3", "5", "6")\n')
            calls = root / 'calls'
            result = subprocess.run(['bash', str(scripts / 'run-mock-ui-tests.sh'),
                                     platform, '/unused/app', 'mac', str(root / 'results')],
                                    env=dict(os.environ, CALLS=str(calls), FAIL_FIRST=str(int(fail_first))),
                                    capture_output=True, text=True)
            self.assertEqual(calls.read_text().splitlines(),
                             ['VerificationJourneyUITests', 'MockWorkflowUITests'] +
                             (['CardCarouselUITests', 'DemoModeUITests', 'ProtectionFlowUITests', 'DocumentsUITests'] if platform == 'ios' else []))
            return result.returncode

    def test_all_passing_suites_succeed(self):
        self.assertEqual(self.run_batch(False), 0)

    def test_failure_is_preserved_after_other_suite_runs(self):
        self.assertNotEqual(self.run_batch(True), 0)

    def test_mobile_includes_gestures_and_demo_even_after_failure(self):
        self.assertNotEqual(self.run_batch(True, "ios"), 0)

    def test_mobile_all_suites_succeed(self):
        self.assertEqual(self.run_batch(False, "ios"), 0)
