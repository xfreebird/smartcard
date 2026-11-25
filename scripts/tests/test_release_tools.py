"""Package checks, traceability, screenshot indexes, icon rendering and package-manager definitions."""
import hashlib
import io
import json
from pathlib import Path
import struct
import tarfile
from unittest.mock import patch
import zipfile

from PIL import Image

from support import REPO, TempCase, completed, copy_into, load, png, run


def elf(machine, bits=2, little=True):
    order = '<' if little else '>'
    header = b'\x7fELF' + bytes([bits, 1 if little else 2]) + b'\0' * 12
    return header + struct.pack(order + 'H', machine) + b'\0' * 32


class AndroidAbiTests(TempCase):
    def package(self, entries):
        path = self.tmp / 'app.aab'
        with zipfile.ZipFile(path, 'w') as archive:
            for name, data in entries.items():
                archive.writestr(name, data)
        return path

    def libraries(self, name='libmoldsign.so', prefix='base/', **overrides):
        expected = {'armeabi-v7a': (1, 40), 'arm64-v8a': (2, 183), 'x86': (1, 3), 'x86_64': (2, 62)}
        entries = {f'{prefix}lib/{abi}/{name}': elf(machine, bits) for abi, (bits, machine) in expected.items()}
        entries.update({'lib/mips/libx.so': b'ignored', 'assets/readme.txt': b'not native'})
        entries.update(overrides)
        return entries

    def test_matching_libraries_for_every_abi_pass(self):
        result = run('scripts/check-android-abis.py', self.package(self.libraries()))
        self.assertEqual(result.code, 0)
        self.assertIn('Native libraries verified for armeabi-v7a, arm64-v8a, x86, x86_64: libmoldsign.so', result.stdout)

    def test_wrong_headers_and_mismatched_sets_fail(self):
        cases = [
            ({'lib/x86/libmoldsign.so': b'not an elf'}, 'Invalid native library: lib/x86/libmoldsign.so'),
            ({'lib/x86_64/libmoldsign.so': elf(183, little=False)}, 'Wrong ELF architecture'),
            ({'lib/x86/extra.so': elf(3, 1)}, 'Native library mismatch for x86'),
        ]
        for override, message in cases:
            with self.subTest(message=message):
                result = run('scripts/check-android-abis.py', self.package(self.libraries(prefix='', **override)))
                self.assertIn(message, str(result.code))
        result = run('scripts/check-android-abis.py', self.package({'lib/x86/libmoldsign.so': elf(3, 1)}))
        self.assertEqual(result.code, 'ARM64 native libraries missing')


class JourneyCoverageTests(TempCase):
    def test_repository_catalog_is_traceable(self):
        result = run('scripts/check-journey-coverage.py')
        self.assertEqual(result.code, 0, result.stderr)
        self.assertIn('No tests executed.', result.stdout)
        catalog = json.loads((REPO / 'tests/journeys/catalog.json').read_text())
        incomplete = [row['id'] for row in catalog['journeys']
                      if row['coverage'] != 'automated' or set(row['platforms']) != {
                          platform for name in row['suites'] for platform in catalog['suites'][name]['platforms']
                          if platform in row['platforms']}]
        gate = run('scripts/check-journey-coverage.py', '--require-full-automation')
        if incomplete:
            self.assertIn('Full automation gate not met: ' + ', '.join(incomplete), gate.code)
        else:
            self.assertEqual(gate.code, 0)

    def test_inconsistent_catalogs_are_rejected(self):
        copy_into(self.tmp, 'tests/journeys/catalog.json')
        catalog = json.loads((self.tmp / 'tests/journeys/catalog.json').read_text())
        source = self.tmp / catalog['source']
        source.parent.mkdir(parents=True)
        source.write_text('| G01 | Install |\n')
        catalog['journeys'] = [row for row in catalog['journeys'] if row['id'] in ('G01', 'P01', 'P02', 'P03')]
        for suite in catalog['suites'].values():
            path = self.tmp / suite['path']
            path.parent.mkdir(parents=True, exist_ok=True)
            path.touch()
        (self.tmp / 'tests/journeys/catalog.json').write_text(json.dumps(catalog))
        self.assertEqual(run('scripts/check-journey-coverage.py', root=self.tmp).code, 0)
        catalog['journeys'][0]['suites'] = ['missing-suite']
        (self.tmp / 'tests/journeys/catalog.json').write_text(json.dumps(catalog))
        with self.assertRaises(AssertionError):
            run('scripts/check-journey-coverage.py', root=self.tmp)


