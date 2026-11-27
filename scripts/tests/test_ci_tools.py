"""CI helper scripts: preflights, policy gates, device orchestration and job selection edge cases."""
import hashlib
import io
import json
import os
from pathlib import Path
import signal
import subprocess
from types import SimpleNamespace
from unittest.mock import Mock, patch
import zipfile

from support import REPO, TempCase, completed, copy_into, load, run

GIB = 1024 ** 3


class EmulatorResourceTests(TempCase):
    def preflight(self, free_gib, meminfo=None):
        real_exists, real_read = Path.exists, Path.read_text

        def exists(path):
            return meminfo is not None if str(path) == '/proc/meminfo' else real_exists(path)

        def read_text(path, *args, **kwargs):
            return meminfo if str(path) == '/proc/meminfo' else real_read(path, *args, **kwargs)
        with patch('shutil.disk_usage', return_value=SimpleNamespace(free=free_gib * GIB)), \
                patch.object(Path, 'exists', exists), patch.object(Path, 'read_text', read_text):
            return run('scripts/ci/check-emulator-resources.py')

    def test_disk_and_memory_thresholds(self):
        result = self.preflight(20)
        self.assertEqual((result.code, result.stdout), (0, 'Android emulator disk preflight: 20.0 GiB available\n'))
        self.assertIn('needs at least 8 GiB free; found 7.5 GiB', self.preflight(7.5).code)
        result = self.preflight(9, 'MemTotal: 1\nMemAvailable: 4194304 kB\n')
        self.assertIn('Android emulator memory preflight: 4.0 GiB available', result.stdout)
        self.assertIn('at least 3 GiB available RAM; found 2.0 GiB', self.preflight(9, 'MemAvailable: 2097152 kB\n').code)


class LinuxDesignSystemTests(TempCase):
    def test_design_system_compiles_in_an_isolated_package(self):
        tool = load('scripts/ci/check-linux-design-system.py')
        sources = self.tmp / 'linux/Sources'
        for relative in ('CAdwaita/module.modulemap', 'MoldSignGnome/Presentation/DesignSystem/Tokens.swift',
                         'MoldSignGnome/Infrastructure/GTK/Gtk.swift', 'MoldSignGnome/Infrastructure/Localization/L10n.swift',
                         'MoldSignGnome/Infrastructure/Localization/LocalizationFormat.swift'):
            (sources / relative).parent.mkdir(parents=True, exist_ok=True)
            (sources / relative).write_text('// ' + relative)
        tool.ROOT = self.tmp
        seen = {}

        def build(command, check):
            package = Path(command[3])
            seen['files'] = sorted(p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file())
            seen['manifest'] = (package / 'Package.swift').read_text()
            seen['command'] = command
            return completed(command)
        with patch.object(tool.subprocess, 'run', build), patch.dict(os.environ, {'SWIFT': '/opt/swift/bin/swift'}):
            tool.main()
        self.assertEqual(seen['command'][:3], ['/opt/swift/bin/swift', 'build', '--package-path'])
        self.assertIn('Sources/DesignSystem/L10n.swift', seen['files'])
        self.assertIn('Sources/CAdwaita/module.modulemap', seen['files'])
        self.assertIn('.systemLibrary(name: "CAdwaita", pkgConfig: "libadwaita-1")', seen['manifest'])
        self.assertFalse(Path(seen['command'][3]).exists())


