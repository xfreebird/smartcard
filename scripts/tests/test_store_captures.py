"""Google Play and Microsoft Store artwork: emulator/VM capture drivers, renderers and the pack builder."""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile
from unittest.mock import Mock, patch
import zipfile

from PIL import Image

from support import TempCase, completed, copy_into, fast_pillow, load, png, run

TOOLS = 'distribution/tools/'


def size_of(path):
    with Image.open(path) as image:
        return image.size, image.mode


def encoded(size, mode='RGB', color='white'):
    buffer = io.BytesIO()
    Image.new(mode, size, color).save(buffer, 'PNG', compress_level=1)
    return buffer.getvalue()


class StoreDevice:
    """adb stand-in for capture-android-store: disclosure, method menu and NFC/reader state per launch."""
    WORDS = {'en': ('Sign', 'With a card reader', 'With your phone · NFC'), 'ro': ('Semnează', 'Cu un cititor de carduri', 'Cu telefonul · NFC')}

    def __init__(self, reader_after_swipe=False, nfc_works=True, disclosure_stays=False, wrong_language=False,
                 ready=True, locale_ok=True, booted=True, broken_dumps=0):
        self.reader_after_swipe, self.nfc_works, self.disclosure_stays = reader_after_swipe, nfc_works, disclosure_stays
        self.wrong_language, self.ready, self.locale_ok, self.booted = wrong_language, ready, locale_ok, booted
        self.broken_dumps, self.calls, self.lang, self.size = broken_dumps, [], 'en', (1080, 1920)

    def reset(self):
        self.disclosure, self.menu, self.nfc, self.swiped = True, False, False, False

    def hierarchy(self):
        sign, reader, nfc = self.WORDS.get(self.lang, self.WORDS['en'])
        nodes = []
        if self.disclosure:
            nodes.append(('Continue', '[0,0][10,10]'))
        nodes.append(('Подписать' if self.wrong_language else sign, '[100,100][110,110]'))
        nodes.append(('ION POPESCU', '[100,200][110,210]'))
        if not self.reader_after_swipe or self.swiped:
            nodes.append((reader, '[20,0][30,10]'))
        if self.menu:
            nodes.append((nfc, '[40,0][50,10]'))
        if self.nfc:
            nodes.append(('NFC ready', '[60,0][70,10]'))
        body = ''.join(f'<node text="{text}" content-desc="" bounds="{bounds}"/>' for text, bounds in nodes)
        return f'<hierarchy>{body}</hierarchy>'

    def __call__(self, command, check, stdout):
        args = [str(part) for part in command[3:]]
        self.calls.append(args)
        output = b''
        if args[:3] == ['shell', 'getprop', 'sys.boot_completed']:
            output = b'1' if self.booted else b'0'
        elif args[:3] == ['shell', 'wm', 'size']:
            self.size = tuple(map(int, args[3].split('x')))
        elif args[:4] == ['shell', 'cmd', 'locale', 'set-app-locales']:
            self.lang = args[args.index('--locales') + 1]
        elif args[:4] == ['shell', 'cmd', 'locale', 'get-app-locales']:
            output = f'Locales: [{self.lang if self.locale_ok else "xx"}]'.encode()
        elif args[:3] == ['shell', 'am', 'start']:
            self.reset()
        elif args[:2] == ['logcat', '-d']:
            output = b'ready:sign ready:settings ready:verify ready:browser' if self.ready else b''
        elif args[:2] == ['shell', 'cat']:
            if self.broken_dumps:
                self.broken_dumps -= 1
                output = b'<broken'
            else:
                output = self.hierarchy().encode()
        elif args[:3] == ['shell', 'input', 'tap']:
            point = (int(args[3]), int(args[4]))
            if point == (5, 5) and not self.disclosure_stays:
                self.disclosure = False
            elif point == (25, 5):
                self.menu = True
            elif point == (45, 5):
                self.menu, self.nfc = False, self.nfc_works
        elif args[:3] == ['shell', 'input', 'swipe']:
            self.swiped = True
        elif args[:3] == ['exec-out', 'screencap', '-p']:
            output = encoded(self.size, 'RGBA')
        return completed(command, stdout=output)


