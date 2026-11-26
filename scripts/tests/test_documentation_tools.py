"""Guide generators and capture drivers for Linux, Apple mobile and the CLI, without devices or VMs."""
import json
import os
from pathlib import Path
import re
from types import SimpleNamespace
from unittest.mock import patch

from PIL import Image

from support import TempCase, completed, image_size, load, png, run


class LinuxGuideTests(TempCase):
    def test_numbered_panels_use_recorded_coordinates(self):
        guide = load('scripts/documentation/generate-linux-guide.py')
        guide.ROOT = self.tmp
        guide.main()
        english = (self.tmp / 'docs/user-guide/content/en/linux.md').read_text()
        self.assertTrue(english.startswith('---\ntitle: "Linux — illustrated desktop guide"\nsidebar_position: 7\n---'))
        first = re.search(r'<GuideScreenshot src="/img/guide/linux/en/connect.png" alt="Connect a reader" steps=\{(.+)\} />', english)
        self.assertEqual([(step['x'], step['y']) for step in json.loads(first.group(1))], guide.COORDS[0])
        self.assertIn('<GuideScreenshot src="/img/guide/linux/en/history-confirm.png"', english)
        self.assertIn('start={3}', english)
        self.assertEqual(english.count('<GuideScreenshot '), len(guide.NAMES) + 1)
        for lang in ('ro', 'ru'):
            self.assertIn(f'/img/guide/linux/{lang}/details.png', (self.tmp / f'docs/user-guide/content/{lang}/linux.md').read_text())


class AppleMobileGuideTests(TempCase):
    def setUp(self):
        super().setUp()
        self.guide = load('scripts/documentation/generate-apple-mobile-guides.py')
        self.guide.ROOT = self.tmp

    def test_ipad_markers_are_mapped_into_cropped_captures(self):
        name, (left, top, right, bottom) = next(iter(self.guide.IPAD_CROPS.items()))
        x, y = self.guide.IPAD_COORDS[name][0]
        panel = self.guide.shot('ipad', 'en', name, 'signSteps' if name == 'sign' else 'cardsSteps')
        steps = json.loads(re.search(r'steps=\{(.+)\} />', panel).group(1))
        self.assertEqual((steps[0]['x'], steps[0]['y']),
                         (round((x - 100 * left) / (right - left), 1), round((y - 100 * top) / (bottom - top), 1)))
        self.assertIn('caption="Native iPad portrait capture', panel)
        phone = self.guide.shot('iphone', 'ru', 'sign', 'signSteps')
        self.assertIn('"x": 50, "y": 71', phone)
        self.assertNotIn('caption=', phone)

    def test_build_and_targeted_refresh_preserve_prose(self):
        settings = list(self.guide.COORDS['settings'])
        for form in ('iphone', 'ipad'):
            for lang in ('en', 'ro', 'ru'):
                self.guide.build(form, lang)
        guide = self.tmp / 'docs/user-guide/content/en/ios.md'
        text = guide.read_text()
        self.assertIn('[iPhone](./ios.md) · [iPad](./ipad.md)', text)
        self.assertIn('1. Open Shortcuts, add an action and search for eSemnBun.', text)
        self.assertEqual(self.guide.COORDS['settings'], settings)
        self.assertIn('"x": 86, "y": 65', text)  # discovery panel uses its own settings marker
        edited = re.sub(r'<GuideScreenshot src="/img/guide/iphone/en/pin\.png"[^\n]* />', '<GuideScreenshot src="/img/guide/iphone/en/pin.png" old />',
                        text).replace('# iPhone', '# iPhone (edited prose)')
        guide.write_text(edited)
        self.guide.refresh_screenshots(['pin'])
        refreshed = guide.read_text()
        self.assertIn('# iPhone (edited prose)', refreshed)
        self.assertNotIn(' old />', refreshed)
        with self.assertRaisesRegex(ValueError, 'Unknown screenshot names: nope'):
            self.guide.refresh_screenshots(['nope'])
        guide.write_text('no panels')
        with self.assertRaisesRegex(ValueError, 'Expected one pin panel'):
            self.guide.refresh_screenshots(['pin'])

    def test_command_line_builds_all_guides_or_refreshes_selected_panels(self):
        self.assertEqual(run('scripts/documentation/generate-apple-mobile-guides.py', root=self.tmp).code, 0)
        self.assertEqual(len(list((self.tmp / 'docs/user-guide/content').glob('*/i*.md'))), 6)
        result = run('scripts/documentation/generate-apple-mobile-guides.py', '--only-screenshots', 'sign,stamp', root=self.tmp)
        self.assertEqual(result.code, 0)


