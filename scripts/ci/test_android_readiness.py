"""Boot recovery cannot dismiss an app failure or hide recurring System UI failures."""
import importlib.util
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
APP_DIALOG = BOOT_DIALOG.replace('System UI', 'eSemnBun')


class AndroidReadiness(unittest.TestCase):
    def run_readiness(self, states, expected_error=None):
        states = iter(states)
        calls = []
        def adb(args, **_):
            calls.append(args)
            return next(states).encode() if args[3:6] == ['exec-out', 'cat', '/sdcard/ci-boot.xml'] else b'diagnostic'
        with tempfile.TemporaryDirectory() as folder, patch.object(module.subprocess, 'check_output', side_effect=adb), patch.object(module.time, 'sleep'):
            output = Path(folder) / 'boot'
            if expected_error:
                with self.assertRaisesRegex(RuntimeError, expected_error):
                    module.prepare('emulator-5554', output)
            else:
                module.prepare('emulator-5554', output)
            self.assertTrue((output / 'readiness.json').exists())
        return [call for call in calls if call[3:6] == ['shell', 'input', 'tap']]

    def test_healthy_launcher_needs_no_recovery(self):
        self.assertEqual([], self.run_readiness([READY] * 3))

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
