"""The native fixture runner must preserve existing simulator files and preferences."""
import importlib.util
import json
from pathlib import Path
import plistlib
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('document_fixtures', ROOT / 'apple/scripts/seed-documents-ui-tests.py')
fixtures = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixtures)


class DocumentUIFixtureTests(unittest.TestCase):
    def inputs(self, root):
        source = root / 'fixtures'
        source.mkdir()
        (source / 'detached-original.txt').write_bytes(b'synthetic original')
        (source / 'detached-signature.xml').write_bytes(b'synthetic signature')
        pdf = root / 'source.pdf'
        pdf.write_bytes(b'synthetic PDF')
        return source, pdf

    def test_seeds_independent_legacy_profiles_and_preserves_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, pdf = self.inputs(root)
            container = root / 'container'
            fixtures.seed(container, source, pdf)
            domains = list((container / 'Library/Preferences').glob('*.plist'))
            self.assertEqual(len(domains), 3)
            for domain in domains:
                values = plistlib.loads(domain.read_bytes())
                self.assertNotIn('signedDocuments', values, 'The app must perform migration')
                self.assertEqual(len(json.loads(values['activity'])), 2)
            self.assertEqual((container / 'Documents/QA-synthetic-semnat.pdf').read_bytes(), pdf.read_bytes())
            self.assertEqual((container / 'Documents/Originals/detached-original.txt').read_bytes(),
                             (source / 'detached-original.txt').read_bytes())

    def test_existing_fixture_refuses_before_any_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, pdf = self.inputs(root)
            container = root / 'container'
            existing = container / 'Documents/detached-signature.xml'
            existing.parent.mkdir(parents=True)
            existing.write_bytes(b'keep existing document')
            with self.assertRaises(AssertionError):
                fixtures.seed(container, source, pdf)
            self.assertEqual(existing.read_bytes(), b'keep existing document')
            self.assertEqual(list(container.rglob('*')), [existing.parent, existing])
