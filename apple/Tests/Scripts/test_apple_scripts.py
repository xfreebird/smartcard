"""Apple automation scripts, exercised in process with fake native tools (runs on any OS)."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import plistlib
import runpy
import stat
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest import mock

SCRIPTS = Path(__file__).resolve().parents[2] / 'scripts'


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), SCRIPTS / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


capture = load('capture-test-display')
helper_check = load('test-demo-insertion-helper')
seeding = load('seed-documents-ui-tests')


def python_command(source):
    return [sys.executable, '-c', textwrap.dedent(source)]


UDID = '76B17219-A89A-4293-9A37-C4B465894385'


class CaptureTestDisplayTests(unittest.TestCase):
    def run_capture(self, command, env, screenshot_codes=(), device=UDID):
        calls = []
        codes = list(screenshot_codes)

        def screenshot(args, **_):
            calls.append(args)
            return subprocess.CompletedProcess(args, codes.pop(0) if codes else 0, 'captured\n', '')

        output = io.StringIO()
        with tempfile.TemporaryDirectory() as directory, mock.patch.object(capture.subprocess, 'run', screenshot), \
                contextlib.redirect_stdout(output):
            code = capture.main([device, str(Path(directory) / 'shots'), *command], env=env)
            created = (Path(directory) / 'shots').is_dir()
        return code, calls, output.getvalue(), created

    def test_checkpoints_capture_the_configured_display(self):
        command = python_command('''
            print("MSIGN_UI_CAPTURE wallet-open")
            print("ordinary output")
            print("MSIGN_UI_CAPTURE Not-A-Checkpoint")
        ''')
        code, calls, output, created = self.run_capture(command, {'MSIGN_CAPTURE_DISPLAY': '3'})
        self.assertEqual(code, 0)
        self.assertTrue(created)
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][:6], ['xcrun', 'simctl', 'io', UDID, 'screenshot', '--display=3'])
        self.assertTrue(calls[0][6].endswith('wallet-open.png'))
        self.assertIn('ordinary output', output)
        self.assertIn('captured', output)

    def test_without_a_display_nothing_is_captured(self):
        code, calls, output, created = self.run_capture(python_command('print("MSIGN_UI_CAPTURE wallet")'), {})
        self.assertEqual((code, calls, created), (0, [], False))
        self.assertIn('MSIGN_UI_CAPTURE wallet', output)

    def test_failed_capture_or_command_fails_the_run(self):
        code, _, _, _ = self.run_capture(python_command('print("MSIGN_UI_CAPTURE a")'), {'MSIGN_CAPTURE_DISPLAY': '1'},
                                         screenshot_codes=[1])
        self.assertEqual(code, 1)
        code, _, _, _ = self.run_capture(python_command('import sys; sys.exit(65)'), {})
        self.assertEqual(code, 65)

    def test_first_failure_interrupts_the_remaining_cases(self):
        command = python_command('''
            import signal, sys, time
            signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
            print("Test Case '-[Suite testA]' failed (0.1 seconds).", flush=True)
            time.sleep(30)
            print("later case")
        ''')
        code, _, output, _ = self.run_capture(command, {'MSIGN_UI_STOP_ON_FAILURE': '1'})
        self.assertEqual(code, 1, 'the interrupted run still reports the failure')
        self.assertNotIn('later case', output)

    def test_failure_after_the_command_already_exited_is_still_reported(self):
        real_popen = subprocess.Popen

        class Exited(real_popen):
            def send_signal(self, signal):
                raise ProcessLookupError

        with mock.patch.object(capture.subprocess, 'Popen', Exited):
            code, _, output, _ = self.run_capture(python_command('print("Test Case \'t\' failed (1 seconds).")'),
                                                  {'MSIGN_UI_STOP_ON_FAILURE': '1'})
        self.assertEqual(code, 1)
        self.assertIn('failed', output)

    def test_lowercase_udid_and_booted_are_accepted(self):
        command = python_command('print("MSIGN_UI_CAPTURE closed")')
        _, calls, _, _ = self.run_capture(command, {'MSIGN_CAPTURE_DISPLAY': '1'}, device=UDID.lower())
        self.assertEqual(calls[0][3], UDID)
        _, calls, _, _ = self.run_capture(command, {'MSIGN_CAPTURE_DISPLAY': '1'}, device='booted')
        self.assertEqual(calls[0][3], 'booted')

    def test_untrusted_device_display_and_output_are_refused_before_running(self):
        command = python_command('raise SystemExit("must not run")')
        for device in ['--set', 'booted --help', '../../device', UDID[:-1], '']:
            with self.subTest(device=device), self.assertRaisesRegex(SystemExit, 'simulator UDID'):
                self.run_capture(command, {'MSIGN_CAPTURE_DISPLAY': '3'}, device=device)
        for display in ['0', '5', '3 --type=jpeg', '--display=1', '1;2', '../3']:
            with self.subTest(display=display), self.assertRaisesRegex(SystemExit, 'MSIGN_CAPTURE_DISPLAY'):
                self.run_capture(command, {'MSIGN_CAPTURE_DISPLAY': display})
        outside = Path.home().resolve() / 'esemnbun-capture-outside'
        for output in [str(outside), '/etc/esemnbun', str(Path(tempfile.gettempdir()) / '..' / '..' / 'escape')]:
            with self.subTest(output=output), self.assertRaisesRegex(SystemExit, 'Output directory'):
                capture.main([UDID, output, *command], env={'MSIGN_CAPTURE_DISPLAY': '3'})
        self.assertFalse(outside.exists())
        with self.assertRaisesRegex(SystemExit, 'Usage'):
            capture.main([UDID, tempfile.gettempdir()], env={})

    def test_symbolic_link_cannot_lead_the_output_outside(self):
        with tempfile.TemporaryDirectory() as directory:
            link = Path(directory) / 'link'
            link.symlink_to('/etc')
            with self.assertRaisesRegex(SystemExit, 'Output directory'):
                capture.main([UDID, str(link / 'shots'), sys.executable, '-c', 'pass'],
                             env={'MSIGN_CAPTURE_DISPLAY': '3'})

    def test_checkpoint_names_cannot_name_other_paths(self):
        command = python_command('''
            print("MSIGN_UI_CAPTURE ../../escape")
            print("MSIGN_UI_CAPTURE a/b")
            print("MSIGN_UI_CAPTURE Upper")
        ''')
        code, calls, _, _ = self.run_capture(command, {'MSIGN_CAPTURE_DISPLAY': '3'})
        self.assertEqual((code, calls), (0, []))

    def test_command_line_entry_point(self):
        with mock.patch.object(sys, 'argv', ['capture-test-display.py', 'device', tempfile.gettempdir(),
                                             sys.executable, '-c', 'print("ok")']), \
                mock.patch.dict(os.environ, {'MSIGN_CAPTURE_DISPLAY': ''}), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(SystemExit) as exit_code:
                runpy.run_path(str(SCRIPTS / 'capture-test-display.py'), run_name='__main__')
        self.assertEqual(exit_code.exception.code, 0)


FAKE_HELPER = '''#!{python}
# Stand-in for the Debug reader watcher: MOCK_WATCHER_DEMO_SUPPRESSED marks the fixture build.
import json, os, sys, time
snapshot = sys.argv[sys.argv.index('--mock-snapshot') + 1]
state = os.environ['FAKE_DEMO_STATE']
previous = None
while True:
    try:
        current = json.load(open(snapshot))
    except ValueError:
        current = previous
    demo = open(state).read() == 'true'
    if demo:
        print('MOCK_WATCHER_DEMO_SUPPRESSED', flush=True)
    elif previous is not None and any(name not in previous or (card and not previous[name]) for name, card in current.items()):
        print('MOCK_WATCHER_OPENED', flush=True)
    if os.environ.get('FAKE_OPEN_EARLY') == '1':
        print('MOCK_WATCHER_OPENED', flush=True)   # a broken helper that ignores demo mode
    if os.environ.get('FAKE_EXIT') == '1':
        sys.exit(3)
    previous = current
    time.sleep(0.05)
'''


class DemoInsertionHelperCheckTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        root = Path(self.directory.name)
        self.app = root / 'eSemnBun.app'
        helper = self.app / 'Contents/Helpers/esemnbun-reader-watcher'
        helper.parent.mkdir(parents=True)
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'md.esemnbun.mac'}))
        helper.write_text(FAKE_HELPER.format(python=sys.executable))
        helper.chmod(helper.stat().st_mode | stat.S_IXUSR)
        self.helper = helper
        self.state = root / 'demo-state'
        self.choices = []
        self.cleanups = 0

    def tearDown(self):
        self.directory.cleanup()

    def choice(self, enabled):
        self.choices.append(enabled)
        self.state.write_text('true' if enabled else 'false')

    def cleanup(self):
        self.cleanups += 1

    def run_check(self, **environment):
        with mock.patch.dict(os.environ, {'FAKE_DEMO_STATE': str(self.state), **environment}), \
                contextlib.redirect_stdout(io.StringIO()) as output:
            helper_check.run(self.app, choice=self.choice, cleanup=self.cleanup, quiet_interval=0.3)
        return output.getvalue()

    def test_demo_suppresses_launches_until_a_live_insertion(self):
        self.assertIn('PASSED', self.run_check())
        self.assertEqual(self.choices, [True, False])
        self.assertEqual(self.cleanups, 1)

    def test_launch_while_demo_is_on_fails(self):
        with self.assertRaises(AssertionError):
            self.run_check(FAKE_OPEN_EARLY='1')
        self.assertEqual(self.cleanups, 1, 'preferences are cleaned up after a failure')

    def test_helper_that_exits_is_reported(self):
        with self.assertRaisesRegex(AssertionError, 'exited prematurely'):
            self.run_check(FAKE_EXIT='1')

    def test_release_helper_without_the_fixture_is_refused(self):
        self.helper.write_text('#!/bin/sh\nexit 0\n')
        with self.assertRaisesRegex(SystemExit, 'Debug helper'):
            self.run_check()
        self.assertEqual(self.choices, [])

    def run_check_at(self, app):
        with contextlib.redirect_stdout(io.StringIO()):
            helper_check.run(app, choice=self.choice, cleanup=self.cleanup, quiet_interval=0.3)

    def test_only_the_watcher_inside_a_macos_esemnbun_bundle_runs(self):
        root = Path(self.directory.name)
        not_bundle = root / 'eSemnBun'
        not_bundle.mkdir()
        for app in [not_bundle, root / 'missing.app']:
            with self.subTest(app=app), self.assertRaisesRegex(SystemExit, 'eSemnBun.app bundle'):
                self.run_check_at(app)
        other = root / 'Other.app'
        (other / 'Contents').mkdir(parents=True)
        (other / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'md.esemnbun.ios'}))
        with self.assertRaisesRegex(SystemExit, 'not the macOS eSemnBun app'):
            self.run_check_at(other)
        (other / 'Contents/Info.plist').write_text('not a property list')
        with self.assertRaisesRegex(SystemExit, 'not the macOS eSemnBun app'):
            self.run_check_at(other)
        # A watcher that links to an executable elsewhere is not part of the bundle.
        outside = root / 'outside-watcher'
        self.helper.rename(outside)
        self.helper.symlink_to(outside)
        with self.assertRaisesRegex(SystemExit, 'no reader watcher inside the bundle'):
            self.run_check()
        self.helper.unlink()
        with self.assertRaisesRegex(SystemExit, 'no reader watcher inside the bundle'):
            self.run_check()
        self.assertEqual(self.choices, [], 'nothing runs before validation')

    def test_wait_times_out_with_the_log(self):
        log = Path(self.directory.name) / 'log'
        log.write_text('nothing yet')
        running = mock.Mock(poll=mock.Mock(return_value=None))
        with self.assertRaisesRegex(AssertionError, 'timed out: nothing yet'):
            helper_check.wait_for(log, running, lambda text: 'never' in text, timeout=0.2)

    def test_defaults_adapters_use_the_isolated_suite(self):
        with mock.patch.object(helper_check.subprocess, 'run') as run:
            helper_check.defaults_choice(True)
            helper_check.defaults_choice(False)
            helper_check.defaults_cleanup()
        self.assertEqual([call.args[0] for call in run.call_args_list], [
            ['defaults', 'write', helper_check.SUITE, 'demoModeEnabled', '-bool', 'true'],
            ['defaults', 'write', helper_check.SUITE, 'demoModeEnabled', '-bool', 'false'],
            ['defaults', 'delete', helper_check.SUITE]])
        self.assertTrue(helper_check.SUITE.startswith('md.esemnbun.qa.'))

    def test_command_line_entry_point(self):
        with mock.patch.object(sys, 'argv', ['test-demo-insertion-helper.py', str(self.app)]), \
                mock.patch.object(subprocess, 'run') as run, \
                mock.patch.dict(os.environ, {'FAKE_DEMO_STATE': str(self.state)}):
            # `defaults` is replaced; mirror its effect on the fake helper's state file.
            run.side_effect = lambda args, **_: self.state.write_text(args[-1]) if args[1] == 'write' else None
            with contextlib.redirect_stdout(io.StringIO()) as output:
                runpy.run_path(str(SCRIPTS / 'test-demo-insertion-helper.py'), run_name='__main__')
        self.assertIn('PASSED', output.getvalue())


class SeedDocumentFixturesTests(unittest.TestCase):
    def inputs(self, root):
        fixtures = root / 'fixtures'
        fixtures.mkdir()
        (fixtures / 'original.txt').write_text('synthetic original')
        (fixtures / 'detached-signature.xml').write_text('<signature/>')
        sample = root / 'sample.pdf'
        sample.write_bytes(b'%PDF-1.4 synthetic')
        return fixtures, sample

    def test_seeds_documents_and_three_isolated_profiles(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixtures, sample = self.inputs(root)
            container = root / 'container'
            seeding.seed(container, fixtures, sample)
            documents = container / 'Documents'
            self.assertEqual((documents / 'QA-synthetic-semnat.pdf').read_bytes(), sample.read_bytes())
            self.assertEqual((documents / 'Originals/original.txt').read_text(), 'synthetic original')
            profiles = sorted((container / 'Library/Preferences').glob('md.esemnbun.qa.documents.*.plist'))
            self.assertEqual([p.name for p in profiles], ['md.esemnbun.qa.documents.duo.plist',
                                                         'md.esemnbun.qa.documents.final.plist',
                                                         'md.esemnbun.qa.documents.history.plist'])
            values = plistlib.loads(profiles[0].read_bytes())
            history = json.loads(values['activity'])
            self.assertEqual([item['title'] for item in history], ['QA-synthetic-semnat.pdf', 'detached-signature.xml'])
            self.assertTrue(all(item['signedOutput'] and item['fileURL'].startswith('file://') for item in history))
            self.assertEqual((values['appLanguage'], values['appTheme']), ('en', 'light'))

    def test_refuses_a_reused_container_and_ambiguous_fixtures(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixtures, sample = self.inputs(root)
            container = root / 'container'
            seeding.seed(container, fixtures, sample)
            with self.assertRaisesRegex(AssertionError, 'fresh dedicated simulator'):
                seeding.seed(container, fixtures, sample)
            (fixtures / 'second.txt').write_text('another original')
            with self.assertRaises(AssertionError):
                seeding.seed(root / 'other', fixtures, sample)

    def test_paths_outside_simulator_containers_and_run_directories_are_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixtures, sample = self.inputs(root)
            outside = str(Path.home().resolve() / 'esemnbun-seed-outside')
            repository_container = str(SCRIPTS.parent / 'container')
            for arguments, message in [([outside, str(fixtures), str(sample)], 'app container'),
                                       ([repository_container, str(fixtures), str(sample)], 'app container'),
                                       ([str(root / 'container'), '/etc', str(sample)], 'fixtures directory'),
                                       ([str(root / 'container'), str(fixtures), '/etc/hosts'], 'sample PDF')]:
                with self.subTest(arguments=arguments), self.assertRaisesRegex(SystemExit, message):
                    seeding.main(arguments)
            with self.assertRaisesRegex(SystemExit, 'Usage'):
                seeding.main([str(root)])
            self.assertFalse((root / 'container').exists())
            self.assertFalse(Path(outside).exists())

    def test_command_line_entry_point(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixtures, sample = self.inputs(root)
            container = root / 'container'
            with mock.patch.object(sys, 'argv', ['seed-documents-ui-tests.py', str(container), str(fixtures), str(sample)]):
                runpy.run_path(str(SCRIPTS / 'seed-documents-ui-tests.py'), run_name='__main__')
            self.assertTrue((container / 'Documents/detached-signature.xml').is_file())


if __name__ == '__main__':
    unittest.main()