class ScreenshotIndexTests(TempCase):
    def test_index_lists_dimensions_and_hashes_per_platform(self):
        png(self.tmp / 'ios/2026-11-01/a/one.png', (3, 7))
        png(self.tmp / 'linux/2026-11-01/two.png', (5, 2))
        png(self.tmp / 'linux/2026-10-30/old.png')
        result = run('scripts/index-screenshots.py', self.tmp, '--date', '2026-11-01')
        index = json.loads((self.tmp / '2026-11-01-index.json').read_text())
        self.assertEqual(json.loads(result.stdout.splitlines()[0]),
                         {'macos': 0, 'ios': 1, 'android': 0, 'windows': 0, 'linux': 1})
        self.assertEqual([(i['path'], i['width'], i['height']) for i in index['images']],
                         [('ios/2026-11-01/a/one.png', 3, 7), ('linux/2026-11-01/two.png', 5, 2)])
        (self.tmp / 'ios/2026-11-01/bad.png').write_bytes(b'GIF89a')
        self.assertIn('Invalid PNG', str(run('scripts/index-screenshots.py', self.tmp, '--date', '2026-11-01').code))


def fake_rsvg(command, check=True):
    """rsvg-convert stand-in: rasterise an RGBA PNG of the requested size."""
    size = int(command[command.index('-w') + 1])
    output = command[command.index('-o') + 1]
    Path(output).parent.mkdir(parents=True, exist_ok=True)
    Image.new('RGBA', (size, size), (63, 110, 245, 128)).save(output)
    return completed(command)


