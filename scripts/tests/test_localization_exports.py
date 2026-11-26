"""Shared catalog exporters: generated resources, drift detection and validation failures."""
from contextlib import redirect_stderr, redirect_stdout
import io
import json
import re
from unittest.mock import patch
import xml.etree.ElementTree as ET

from support import REPO, TempCase, copy_into, load, run


def entry(platform, key, **translations):
    return {'platform': platform, 'key': key, 'translations': translations}


class LocalizeTests(TempCase):
    def setUp(self):
        super().setUp()
        self.localize = load('scripts/localize.py')
        self.catalog = {'entries': [
            entry('android', 'greeting', ro='Salut %1$s', en="It's %1$s \"quoted\"", ru='Привет %1$s'),
            entry('android', 'files', ro={'one': '%d fișier', 'other': '%d fișiere'},
                  en={'one': 'One file', 'other': '%d files'}, ru={'one': '%d файл', 'other': '%d файлов'}),
            entry('windows', 'Title.Text', ro='Semnează & trimite', en='Sign <now>'),
            entry('apple', 'signTitle', ro='Semnează', en='Sign', ru='Подписать'),
            entry('linux', 'quit', ro='Ieșire', en='Quit', ru='Выход'),
        ]}

    def use_catalog(self, catalog):
        path = self.tmp / 'localization/catalog.json'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(catalog, ensure_ascii=False))
        self.localize.ROOT = self.tmp
        self.localize.CATALOG = path

    def main(self, *argv):
        self.output = io.StringIO()
        with patch('sys.argv', ['localize.py', *argv]), redirect_stdout(self.output), redirect_stderr(self.output):
            return self.localize.main()

    def test_outputs_escape_each_platform_format_and_fall_back_to_english(self):
        outputs = self.localize.outputs(self.catalog, ['android', 'windows', 'apple', 'linux'])
        android = ET.fromstring(outputs['android/app/src/main/res/values-en/strings.xml'])
        self.assertEqual(android.find("string[@name='greeting']").text, 'It\\\'s %1$s \\"quoted\\"')
        plural = {item.get('quantity'): item.text for item in android.find("plurals[@name='files']")}
        self.assertEqual(plural, {'one': 'One file', 'other': '%d files'})
        resw = ET.fromstring(outputs['windows/src/MoldSign.App/Strings/ru-RU/Resources.resw'])
        # Russian is missing for the Windows entry, so English is exported instead of Romanian.
        self.assertEqual(resw.find("data[@name='Title.Text']/value").text, 'Sign <now>')
        self.assertEqual(resw.find("resheader[@name='version']/value").text, '2.0')
        xcstrings = json.loads(outputs['apple/Apps/Shared/Resources/Localizable.xcstrings'])
        self.assertEqual(xcstrings['strings']['signTitle']['localizations']['ru']['stringUnit']['value'], 'Подписать')
        self.assertIn('        case signTitle\n', outputs['apple/Apps/Shared/Services/L10n.swift'])
        linux = outputs['linux/Sources/MoldSignGnome/Infrastructure/Localization/L10n.swift']
        self.assertIn('        case quit\n', linux)
        self.assertIn('"en": "Quit"', linux)

    def test_write_then_check_round_trips_and_detects_drift(self):
        self.use_catalog(self.catalog)
        self.assertEqual(self.main('--platform', 'ios', '--platform', 'android'), 0)
        written = self.tmp / 'android/app/src/main/res/values/strings.xml'
        self.assertIn('Salut %1$s', written.read_text())
        self.assertFalse((self.tmp / 'windows').exists())
        self.assertEqual(self.main('--check', '--platform', 'apple', '--platform', 'android', '--require-complete'), 0)
        written.write_text('stale')
        self.assertEqual(self.main('--check', '--platform', 'android'), 1)
        self.assertIn('android/app/src/main/res/values/strings.xml', self.output.getvalue())

    def test_check_rejects_unkeyed_swift_copy(self):
        self.use_catalog(self.catalog)
        self.main('--platform', 'linux')
        source = self.tmp / 'linux/Sources/Screen.swift'
        source.write_text('let a = L10n.text(.quit)\nlet b = Button("Delete document")\nlet c = Text("\\(value)")\n')
        (self.tmp / 'linux/Sources/MoldSignGnome/Infrastructure/Localization/Other.swift').write_text(
            'let d = String(localized: "x")\n')
        self.assertEqual(self.main('--check', '--platform', 'linux'), 1)
        self.assertIn('linux/Sources/Screen.swift:2\n', self.output.getvalue())
        self.assertNotIn('Screen.swift:3', self.output.getvalue())
        source.write_text('let ok = Text(L10n.text(.quit))\n')
        (self.tmp / 'linux/Sources/MoldSignGnome/Infrastructure/Localization/Other.swift').unlink()
        self.assertEqual(self.main('--check', '--platform', 'linux'), 0)

    def test_catalog_validation_failures(self):
        cases = {
            'Duplicate localization': [self.catalog['entries'][3], self.catalog['entries'][3]],
            'stable identifiers': [entry('apple', 'not-valid', ro='a')],
            'Formatting arguments differ': [entry('linux', 'count', ro='%d items', en='items')],
            "Missing ['ru']": [entry('apple', 'partial', ro='a', en='b')],
        }
        for message, entries in cases.items():
            with self.subTest(message=message):
                self.use_catalog({'entries': entries})
                with self.assertRaisesRegex(SystemExit, re.escape(message)):
                    self.main('--require-complete', '--platform', 'apple', '--platform', 'linux')

    def test_repository_exports_match_catalog(self):
        result = run('scripts/localize.py', '--check', '--require-complete')
        self.assertEqual(result.code, 0, result.stderr)
        self.assertIn('Localization exports match: apple, android, windows, linux', result.stdout)