class FakeBinary:
    def __init__(self):
        self.calls = []

    def __call__(self, command, **kwargs):
        self.calls.append(command)
        if command[1:3] == ['capabilities', '--json']:
            return completed(command, stdout='{"data": {"mcp": false}, "ok": true}\n', stderr='')
        return completed(command, 2, stdout='{"verdict": "unsigned"}', stderr='no signature')


class CliGuideTests(TempCase):
    def test_guides_record_read_only_observations_and_render_panels(self):
        binary = self.tmp / 'swift/MoldSignKit/.build/debug/esemnbun'
        binary.parent.mkdir(parents=True)
        binary.write_bytes(b'cli')
        (self.tmp / 'docs/user-guide').mkdir(parents=True)
        fake = FakeBinary()
        with patch('subprocess.run', fake), patch('subprocess.check_output', return_value='abc\n'):
            result = run('scripts/documentation/generate-cli-guides.py', cwd=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        evidence = json.loads((self.tmp / 'docs/user-guide/cli-evidence.json').read_text())
        self.assertEqual(evidence['commit'], 'abc')
        self.assertEqual(evidence['observations'][1]['exit'], 2)
        self.assertEqual([call[1:] for call in fake.calls][0], ['capabilities', '--json'])
        mac = (self.tmp / 'docs/user-guide/content/en/macos-cli.md').read_text()
        self.assertIn('brew install xfreebird/utils/esemnbun-cli', mac)
        self.assertIn('/img/guide/macos-cli/en/capability.svg', mac)
        windows = (self.tmp / 'docs/user-guide/content/ru/windows-cli.md').read_text()
        self.assertIn(':::info', windows)
        self.assertEqual(re.findall(r'(?m)^## (\d+)\. ', windows), [str(i) for i in range(1, len(re.findall(r'(?m)^## \d+\. ', windows)) + 1)])
        svg = (self.tmp / 'website/static/img/guide/linux-cli/ro/verify.svg').read_text()
        self.assertTrue(svg.startswith('<svg xmlns="http://www.w3.org/2000/svg" width="960"'))
        self.assertIn('fill="#9ce0bc">$ esemnbun verify Contract-semnat.pdf</text>', svg)


class Console:
    """A launched simulator console that reports readiness on a real pipe."""

    def __init__(self, ready=True):
        read, write = os.pipe()
        os.write(write, b'launching\nMSIGN_DEMO_READY\n' if ready else b'starting\n')
        os.close(write)
        self.stdout = os.fdopen(read, 'rb', buffering=0)
        self.ready = ready
        self.terminated = False

    def poll(self):
        return None if self.ready else 1

    def terminate(self):
        self.terminated = True

    def wait(self, timeout=None):
        self.stdout.close()
        return 0


class AppleMobileCaptureTests(TempCase):
    def setUp(self):
        super().setUp()
        self.app = self.tmp / 'eSemnBun.app'
        self.app.mkdir()
        (self.app / 'eSemnBun').write_bytes(b'binary')
        (self.app / 'eSemnBun.debug.dylib').write_bytes(b'..MSIGN_DEMO_SCENARIO..')
        self.output = self.tmp / 'out'

    def capture(self, *extra, ready=True):
        consoles, launched = [], []

        def popen(command, **kwargs):
            launched.append((command, kwargs['env']))
            consoles.append(Console(ready))
            return consoles[-1]

        def simctl(command, **kwargs):
            if 'screenshot' in command:
                png(command[-1])
            return completed(command)
        with patch('subprocess.Popen', popen), patch('subprocess.run', simctl), patch('time.sleep'):
            result = run('scripts/documentation/capture-apple-mobile-guides.py', 'SIM-1', self.app, self.output, *extra, env={})
        return result, launched, consoles

    def test_selected_scenarios_are_captured_per_language(self):
        result, launched, consoles = self.capture('--only', 'stamp,settings')
        self.assertEqual(result.code, 0, result.stderr)
        self.assertEqual(len(launched), 6)
        stamp_env = launched[0][1]
        self.assertEqual(stamp_env['SIMCTL_CHILD_MSIGN_QA_STAMP_PREVIEW'], '1')
        self.assertEqual(stamp_env['SIMCTL_CHILD_MSIGN_DEMO_FILES'], 'fixture-single')
        self.assertEqual(launched[1][1]['SIMCTL_CHILD_MSIGN_CAPTURE_SHEET'], 'settings')
        self.assertIn('-bridgeEnabled', launched[0][0])
        evidence = json.loads((self.output / 'capture.json').read_text())
        self.assertEqual([(r['locale'], r['name']) for r in evidence['records']][-1], ('ru', 'settings'))
        self.assertTrue((self.output / 'ro/stamp.png').is_file())
        self.assertEqual(stamp_env['DEVELOPER_DIR'], '/Applications/Xcode-27.1-rc.app/Contents/Developer')

    def test_invalid_inputs_and_unready_launches_stop(self):
        self.assertEqual(self.capture('--only', 'stamp,unknown')[0].code, 'Unknown capture names: unknown')
        with self.assertRaisesRegex(RuntimeError, 'not ready stamp'):
            self.capture('--only', 'stamp', ready=False)
        (self.app / 'eSemnBun.debug.dylib').write_bytes(b'release')
        self.assertIn('isolated Debug build', self.capture()[0].code)


class LinuxCaptureTests(TempCase):
    def test_binary_path_must_be_explicit(self):
        result = run('scripts/documentation/capture-linux-guide.py', env={'GUIDE_LINUX_BINARY': 'relative/esemnbun-gnome'})
        self.assertIn('GUIDE_LINUX_BINARY', str(result.code))

    def test_capture_uses_private_directories_and_records_crops(self):
        records = self.tmp / 'docs/user-guide/linux-capture-records.json'
        records.parent.mkdir(parents=True)
        records.write_text(json.dumps([{'path': 'website/static/img/guide/linux/en/connect.png', 'stale': True}]))
        for lang in ('en', 'ro', 'ru'):
            folder = self.tmp / f'website/static/img/guide/linux/{lang}'
            folder.mkdir(parents=True)
        commands = []

        def ssh(command, text=True):
            commands.append(command)
            remote = command[-1]
            if remote.startswith('mktemp -d'):
                return '/home/user/esemnbun-guide.ABC\n' if '-J' in command else '/Users/user/esemnbun-guide.XYZ\n'
            if remote.startswith('cat '):
                name = re.search(r'/(\w\w)-([\w-]+)\.json', remote)
                scenario = next((row[1] for row in self.scenarios if row[0] == name.group(2)), None)
                return json.dumps({'run': self.namespace['RUN'], 'language': name.group(1), 'scenario': scenario or 'baseline'})
            return ''

        def scp(command, check):
            Image.new('RGB', (1600, 1000), 'navy').save(command[-1])
            return completed(command)
        with patch('subprocess.check_output', ssh), patch('subprocess.run', scp), patch('time.sleep'), \
                patch('uuid.uuid4', return_value=SimpleNamespace(hex='feedface')):
            self.namespace = {'RUN': 'guide-linux-20261108-feedface'}
            source = Path(__file__).resolve().parents[2] / 'scripts/documentation/capture-linux-guide.py'
            self.scenarios = [row for row in self.read_scenarios(source)]
            result = run('scripts/documentation/capture-linux-guide.py', root=self.tmp,
                         env={'GUIDE_LINUX_BINARY': '/home/user/src/linux/.build/debug/esemnbun-gnome'})
        self.assertEqual(result.code, 0, result.stderr)
        evidence = json.loads(records.read_text())
        self.assertEqual(len(evidence), 3 * len(self.scenarios))
        self.assertFalse(any(entry.get('stale') for entry in evidence))
        menu = next(entry for entry in evidence if entry['path'].endswith('ru/menu.png'))
        self.assertEqual(menu['dimensions'], [1396 - 1185, 333 - 178])
        connect = next(entry for entry in evidence if entry['path'].endswith('en/connect.png'))
        self.assertEqual(connect['dimensions'], [1100, 780])
        remote = [command[-1] for command in commands]
        self.assertIn('mkdir -p /home/user/esemnbun-guide.ABC/config', '\n'.join(remote))
        self.assertTrue(any("MSIGN_DEMO_SCENARIO=verify-valid" in command for command in remote))
        self.assertTrue(any('scroll.py 5901 5 10' in command for command in remote))
        self.assertFalse(any('/tmp/' in command for command in remote))

    @staticmethod
    def read_scenarios(source):
        namespace = {}
        text = source.read_text()
        block = text[text.index('SCENARIOS=['):text.index('def main():')]
        exec(block.replace('SCENARIOS +=', 'SCENARIOS +='), namespace)
        return namespace['SCENARIOS']


class AppleGuideImageTests(TempCase):
    def test_ipad_captures_are_cropped_and_hashed(self):
        guide = load('scripts/documentation/generate-apple-mobile-guides.py')
        name = next(iter(guide.IPAD_CROPS))
        raw = self.tmp / 'raw'
        ipad_raw = png(raw / 'en' / f'{name}.png', (200, 100))
        phone = png(self.tmp / f'website/static/img/guide/iphone/en/{name}.png', (50, 100))
        png(self.tmp / 'website/static/img/guide/ipad/en/placeholder.png')
        (self.tmp / 'docs/user-guide').mkdir(parents=True)
        hashed = lambda path: __import__('hashlib').sha256(path.read_bytes()).hexdigest()
        manifests = {}
        for form, path in (('iphone', phone), ('ipad', ipad_raw)):
            manifests[form] = self.tmp / f'{form}.json'
            manifests[form].write_text(json.dumps({'device': form, 'binarySha256': 'b',
                                                   'records': [{'locale': 'en', 'name': name, 'sha256': hashed(path)}]}))
        result = run('scripts/documentation/prepare-apple-mobile-guide-images.py', raw, manifests['iphone'], manifests['ipad'],
                     root=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        evidence = json.loads((self.tmp / 'docs/user-guide/apple-mobile-evidence.json').read_text())
        left, top, right, bottom = guide.IPAD_CROPS[name]
        ipad = next(item for item in evidence['records'] if item['platform'] == 'ipad')
        self.assertEqual(ipad['cropPixels'], [round(left * 200), round(top * 100), round(right * 200), round(bottom * 100)])
        self.assertEqual(image_size(self.tmp / f'website/static/img/guide/ipad/en/{name}.png'),
                         (ipad['cropPixels'][2] - ipad['cropPixels'][0], ipad['cropPixels'][3] - ipad['cropPixels'][1]))
        self.assertIn('Validated 2 native images', result.stdout)
        manifests['ipad'].write_text(json.dumps({'device': 'ipad', 'binarySha256': 'b',
                                                 'records': [{'locale': 'en', 'name': name, 'sha256': 'wrong'}]}))
        with self.assertRaises(AssertionError):
            run('scripts/documentation/prepare-apple-mobile-guide-images.py', raw, manifests['iphone'], manifests['ipad'],
                root=self.tmp)
