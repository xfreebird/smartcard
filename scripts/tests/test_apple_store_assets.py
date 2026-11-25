"""Apple store tooling: licensed bezel cache, rendering, validation, creative export and capture drivers."""
import hashlib
import io
import json
import os
from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import Mock, patch

from PIL import Image, ImageDraw

from support import REPO, TempCase, completed, fast_pillow, load, png, run

TOOLS = 'distribution/tools/'


def bezel(cache, family, screen, border=10, island=True):
    """A product frame with a transparent display opening and an opaque camera island inside it."""
    width, height = screen
    image = Image.new('RGBA', (width + 2 * border, height + 2 * border), (20, 20, 30, 255))
    ImageDraw.Draw(image).rectangle((border, border, border + width - 1, border + height - 1), fill=(0, 0, 0, 0))
    if island:
        ImageDraw.Draw(image).rectangle((border + width // 2 - 2, border + 2, border + width // 2 + 2, border + 4),
                                        fill=(5, 5, 5, 255))
    path = Path(cache) / f'{family}.png'
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, compress_level=1)
    manifest = Path(cache) / 'frames.json'
    frames = json.loads(manifest.read_text()) if manifest.exists() else {}
    frames[family] = {'file': path.name, 'screen': [border, border, width, height], 'model': family,
                      'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    manifest.write_text(json.dumps(frames))
    return frames[family]


class FrameTestCase(TempCase):
    def setUp(self):
        super().setUp()
        self.frames = load(TOOLS + 'apple_product_frames.py', 'apple_product_frames')
        self.frames.CACHE = self.tmp / 'bezels'
        self.frames.frame_resource.cache_clear()
        self.addCleanup(self.frames.frame_resource.cache_clear)

    def rectangular_openings(self):
        """Skip the pure-Python flood fill for full-size bezels; ProductFrameTests covers it directly."""
        def frame_resource(family):
            item = json.loads((self.frames.CACHE / 'frames.json').read_text())[family]
            frame = Image.open(self.frames.CACHE / item['file']).convert('RGBA')
            x, y, w, h = item['screen']
            opening = Image.new('L', frame.size)
            ImageDraw.Draw(opening).rectangle((x - 1, y - 1, x + w, y + h), fill=255)
            return frame, opening, item
        return patch.object(self.frames, 'frame_resource', frame_resource)


class ProductFrameTests(FrameTestCase):
    def test_native_capture_is_composited_into_the_display_opening(self):
        bezel(self.frames.CACHE, 'iphone', (30, 60))
        screen = Image.new('RGB', (30, 60), (200, 10, 10))
        framed = self.frames.device_frame(screen, 'iphone')
        self.assertEqual(framed.size, (50, 80))
        self.assertEqual(framed.getpixel((25, 50)), (200, 10, 10, 255))
        self.assertEqual(framed.getpixel((25, 13)), (5, 5, 5, 255))  # camera island stays on top
        self.assertEqual(framed.getpixel((2, 2)), (20, 20, 30, 255))
        self.assertIs(self.frames.device_frame(screen, 'ipad'), screen)
        with self.assertRaisesRegex(RuntimeError, 'never stretch the UI'):
            self.frames.device_frame(Image.new('RGB', (31, 60)), 'iphone')

    def test_missing_changed_or_unexpected_frames_are_refused(self):
        with self.assertRaisesRegex(RuntimeError, 'Official Apple bezels are required'):
            self.frames.frame_resource('iphone')
        bezel(self.frames.CACHE, 'iphone', (30, 60))
        manifest = json.loads((self.frames.CACHE / 'frames.json').read_text())
        manifest['iphone']['sha256'] = '0' * 64
        (self.frames.CACHE / 'frames.json').write_text(json.dumps(manifest))
        with self.assertRaisesRegex(RuntimeError, 'checksum changed'):
            self.frames.frame_resource('iphone')
        self.frames.frame_resource.cache_clear()
        item = bezel(self.frames.CACHE, 'iphone', (30, 60))
        manifest = json.loads((self.frames.CACHE / 'frames.json').read_text())
        manifest['iphone']['screen'] = [item['screen'][0] + 5, item['screen'][1], 25, 60]
        (self.frames.CACHE / 'frames.json').write_text(json.dumps(manifest))
        with self.assertRaisesRegex(RuntimeError, 'Unexpected Apple display opening'):
            self.frames.frame_resource('iphone')


class RenderTests(FrameTestCase):
    def test_store_screenshots_keep_official_and_supplemental_sets_apart(self):
        bezel(self.frames.CACHE, 'iphone', (1320, 2868), border=20)
        bezel(self.frames.CACHE, 'duo-compact', (1398, 2034), border=20)
        raw = self.tmp / 'raw'
        png(raw / 'ro/macos/01-sign.png', (400, 250))
        png(raw / 'en/iphone/02-reader.png', (1320, 2868), mode='RGB')
        png(raw / 'ru/duo-compact/05-card.png', (1398, 2034), mode='RGB')
        (raw / 'manifest-macos.json').write_text(json.dumps([{'path': 'ro/macos/01-sign.png', 'runtimeVersion': '26.1',
                                                             'sdkVersion': '26.1', 'captureBackend': 'screencapture'}]))
        (raw / 'manifest-old.json').write_text(json.dumps([{'path': 'ro/macos/01-sign.png'}]))
        with fast_pillow(), self.rectangular_openings():
            result = run(TOOLS + 'apple_render.py', '--raw', raw, '--output', self.tmp / 'shots',
                         '--supplemental-output', self.tmp / 'duo')
        self.assertEqual(result.code, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'Rendered 3 store screenshots')
        official = json.loads((self.tmp / 'shots/manifest.json').read_text())
        self.assertEqual([(item['locale'], item['family']) for item in official], [('ro', 'macos'), ('en', 'iphone')])
        self.assertEqual(official[0]['sourceRuntime'], '26.1')
        self.assertEqual(Image.open(self.tmp / 'shots/ro/macos/01-sign.png').size, (2880, 1800))
        phone = Image.open(self.tmp / 'shots/en/iphone/02-reader.png')
        self.assertEqual((phone.size, phone.mode), ((1320, 2868), 'RGB'))
        supplemental = json.loads((self.tmp / 'duo/manifest.json').read_text())
        self.assertEqual(supplemental['assets'][0]['path'], 'ru/duo-compact/05-card.png')
        self.assertTrue((self.tmp / 'duo/ru/duo-compact/05-card.png').is_file())


class ValidateTests(TempCase):
    def populate(self, root, families, count=None):
        blobs = {}
        for lang in ('ro', 'en', 'ru'):
            for family, (size, n) in families.items():
                if size not in blobs:
                    buffer = io.BytesIO()
                    Image.new('RGB', size, 'white').save(buffer, 'PNG', compress_level=1)
                    blobs[size] = buffer.getvalue()
                for index in range(count or n):
                    path = root / lang / family / f'{index:02}.png'
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(blobs[size])

    def test_exact_slots_and_optional_duo_set_are_indexed(self):
        self.populate(self.tmp / 'shots', {'iphone': ((1320, 2868), 5), 'ipad': ((2064, 2752), 5),
                                           'macos': ((2880, 1800), 6)})
        self.populate(self.tmp / 'duo', {'duo-compact': ((1398, 2034), 5), 'duo-expanded': ((2853, 2007), 5)})
        result = run(TOOLS + 'apple_validate.py', self.tmp / 'shots', '--duo-directory', self.tmp / 'duo')
        self.assertEqual(result.stdout.strip(), 'PASS: 78 opaque localized Apple screenshots, exact accepted sizes')
        index = json.loads((self.tmp / 'shots/submission-index.json').read_text())
        self.assertEqual({item['locale'] for item in index['assets']}, {'ro', 'en-US', 'ru'})
        png(self.tmp / 'shots/en/macos/00.png', (2880, 1800))
        with self.assertRaises(AssertionError):
            run(TOOLS + 'apple_validate.py', self.tmp / 'shots')


class CreativeTests(FrameTestCase):
    def test_header_and_search_artwork_are_composed_then_exported(self):
        bezel(self.frames.CACHE, 'iphone', (1320, 2868), border=20)
        raw = self.tmp / 'raw'
        for lang in ('en', 'ro', 'ru'):
            for name in ('01-sign.png', '02-reader.png'):
                png(raw / lang / 'iphone' / name, (1320, 2868), mode='RGB')
        source = self.tmp / 'creative-source'
        with fast_pillow(), self.rectangular_openings():
            composed = run(TOOLS + 'compose-apple-creative.py', '--raw', raw, '--output', source)
        self.assertEqual(composed.code, 0, composed.stderr)
        manifest = json.loads((source / 'composition-manifest.json').read_text())
        self.assertEqual(len(manifest), 6)
        header = next(item for item in manifest if item['layout'] == 'header' and item['locale'] == 'ru')
        left, top, right, bottom = header['appleTemplateSafeArea']
        self.assertTrue(all(left <= box[0] and box[2] <= right and top <= box[1] and box[3] <= bottom
                            for box in header['messageBounds']))
        self.assertEqual(Image.open(source / 'en-search-results.png').size, (3840, 2560))

        exported = self.tmp / 'creative'
        with fast_pillow():
            result = run(TOOLS + 'export-apple-creative.py', '--source', source, '--output', exported)
        self.assertEqual(result.stdout.strip(), 'Exported 6 placement-specific creative assets')
        items = json.loads((exported / 'manifest.json').read_text())
        self.assertEqual(items[0]['placements'], ['PRODUCT_PAGE_HEADER_ASSET'])
        self.assertTrue((exported / 'composition-manifest.json').is_file())
        self.assertEqual((exported / 'README.md').read_text(), (REPO / 'distribution/apple/creative/README.md').read_text())

    def test_wrong_sizes_are_refused(self):
        raw = self.tmp / 'raw'
        for lang in ('en', 'ro', 'ru'):
            png(raw / lang / 'iphone/01-sign.png', (10, 10))
            png(raw / lang / 'iphone/02-reader.png', (10, 10))
        with self.assertRaisesRegex(ValueError, 'Expected native 1320 × 2868 captures for en'):
            run(TOOLS + 'compose-apple-creative.py', '--raw', raw, '--output', self.tmp / 'out')
        source = self.tmp / 'source'
        png(source / 'en-header.png', (10, 10))
        result = run(TOOLS + 'export-apple-creative.py', '--source', source, '--output', self.tmp / 'out')
        self.assertEqual(result.code, 2)
        self.assertIn('refusing to crop', result.stderr)
        (source / 'en-header.png').unlink()
        self.assertIn('Missing localized artwork', run(TOOLS + 'export-apple-creative.py', '--source', source,
                                                      '--output', self.tmp / 'out').stderr)


class BezelImportTests(TempCase):
    def test_licensed_frames_are_cached_with_checksums(self):
        phone, duo = self.tmp / 'Bezel-iPhone-17', self.tmp / 'Bezel-iPhone-Duo'
        for path, (x, y, w, h) in [(phone / 'PNG/iPhone 17 Pro Max/iPhone 17 Pro Max - Deep Blue - Portrait.png', (75, 66, 1320, 2868)),
                                   (duo / 'PNG/iPhone Duo - Night Sky - Outer Closed Portrait.png', (88, 80, 1398, 2034)),
                                   (duo / 'PNG/iPhone Duo - Night Sky - Inner Open Landscape.png', (120, 120, 2853, 2007))]:
            image = Image.new('RGBA', (x + w + 10, y + h + 10), (0, 0, 0, 255))
            ImageDraw.Draw(image).rectangle((x, y, x + w - 1, y + h - 1), fill=(0, 0, 0, 0))
            path.parent.mkdir(parents=True, exist_ok=True)
            image.save(path, compress_level=1)
        (phone / 'Apple Design Resources License.rtf').write_text('license')
        cache = self.tmp / 'cache'
        result = run(TOOLS + 'import-apple-product-bezels.py', '--iphone17-volume', phone, '--duo-volume', duo, '--cache', cache)
        self.assertIn('Cached 3 original Apple PNG frames', result.stdout)
        frames = json.loads((cache / 'frames.json').read_text())
        self.assertEqual(frames['duo-expanded']['screen'], [120, 120, 2853, 2007])
        self.assertEqual(frames['iphone']['sha256'], hashlib.sha256((cache / 'iphone.png').read_bytes()).hexdigest())
        self.assertTrue((cache / 'Bezel-iPhone-17-License.rtf').is_file())
        missing = run(TOOLS + 'import-apple-product-bezels.py', '--iphone17-volume', self.tmp / 'none', '--cache', cache)
        self.assertEqual(missing.code, 2)
        self.assertIn('after accepting their license', missing.stderr)


class Simulator:
    """simctl/xcodebuild stand-in for the Apple capture drivers."""

    def __init__(self, test, device_data, runtime='26.2', name='eSemnBun-store-duo-1', state='Booted', size=(1320, 2868)):
        self.test, self.device_data, self.size, self.calls = test, device_data, size, []
        self.runtime = {'identifier': 'com.apple.CoreSimulator.SimRuntime.iOS-26-2', 'version': runtime, 'isAvailable': True,
                        'name': f'iOS {runtime}'}
        self.device = {'udid': 'DEV-1', 'name': name, 'state': state}

    def check_output(self, command, text=True, **kwargs):
        command = [str(part) for part in command]
        self.calls.append(command)
        if command[:4] == ['xcrun', 'simctl', 'list', 'devices']:
            return json.dumps({'devices': {self.runtime['identifier']: [self.device]}})
        if command[:4] == ['xcrun', 'simctl', 'list', 'runtimes']:
            return json.dumps({'runtimes': [self.runtime, {'identifier': 'com.apple.CoreSimulator.SimRuntime.iOS-27-0',
                                                           'version': '27.0', 'isAvailable': True}]})
        if command[:3] == ['xcrun', 'simctl', 'get_app_container']:
            return str(self.device_data / 'Containers/Data/Application/APP')
        if command[:3] == ['xcrun', 'simctl', 'launch']:
            log = self.device_data / command[3].removeprefix('--stdout=/')
            log.write_text('MSIGN_DEMO_READY\n')
        if command[:3] == ['xcrun', 'simctl', 'create']:
            return 'NEW-' + command[3].rsplit('-', 1)[0][-4:] + '\n'
        if command[:3] == ['xcrun', '--sdk', 'iphonesimulator']:
            return '26.2'
        if command[:3] == ['xcrun', 'simctl', 'io']:
            Image.new('RGB', self.size).save(command[-1])
        return ''


class AppleCaptureTests(TempCase):
    def setUp(self):
        super().setUp()
        self.app = self.tmp / 'Debug.app'
        self.app.mkdir()
        (self.app / 'eSemnBun.debug.dylib').write_bytes(b'MSIGN_DEMO_SCENARIO')
        self.device_data = self.tmp / 'device/data'
        (self.device_data / 'tmp').mkdir(parents=True)
        self.out = self.tmp / 'capture'
        self.out.mkdir()

    def capture(self, simulator, *args, home=None):
        with patch('subprocess.check_output', simulator.check_output), patch('subprocess.run') as run_quiet, \
                patch('time.sleep'), patch.object(Path, 'home', return_value=home or self.tmp):
            result = run(TOOLS + 'apple_capture.py', '--app', self.app, '--device', 'DEV-1', *args, cwd=self.out)
        return result, run_quiet

    def test_device_hub_capture_moves_the_native_duo_screenshot(self):
        desktop = self.tmp / 'Desktop'
        desktop.mkdir()
        simulator = Simulator(self, self.device_data, size=(2853, 2007))
        helper = self.tmp / 'devicehub-capture'
        original = simulator.check_output

        def check_output(command, text=True, **kwargs):
            if str(command[0]) == str(helper):
                Image.new('RGB', (2853, 2007)).save(desktop / 'Screenshot eSemnBun-store-duo-1 1.png')
                return 'captured'
            return original(command, text, **kwargs)
        simulator.check_output = check_output
        result, quiet = self.capture(simulator, '--family', 'duo-expanded', '--stories', '04-verify', '--languages', 'ru',
                                     '--devicehub-helper', helper, '--keep-booted')
        self.assertEqual(result.code, 0, result.stderr)
        manifest = json.loads((self.out / 'manifest-duo-expanded.json').read_text())
        self.assertEqual((manifest[0]['foldState'], manifest[0]['orientation']), ('expanded', 'landscape'))
        self.assertTrue((self.out / 'ru/duo-expanded/04-verify.png').is_file())
        self.assertFalse(any(call.args[0][:3] == ['xcrun', 'simctl', 'shutdown'] for call in quiet.call_args_list))

    def test_wrong_duo_posture_or_old_runtime_is_rejected(self):
        for family, size, message in [('duo-expanded', (1398, 2034), 'Expected expanded landscape Duo'),
                                      ('duo-compact', (2853, 2007), 'Expected compact portrait Duo')]:
            with self.subTest(family=family), self.assertRaisesRegex(RuntimeError, message):
                self.capture(Simulator(self, self.device_data, size=size), '--family', family, '--stories', '05-card',
                             '--languages', 'en')
            self.assertFalse((self.out / 'en' / family / '05-card.png').exists())
        with self.assertRaisesRegex(RuntimeError, 'iOS 26 or newer'):
            self.capture(Simulator(self, self.device_data, runtime='18.4'), '--family', 'iphone')

    def test_device_hub_without_new_screenshot_fails(self):
        (self.tmp / 'Desktop').mkdir()
        simulator = Simulator(self, self.device_data)
        original = simulator.check_output
        simulator.check_output = lambda command, text=True, **kw: 'noop' if 'helper' in str(command[0]) else original(command, text, **kw)
        with self.assertRaisesRegex(RuntimeError, 'Device Hub did not write'):
            self.capture(simulator, '--family', 'iphone', '--stories', '01-sign', '--languages', 'en',
                         '--devicehub-helper', self.tmp / 'helper')


class CaptureAllTests(TempCase):
    def drive(self, *args, simulator=None):
        simulator = simulator or Simulator(self, self.tmp)
        calls = []

        def check_call(command, cwd=None):
            calls.append(([str(part) for part in command], cwd))
            return 0
        with patch('subprocess.check_call', check_call), patch('subprocess.check_output', simulator.check_output), \
                patch('subprocess.run') as quiet:
            result = run(TOOLS + 'apple_capture_all.py', '--output', self.tmp / 'pack', *args)
        return result, calls, quiet

    def test_disposable_simulators_are_created_used_and_deleted(self):
        result, calls, quiet = self.drive('--families', 'iphone,ipad,macos', '--macos-app', self.tmp / 'Mac.app')
        self.assertEqual(result.code, 0, result.stderr)
        commands = [call[0] for call in calls]
        self.assertTrue(commands[0][:2] == ['xcodebuild', '-project'] and 'eSemnBun-iOS' in commands[0])
        captures = [c for c in commands if c[:2] == ['python3', str(REPO / TOOLS / 'apple_capture.py')]]
        self.assertEqual([c[c.index('--family') + 1] for c in captures], ['iphone', 'ipad'])
        self.assertEqual(sum(c[:3] == ['xcrun', 'simctl', 'delete'] for c in commands), 2)
        self.assertIn(['python3', str(REPO / TOOLS / 'apple_validate.py'), str(self.tmp / 'pack/apple/screenshots')], commands)
        self.assertTrue(any(c[1].endswith('apple_capture_macos.py') for c in commands if len(c) > 1))
        self.assertEqual(calls[1][1], self.tmp / 'pack/apple/raw')

    def test_duo_capture_requires_a_prepared_task_device(self):
        result, _, _ = self.drive('--families', 'duo-compact', '--ios-app', 'App.app')
        self.assertIn('Duo capture needs one manually prepared family', result.code)
        result, _, _ = self.drive('--families', 'duo-compact', '--ios-app', 'App.app', '--duo-device', 'DEV-1',
                                  simulator=Simulator(self, self.tmp, state='Shutdown'))
        self.assertIn('Only a booted task-owned', result.code)
        result, calls, _ = self.drive('--families', 'duo-compact', '--ios-app', 'App.app', '--duo-device', 'DEV-1')
        self.assertEqual(result.code, 0, result.stderr)
        self.assertEqual(calls[0][0][0], 'swiftc')
        self.assertIn('--devicehub-helper', calls[1][0])

    def test_unknown_family_and_missing_runtime_stop(self):
        self.assertEqual(self.drive('--families', 'watch')[0].code, 2)
        simulator = Simulator(self, self.tmp, runtime='18.0')
        simulator.check_output = lambda command, text=True, **kw: json.dumps({'runtimes': [simulator.runtime]})
        self.assertEqual(self.drive('--families', 'iphone', '--ios-app', 'A.app', simulator=simulator)[0].code,
                         'Install an iOS 26 or newer simulator runtime')


class MacCaptureTests(TempCase):
    def test_each_story_is_captured_from_the_mock_window(self):
        app = self.tmp / 'eSemnBun.app'
        (app / 'Contents/MacOS').mkdir(parents=True)
        (app / 'Contents/MacOS/eSemnBun.debug.dylib').write_bytes(b'MSIGN_DEMO_SCENARIO')
        windows = iter(['', '41'] + ['42'] * 100)
        processes = []

        def check_output(command, text=True):
            if command[:3] == ['xcrun', '--sdk', 'macosx']:
                return '26.1'
            return next(windows)

        def check_call(command):
            if command[0] == '/usr/sbin/screencapture':
                png(command[-1])
            return 0

        def popen(command, env, stdout, stderr):
            processes.append((command, env, Mock(pid=77)))
            return processes[-1][2]
        with patch('subprocess.check_output', check_output), patch('subprocess.check_call', check_call), \
                patch('subprocess.Popen', popen), patch('subprocess.run') as osascript, patch('time.sleep'), \
                patch('platform.mac_ver', return_value=('26.1', '', '')):
            result = run(TOOLS + 'apple_capture_macos.py', '--app', app, '--output', self.tmp / 'raw')
        self.assertEqual(result.code, 0, result.stderr)
        manifest = json.loads((self.tmp / 'raw/manifest-macos.json').read_text())
        self.assertEqual({item['language'] for item in manifest}, {'ro', 'en', 'ru'})
        self.assertEqual(manifest[0]['runtimeVersion'], '26.1')
        dark = next(env for command, env, _ in processes if env['MSIGN_DEMO_SCENARIO'] == 'multiple')
        self.assertEqual(dark['MSIGN_DEMO_DARK'], '1')
        self.assertTrue(all(process.terminate.called for _, _, process in processes))
        self.assertIn('set size of first window to {1280, 800}', osascript.call_args_list[0].args[0][2])

    def test_missing_window_stops_and_terminates_the_app(self):
        app = self.tmp / 'eSemnBun.app'
        (app / 'Contents/MacOS').mkdir(parents=True)
        (app / 'Contents/MacOS/eSemnBun.debug.dylib').write_bytes(b'MSIGN_DEMO_SCENARIO')
        process = Mock(pid=1)
        with patch('subprocess.check_output', return_value=''), patch('subprocess.check_call'), \
                patch('subprocess.Popen', return_value=process), patch('time.sleep'), \
                self.assertRaisesRegex(RuntimeError, 'No mock app window'):
            run(TOOLS + 'apple_capture_macos.py', '--app', app, '--output', self.tmp / 'raw', '--browser-only')
        process.terminate.assert_called_once()


class DiskImageSettingsTests(TempCase):
    def test_finder_layout_and_native_bookmark(self):
        alias = SimpleNamespace(Bookmark=SimpleNamespace(for_file=None))
        defines = {'app': '/build/eSemnBun.app', 'icon': '/build/volume.icns', 'background': '/build/bg.png'}
        with patch.dict(sys.modules, {'mac_alias': alias}), patch.dict(os.environ, {'ESEMNBUN_BOOKMARK_TOOL': '/bin/bookmark'}), \
                patch('subprocess.check_output', return_value=b'bookmark') as tool:
            settings = __import__('runpy').run_path(str(REPO / 'distribution/apple/dmg/settings.py'),
                                                     init_globals={'defines': defines})
            self.assertEqual(alias.Bookmark.for_file('/Volumes/eSemnBun/.background.png').to_bytes(), b'bookmark')
        tool.assert_called_once_with(['/bin/bookmark', '/Volumes/eSemnBun/.background.png'])
        self.assertEqual((settings['format'], settings['filesystem'], settings['files']), ('UDZO', 'HFS+', ['/build/eSemnBun.app']))
        self.assertEqual(settings['icon_locations'], {'eSemnBun.app': (208, 190), ' ': (472, 190)})
        self.assertEqual(settings['symlinks'], {' ': '/Applications'})
        self.assertEqual(settings['hide_extensions'], [])