class XCTestResultTests(TempCase):
    SUMMARY = {'result': 'Failed', 'passedTests': 1, 'totalTestCount': 2, 'failedTests': 1, 'skippedTests': 0,
               'testFailures': [{'testIdentifierString': 'Suite/test', 'failureText': '100% wrong\nAX tree'}, {}]}

    def check(self, *args, env=None):
        # The runners pipe xcresulttool's summary in; the checker takes no bundle path.
        return run('scripts/ci/check-xctest-result.py', *args, stdin=json.dumps(self.SUMMARY), env=env or {})

    def test_failures_are_reported_as_single_workflow_commands(self):
        result = self.check('--report-failures', env={'GITHUB_ACTIONS': 'true'})
        self.assertEqual(result.stdout.splitlines(), [
            '::error title=Native XCTest failure::Suite/test: 100%25 wrong%0AAX tree',
            '::error title=Native XCTest failure::XCTest: Unknown failure'])
        with patch.dict(os.environ, {'GITHUB_ACTIONS': 'false'}):
            local = self.check('--report-failures')
        self.assertEqual(local.stdout.splitlines()[0], 'Suite/test: 100% wrong')

    def test_incomplete_runs_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Expected 2 passing tests without skips'):
            self.check('2')
        tool = load('scripts/ci/check-xctest-result.py')
        tool.require_complete({'result': 'Passed', 'passedTests': 3, 'totalTestCount': 3, 'failedTests': 0,
                               'skippedTests': 0}, 3)


class FakeProcess:
    def __init__(self, states):
        self.states = list(states)
        self.pid = 4242
        self.waited = False

    def poll(self):
        state = self.states[0] if len(self.states) == 1 else self.states.pop(0)
        if isinstance(state, BaseException):
            raise state
        return state

    def wait(self):
        self.waited = True
        return 0


class IOSDeviceRunnerTests(TempCase):
    def setUp(self):
        super().setUp()
        self.runner = load('scripts/ci/run-ios-ui-devices.py')
        self.targets = self.tmp / 'targets.tsv'
        self.targets.write_text('iPhone\tPHONE-1\niPad\tPAD-1\n')

    def execute(self, family, states, shutdown=None):
        processes = []

        def popen(command, start_new_session):
            self.assertTrue(start_new_session)
            processes.append((command, FakeProcess(states)))
            return processes[-1][1]
        with patch.object(self.runner.subprocess, 'Popen', popen), \
                patch.object(self.runner.subprocess, 'run', shutdown or Mock(return_value=completed())) as simctl, \
                patch.object(self.runner.os, 'killpg') as killpg, patch.object(self.runner.time, 'sleep'), \
                patch('sys.stdout', io.StringIO()) as out:
            code = self.runner.run('App.app', self.targets, self.tmp / 'out', family)
        return code, processes, simctl, killpg, out.getvalue()

    def test_selected_family_runs_in_its_own_worker_and_simulator_is_shut_down(self):
        code, processes, simctl, killpg, out = self.execute('iPad', [None, 0])
        self.assertEqual(code, 0)
        command = processes[0][0]
        self.assertEqual(command[2:], ['--worker', 'App.app', 'PAD-1', str(self.tmp / 'out/iPad')])
        self.assertIn('Starting iPad UI suites on PAD-1', out)
        simctl.assert_called_once_with(['xcrun', 'simctl', 'shutdown', 'PAD-1'], timeout=20, check=False)
        killpg.assert_not_called()

    def test_failure_or_cancellation_stops_the_worker_group(self):
        code, processes, _, killpg, out = self.execute('iPhone', [3])
        self.assertEqual(code, 1)
        self.assertIn('::error::The required iOS device failed', out)
        code, processes, _, killpg, _ = self.execute('iPhone', [KeyboardInterrupt(), None])
        self.assertEqual(code, 130)
        self.assertEqual(killpg.call_args_list[0].args, (4242, signal.SIGTERM))
        self.assertEqual(killpg.call_args_list[-1].args, (4242, signal.SIGKILL))
        self.assertTrue(processes[0][1].waited)

    def test_shutdown_timeout_is_a_warning(self):
        timeout = Mock(side_effect=subprocess.TimeoutExpired('simctl', 20))
        code, _, _, _, out = self.execute('iPhone', [0], shutdown=timeout)
        self.assertEqual(code, 0)
        self.assertIn('::warning::Simulator shutdown timed out: PHONE-1', out)

    def test_group_stop_tolerates_exited_processes(self):
        process = FakeProcess([None, None, 0])
        with patch.object(self.runner.os, 'killpg', side_effect=ProcessLookupError), patch.object(self.runner.time, 'sleep'):
            self.runner.stop_groups([process, FakeProcess([0])])
        self.assertTrue(process.waited)

    def test_invalid_target_lists_are_rejected(self):
        for content, family, message in [('iPhone\tA\n', 'iPhone', 'Exactly one distinct'),
                                         ('iPhone\tA\niPad\tA\n', 'iPhone', 'Exactly one distinct'),
                                         ('iPhone\tA\niPad\tB\n', 'Watch', 'exactly one required')]:
            self.targets.write_text(content)
            with self.subTest(content=content), self.assertRaisesRegex(ValueError, message):
                self.runner.run('App.app', self.targets, self.tmp, family)

    def test_worker_boots_and_runs_fail_fast_suites(self):
        with patch('subprocess.run') as boot, patch('subprocess.call', return_value=5) as suites:
            result = run('scripts/ci/run-ios-ui-devices.py', '--worker', 'App.app', 'PAD-1', self.tmp)
        self.assertEqual(result.code, 5)
        self.assertEqual(boot.call_args_list[1].args[0], ['xcrun', 'simctl', 'bootstatus', 'PAD-1', '-b'])
        self.assertEqual(suites.call_args.args[0][1:], [str(REPO / 'apple/scripts/run-mock-ui-tests.sh'), 'ios', 'App.app',
                                                        'PAD-1', str(self.tmp)])
        self.assertEqual(suites.call_args.kwargs['env']['MSIGN_UI_FAIL_FAST'], '1')
        with patch('subprocess.Popen', return_value=FakeProcess([0])), patch('subprocess.run'), \
                patch('signal.signal'), patch('time.sleep'):
            self.assertEqual(run('scripts/ci/run-ios-ui-devices.py', 'App.app', self.targets, self.tmp, 'iPhone').code, 0)