class AppIconTests(TempCase):
    def setUp(self):
        super().setUp()
        self.icons = load('scripts/make-app-icons.py')

    def test_masters_are_valid_svg_with_the_signature_mask(self):
        import xml.etree.ElementTree as ET
        for text in (self.icons.full_bleed(), self.icons.rounded(1024, 100, 185, (14, 12, 0.32)),
                     self.icons.rounded(256, 0, 56, None), self.icons.android_foreground()):
            root = ET.fromstring(text)
            self.assertEqual(root.tag, '{http://www.w3.org/2000/svg}svg')
        self.assertIn('filter="url(#sh)"', self.icons.rounded(128, 8, 26, (2, 2, 0.25)))
        self.assertNotIn('filter=', self.icons.rounded(256, 0, 56, None))
        # The 88-unit disc is scaled into the 30 dp radius of the adaptive icon's centred safe zone.
        scale = 30 / 88
        self.assertIn(f'translate({54 - 128 * scale} {54 - 128 * scale}) scale({scale})', self.icons.android_foreground())

    def test_every_platform_asset_is_written_from_one_design(self):
        self.icons.ROOT = str(self.tmp)
        self.icons.RSVG = str(self.tmp / 'rsvg-convert')
        Path(self.icons.RSVG).touch()
        commands = []

        def subprocess_run(command, check=True):
            commands.append(command)
            return fake_rsvg(command) if command[0] == self.icons.RSVG else completed(command)
        with patch.object(self.icons.subprocess, 'run', subprocess_run), patch('sys.stdout', io.StringIO()) as out:
            self.icons.main()
        ios = Image.open(self.tmp / 'apple/Apps/iOS/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png')
        self.assertEqual((ios.size, ios.mode), ((1024, 1024), 'RGB'))
        mac = json.loads((self.tmp / 'apple/Apps/macOS/Assets.xcassets/AppIcon.appiconset/Contents.json').read_text())
        self.assertEqual(len(mac['images']), 10)
        self.assertEqual(Image.open(self.tmp / 'apple/Apps/macOS/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png').size,
                         (1024, 1024))
        self.assertEqual(Image.open(self.tmp / 'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png').size,
                         (432, 432))
        self.assertIn('android:color="#FF3F6EF5"', (self.tmp / 'android/app/src/main/res/drawable/ic_launcher_background.xml').read_text())
        self.assertEqual(commands[-1][1], str(self.tmp / 'windows/scripts/make-icons.py'))
        self.assertTrue((self.tmp / 'linux/data/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg').is_file())
        self.assertIn('wrote design/app-icon/macos.svg', out.getvalue())
        self.assertFalse(any(Path(c[-1]).exists() for c in commands if c[0] == self.icons.RSVG))

    def test_missing_converter_stops(self):
        self.icons.RSVG = str(self.tmp / 'missing')
        with self.assertRaisesRegex(SystemExit, 'rsvg-convert not found'):
            self.icons.main()

    def test_launch_assets_use_the_same_mark(self):
        copy_into(self.tmp, 'scripts/make-app-icons.py')
        (self.tmp / 'design/app-icon').mkdir(parents=True)
        (self.tmp / 'design/app-icon/android-foreground.svg').write_text('<svg/>')
        with patch('shutil.which', return_value='/usr/bin/rsvg-convert'), patch('subprocess.run', fake_rsvg):
            result = run('scripts/make-launch-assets.py', root=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        self.assertIn('eSemnBun</text>', (self.tmp / 'design/launch-screen/AndroidLaunchBranding.svg').read_text())
        self.assertEqual(Image.open(self.tmp / 'apple/Apps/iOS/LaunchResources/LaunchMark.png').size, (384, 384))
        self.assertEqual(Image.open(self.tmp / 'android/app/src/main/res/drawable-xxxhdpi/launch_icon.png').size, (1152, 1152))
        with patch('shutil.which', return_value=None):
            self.assertIn('Install librsvg', run('scripts/make-launch-assets.py', root=self.tmp).code)


def release(version='1.4.2', **extra):
    names = [f'esemnbun-{version}-macos-universal.tar.gz', f'esemnbun-cli-{version}-windows-x64.zip',
             f'esemnbun-{version}-linux-x86_64.tar.gz']
    return {'tag_name': f'v{version}', 'draft': False, 'prerelease': False, 'assets': [
        {'name': name, 'browser_download_url': f'https://github.com/xfreebird/smartcard/releases/download/v{version}/{name}',
         'digest': 'sha256:' + hashlib.sha256(name.encode()).hexdigest()} for name in names], **extra}


class PackageDefinitionTests(TempCase):
    def test_definitions_reference_the_public_mirror_and_release_digests(self):
        data = self.tmp / 'release.json'
        data.write_text(json.dumps(release()))
        result = run('scripts/packages/generate.py', data, '--out', self.tmp / 'out')
        self.assertEqual(result.stdout.strip(), 'Generated Homebrew, Scoop, Chocolatey and Arch definitions for 1.4.2')
        formula = (self.tmp / 'out/esemnbun-cli.rb').read_text()
        self.assertIn('url "https://esemnbun.md/packages/downloads/v1.4.2/esemnbun-1.4.2-macos-universal.tar.gz"', formula)
        self.assertIn('sha256 "' + hashlib.sha256(b'esemnbun-1.4.2-macos-universal.tar.gz').hexdigest(), formula)
        scoop = json.loads((self.tmp / 'out/bucket/esemnbun-cli.json').read_text())
        self.assertEqual(scoop['architecture']['64bit']['hash'], hashlib.sha256(b'esemnbun-cli-1.4.2-windows-x64.zip').hexdigest())
        self.assertIn('<version>1.4.2</version>', (self.tmp / 'out/chocolatey/esemnbun-cli.nuspec').read_text())
        self.assertIn(hashlib.sha256((REPO / 'LICENSE').read_bytes()).hexdigest(), (self.tmp / 'out/arch/PKGBUILD').read_text())

    def test_untrusted_or_unstable_releases_are_rejected(self):
        data = self.tmp / 'release.json'
        data.write_text(json.dumps(release(prerelease=True)))
        with patch('sys.stderr', io.StringIO()):
            self.assertEqual(run('scripts/packages/generate.py', data, '--out', self.tmp / 'out').code, 2)
        tampered = release()
        tampered['assets'][0]['browser_download_url'] = 'https://example.invalid/x.tar.gz'
        data.write_text(json.dumps(tampered))
        with self.assertRaisesRegex(ValueError, 'Untrusted asset URL or missing digest'):
            run('scripts/packages/generate.py', data, '--out', self.tmp / 'out')


def tarball(members):
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode='w:gz') as archive:
        for name, data in members.items():
            info = tarfile.TarInfo(name)
            if data is None:
                info.type = tarfile.DIRTYPE
                archive.addfile(info)
            else:
                info.size = len(data)
                archive.addfile(info, io.BytesIO(data))
    return buffer.getvalue()