class AndroidStoreCaptureTests(TempCase):
    def setUp(self):
        super().setUp()
        self.apk = self.tmp / 'app.apk'
        self.apk.write_bytes(b'apk')

    def capture(self, device, *args):
        with patch('subprocess.run', device), patch('time.sleep'):
            return run(TOOLS + 'capture-android-store.py', '--adb', '/sdk/adb', '--apk', self.apk,
                       '--output', self.tmp / 'out', *args)

    def test_each_story_switches_methods_and_records_the_apk(self):
        (self.tmp / 'out').mkdir()
        (self.tmp / 'out/capture-manifest.json').write_text(json.dumps([
            {'file': 'old', 'layout': 'phone', 'locale': 'ro', 'page': 'sign'},
            {'file': 'kept', 'layout': 'seven-inch', 'locale': 'en', 'page': 'sign'}]))
        device = StoreDevice()
        result = self.capture(device, '--layouts', 'phone', '--languages', 'en,ro', '--stories', 'sign,reader,card,verify,browser')
        self.assertEqual(result.code, 0, result.stderr)
        audit = json.loads((self.tmp / 'out/capture-manifest.json').read_text())
        self.assertEqual(audit[0]['file'], 'kept')
        self.assertEqual(len(audit), 1 + 2 * 5)
        self.assertEqual(size_of(self.tmp / 'out/ro/phone/02-card.png'), ((1080, 1920), 'RGB'))
        self.assertIn(['shell', 'input', 'tap', '45', '5'], device.calls)
        self.assertEqual(device.calls[-1], ['shell', 'am', 'force-stop', 'md.esemnbun.app'])

    def test_landscape_layout_scrolls_to_the_method_selector(self):
        device = StoreDevice(reader_after_swipe=True)
        result = self.capture(device, '--layouts', 'ten-inch', '--languages', 'en', '--stories', 'sign,reader')
        self.assertEqual(result.code, 0, result.stderr)
        swipes = [call for call in device.calls if call[:3] == ['shell', 'input', 'swipe']]
        self.assertEqual(swipes[0][3:], ['844', '788', '844', '345', '420'])
        self.assertEqual(size_of(self.tmp / 'out/en/ten-inch/01-sign.png')[0], (1920, 1080))

    def test_unexpected_device_states_stop_capture_and_keep_the_audit(self):
        cases = [
            (StoreDevice(nfc_works=False), 'sign', 'did not enter NFC mode'),
            (StoreDevice(disclosure_stays=True), 'card', 'Disclosure still covers capture'),
            (StoreDevice(wrong_language=True), 'card', 'Wrong capture language en'),
            (StoreDevice(ready=False), 'card', 'Frame timeout phone/en/card'),
            (StoreDevice(locale_ok=False), 'card', 'Cannot set capture language en'),
            (StoreDevice(broken_dumps=3), 'card', 'Could not read the current Android accessibility hierarchy'),
        ]
        for device, story, message in cases:
            with self.subTest(message=message), self.assertRaisesRegex(RuntimeError, message):
                self.capture(device, '--layouts', 'phone', '--languages', 'en', '--stories', story)
            self.assertEqual(json.loads((self.tmp / 'out/capture-manifest.json').read_text()), [])
        with self.assertRaisesRegex(RuntimeError, 'Emulator not ready'):
            self.capture(StoreDevice(booted=False))
        with self.assertRaisesRegex(AssertionError, 'Dedicated emulator required'):
            self.capture(StoreDevice(), '--serial', 'R5CT')

    def test_reader_story_requires_a_visible_demo_card(self):
        device = StoreDevice()
        original = device.hierarchy
        device.hierarchy = lambda: original().replace('ION POPESCU', 'Nobody')
        with self.assertRaisesRegex(RuntimeError, 'Reader capture needs the selected method'):
            self.capture(device, '--layouts', 'phone', '--languages', 'en', '--stories', 'reader')

    def test_missing_method_selector_is_named(self):
        device = StoreDevice()
        original = device.hierarchy
        device.hierarchy = lambda: original().replace('With a card reader', 'Something else')
        with self.assertRaisesRegex(RuntimeError, 'Cannot locate signing method'):
            self.capture(device, '--layouts', 'phone', '--languages', 'en', '--stories', 'sign')


