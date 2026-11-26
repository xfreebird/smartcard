"""User-guide organisation, validation and Android capture drivers against disposable checkouts."""
import io
import json
from pathlib import Path
import shutil
import unicodedata
import xml.etree.ElementTree as ET
from unittest.mock import patch

from PIL import Image

from support import REPO, TempCase, completed, copy_into, load, run


def python_slugs(groups):
    """Deterministic stand-in for github-slugger: lowercase, drop punctuation, number repeats."""
    result = []
    for headings in groups:
        seen, slugs = {}, []
        for heading in headings:
            base = ''.join(ch for ch in heading.lower() if ch in ' -_' or unicodedata.category(ch)[0] in 'LNM')
            base = base.replace(' ', '-')
            slug = base
            while slug in seen:
                seen[base] += 1
                slug = f'{base}-{seen[base]}'
            seen[slug] = 0
            slugs.append(slug)
        result.append(slugs)
    return result


class OrganizeGuidesTests(TempCase):
    def setUp(self):
        super().setUp()
        self.organizer = load('scripts/docs/organize-user-guides.py')
        self.organizer.ROOT = self.tmp
        self.organizer.MAPS = {'windows-cli': self.organizer.MAPS['windows-cli']}
        self.organizer.slug_groups = python_slugs
        for lang in ('en', 'ro', 'ru'):
            copy_into(self.tmp, f'docs/user-guide/content/{lang}/windows-cli.md')

    def organize(self, check=False):
        out = io.StringIO()
        with patch('sys.stdout', out):
            self.organizer.organize(check)
        return json.loads(out.getvalue())

    def test_task_pages_match_the_published_documentation(self):
        summary = self.organize()
        self.assertEqual((summary['overviews'], summary['taskPages']), (3, 27))
        for lang in ('en', 'ro', 'ru'):
            docs = Path('website/docs' if lang == 'en' else f'website/i18n/{lang}/docusaurus-plugin-content-docs/current')
            for page in sorted((REPO / docs / 'platforms/windows-cli').glob('*.md')):
                with self.subTest(page=f'{lang}/{page.name}'):
                    generated = self.tmp / docs / 'platforms/windows-cli' / page.name
                    self.assertEqual(generated.read_text(), page.read_text())
        manifest = json.loads((self.tmp / 'website/src/data/guide-navigation.json').read_text())
        topics = [topic['id'] for topic in manifest['platforms'][0]['topics']]
        self.assertEqual(topics[:4], ['setup', 'verification', 'mcp', 'unattended'])
        self.assertEqual(manifest['platforms'][0]['topics'][1]['labels']['en'], 'Verify with MCP')
        self.assertTrue(all(target.split('/#')[0] in topics for target in manifest['platforms'][0]['anchors']['en'].values()))
        self.assertEqual(self.organize(check=True)['filesUpdated'], 0)

    def test_check_reports_drift_and_missing_sources(self):
        self.organize()
        page = self.tmp / 'website/docs/platforms/windows-cli/mcp.md'
        page.write_text('edited')
        with patch('sys.stdout', io.StringIO()), self.assertRaisesRegex(SystemExit, 'website/docs/platforms/windows-cli/mcp.md'):
            self.organizer.organize(True)
        (self.tmp / 'docs/user-guide/content/ru/windows-cli.md').unlink()
        with self.assertRaisesRegex(SystemExit, 'Missing canonical source'):
            self.organizer.organize(True)

    def test_missing_source_is_seeded_from_the_overview_page(self):
        source = self.tmp / 'docs/user-guide/content/ro/windows-cli.md'
        published = self.tmp / 'website/i18n/ro/docusaurus-plugin-content-docs/current/platforms/windows-cli.md'
        published.parent.mkdir(parents=True)
        shutil.move(source, published)
        self.organize()
        self.assertTrue(source.is_file())

    def test_slug_groups_delegate_to_github_slugger(self):
        with patch.object(self.organizer.subprocess, 'run', return_value=completed(stdout='[["a-b"]]')) as node:
            self.assertEqual(load('scripts/docs/organize-user-guides.py').slug_groups([['A b']]), [['a-b']])
        command = node.call_args.args[0]
        self.assertEqual(command[:3], ['node', '--input-type=module', '-e'])
        self.assertIn("import Slugger from 'github-slugger'", command[3])
        self.assertEqual(node.call_args.kwargs['input'], '[["A b"]]')
        self.assertEqual(node.call_args.kwargs['cwd'], REPO / 'website')