class SiteRepositoryTests(TempCase):
    def setUp(self):
        super().setUp()
        copy_into(self.tmp, 'distribution/packages/index.html', 'spec/mcp.md')
        (self.tmp / 'distribution/packages/signing-key.asc').write_text('key')
        (self.tmp / 'website/src/data').mkdir(parents=True)
        self.blobs = {}

    def published(self, tag, complete=True, draft=False):
        repositories = tarball({'packages': None, 'packages/apt/dists/stable/Release': b'r',
                                'packages/apt/dists/stable/Release.gpg': b's', 'packages/rpm/x86_64/repodata/repomd.xml': b'x',
                                'packages/rpm/x86_64/repodata/repomd.xml.asc': b'y',
                                f'packages/downloads/{tag}/esemnbun-{tag}.tar.gz': b'cli',
                                f'packages/downloads/{tag}/nested/skip.txt': b'no'})
        definitions = io.BytesIO()
        with zipfile.ZipFile(definitions, 'w') as archive:
            archive.writestr('arch/PKGBUILD', f'pkgver={tag}')
        files = {'esemnbun-package-repositories.tar.gz': repositories,
                 'esemnbun-package-definitions.zip': definitions.getvalue(), 'esemnbun-cli.nupkg': b'nupkg'}
        if not complete:
            files.pop('esemnbun-cli.nupkg')
        assets = []
        for name, data in files.items():
            url = f'https://api.example.invalid/{tag}/{name}'
            self.blobs[url] = data
            assets.append({'name': name, 'url': url, 'digest': 'sha256:' + hashlib.sha256(data).hexdigest(),
                           'browser_download_url': f'https://github.com/xfreebird/smartcard/releases/download/{tag}/{name}'})
        return {'tag_name': tag, 'draft': draft, 'prerelease': False, 'assets': assets}

    def fetch(self, current, releases):
        data = self.tmp / 'release.json'
        data.write_text(json.dumps(current))
        commands = []

        def gh(command):
            commands.append(command)
            if command[2].startswith('repos/'):
                return json.dumps(releases).encode()
            return self.blobs[command[2]]
        with patch('subprocess.check_output', gh), patch('subprocess.run') as gpg:
            result = run('scripts/packages/fetch-site-repositories.py', data, root=self.tmp)
        return result, commands, gpg

    def test_signed_feeds_and_two_previous_versions_are_staged(self):
        current, older, oldest, ancient = (self.published(tag) for tag in ('v1.3.0', 'v1.2.0', 'v1.1.0', 'v1.0.0'))
        result, commands, gpg = self.fetch(current, [current, older, oldest, ancient])
        self.assertEqual(result.code, 0, result.stderr)
        packages = self.tmp / 'website/static/packages'
        self.assertEqual((packages / 'apt/dists/stable/Release').read_bytes(), b'r')
        self.assertEqual((packages / 'PKGBUILD').read_text(), 'pkgver=v1.3.0')
        self.assertEqual((packages / 'downloads/v1.3.0/esemnbun-cli.nupkg').read_bytes(), b'nupkg')
        self.assertTrue((packages / 'downloads/v1.1.0/esemnbun-v1.1.0.tar.gz').is_file())
        self.assertFalse((packages / 'downloads/v1.0.0').exists())
        self.assertFalse((packages / 'downloads/v1.2.0/skip.txt').exists())
        self.assertEqual(json.loads((self.tmp / 'website/src/data/package-release.json').read_text()), {'version': '1.3.0'})
        self.assertNotIn('@VERSION@', (packages / 'index.html').read_text())
        verified = [call.args[0][0] for call in gpg.call_args_list]
        self.assertEqual(verified, ['gpg', 'gpgv', 'gpgv'])

    def test_partial_release_falls_back_or_keeps_existing_feeds(self):
        partial = self.published('v2.0.0', complete=False)
        good = self.published('v1.9.0')
        result, _, _ = self.fetch(partial, [partial, good])
        self.assertEqual(result.code, 0, result.stderr)
        self.assertEqual(json.loads((self.tmp / 'website/src/data/package-release.json').read_text()), {'version': '1.9.0'})
        result, _, gpg = self.fetch(partial, [partial, self.published('v1.8.0', draft=True)])
        self.assertEqual((result.code, result.stdout.strip()), (0, 'No complete package release is available yet.'))
        gpg.assert_not_called()

    def test_digest_mismatch_stops_before_staging(self):
        current = self.published('v1.3.0')
        current['assets'][0]['digest'] = 'sha256:' + '0' * 64
        with self.assertRaisesRegex(AssertionError, 'Repository archive digest mismatch'):
            self.fetch(current, [current])
        self.assertFalse((self.tmp / 'website/static/packages').exists())