class AndroidStoreAllTests(TempCase):
    def drive(self, devices='List of devices attached\n', avds='eSemnBun-mock\n', ready=('1',), exited=False, hang=False):
        sdk = self.tmp / 'sdk'
        process = Mock()
        process.poll.return_value = 1 if exited else None
        if hang:
            process.wait.side_effect = [subprocess.TimeoutExpired('emulator', 20), 0]
        answers = iter(ready)
        calls = []

        def check_output(command, text=True):
            return devices if command[1] == 'devices' else avds

        def subprocess_run(command, **kwargs):
            calls.append(command)
            if command[-2:] == ['getprop', 'sys.boot_completed']:
                return completed(command, 0, stdout=next(answers, '1'), stderr='')
            return completed(command)

        def popen(command, stdout, stderr):
            stdout.write('emulator log line\n')
            stdout.flush()
            return process
        with patch('subprocess.check_output', check_output), patch('subprocess.run', subprocess_run), \
                patch('subprocess.Popen', popen), patch('time.sleep'):
            result = run(TOOLS + 'capture-android-store-all.py', '--output', self.tmp / 'pack', '--sdk', sdk, '--port', '5570')
        return result, calls, process

    def test_task_owned_emulator_is_booted_used_and_stopped(self):
        result, calls, process = self.drive(ready=('', '0', '1'))
        self.assertEqual(result.code, 0, result.stderr)
        capture = next(call for call in calls if call[0] == 'python3')
        self.assertEqual(capture[capture.index('--serial') + 1], 'emulator-5570')
        self.assertEqual(capture[capture.index('--output') + 1], str(self.tmp / 'pack/google/assets/android'))
        self.assertEqual(calls[-1], [str(self.tmp / 'sdk/platform-tools/adb'), '-s', 'emulator-5570', 'emu', 'kill'])
        self.assertIn('read-only emulator stopped', result.stdout)
        _, _, hung = self.drive(hang=True)
        hung.terminate.assert_called_once()

    def test_busy_port_missing_avd_and_failed_boot_stop(self):
        self.assertIn('emulator-5570 is already in use', self.drive(devices='emulator-5570\tdevice\n')[0].code)
        self.assertIn("AVD 'eSemnBun-mock' not installed", self.drive(avds='Other\n')[0].code)
        with self.assertRaisesRegex(RuntimeError, 'Test emulator exited; emulator log line'):
            self.drive(exited=True)
        with self.assertRaisesRegex(TimeoutError, 'boot timed out'):
            self.drive(ready=('0',) * 240)
        with self.assertRaisesRegex(AssertionError, 'even dedicated emulator port'):
            run(TOOLS + 'capture-android-store-all.py', '--output', self.tmp, '--port', '5571')


