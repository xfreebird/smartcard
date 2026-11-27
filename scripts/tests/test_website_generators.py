"""Website data generators: release downloads, update channels, diagrams and clock normalisation."""
import hashlib
import io
import json
from pathlib import Path
from unittest.mock import patch

from PIL import Image, ImageDraw

from support import REPO, TempCase, completed, load, run

GITHUB = 'https://github.com/xfreebird/smartcard/releases/download/'


def asset(tag, name, size=10, identifier=1, digest=None):
    return {'name': name, 'size': size, 'id': identifier, 'browser_download_url': f'{GITHUB}{tag}/{name}',
            'digest': digest or 'sha256:' + hashlib.sha256(b'x' * size).hexdigest()}


class DownloadsTests(TempCase):
    NAMES = ['eSemnBun-1.5.0.dmg', 'eSemnBun-1.5.0-x64.msi', 'esemnbun-cli-1.5.0-windows-x64.zip', 'eSemnBun-1.5.0.apk',
             'md.moldsign.MoldSign-1.5.0-x86_64.flatpak', 'esemnbun_1.5.0_amd64.deb', 'esemnbun-1.5.0-1.aarch64.rpm',
             'esemnbun-1.5.0-macos-universal.tar.gz', 'esemnbun-1.5.0-linux-x86_64.tar.gz', 'esemnbun-cli_1.5.0_amd64.deb',
             'esemnbun-cli-1.5.0-1.x86_64.rpm', 'SHA256SUMS.txt', 'eSemnBun-self-signed.cer', 'notes.txt',
             'esemnbun-package-repositories.tar.gz']

    def release(self, tag='v1.5.0', names=None, **extra):
        return {'tag_name': tag, 'html_url': f'https://github.com/xfreebird/smartcard/releases/tag/{tag}',
                'assets': [asset(tag, name, identifier=i) for i, name in enumerate(names or self.NAMES)], **extra}

    def generate(self, release, *flags, previous=None):
        source = self.tmp / 'release.json'
        source.write_text(json.dumps(release))
        out = self.tmp / 'out/release.json'
        if previous is not None:
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(previous))
        return run('website/scripts/generate-downloads.py', source, '--out', out, *flags), out

    def test_assets_are_classified_and_mirrored(self):
        previous = {'version': '1.4.0', 'platforms': ['kept'], 'assets': [
            {'name': 'eSemnBun-1.4.0-arm64.msi', 'url': 'https://esemnbun.md/old.msi', 'size': 1},
            {'name': 'eSemnBun-1.3.0-arm64.msi', 'url': 'https://esemnbun.md/older.msi', 'size': 1},
            {'name': 'eSemnBun-1.4.0.dmg', 'url': 'https://esemnbun.md/old.dmg', 'size': 1},
            {'name': 'readme.txt', 'url': 'https://esemnbun.md/readme.txt', 'size': 1}]}
        result, out = self.generate(self.release(), previous=previous)
        self.assertEqual(result.code, 0, result.stderr)
        data = json.loads(out.read_text())
        self.assertEqual((data['version'], data['platforms']), ('1.5.0', ['kept']))
        assets = {item['name']: item for item in data['assets']}
        self.assertNotIn('notes.txt', assets)
        self.assertNotIn('esemnbun-package-repositories.tar.gz', assets)
        self.assertEqual((assets['eSemnBun-1.5.0.dmg']['platform'], assets['eSemnBun-1.5.0.dmg']['architecture']),
                         ('macos', 'Apple silicon / Intel'))
        self.assertEqual(assets['esemnbun-1.5.0-1.aarch64.rpm']['architecture'], 'ARM64')
        self.assertEqual(assets['esemnbun-1.5.0-linux-x86_64.tar.gz']['platform'], 'linux-cli')
        self.assertEqual(assets['esemnbun-1.5.0-linux-x86_64.tar.gz']['format'], 'TAR.GZ')
        self.assertEqual(assets['md.moldsign.MoldSign-1.5.0-x86_64.flatpak']['platform'], 'linux')
        self.assertEqual(assets['esemnbun-cli_1.5.0_amd64.deb']['url'],
                         'https://esemnbun.md/packages/apt/pool/main/e/esemnbun-cli/esemnbun-cli_1.5.0_amd64.deb')
        self.assertEqual(assets['esemnbun-cli-1.5.0-1.x86_64.rpm']['url'], 'https://esemnbun.md/packages/rpm/x86_64/esemnbun-cli-1.5.0-1.x86_64.rpm')
        self.assertTrue(assets['esemnbun-cli-1.5.0-windows-x64.zip']['url'].startswith('https://esemnbun.md/packages/downloads/v1.5.0/'))
        self.assertNotIn('platform', assets['SHA256SUMS.txt'])
        # Only the newest missing ARM64 MSI is carried forward; the replaced macOS package is dropped.
        self.assertIn('eSemnBun-1.4.0-arm64.msi', assets)
        self.assertNotIn('eSemnBun-1.3.0-arm64.msi', assets)
        self.assertNotIn('eSemnBun-1.4.0.dmg', assets)

    def test_default_output_seeds_from_the_published_snapshot(self):
        source = self.tmp / 'release.json'
        source.write_text(json.dumps(self.release(names=['eSemnBun-1.5.0.dmg'])))
        written = {}
        with patch.object(Path, 'write_text', lambda path, text, *a, **k: written.__setitem__(path, text)), \
                patch.object(Path, 'mkdir'):
            result = run('website/scripts/generate-downloads.py', source)
        self.assertEqual(result.code, 0, result.stderr)
        target = REPO / 'website/src/data/release.json'
        published = json.loads(target.read_text())
        generated = json.loads(written[target])
        self.assertEqual(generated['platforms'], published['platforms'])
        self.assertEqual(generated['version'], '1.5.0')

    def test_unstable_or_foreign_assets_are_rejected(self):
        unstable = self.generate(self.release(prerelease=True), previous={'assets': []})[0]
        self.assertEqual(unstable.code, 2)
        self.assertIn('Expected a published stable x.y.z release', unstable.stderr)
        foreign = self.release(names=['eSemnBun-1.5.0.apk'])
        foreign['assets'][0]['browser_download_url'] = 'https://example.invalid/eSemnBun-1.5.0.apk'
        result = self.generate(foreign, previous={'assets': []})[0]
        self.assertEqual(result.code, 2)
        self.assertIn('Unexpected release asset host or tag', result.stderr)

    def stage(self, releases, payloads, previous=None):
        downloads = {}

        def gh_api(command):
            tag = command[2].rsplit('/', 1)[1]
            return json.dumps(releases[tag]).encode()

        def gh_download(command, stdout, check):
            identifier = int(command[2].rsplit('/', 1)[1])
            stdout.write(payloads[identifier])
            downloads[identifier] = True
            return completed(command)
        with patch('subprocess.check_output', gh_api), patch('subprocess.run', gh_download):
            result, out = self.generate(releases['v1.5.0'], '--public-dir', self.tmp / 'public', previous=previous or {'assets': []})
        return result, out, downloads, result.stderr

    def test_public_installers_are_verified_before_staging(self):
        current = {'tag_name': 'v1.5.0', 'html_url': 'u', 'assets': [asset('v1.5.0', 'eSemnBun-1.5.0.apk', 3, 7)]}
        older = {'tag_name': 'v1.4.0', 'draft': False, 'prerelease': False,
                 'assets': [asset('v1.4.0', 'eSemnBun-1.4.0.msi', 4, 8)]}
        previous = {'assets': [{'name': 'eSemnBun-1.4.0.msi', 'url': 'https://esemnbun.md/release-downloads/v1.4.0/eSemnBun-1.4.0.msi',
                                'size': 4}, {'name': 'x.deb', 'url': 'https://mirror.example/x.deb', 'size': 1}]}
        current['draft'] = current['prerelease'] = False
        result, out, downloads, _ = self.stage({'v1.5.0': current, 'v1.4.0': older}, {7: b'xxx', 8: b'xxxx'}, previous)
        self.assertEqual(result.code, 0, result.stderr)
        self.assertEqual((self.tmp / 'public/v1.5.0/eSemnBun-1.5.0.apk').read_bytes(), b'xxx')
        self.assertEqual((self.tmp / 'public/v1.4.0/eSemnBun-1.4.0.msi').read_bytes(), b'xxxx')
        assets = {item['name']: item for item in json.loads(out.read_text())['assets']}
        self.assertEqual(assets['eSemnBun-1.5.0.apk']['url'], 'https://esemnbun.md/release-downloads/v1.5.0/eSemnBun-1.5.0.apk')
        self.assertEqual(assets['x.deb']['url'], 'https://mirror.example/x.deb')
        self.assertIn('Staged v1.5.0/eSemnBun-1.5.0.apk (3 bytes, SHA-256 verified)', result.stdout)

        result, _, _, err = self.stage({'v1.5.0': current}, {7: b'tampered'})
        self.assertEqual(result.code, 2)
        self.assertIn('Published asset verification failed for v1.5.0/eSemnBun-1.5.0.apk', err)
        missing = dict(older, assets=[])
        result, _, _, err = self.stage({'v1.5.0': current, 'v1.4.0': missing}, {7: b'xxx'}, previous)
        self.assertIn('No matching stable release asset for v1.4.0/eSemnBun-1.4.0.msi', err)
        renamed = {'assets': [{'name': 'other.msi', 'url': 'https://esemnbun.md/release-downloads/v1.4.0/eSemnBun-1.4.0.msi', 'size': 1}]}
        result, _, _, err = self.stage({'v1.5.0': current}, {7: b'xxx'}, renamed)
        self.assertIn('Invalid download path for other.msi', err)


