"""Contract tests for coverage import and publisher dependency evidence."""

from contextlib import redirect_stdout
import hashlib
import io
import json
import os
from pathlib import Path
import runpy
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET
import zipfile


TOOLS = Path(__file__).resolve().parent


class ReportToolsTests(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.root = Path(scratch.name).resolve()
        self.source = self.root / 'Sources'
        self.source.mkdir()

    def run_tool(self, name, *args, stdin=''):
        path = TOOLS / name
        with patch('sys.argv', [str(path), *map(str, args)]), patch('sys.stdin', io.StringIO(stdin)), \
                redirect_stdout(io.StringIO()):
            runpy.run_path(str(path), run_name='__main__')

    def test_lcov_merges_objects_and_keeps_checkout_relative_source_paths(self):
        swift = self.source / 'App & Core.swift'
        swift.write_text('let x = 1\nlet y = x + 1\n', encoding='utf-8')
        report = self.root / 'nested/report.xml'
        self.run_tool('sonar-lcov.py', self.root, 'Sources', report, stdin=(
            f'SF:{swift}\nDA:1,0\nDA:2,0\nend_of_record\n'
            'SF:Outside.swift\nDA:1,8\nend_of_record\n'
            'SF:Sources/App & Core.swift\nDA:1,1\nend_of_record\n'))
        entries = ET.parse(report).getroot().findall('file')
        self.assertEqual([file.get('path') for file in entries], ['Sources/App & Core.swift'])
        self.assertEqual([(line.get('lineNumber'), line.get('covered')) for line in entries[0]],
                         [('1', 'true'), ('2', 'false')])

    def test_lcov_rejects_empty_evidence_and_invalid_lines(self):
        (self.source / 'App.swift').write_text('let x = 1\n', encoding='utf-8')
        for line, error in [('1,0', 'No covered production lines'), ('-1,1', 'Invalid coverage'),
                            ('2,1', 'nonexistent line')]:
            with self.subTest(line=line), self.assertRaisesRegex(ValueError, error):
                self.run_tool('sonar-lcov.py', self.root, 'Sources', self.root / 'report.xml',
                              stdin=f'SF:Sources/App.swift\nDA:{line}\nend_of_record\n')
        with self.assertRaisesRegex(SystemExit, 'inside the repository'):
            self.run_tool('sonar-lcov.py', self.root, '..', self.root / 'report.xml')

    def test_windows_coverage_checks_identity_and_accepts_windows_line_endings(self):
        source = self.source / 'App.cs'
        source.write_bytes(b'class App {}\n')
        report, producer, result = [self.root / name for name in ('windows.xml', 'root.txt', 'rebased.xml')]
        producer.write_text('D:\\work\\repo\n', encoding='utf-8-sig')
        root = ET.Element('results')
        ET.SubElement(root, 'source_file', path=r'd:\work\repo\Sources\App.cs', checksum_type='SHA256',
                      checksum=hashlib.sha256(b'class App {}\r\n').hexdigest().upper())
        ET.SubElement(root, 'source_file', path=r'D:\work\repo\obj\Generated.cs')
        ET.SubElement(root, 'source_file', path=r'C:\sdk\Library.cs')
        ET.ElementTree(root).write(report)
        old_directory = Path.cwd()
        os.chdir(self.root)
        try:
            self.run_tool('sonar-windows-coverage.py', report, producer, result)
            entries = ET.parse(result).getroot().findall('source_file')
            self.assertEqual([entry.get('path') for entry in entries],
                             [str(source), r'D:\work\repo\obj\Generated.cs', r'C:\sdk\Library.cs'])
            source.write_bytes(b'class Different {}\n')
            with self.assertRaisesRegex(ValueError, 'differs from the checkout'):
                self.run_tool('sonar-windows-coverage.py', report, producer, result)
        finally:
            os.chdir(old_directory)

    def test_windows_coverage_rejects_paths_outside_the_scanner_checkout(self):
        rebase = runpy.run_path(str(TOOLS / 'sonar-windows-coverage.py'))['rebase']
        producer = self.root / 'root.txt'
        producer.write_text('D:\\work\\repo\n', encoding='utf-8')
        report = self.root / 'windows.xml'
        report.write_text(r'<results><source_file path="D:\work\repo\..\App.cs"/></results>', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'escapes the checkout'):
            rebase(report, producer, self.root / 'rebased.xml', self.root)

    @unittest.skipUnless(os.name == 'posix', 'Apple capture is a POSIX tool')
    def test_apple_manifest_uses_capture_directory_and_refuses_symlink_escape(self):
        capture = TOOLS.parents[1] / 'distribution/tools/apple_capture.py'
        app = self.root / 'Debug.app'
        app.mkdir()
        (app / 'App').write_bytes(b'MSIGN_DEMO_SCENARIO')
        container = self.root / 'device/Containers/Data/Application/fixture'
        device_id, runtime_id = 'fixture-device', 'fixture-runtime'
        commands = {
            ('list', 'devices', '--json'): json.dumps({'devices': {runtime_id: [{'udid': device_id, 'name': 'Fixture'}]}}),
            ('list', 'runtimes', '--json'): json.dumps({'runtimes': [{'identifier': runtime_id, 'version': '26.5'}]}),
            ('get_app_container', device_id, 'md.esemnbun.ios', 'data'): str(container),
        }

        def native_fixture(command, **_):
            if command[:2] == ('xcrun', 'simctl'):
                return commands.get(command[2:], '')
            self.assertEqual(command, ('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version'))
            return '26.5'

        output = self.root / 'capture'
        output.mkdir()
        args = ('--app', app, '--device', device_id, '--family', 'iphone', '--languages', 'fixture')
        old_directory = Path.cwd()
        os.chdir(output)
        try:
            with patch.dict('sys.modules', {'PIL': SimpleNamespace(Image=None)}), \
                    patch('subprocess.check_output', side_effect=native_fixture), patch('subprocess.run'):
                self.run_tool(capture, *args)
                manifest = output / 'manifest-iphone.json'
                self.assertEqual(json.loads(manifest.read_text(encoding='utf-8')), [])
                manifest.unlink()
                outside = self.root / 'outside.json'
                outside.write_text('preserve', encoding='utf-8')
                manifest.symlink_to(outside)
                with self.assertRaisesRegex(ValueError, 'leaves the capture directory'):
                    self.run_tool(capture, *args)
                self.assertEqual(outside.read_text(encoding='utf-8'), 'preserve')
        finally:
            os.chdir(old_directory)

    def test_wheel_lock_uses_verified_identity_and_rejects_checksum_mismatch(self):
        metadata = {}
        for name in ('requests', 'PyJWT', 'cryptography'):
            filename = f'{name}-1.0-py3-none-any.whl'
            wheel = self.root / filename
            with zipfile.ZipFile(wheel, 'w') as archive:
                archive.writestr(f'{name}-1.0.dist-info/METADATA', f'Name: {name}\nVersion: 1.0\n')
            metadata[name] = {'filename': filename, 'digests': {'sha256': hashlib.sha256(wheel.read_bytes()).hexdigest()}}

        def release(url, *, timeout):
            self.assertEqual(timeout, 30)
            self.assertTrue(url.startswith('https://pypi.org/pypi/'))
            return io.BytesIO(json.dumps({'urls': [metadata[url.split('/')[-3]]]}).encode())

        lock = self.root / 'requirements.txt'
        with patch('urllib.request.urlopen', side_effect=release):
            self.run_tool('lock-publisher-wheels.py', self.root, '--output', lock)
            lines = lock.read_text(encoding='utf-8').splitlines()
            self.assertEqual(lines[2:], [f'{name}==1.0 --hash=sha256:{metadata[name]["digests"]["sha256"]}'
                                         for name in ('cryptography', 'PyJWT', 'requests')])
            metadata['requests']['digests']['sha256'] = '0' * 64
            with self.assertRaisesRegex(ValueError, 'Wheel does not match PyPI'):
                self.run_tool('lock-publisher-wheels.py', self.root, '--output', lock)
        self.assertEqual(lock.read_text(encoding='utf-8').splitlines(), lines)