class AppleTargetCommandTests(TempCase):
    def test_command_line_prints_targets_or_a_reason(self):
        devices = self.tmp / 'devices.json'
        runtimes = self.tmp / 'runtimes.json'
        runtime = 'com.apple.CoreSimulator.SimRuntime.iOS-26-1'
        devices.write_text(json.dumps({'devices': {runtime: [
            {'udid': 'P', 'isAvailable': True, 'name': 'iPhone 17', 'deviceTypeIdentifier': 'x.iPhone-17'},
            {'udid': 'T', 'isAvailable': True, 'name': 'iPad mini', 'deviceTypeIdentifier': 'x.iPad-mini-A17-Pro'}]}}))
        runtimes.write_text(json.dumps({'runtimes': [{'identifier': runtime, 'isAvailable': True, 'version': '26.1'}]}))
        result = run('scripts/ci/select_apple_ui_targets.py', devices, runtimes, '26.1')
        self.assertEqual(result.stdout, 'iPhone\tP\niPad\tT\n')
        self.assertIn('No available iPhone runtime', run('scripts/ci/select_apple_ui_targets.py', devices, runtimes, '27.0').code)
        self.assertIn('Unrecognized Apple version', run('scripts/ci/select_apple_ui_targets.py', devices, runtimes, 'x').code)
        self.assertIn('No such file', run('scripts/ci/select_apple_ui_targets.py', self.tmp / 'none', runtimes, '26.1').code)
        self.assertIn('Usage:', run('scripts/ci/select_apple_ui_targets.py').code)