class WindowsRemoteCaptureTests(TempCase):
    def setUp(self):
        super().setUp()
        for relative in ('windows/src/App.cs', 'windows/src/bin/Debug/skip.dll', 'spec/cli.md', 'localization/catalog.json',
                         'distribution/tools/capture-windows-store.ps1', 'swift/MoldSignKit/Resources/localhost.p12'):
            (self.tmp / relative).parent.mkdir(parents=True, exist_ok=True)
            (self.tmp / relative).write_text(relative)

    def drive(self, result='OK', archive=None, ssh_failures=0, *extra):
        commands, staged = [], {}
        failures = [ssh_failures]

        def subprocess_run(command, **kwargs):
            commands.append(command)
            if command[0] == 'scp':
                source, target = command[-2], command[-1]
                if source.endswith('source.tgz'):
                    with tarfile.open(source) as tar:
                        staged['names'] = tar.getnames()
                else:
                    Path(target).write_bytes(archive or self.capture_zip())
                return completed(command)
            if failures[0]:
                failures[0] -= 1
                return completed(command, 255, stdout='', stderr='')
            encoded_command = command[-1]
            script = __import__('base64').b64decode(encoded_command).decode('utf-16le')
            return completed(command, 0, stdout=result if 'result.txt' in script and 'Test-Path' in script else '', stderr='')
        with patch('subprocess.run', subprocess_run), patch('time.sleep'):
            outcome = run(TOOLS + 'capture-windows-store-remote.py', '--output', self.tmp / 'pack', *extra, root=self.tmp)
        return outcome, commands, staged

    def capture_zip(self, names=None):
        buffer = io.BytesIO()
        image = encoded((1366, 768))
        with zipfile.ZipFile(buffer, 'w') as archive:
            archive.writestr('ro-RO/', '')
            for tag in ('ro-RO', 'en-US', 'ru-RU'):
                for page in ('sign', 'card', 'verify', 'settings'):
                    archive.writestr(f'{tag}\\{page}.png', image)
            for name in names or ():
                archive.writestr(name, b'x')
        return buffer.getvalue()

    def test_source_is_staged_built_in_the_desktop_session_and_collected(self):
        outcome, commands, staged = self.drive(ssh_failures=1)
        self.assertEqual(outcome.code, 0, outcome.stderr)
        self.assertIn('Captured 12 Windows screenshots', outcome.stdout)
        self.assertNotIn('windows/src/bin/Debug/skip.dll', staged['names'])
        self.assertIn('swift/MoldSignKit/Resources/localhost.p12', staged['names'])
        manifest = json.loads((self.tmp / 'pack/microsoft/assets/capture-manifest.json').read_text())
        self.assertEqual(manifest[3]['file'], str(self.tmp / 'pack/microsoft/assets/ro/04-settings.png'))
        self.assertFalse(manifest[0]['hardware'])
        last = __import__('base64').b64decode(commands[-1][-1]).decode('utf-16le')
        self.assertIn('Unregister-ScheduledTask', last)

    def test_failures_are_reported_and_the_task_is_removed(self):
        with self.assertRaisesRegex(RuntimeError, 'Windows publish failed'):
            self.drive(result='Windows publish failed')
        with self.assertRaisesRegex(RuntimeError, 'Unsafe capture archive path'):
            self.drive(archive=self.capture_zip(['../escape.png']))
        with self.assertRaisesRegex(TimeoutError, 'timed out'):
            self.drive('', None, 0, '--timeout', '0')
        with self.assertRaisesRegex(AssertionError, 'dedicated screenshot staging folder'):
            run(TOOLS + 'capture-windows-store-remote.py', '--output', self.tmp, '--stage', 'D:/builds')
        with self.assertRaisesRegex(AssertionError, 'safe path characters'):
            run(TOOLS + 'capture-windows-store-remote.py', '--output', self.tmp, '--stage', 'C:/Users/x/screenshot;rm')


