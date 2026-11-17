"""Prepared XCTest runs must select a suite, avoid rebuilding, and propagate failure."""
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AppleUIPrebuiltTests(unittest.TestCase):
    def run_fixture(self, exit_code=0, manifest_exists=True):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = root / 'apple/scripts'
            scripts.mkdir(parents=True)
            for name in ('run-carousel-ui-tests.sh', 'capture-test-display.py'):
                shutil.copyfile(ROOT / 'apple/scripts' / name, scripts / name)
            app = root / 'Fake.app'
            app.mkdir()
            (app / 'Info.plist').write_bytes(plistlib.dumps({
                'CFBundleIdentifier': 'md.esemnbun.ios',
                'CFBundleSupportedPlatforms': ['iPhoneSimulator'],
                'CFBundleExecutable': 'eSemnBun'}))
            (app / 'eSemnBun').write_bytes(b'MSIGN_DEMO_CARDS')
            manifest = root / 'Host.xctestrun'
            if manifest_exists:
                manifest.touch()
            binaries = root / 'bin'
            binaries.mkdir()
            commands = {
                'xcrun': '#!/bin/sh\necho \'{"devices":{"runtime":[{"udid":"tablet-id","state":"Booted"}]}}\'\n',
                'xcodegen': '#!/bin/sh\nexit 99\n',
                'xcodebuild': '#!/usr/bin/env python3\nimport json, os, sys\n'
                              'open(os.environ["CALL_LOG"], "w").write(json.dumps(sys.argv[1:]))\n'
                              'sys.exit(int(os.environ["TEST_EXIT_CODE"]))\n',
            }
            for name, body in commands.items():
                tool = binaries / name
                tool.write_text(body)
                tool.chmod(0o755)
            calls = root / 'calls.json'
            env = {**os.environ, 'PATH': f'{binaries}:{os.environ["PATH"]}',
                   'MSIGN_UI_XCTESTRUN': str(manifest), 'MSIGN_UI_TEST_SOURCE': '/fixtures/MockWorkflowUITests.swift',
                   'CALL_LOG': str(calls), 'TEST_EXIT_CODE': str(exit_code)}
            env.pop('MSIGN_UI_BUILD_ONLY', None)
            env.pop('MSIGN_CAPTURE_DISPLAY', None)
            result = subprocess.run(['bash', str(scripts / 'run-carousel-ui-tests.sh'),
                                     str(app), 'tablet-id', str(root / 'results')],
                                    env=env, capture_output=True, text=True, timeout=10)
            return result, json.loads(calls.read_text()) if calls.exists() else []

    def test_prebuilt_suite_runs_without_a_build_or_project_generator(self):
        result, args = self.run_fixture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(args[0], 'test-without-building')
        self.assertIn('-xctestrun', args)
        self.assertIn('-only-testing:GestureTests/MockWorkflowUITests', args)
        self.assertIn('-resultBundlePath', args)
        self.assertNotIn('-project', args)

    def test_native_failure_is_not_hidden_by_log_capture(self):
        result, args = self.run_fixture(exit_code=7)
        self.assertEqual(result.returncode, 7)
        self.assertTrue(args)

    def test_missing_manifest_fails_before_invoking_xcode(self):
        result, args = self.run_fixture(manifest_exists=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(args, [])