class UpdateManifestTests(TempCase):
    def test_published_channels_match_release_data(self):
        version = json.loads((REPO / 'website/src/data/release.json').read_text())['version']
        result = run('website/scripts/generate-update-manifests.py', '--version', 'v' + version,
                     '--release-data', REPO / 'website/src/data/release.json', '--out', self.tmp)
        self.assertEqual(result.code, 0)
        for platform in ('macos', 'windows', 'linux'):
            self.assertEqual((self.tmp / f'{platform}.json').read_text(),
                             (REPO / f'website/static/updates/{platform}.json').read_text())

    def test_each_platform_uses_its_newest_installer(self):
        data = self.tmp / 'release.json'
        data.write_text(json.dumps({'assets': [{'name': 'eSemnBun-1.10.0.msi'}, {'name': 'eSemnBun-1.9.3.msi'},
                                               {'name': 'esemnbun_1.2.0_amd64.deb'}, {'name': 'notes-1.11.0.txt'}]}))
        run('website/scripts/generate-update-manifests.py', '--version', '2.0.0', '--release-data', data, '--out', self.tmp / 'u')
        self.assertEqual(json.loads((self.tmp / 'u/windows.json').read_text())['version'], '1.10.0')
        self.assertEqual(json.loads((self.tmp / 'u/linux.json').read_text())['version'], '1.2.0')
        self.assertFalse((self.tmp / 'u/macos.json').exists())
        run('website/scripts/generate-update-manifests.py', '--version', '2.0.1', '--out', self.tmp / 'plain')
        self.assertEqual(json.loads((self.tmp / 'plain/macos.json').read_text()),
                         {'version': '2.0.1', 'downloadURL': 'https://esemnbun.md/downloads/'})
        with patch('sys.stderr', io.StringIO()):
            self.assertEqual(run('website/scripts/generate-update-manifests.py', '--version', '2.0-beta').code, 2)