class PromotionalRenderTests(TempCase):
    def sources(self):
        android, windows = self.tmp / 'android', self.tmp / 'windows'
        portrait, landscape, desktop = encoded((1080, 1920)), encoded((1920, 1080)), encoded((1366, 768))
        for lang in ('ro', 'en', 'ru'):
            for family in ('phone', 'seven-inch', 'ten-inch'):
                for name in ('01-sign.png', '02-reader.png', '03-verify.png', '02-card.png'):
                    path = android / lang / family / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(landscape if family == 'ten-inch' else portrait)
            for name in ('01-sign.png', '02-card.png', '03-verify.png', '04-settings.png'):
                path = windows / lang / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(desktop)
        return android, windows

    def test_campaign_images_and_feature_graphics_are_rendered(self):
        android, windows = self.sources()
        with fast_pillow():
            result = run(TOOLS + 'render-crossplatform-promos.py', '--output', self.tmp / 'promo', '--android-raw', android,
                         '--windows-raw', windows, '--android-feature-graphics', self.tmp / 'features')
        self.assertEqual(result.code, 0, result.stderr)
        manifest = json.loads((self.tmp / 'promo/manifest.json').read_text())
        self.assertEqual(len(manifest), 48)
        self.assertEqual(size_of(self.tmp / 'promo/android/en/ten-inch/04-settings.png'), ((2560, 1440), 'RGB'))
        self.assertEqual(size_of(self.tmp / 'promo/windows/ru/desktop/03-verify.png')[0], (2880, 1800))
        self.assertEqual(size_of(self.tmp / 'features/ro/feature-graphic.png'), ((1024, 500), 'RGB'))

    def test_incomplete_or_undersized_sources_fail_closed(self):
        android, windows = self.sources()
        (windows / 'en/02-card.png').write_bytes(encoded((800, 600)))
        common = ['--output', self.tmp / 'promo', '--android-raw', android, '--windows-raw', windows]
        self.assertIn('Windows source below Store size', run(TOOLS + 'render-crossplatform-promos.py', *common).code)
        (android / 'ru/ten-inch/03-verify.png').write_bytes(encoded((1080, 1920)))
        self.assertIn('Wrong Android source size', run(TOOLS + 'render-crossplatform-promos.py', *common, '--stores', 'android').code)
        (android / 'ro/phone/01-sign.png').unlink()
        self.assertIn('Missing Android source', run(TOOLS + 'render-crossplatform-promos.py', *common).code)
        (windows / 'ro/01-sign.png').unlink()
        self.assertIn('Missing Windows source', run(TOOLS + 'render-crossplatform-promos.py', *common, '--stores', 'windows').code)
        self.assertIn('--stores must select', run(TOOLS + 'render-crossplatform-promos.py', *common, '--stores', 'ios').code)
        self.assertFalse((self.tmp / 'promo').exists())