class ValidateGuidesTests(TempCase):
    def test_published_guides_pass(self):
        result = run('scripts/docs/validate-user-guides.py')
        self.assertEqual(result.code, False, result.stdout[-2000:])
        report = json.loads(result.stdout)
        self.assertEqual(report['errors'], [])
        self.assertEqual(report['guideCount'], 30)

    def test_structural_and_asset_errors_are_reported(self):
        navigation = {'platforms': [
            {'id': 'windows-cli', 'assetPlatform': 'windows-cli', 'topics': [
                {'id': 'setup', 'panels': {'en': 1, 'ro': 0, 'ru': 0}}, {'id': 'plain', 'panels': {'en': 0}},
                {'id': 'gone', 'panels': {}}]},
            {'id': 'linux', 'assetPlatform': 'linux', 'topics': []}]}
        path = self.tmp / 'website/src/data/guide-navigation.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps(navigation))
        pages = self.tmp / 'website/docs/platforms'
        (pages / 'windows-cli').mkdir(parents=True)
        (pages / 'windows-cli.md').write_text('<GuideScreenshot src="/x.png" />')
        task = '\n'.join(['---', 'pagination_next: "platforms/linux/setup"', '---'] + ['## h'] * 9 + [
            '<GuideScreenshot src="/img/guide/windows-cli/en/ok.png" steps={[{"x": 120, "y": 5}]} />',
            '<GuideScreenshot src="/img/guide/linux/en/bad.svg" steps={[{"text": "none"}]} />',
            'Version 0.2.0'])
        (pages / 'windows-cli/setup.md').write_text(task)
        (pages / 'windows-cli/plain.md').write_text('## Text only\n<img src="/img/guide/windows-cli/en/missing.png" />')
        static = self.tmp / 'website/static/img/guide'
        (static / 'windows-cli/en').mkdir(parents=True)
        (static / 'windows-cli/en/ok.png').write_bytes(b'\x89PNG\r\n\x1a\ntruncated')
        (static / 'linux/en').mkdir(parents=True)
        (static / 'linux/en/bad.svg').write_text('<svg>')
        result = run('scripts/docs/validate-user-guides.py', root=self.tmp)
        self.assertEqual(result.code, True)
        errors = '\n'.join(json.loads(result.stdout)['errors'])
        for message in ['en/windows-cli: overview must be a task directory', 'Windows task requires numbered visual',
                        'en/windows-cli/setup: changed illustration coverage', 'task is too broad',
                        'pagination leaves device', 'Missing task page', 'screenshot panel has no numbered target',
                        'obsolete version statement', 'en/windows-cli: 2 illustrated panels; at least 3 required',
                        'Truncated or invalid PNG', 'Invalid SVG', 'incorrect platform or native locale',
                        'callout outside image (120)', 'Missing localized guide: website/i18n/ro',
                        'Missing localized guide: website/docs/platforms/linux.md']:
            self.assertIn(message, errors)


def layout(*nodes, package=True):
    body = ''.join(f'<node text="{text}" content-desc="{desc}" bounds="{bounds}"/>' for text, desc, bounds in nodes)
    return (f'<hierarchy><node package="{"md.esemnbun.app" if package else "other"}">{body}</node></hierarchy>').encode()