class JobSelectionCommandTests(TempCase):
    def test_pull_request_selection_is_written_to_outputs_and_summary(self):
        event = self.tmp / 'event.json'
        event.write_text(json.dumps({'pull_request': {'base': {'sha': 'a'}, 'head': {'sha': 'b'}}}))
        output, summary = self.tmp / 'output', self.tmp / 'summary'
        changed = b'website/README.md\0scripts/package-macos.sh\0'
        with patch('subprocess.check_output', return_value=changed) as git:
            result = run('scripts/ci/select_jobs.py', '--event', event, '--output', output,
                         env={'GITHUB_STEP_SUMMARY': str(summary)})
        self.assertEqual(git.call_args_list[0].args[0], ['git', 'diff', '--name-only', '-z', 'a...b'])
        self.assertEqual(output.read_text(), result.stdout)
        self.assertIn('windows=true', result.stdout)
        self.assertIn('2 changed paths since the merge base.', summary.read_text())

    def test_unavailable_history_runs_everything(self):
        event = self.tmp / 'event.json'
        event.write_text(json.dumps({'before': '0' * 40, 'after': 'b'}))
        result = run('scripts/ci/select_jobs.py', '--event', event, env={'GITHUB_STEP_SUMMARY': str(self.tmp / 's')})
        self.assertEqual(result.stdout.count('=true'), 7)
        self.assertIn('Full CI: history unavailable.', (self.tmp / 's').read_text())
        selector = load('scripts/ci/select_jobs.py')
        failing = Mock(side_effect=subprocess.CalledProcessError(128, 'git'))
        self.assertIsNone(selector.changed_paths({'before': 'a', 'after': 'b'}, git=failing).paths)
        self.assertEqual(failing.call_args.args[0][-1], 'a..b')


class AndroidPolicyTests(TempCase):
    def setUp(self):
        super().setUp()
        self.policy = load('scripts/ci/android_build_policy.py')
        copy_into(self.tmp, 'android/gradle/libs.versions.toml', 'android/gradle/wrapper/gradle-wrapper.properties',
                  'android/gradle.properties', 'android/gradle/gradle-daemon-jvm.properties')

    def edit(self, relative, old, new):
        path = self.tmp / relative
        text = path.read_text()
        self.assertIn(old, text)
        path.write_text(text.replace(old, new, 1))

    def test_source_policy_rejects_weakened_toolchains(self):
        expected = self.policy.source_policy(self.tmp)
        wrapper = 'android/gradle/wrapper/gradle-wrapper.properties'
        url = self.policy.properties((self.tmp / wrapper).read_text())['distributionUrl']
        cases = [
            (wrapper, url.rsplit('/', 1)[1], 'gradle-9.0.0-bin.zip', 'Gradle 9.1+'),
            (wrapper, 'distributionSha256Sum=', 'distributionSha256Sum=x', 'SHA-256 must be pinned'),
            ('android/gradle/libs.versions.toml', f'agp = "{expected["agp"]}"', 'agp = "8.9.0"', 'AGP 9+'),
            ('android/gradle/libs.versions.toml', f'agp = "{expected["agp"]}"', 'agp = "9.0"', 'stable three-part'),
        ]
        for relative, old, new, message in cases:
            with self.subTest(message=message):
                copy_into(self.tmp, relative)
                self.edit(relative, old, new)
                with self.assertRaisesRegex(ValueError, message):
                    self.policy.source_policy(self.tmp)
                copy_into(self.tmp, relative)

    def bundle(self, r8, agp=None, size=None):
        path = self.tmp / 'app.aab'
        expected = self.policy.source_policy(self.tmp)
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr('BUNDLE-METADATA/com.android.tools.build.gradle/app-metadata.properties',
                             'androidGradlePluginVersion=' + (agp or expected['agp']) + ('\n#' + 'x' * size if size else ''))
            archive.writestr('BUNDLE-METADATA/com.android.tools/r8.json', json.dumps(r8))
        return path, expected

    def test_bundle_metadata_must_prove_release_optimization(self):
        good = {'options': {'isObfuscationEnabled': True, 'isOptimizationsEnabled': True, 'isShrinkingEnabled': True,
                            'isDebugModeEnabled': False, 'isProGuardCompatibilityModeEnabled': False},
                'resourceOptimization': {'isOptimizedShrinkingEnabled': True}}
        cases = [
            ([], 'structured R8'),
            ({**good, 'options': {**good['options'], 'isShrinkingEnabled': False}}, 'isShrinkingEnabled'),
            ({**good, 'options': {**good['options'], 'isDebugModeEnabled': True}}, 'non-Debug'),
        ]
        for r8, message in cases:
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                self.policy.verify_bundle(*self.bundle(r8))
        with self.assertRaisesRegex(ValueError, 'Unexpectedly large'):
            self.policy.verify_bundle(*self.bundle(good, size=1024 * 1024))

    def test_command_line_reports_failures_without_traceback(self):
        result = run('scripts/ci/android_build_policy.py', '--aab', self.tmp / 'missing.aab')
        self.assertEqual(result.code, 1)
        self.assertIn('Android build policy failed:', result.stderr)