class WindowsAndroidArtworkTests(TempCase):
    def test_brand_artwork_captions_and_validation_manifest(self):
        copy_into(self.tmp, 'android/design/play-store-icon-512.png', 'windows/src/MoldSign.App/Assets/Square150x150Logo.scale-200.png')
        png(self.tmp / 'distribution/google/assets/android/en/phone/01-sign.png', (1080, 1920), mode='RGB')
        with fast_pillow():
            result = run(TOOLS + 'render-windows-android-assets.py', root=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        google = self.tmp / 'distribution/google/assets/android'
        microsoft = self.tmp / 'distribution/microsoft/assets'
        self.assertEqual(size_of(google / 'en/feature-graphic.png'), ((1024, 500), 'RGB'))
        self.assertEqual(size_of(microsoft / 'hero-1920x1080.png'), ((1920, 1080), 'RGB'))
        self.assertEqual(size_of(microsoft / 'app-tile-300.png')[0], (300, 300))
        captions = json.loads((microsoft / 'ru/captions.json').read_text())
        self.assertEqual(captions[-1], 'Выберите язык, тему и настройки приложения.')
        self.assertEqual(json.loads((google / 'en/captions.json').read_text())[-1], 'Use your card on compatible portals.')

        png(microsoft / 'en/01-sign.png', (1366, 768), mode='RGB')
        png(google / 'ro/ten-inch/01-sign.png', (1920, 1080), mode='RGB')
        with fast_pillow():
            result = run(TOOLS + 'validate-windows-android-assets.py', root=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        records = json.loads((self.tmp / 'distribution/windows-android-assets.json').read_text())
        self.assertIn('distribution/microsoft/assets/hero-1920x1080.png', {record['file'] for record in records})
        self.assertIn(f'Validated {len(records)} store PNGs', result.stdout)
        self.assertEqual(Image.open(self.tmp / 'distribution/windows-android-contact-sheet.jpg').format, 'JPEG')
        png(google / 'en/phone/01-sign.png', (1080, 1920))
        with self.assertRaises(AssertionError):
            run(TOOLS + 'validate-windows-android-assets.py', root=self.tmp)


class StorePackTests(TempCase):
    def setUp(self):
        super().setUp()
        self.pack = load(TOOLS + 'create-store-screenshots.py')
        root = self.tmp / 'repo'
        for relative in ('distribution/apple/ios/en-US/name.txt', 'distribution/apple/screenshots/skip.png',
                         'distribution/google/metadata/title.txt', 'distribution/google/assets/android/en/captions.json',
                         'distribution/microsoft/listings/en.json', 'distribution/microsoft/assets/hero-1920x1080.png',
                         'distribution/SUBMISSION-METADATA.md'):
            (root / relative).parent.mkdir(parents=True, exist_ok=True)
            if relative.endswith('.png'):
                png(root / relative)
            else:
                (root / relative).write_text(relative)
        self.pack.ROOT = root

    def main(self, *argv):
        out = io.StringIO()
        with patch('sys.argv', ['create-store-screenshots.py', *map(str, argv)]), patch('sys.stdout', out):
            self.pack.main()
        return out.getvalue()

    def test_dry_run_lists_the_pipeline_without_running_it(self):
        with patch.object(self.pack.subprocess, 'run') as subprocess_run:
            plan = json.loads(self.main('--output', self.tmp / 'pack', '--platforms', 'apple,android', '--dry-run'))
        subprocess_run.assert_not_called()
        scripts = [Path(command[1]).name for command in plan['commands']]
        self.assertEqual(scripts, ['apple_capture_all.py', 'capture-android-store-all.py', 'apple_render.py', 'apple_validate.py',
                                   'compose-apple-creative.py', 'export-apple-creative.py', 'render-crossplatform-promos.py',
                                   'prepare-store-metadata.py', 'localize.py'])
        self.assertFalse((self.tmp / 'pack').exists())

    def test_render_only_pack_copies_metadata_and_indexes_images(self):
        output = self.tmp / 'pack'
        (output / 'apple/raw/en/duo-compact').mkdir(parents=True)
        png(output / 'apple/screenshots/en/iphone/01.png', (6, 9), mode='RGB')
        with patch.object(self.pack.subprocess, 'run') as subprocess_run, \
                patch.object(self.pack.subprocess, 'check_output', side_effect=['abc123\n', b' M file\n']):
            text = self.main('--output', output, '--render-only')
        commands = [call.args[0] for call in subprocess_run.call_args_list]
        self.assertTrue(all(call.kwargs == {'cwd': self.pack.ROOT, 'check': True} for call in subprocess_run.call_args_list))
        self.assertIn('--duo-directory', commands[1])
        self.assertIn('--stores', commands[4])
        self.assertTrue((output / 'metadata/apple/ios/en-US/name.txt').is_file())
        self.assertFalse((output / 'metadata/apple/screenshots').exists())
        self.assertTrue((output / 'microsoft/assets/hero-1920x1080.png').is_file())
        self.assertTrue((output / 'SUBMISSION-METADATA.md').is_file())
        manifest = json.loads((output / 'pack-manifest.json').read_text())
        self.assertEqual((manifest['sourceCommit'], manifest['workingTreeChanges']), ('abc123', True))
        shot = output / 'apple/screenshots/en/iphone/01.png'
        self.assertIn({'path': 'apple/screenshots/en/iphone/01.png', 'width': 6, 'height': 9, 'mode': 'RGB',
                       'sha256': hashlib.sha256(shot.read_bytes()).hexdigest()}, manifest['images'])
        self.assertIn('Prepared', text)

    def test_unknown_platforms_are_usage_errors(self):
        with patch('sys.stderr', io.StringIO()), self.assertRaises(SystemExit) as raised:
            self.main('--platforms', 'apple,ios')
        self.assertEqual(raised.exception.code, 2)