class BrowserExportTests(TempCase):
    def test_repository_browser_exports_match(self):
        locale = run('scripts/export-browser-locale.py', '--check')
        self.assertEqual((locale.code, locale.stdout), (0, 'Browser locale exports match\n'))
        services = run('scripts/export-browser-services.py', '--check')
        self.assertEqual((services.code, services.stdout), (0, 'Browser service exports match\n'))

    def test_locale_export_writes_both_platforms_then_detects_drift(self):
        copy_into(self.tmp, 'spec/browser/locale.js')
        for name in ('apple/Apps/Shared/Services', 'android/app/src/main/kotlin/md/moldsign/app/ui/screens'):
            (self.tmp / name).mkdir(parents=True)
        self.assertEqual(run('scripts/export-browser-locale.py', root=self.tmp).stdout, 'Browser locale exports updated\n')
        swift = (self.tmp / 'apple/Apps/Shared/Services/BrowserLocaleScript.swift').read_text()
        self.assertIn('.replacingOccurrences(of: "__APP_LANGUAGE__", with: language)', swift)
        self.assertEqual(run('scripts/export-browser-locale.py', '--check', root=self.tmp).code, 0)
        (self.tmp / 'android/app/src/main/kotlin/md/moldsign/app/ui/screens/BrowserLocaleScript.kt').write_text('old')
        result = run('scripts/export-browser-locale.py', '--check', root=self.tmp)
        self.assertIn('Browser locale export differs: android/', str(result.code))

    def test_service_export_writes_swift_kotlin_and_assets(self):
        copy_into(self.tmp, 'spec/browser/services.json', 'spec/browser/icons')
        services = json.loads((self.tmp / 'spec/browser/services.json').read_text())
        services[0] = {'id': 'keyed', 'titleKey': 'portalTitle', 'url': 'https://example.md/', 'icon': services[0]['icon']}
        (self.tmp / 'spec/browser/services.json').write_text(json.dumps(services))
        self.assertEqual(run('scripts/export-browser-services.py', root=self.tmp).stdout, 'Browser service exports updated\n')
        swift = (self.tmp / 'apple/Apps/Shared/Services/PortalService.swift').read_text()
        self.assertIn('.init(id: "keyed", name: nil, titleKey: .portalTitle, url: URL(string: "https://example.md/")!', swift)
        kotlin = (self.tmp / 'android/app/src/main/kotlin/md/moldsign/app/ui/screens/PortalService.kt').read_text()
        self.assertIn('PortalService(null, R.string.portalTitle, "https://example.md/"', kotlin)
        icon = services[0]['icon']
        self.assertEqual((self.tmp / f'android/app/src/main/res/drawable-nodpi/portal_service_{icon}.png').read_bytes(),
                         (REPO / f'spec/browser/icons/{icon}.png').read_bytes())
        (self.tmp / 'apple/Apps/Shared/Resources/PortalServices.xcassets/Contents.json').unlink()
        self.assertIn('differs', str(run('scripts/export-browser-services.py', '--check', root=self.tmp).code))

    def test_service_export_rejects_credentials_in_urls(self):
        copy_into(self.tmp, 'spec/browser/icons')
        (self.tmp / 'spec/browser/services.json').write_text(json.dumps(
            [{'id': 'a', 'title': 'A', 'url': 'https://user:secret@example.md/', 'icon': 'evo'}]))
        with self.assertRaises(AssertionError):
            run('scripts/export-browser-services.py', root=self.tmp)


