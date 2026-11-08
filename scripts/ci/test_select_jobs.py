import subprocess
import unittest
from select_jobs import JOBS, changed_paths, select


class SelectionTests(unittest.TestCase):
    def test_docs_and_website_skip_native(self):
        for path in ['docs/reports/release.md', 'website/src/pages/index.jsx', 'AGENTS.md',
                     '.agents/skills/esemnbun-release-stores/SKILL.md', 'fastlane/SIGNING.md', 'android/README.md']:
            self.assertFalse(any(select([path]).values()), path)

    def test_native_and_shared_changes(self):
        self.assertEqual({k for k, v in select(['android/app/ui.kt']).items() if v}, {'android', 'localization'})
        self.assertEqual({k for k, v in select(['windows/src/Job.cs']).items() if v}, {'windows', 'localization'})
        self.assertEqual({k for k, v in select(['swift/MoldSignKit/Package.swift']).items() if v}, {'swift', 'macos', 'ios', 'linux'})
        self.assertTrue(all(select(['spec/mcp.md']).values()))
        self.assertTrue(all(select(['localization/catalog.json']).values()))

    def test_unknown_and_ci_changes_fail_open(self):
        for path in ['new-build-system.toml', 'scripts/ci/select_jobs.py', '.github/workflows/ci.yml']:
            self.assertTrue(all(select([path]).values()))

    def test_union(self):
        self.assertEqual(set(k for k,v in select(['linux/a.swift','windows/b.cs']).items() if v), {'linux','windows','localization'})

    def test_pr_uses_merge_base_and_null_delimited_paths(self):
        def git(command, **kwargs):
            self.assertEqual(command[-1], 'base...head')
            return b'android/file name.kt\0docs/a.md\0'
        event={'pull_request': {'base': {'sha':'base'},'head':{'sha':'head'}}}
        self.assertEqual(changed_paths(event, git), ['android/file name.kt','docs/a.md'])

    def test_push_and_missing_history(self):
        self.assertIsNone(changed_paths({'before':'0000','after':'head'}))
        def missing(*args, **kwargs):raise subprocess.CalledProcessError(1, 'git')
        self.assertIsNone(changed_paths({'before':'base','after':'head'}, missing))
        self.assertEqual(changed_paths({'before':'base','after':'head'}, lambda *a, **k:b''), [])