class WriteAndroidGuidesTests(TempCase):
    def test_guides_place_markers_from_recorded_layouts(self):
        for lang, folder in (('ro', 'values'), ('en', 'values-en'), ('ru', 'values-ru')):
            copy_into(self.tmp, f'android/app/src/main/res/{folder}/strings.xml')
        strings = {n.get('name'): ''.join(n.itertext()) for n in
                   ET.parse(self.tmp / 'android/app/src/main/res/values-en/strings.xml').getroot()}
        xml = self.tmp / '.local/guide-layouts/android'
        xml.mkdir(parents=True)
        (xml / 'android-phone-en-connect.xml').write_bytes(layout((strings['action_allow'], '', '[100,200][300,400]')))
        (xml / 'android-phone-en-sign.xml').write_bytes(layout(
            ('', 'ION POPESCU 2 cards', '[0,0][10,10]'), ('', 'ION POPESCU', '[100,100][600,500]'),
            ('', 'ION POPESCU', '[100,100][200,150]'), ('x', '', 'invalid')))
        (xml / 'android-tablet-en-pin.xml').write_bytes(layout(('PIN field', '', '[160,110][480,330]')))
        (xml / 'android-phone-en-sign-failure.xml').write_bytes(
            layout((strings['error_network'].replace('%1$s', 'TSA'), '', '[50,50][60,60]')))
        (xml / 'android-phone-en-about.xml').write_bytes(layout(('Version 0.2.6', '', '[10,2000][500,2100]')))
        (xml / 'android-phone-en-results.xml').write_bytes(b'')
        result = run('scripts/docs/write-android-guides.py', root=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        phone = (self.tmp / 'docs/user-guide/content/en/android.md').read_text()
        tablet = (self.tmp / 'docs/user-guide/content/en/android-tablet.md').read_text()
        self.assertIn('"x": 7.3, "y": 12.5', phone)  # allow button: left edge minus 2 %, vertical centre
        self.assertIn('"x": 13.3, "y": 9.2', phone)  # largest selected card face, offset beside it
        self.assertIn('"x": 53, "y": 84', phone)  # fixed phone sign action
        self.assertIn('"x": 8.0, "y": 20.0', tablet)
        self.assertIn('"x": 66, "y": 53.5', tablet)
        self.assertIn('Open Documents', tablet)
        self.assertNotIn('Open Documents', phone)
        self.assertTrue((self.tmp / 'docs/user-guide/content/ru/android.md').read_text().startswith('---\ntitle: Телефон'))


class FakeAndroid:
    """adb stand-in: boot state, logcat readiness, UI hierarchy dumps and PNG screen captures."""

    def __init__(self, test, xml=None, ready=True):
        self.test, self.calls, self.ready = test, [], ready
        self.xml = xml or layout(('Sign', '', '[0,0][10,10]'))
        self.size = (1080, 2400)

    def __call__(self, command, **kwargs):
        if command[0] == 'git':
            return 'abc123\n' if command[1] == 'rev-parse' else ''
        args = [str(part) for part in command[3:]]
        self.calls.append(args)
        if args[:2] == ['shell', 'wm'] and len(args) > 3 and args[2] == 'size' and 'x' in args[3]:
            self.size = tuple(map(int, args[3].split('x')))
        if args[:3] == ['shell', 'getprop', 'sys.boot_completed']:
            return b'1\n'
        if args[:2] == ['logcat', '-d']:
            return b'ready:sign capture-ready:activity capture-scroll-ready:sign capture-scroll-ready:verify ' \
                   b'ready:verify ready:browser ready:settings ready:card ready:activity' if self.ready else b''
        if args[:2] == ['shell', 'cat']:
            return self.xml(self) if callable(self.xml) else self.xml
        if args[:3] == ['exec-out', 'screencap', '-p']:
            data = io.BytesIO()
            Image.new('RGB', self.size, 'white').save(data, 'PNG')
            return data.getvalue()
        return b''


class CaptureAndroidGuideTests(TempCase):
    ENV = {'GUIDE_ADB': '/sdk/adb', 'GUIDE_ANDROID_SERIAL': 'emulator-5570', 'GUIDE_DISPLAY_ID': '2',
           'GUIDE_CAPTURE_STATES': 'pin,results,certificate,browser,sign-progress,details',
           'GUIDE_CAPTURE_HOST': 'ci', 'GUIDE_CAPTURE_REFRESH': '1'}

    def setUp(self):
        super().setUp()
        apk = self.tmp / 'android/app/build/outputs/apk/debug/app-debug.apk'
        apk.parent.mkdir(parents=True)
        apk.write_bytes(b'apk')

    def capture(self, device, **env):
        with patch('subprocess.check_output', device), patch('time.sleep'):
            return run('scripts/docs/capture-android-guide.py', root=self.tmp, env={**self.ENV, **env})

    def test_capture_records_evidence_for_each_layout_and_language(self):
        device = FakeAndroid(self, layout(('DEMO-Application-NOT-SIGNED.pdf', '', '[0,0][1,1]')))
        result = self.capture(device)
        self.assertEqual(result.code, 0, result.stderr)
        evidence = json.loads((self.tmp / 'docs/user-guide/android-evidence.json').read_text())
        files = {record['file'] for record in evidence['screenshots']}
        self.assertEqual(len(files), 2 * 3 * 6)
        self.assertIn('website/static/img/guide/android-tablet/ru/pin.png', files)
        record = next(r for r in evidence['screenshots'] if r['file'].endswith('android-phone/en/sign-progress.png'))
        self.assertEqual((record['staticSigningStep'], record['captureHost'], record['sourceCommit']), ('Signing', 'ci', 'abc123'))
        self.assertIn(['exec-out', 'screencap', '-p', '-d', '2'], device.calls)
        self.assertIn(['shell', 'input', 'keyevent', '4'], device.calls)
        self.assertEqual(device.calls[-1], ['shell', 'wm', 'density', 'reset'])

        resumed = FakeAndroid(self)
        result = self.capture(resumed, GUIDE_CAPTURE_RESUME='1')
        self.assertEqual(result.code, 0, result.stderr)
        self.assertNotIn(['exec-out', 'screencap', '-p', '-d', '2'], resumed.calls)

    def test_unsafe_device_states_stop_the_capture(self):
        self.assertIn('explicit Android emulator serial',
                      str(run('scripts/docs/capture-android-guide.py', env={'GUIDE_ANDROID_SERIAL': 'R58M123'}).code))
        cases = [
            (FakeAndroid(self, layout(('x', '', '[0,0][1,1]'), package=False)), 'Unexpected foreground window'),
            (FakeAndroid(self, layout(('x', '', '[0,0][1,1]'))), 'Completed sample files missing'),
            (FakeAndroid(self, layout(('demo.banner DEMO-Application-NOT-SIGNED.pdf', '', '[0,0][1,1]'))), 'Demo banner'),
            (FakeAndroid(self, ready=False), 'Not ready'),
        ]
        for device, message in cases:
            with self.subTest(message=message), self.assertRaisesRegex(RuntimeError, message):
                self.capture(device, GUIDE_CAPTURE_STATES='results')

    def test_boot_timeout_is_reported(self):
        def never_booted(command, **kwargs):
            return b'0' if 'getprop' in command else b''
        with self.assertRaisesRegex(RuntimeError, 'boot did not complete'):
            self.capture(never_booted)


class CaptureAndroidExtrasTests(TempCase):
    def test_extras_capture_menus_for_both_layouts(self):
        for folder in ('values', 'values-en', 'values-ru'):
            copy_into(self.tmp, f'android/app/src/main/res/{folder}/strings.xml')
        evidence = self.tmp / 'docs/user-guide/android-evidence.json'
        evidence.parent.mkdir(parents=True)
        evidence.write_text('{"screenshots": [{"file": "website/static/img/guide/android-phone/en/format.png"}]}')
        (self.tmp / '.local/guide-layouts/android').mkdir(parents=True)
        for platform in ('android-phone', 'android-tablet'):
            for lang in ('en', 'ro', 'ru'):
                (self.tmp / f'website/static/img/guide/{platform}/{lang}').mkdir(parents=True)
        labels = set()
        for folder in ('values', 'values-en', 'values-ru'):
            root = ET.parse(self.tmp / f'android/app/src/main/res/{folder}/strings.xml').getroot()
            strings = {n.get('name'): ''.join(n.itertext()) for n in root}
            labels.update(strings[key] for key in ('file_options', 'nav_browser', 'browser_open_in_app', 'browser_services',
                                                    'browser_bookmark_add', 'browser_clear_data', 'browser_bookmark_manage'))
        def screen(device):
            # The embedded-browser entry appears only after scrolling the Browser workspace once.
            scrolled = any(call[:3] == ['shell', 'input', 'swipe'] for call in device.calls)
            visible = [label for label in sorted(labels) if scrolled or label not in open_labels]
            return layout(*[(label.replace('&', '&amp;').replace('"', '&quot;'), '', '[10,10][30,30]') for label in visible])
        open_labels = set()
        for folder in ('values', 'values-en', 'values-ru'):
            root = ET.parse(self.tmp / f'android/app/src/main/res/{folder}/strings.xml').getroot()
            open_labels.update(''.join(n.itertext()) for n in root if n.get('name') == 'browser_open_in_app')
        device = FakeAndroid(self, screen)
        with patch('subprocess.check_output', device), patch('time.sleep'):
            result = run('scripts/docs/capture-android-guide-extras.py', root=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        records = json.loads(evidence.read_text())['screenshots']
        self.assertEqual(len(records), 2 * 3 * 5)
        self.assertEqual(sum(r['file'].endswith('android-phone/en/format.png') for r in records), 1)
        self.assertTrue(all(r['synthetic'] == (r['file'].endswith('/format.png')) for r in records))
        self.assertTrue((self.tmp / '.local/guide-layouts/android/android-tablet-ru-bookmarks.xml').is_file())

    def test_missing_controls_are_reported(self):
        copy_into(self.tmp, 'android/app/src/main/res/values/strings.xml', 'android/app/src/main/res/values-en/strings.xml')
        with patch('subprocess.check_output', FakeAndroid(self)), patch('time.sleep'), \
                self.assertRaisesRegex(RuntimeError, 'Cannot find'):
            run('scripts/docs/capture-android-guide-extras.py', root=self.tmp)
        strings = {n.get('name'): ''.join(n.itertext()) for n in
                   ET.parse(self.tmp / 'android/app/src/main/res/values-en/strings.xml').getroot()}
        (self.tmp / '.local/guide-layouts/android').mkdir(parents=True)
        (self.tmp / 'website/static/img/guide/android-phone/en').mkdir(parents=True)
        evidence = self.tmp / 'docs/user-guide/android-evidence.json'
        evidence.parent.mkdir(parents=True)
        evidence.write_text('{"screenshots": []}')
        no_browser = layout(*[(strings[key], '', '[1,1][9,9]') for key in ('file_options', 'nav_browser')])
        with patch('subprocess.check_output', FakeAndroid(self, no_browser)), patch('time.sleep'), \
                self.assertRaisesRegex(RuntimeError, 'No embedded-browser entry'):
            run('scripts/docs/capture-android-guide-extras.py', root=self.tmp)

