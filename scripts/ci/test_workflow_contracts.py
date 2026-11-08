"""Detect credential-documentation drift and CI privilege regressions without reading secret values."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[2]


class WorkflowContracts(unittest.TestCase):
    def test_all_referenced_distribution_secrets_are_documented(self):
        names=set()
        for path in (ROOT/'.github/workflows').glob('*.yml'):
            names.update(re.findall(r'secrets\.([A-Z][A-Z0-9_]*)',path.read_text()))
        guide=(ROOT/'docs/14-github-actions.md').read_text()
        self.assertGreater(len(names),15)
        for name in names:self.assertIn('`'+name+'`',guide,name)

    def test_validation_has_no_distribution_secrets_or_write_permission(self):
        ci=(ROOT/'.github/workflows/ci.yml').read_text()
        self.assertNotIn('secrets.',ci)
        self.assertNotIn('contents: write',ci)
        self.assertNotIn('pull_request_target',ci)
        self.assertIn('name: CI result',ci)

    def test_counter_callers_keep_shared_serialization(self):
        for name in ['android-build.yml','release.yml']:
            text=(ROOT/'.github/workflows'/name).read_text()
            self.assertIn('group: android-play-version-code',text)
            self.assertIn('bash scripts/ci/reserve-android-version.sh',text)
        publish=(ROOT/'.github/workflows/android-play-publish.yml').read_text()
        self.assertIn('group: android-play-version-code',publish)
        self.assertNotIn('cancel-in-progress: true',publish)