class PublisherLockTests(TempCase):
    def wheel(self, name, version='1.0'):
        path = self.tmp / 'wheels' / f'{name}-{version}-py3-none-any.whl'
        path.parent.mkdir(exist_ok=True)
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr(f'{name}-{version}.dist-info/METADATA', f'Name: {name}\nVersion: {version}\n')
        return path

    def lock(self, pypi):
        def urlopen(url, timeout):
            name = url.split('/pypi/', 1)[1].split('/', 1)[0]
            return io.BytesIO(json.dumps(pypi(name)).encode())
        with patch('urllib.request.urlopen', urlopen):
            return run('scripts/ci/lock-publisher-wheels.py', self.tmp / 'wheels', '--output', self.tmp / 'lock.txt')

    def test_lock_rejects_ambiguous_or_unknown_wheels(self):
        for name in ('requests', 'PyJWT', 'cryptography'):
            self.wheel(name)

        def matching(name):
            # Every local wheel is published, so only the lock's own identity checks can fail.
            return {'urls': [{'filename': path.name, 'digests': {'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}}
                             for path in (self.tmp / 'wheels').glob('*.whl')]}
        self.assertEqual(self.lock(matching).code, 0)
        self.assertIn('cryptography==1.0 --hash=sha256:', (self.tmp / 'lock.txt').read_text())
        with self.assertRaisesRegex(ValueError, 'does not match PyPI'):
            self.lock(lambda name: {'urls': []})
        self.wheel('requests', '2.0')
        with self.assertRaisesRegex(ValueError, 'Multiple wheels for requests'):
            self.lock(matching)
        for path in (self.tmp / 'wheels').iterdir():
            path.unlink()
        broken = self.tmp / 'wheels/bad-1.0-py3-none-any.whl'
        with zipfile.ZipFile(broken, 'w') as archive:
            archive.writestr('a.dist-info/METADATA', 'Name: bad\nVersion: 1\n')
            archive.writestr('b.dist-info/METADATA', 'Name: bad\nVersion: 1\n')
        with self.assertRaisesRegex(ValueError, 'Ambiguous metadata'):
            self.lock(matching)
        broken.unlink()
        with zipfile.ZipFile(broken, 'w') as archive:
            archive.writestr('a.dist-info/METADATA', 'Name: bad name\nVersion: 1\n')
        with self.assertRaisesRegex(ValueError, 'Invalid distribution identity'):
            self.lock(matching)


class WindowsCoverageTests(TempCase):
    def test_relative_checkout_root_is_rejected(self):
        tool = load('scripts/ci/sonar-windows-coverage.py')
        root = self.tmp / 'root.txt'
        root.write_text('src\\checkout')
        with self.assertRaisesRegex(ValueError, 'absolute Windows checkout path'):
            tool.rebase(self.tmp / 'report.xml', root, self.tmp / 'out.xml', self.tmp)
