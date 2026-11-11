"""Boot recovery cannot dismiss an app failure or hide recurring framework failures."""
import importlib.util
import json
import subprocess
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('android_ready', Path(__file__).with_name('prepare-android-ui.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

READY = '<hierarchy><node package="com.android.launcher3" text="Home" /></hierarchy>'
BOOT_DIALOG = '''<hierarchy>
<node text="System UI isn't responding" />
<node text="Wait" resource-id="android:id/aerr_wait" bounds="[10,20][110,60]" />
</hierarchy>'''
SYSTEM_DIALOG = BOOT_DIALOG.replace('System UI', 'Process system')
APP_DIALOG = BOOT_DIALOG.replace('System UI', 'eSemnBun')


class AndroidReadiness(unittest.TestCase):
    def run_readiness(self, states, expected_error=None, dump_errors=(), expected_states=None):
        states = iter(states)
        calls = []
        dump_errors = iter(dump_errors)
        def adb(args, **_):
            calls.append(args)
            if args[3:6] == ['shell', 'uiautomator', 'dump']:
                error = next(dump_errors, None)
                if error is not None:
                    raise error
            return next(states).encode() if args[3:6] == ['exec-out', 'cat', '/sdcard/ci-boot.xml'] else b'diagnostic'
        with tempfile.TemporaryDirectory() as folder, patch.object(module.subprocess, 'check_output', side_effect=adb), patch.object(module.time, 'sleep'):
            output = Path(folder) / 'boot'
            if expected_error:
                with self.assertRaisesRegex(RuntimeError, expected_error):
                    module.prepare('emulator-5554', output)
            else:
                module.prepare('emulator-5554', output)
            self.assertTrue((output / 'readiness.json').exists())
            if expected_states is not None:
                self.assertEqual(expected_states, json.loads((output / 'readiness.json').read_text())['states'])
        return [call for call in calls if call[3:6] == ['shell', 'input', 'tap']]

    def test_healthy_launcher_needs_no_recovery(self):
        self.assertEqual([], self.run_readiness([READY] * 3))

    def test_absent_initial_accessibility_root_is_not_a_healthy_observation(self):
        self.assertEqual([], self.run_readiness(['cat: no such file'] + [READY] * 3))

    def test_only_initial_system_ui_dialog_can_be_acknowledged(self):
        taps = self.run_readiness([BOOT_DIALOG] + [READY] * 3)
        self.assertEqual(1, len(taps))
        self.assertEqual(['60', '40'], taps[0][-2:])

    def test_recurring_system_ui_failure_stops_before_tests(self):
        taps = self.run_readiness([BOOT_DIALOG, READY, BOOT_DIALOG], 'did not recover')
        self.assertEqual(1, len(taps))

    def test_app_error_is_never_dismissed(self):
        self.assertEqual([], self.run_readiness([APP_DIALOG], 'Unexpected application error'))

    def test_missing_wait_action_fails(self):
        self.assertEqual([], self.run_readiness([BOOT_DIALOG.replace('android:id/aerr_wait', '')], 'no native Wait action'))

    def test_physical_device_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'dedicated emulator'):
            module.prepare('phone', Path('unused'))

    def test_initial_framework_process_anr_requires_a_stable_launcher(self):
        self.assertEqual(1, len(self.run_readiness([SYSTEM_DIALOG] + [READY] * 3)))

    def test_different_framework_failure_after_recovery_still_fails(self):
        self.assertEqual(1, len(self.run_readiness([SYSTEM_DIALOG, READY, BOOT_DIALOG], 'did not recover')))

    def test_second_framework_failure_before_healthy_observation_still_fails(self):
        self.assertEqual(1, len(self.run_readiness([SYSTEM_DIALOG, BOOT_DIALOG], "did not recover")))

    def test_boot_accessibility_connection_failure_requires_three_fresh_checks(self):
        error = subprocess.CalledProcessError(137, ['adb', 'shell', 'uiautomator', 'dump'])
        self.assertEqual([], self.run_readiness([READY] * 3, dump_errors=[error],
            expected_states=['waiting-accessibility-command'] + ['ready'] * 3))

    def test_accessibility_failure_resets_the_healthy_observation_count(self):
        error = subprocess.TimeoutExpired(['adb', 'shell', 'uiautomator', 'dump'], 20)
        self.assertEqual([], self.run_readiness([READY] * 5, dump_errors=[None, None, error],
            expected_states=['ready', 'ready', 'waiting-accessibility-command', 'ready', 'ready', 'ready']))

    def test_repeated_accessibility_failure_stops_before_installation(self):
        error = subprocess.CalledProcessError(137, ['adb', 'shell', 'uiautomator', 'dump'])
        self.assertEqual([], self.run_readiness([], 'Accessibility dump failed repeatedly', dump_errors=[error] * 3,
            expected_states=['waiting-accessibility-command'] * 3))