class DeveloperDiagramTests(TempCase):
    def test_diagrams_are_reproducible(self):
        written = {}
        with patch.object(Path, 'mkdir'), \
                patch.object(Path, 'write_text', lambda path, text, encoding=None: written.__setitem__(path.name, text)):
            run('website/scripts/generate-developer-diagrams.py')
        self.assertEqual(sorted(written), ['architecture.svg', 'card-sequence.svg', 'release-pipeline.svg'])
        for name, text in written.items():
            self.assertEqual(text, (REPO / 'website/static/img/developers' / name).read_text(encoding='utf-8'))
        self.assertIn('role="img" aria-labelledby="title description"', written['architecture.svg'])
        diagrams = load('website/scripts/generate-developer-diagrams.py')
        self.assertEqual(diagrams.text(1, 2, ['a', 'b<c']).count('<tspan'), 2)
        self.assertIn('stroke-dasharray="7 5"', diagrams.arrow(0, 0, 1, 1, reply=True))


class ScreenshotClockTests(TempCase):
    def setUp(self):
        super().setUp()
        self.clocks = load('website/scripts/normalize-screenshot-clocks.py')

    def test_published_screenshots_match_the_reviewed_manifest(self):
        with patch('sys.argv', ['normalize', '--check']), patch('sys.stdout', io.StringIO()) as out:
            self.clocks.main()
        self.assertRegex(out.getvalue(), r'^\d+ clock records verified; 0 images normalized')

    def fixture(self, status_bar=False, alpha=False):
        image = Image.new('RGBA' if alpha else 'RGB', (60, 30), (240, 240, 250, 255) if alpha else (240, 240, 250))
        ImageDraw.Draw(image).text((5, 5), '13:33', fill=(0, 0, 0))
        screenshot = self.tmp / 'shot.png'
        image.save(screenshot)
        donor = Image.new('RGB', (20, 10), (255, 255, 255))
        ImageDraw.Draw(donor).rectangle((4, 2, 15, 7), fill=(10, 10, 10))
        donor.save(self.tmp / 'donor.png')
        strip = self.tmp / 'strip.png'
        Image.new('RGB', (40, 4), (1, 2, 3)).save(strip)
        row = {'path': 'shot.png', 'originalSha256': self.clocks.sha(screenshot), 'rectangle': [2, 2, 40, 20],
               'clockCrop': 'donor.png', 'clockPosition': [4, 4], 'clockSize': [24, 12]}
        if status_bar:
            row['statusBar'] = {'source': 'strip.png', 'sourceSha256': self.clocks.sha(strip),
                                'rectangle': [0, 0, 60, 22], 'crop': [0, 0, 40, 4]}
        manifest = self.tmp / 'clocks.json'
        manifest.write_text(json.dumps({'images': [row]}))
        self.clocks.ROOT, self.clocks.MANIFEST = self.tmp, manifest
        return screenshot, manifest

    def normalize(self, *argv):
        with patch('sys.argv', ['normalize', *argv]), patch('sys.stdout', io.StringIO()) as out:
            self.clocks.main()
        return out.getvalue()

    def test_clock_and_status_bar_edits_stay_inside_their_rectangles(self):
        screenshot, manifest = self.fixture(status_bar=True, alpha=True)
        before = Image.open(screenshot).convert('RGB')
        self.assertIn('1 images normalized', self.normalize())
        after = Image.open(screenshot)
        self.assertEqual(after.mode, 'RGBA')
        self.assertEqual(after.convert('RGB').getpixel((50, 2)), (1, 2, 3))
        self.assertEqual(after.convert('RGB').getpixel((59, 29)), before.getpixel((59, 29)))
        row = json.loads(manifest.read_text())['images'][0]
        self.assertEqual(row['sha256'], self.clocks.sha(screenshot))
        self.assertIn('0 images normalized', self.normalize('--check'))

    def test_unexpected_inputs_are_refused(self):
        screenshot, manifest = self.fixture()
        with self.assertRaisesRegex(SystemExit, 'changed without clock review'):
            self.normalize('--check')
        screenshot.write_bytes(screenshot.read_bytes() + b'x')
        with self.assertRaisesRegex(SystemExit, 'Unexpected source screenshot'):
            self.normalize()
        screenshot, manifest = self.fixture(status_bar=True)
        data = json.loads(manifest.read_text())
        data['images'][0]['statusBar']['sourceSha256'] = '0'
        manifest.write_text(json.dumps(data))
        with self.assertRaisesRegex(SystemExit, 'Status-bar donor changed'):
            self.normalize()
        screenshot, manifest = self.fixture(status_bar=True)
        data = json.loads(manifest.read_text())
        data['images'][0]['statusBar']['rectangle'] = [42, 0, 58, 4]
        manifest.write_text(json.dumps(data))
        with self.assertRaisesRegex(SystemExit, 'Edit escaped the status-bar band'):
            self.normalize()
        data['images'][0]['clockPosition'] = [30, 4]
        manifest.write_text(json.dumps(data))
        with self.assertRaisesRegex(SystemExit, 'Edit escaped the clock rectangle'):
            self.normalize()