class StoreMetadataTests(TempCase):
    def checkout(self, mutate=None, config=None):
        copy_into(self.tmp, 'distribution/stores.json', 'localization/catalog.json')
        catalog_path = self.tmp / 'localization/catalog.json'
        catalog = json.loads(catalog_path.read_text())
        if mutate:
            mutate(catalog['storeMetadata'])
            catalog_path.write_text(json.dumps(catalog, ensure_ascii=False))
        if config:
            stores = json.loads((self.tmp / 'distribution/stores.json').read_text())
            stores.update(config)
            (self.tmp / 'distribution/stores.json').write_text(json.dumps(stores))

    def test_repository_metadata_matches_catalog(self):
        result = run('scripts/prepare-store-metadata.py', '--check')
        self.assertEqual(result.code, 0, result.stderr)
        self.assertIn('Local metadata matches for Apple, Google, Microsoft and Huawei.', result.stdout)

    def test_export_writes_every_store_and_mirrors_mac_english(self):
        self.checkout(config={'usesPlaceholderURLs': True})
        result = run('scripts/prepare-store-metadata.py', root=self.tmp)
        self.assertEqual(result.code, 0, result.stderr)
        self.assertIn('reserved placeholders', result.stdout)
        gb = self.tmp / 'distribution/apple/macos/en-GB/name.txt'
        self.assertEqual(gb.read_text(), (self.tmp / 'distribution/apple/macos/en-US/name.txt').read_text())
        listing = json.loads((self.tmp / 'distribution/microsoft/listings/en.json').read_text())
        self.assertEqual(listing['platform'], 'windows')
        self.assertLessEqual(len(listing['searchTerms']), 7)
        self.assertNotIn('platformNotes', listing)
        self.assertEqual(run('scripts/prepare-store-metadata.py', '--check', root=self.tmp).code, 0)
        (self.tmp / 'distribution/metadata/ro.json').write_text('{}')
        drift = run('scripts/prepare-store-metadata.py', '--check', root=self.tmp)
        self.assertEqual(drift.code, 1)
        self.assertIn('distribution/metadata/ro.json', drift.stderr)

    def test_missing_submission_urls_fail_check(self):
        self.checkout(config={'privacyPolicyURL': ''})
        result = run('scripts/prepare-store-metadata.py', '--check', root=self.tmp)
        self.assertEqual(result.code, 1)
        self.assertIn('Submission fields still required: privacyPolicyURL', result.stdout)

    def test_listing_limits_and_platform_mentions_are_enforced(self):
        def set_field(lang, field, value):
            return lambda metadata: metadata[lang].__setitem__(field, value)

        def set_notes(platform, value):
            return lambda metadata: metadata['en']['releaseNotesByPlatform'].__setitem__(platform, value)

        def long_term(metadata):
            metadata['en']['keywords'] = 'x' * 41 + ',b'
            metadata['en'].pop('keywordsByPlatform', None)

        cases = {
            'en/name: 31 exceeds 30': set_field('en', 'name', 'n' * 31),
            'missing platform release notes': set_notes('linux', ''),
            'mentions another platform (Android)': set_notes('ios', 'Now on Android too'),
            'en/android/changelog': set_notes('android', 'a' * 501),
            'search term exceeds 40': long_term,
        }
        for message, mutate in cases.items():
            with self.subTest(message=message):
                self.checkout(mutate)
                result = run('scripts/prepare-store-metadata.py', root=self.tmp)
                self.assertIn(message, str(result.code))

