import subprocess
import unittest
from select_jobs import JOBS, changed_paths, last_validated_commit, select, selection, workflow_jobs

HEAD, GREEN, OLDER = 'c' * 40, 'b' * 40, 'a' * 40


def chosen(*paths):
    return {k for k, v in select(list(paths)).items() if v}


def pull(**head):
    return {'pull_request': {'base': {'sha': 'base'},
                             'head': {'sha': HEAD, 'ref': 'feature', 'repo': {'full_name': 'owner/repo'}} | head}}


ENVIRONMENT = {'GITHUB_TOKEN': 'token', 'GITHUB_REPOSITORY': 'owner/repo'}


def run(sha, conclusion='success', repository='owner/repo'):
    return {'head_sha': sha, 'conclusion': conclusion, 'head_repository': {'full_name': repository}}


class SelectionTests(unittest.TestCase):
    def test_docs_and_website_skip_native(self):
        for path in ['docs/reports/release.md', 'website/src/pages/index.jsx', 'AGENTS.md',
                     '.agents/skills/esemnbun-release-stores/SKILL.md', 'fastlane/SIGNING.md', 'android/README.md']:
            self.assertFalse(any(select([path]).values()), path)

    def test_native_and_shared_changes(self):
        self.assertEqual(chosen('android/app/ui.kt'), {'android', 'localization'})
        self.assertEqual(chosen('windows/src/Job.cs'), {'windows', 'localization'})
        self.assertEqual(chosen('swift/MoldSignKit/Package.swift'), {'swift', 'macos', 'ios', 'linux'})
        self.assertTrue(all(select(['spec/mcp.md']).values()))
        self.assertTrue(all(select(['localization/catalog.json']).values()))

    def test_apple_changes_run_only_the_affected_apps(self):
        for path in ('apple/Apps/iOS/MobileRootView.swift', 'apple/ShareExtension/ShareViewController.swift',
                     'apple/scripts/run-ios-ui-batch.sh', 'scripts/ci/prepare-ios-ui-resources.sh',
                     'apple/scripts/run-ios-unit-tests.sh'):
            self.assertEqual(chosen(path) - {'localization'}, {'ios'}, path)
        for path in ('apple/Apps/macOS/MoldSignMacApp.swift', 'apple/Helpers/ReaderWatcher/main.swift',
                     'apple/scripts/test-macos-insertion-window.sh'):
            self.assertEqual(chosen(path) - {'localization'}, {'macos'}, path)
        for path in ('apple/Apps/Shared/Model/AppModel.swift', 'apple/eSemnBun.xcodeproj/project.pbxproj',
                     'apple/Tests/InteractionUITests/DocumentsUITests.swift', 'apple/scripts/run-mock-ui-tests.sh',
                     'apple/NewTarget/File.swift', 'apple/Package.swift',
                     'apple/Tests/MainWindowPolicyTests/MainWindowPresentationPolicyTests.swift',
                     'apple/Apps/macOS/WindowPolicy/MainWindowPresentationPolicy.swift',
                     'apple/Helpers/ReaderWatcher/InsertionPolicy.swift', 'apple/Apps/iOS/SharedDocumentInbox.swift'):
            self.assertEqual(chosen(path), {'macos', 'ios', 'localization'}, path)

    def test_ci_tools_run_only_the_jobs_that_use_them(self):
        for path in ('scripts/ci/test_workflow_contracts.py', 'scripts/ci/select_jobs.py', 'scripts/tests/test_ci_tools.py',
                     'scripts/agents/test_agents.py', 'apple/Tests/Scripts/test_apple_scripts.py',
                     'scripts/ci/sonar-lcov.py', 'scripts/test_play_publish.py', 'scripts/play_publish.py',
                     'scripts/app_store_submit.py', 'scripts/test_app_store_submit.py', '.sonarcloud.properties',
                     '.github/dependabot.yml'):
            self.assertEqual(chosen(path), set(), path)
        self.assertEqual(chosen('scripts/ci/robolectric-cache.sh'), {'android'})
        self.assertEqual(chosen('scripts/ci/apt-install.sh'), {'linux'})
        for path in ('scripts/ci/test-apple-ui.sh', 'scripts/ci/check-xctest-result.py'):
            self.assertEqual(chosen(path), {'macos', 'ios'}, path)

    def test_unknown_and_ci_changes_fail_open(self):
        for path in ['new-build-system.toml', 'scripts/ci/new-tool.py', '.github/workflows/ci.yml']:
            self.assertTrue(all(select([path]).values()), path)

    def test_union(self):
        self.assertEqual(chosen('linux/a.swift', 'windows/b.cs'), {'linux', 'windows', 'localization'})


class ChangedPathTests(unittest.TestCase):
    def test_pr_uses_merge_base_and_null_delimited_paths(self):
        def git(command, **kwargs):
            if command[1] == 'merge-base':
                self.assertEqual(command[2:], ['base', HEAD])
                return OLDER.encode() + b'\n'
            self.assertEqual(command[-1], 'base...' + HEAD)
            return b'android/file name.kt\0docs/a.md\0'
        self.assertEqual(tuple(changed_paths(pull(), git)), (['android/file name.kt', 'docs/a.md'], 'the merge base', OLDER, HEAD))

    def test_pr_push_compares_with_the_last_commit_that_passed(self):
        def git(command, **kwargs):
            self.assertEqual(command[-1], GREEN + '..' + HEAD)
            return b'docs/a.md\0'
        comparison = changed_paths(pull(), git, baseline=lambda event: GREEN)
        self.assertEqual((comparison.paths, comparison.old, comparison.new), (['docs/a.md'], GREEN, HEAD))
        self.assertIn(GREEN[:12], comparison.description)

    def test_unusable_baseline_falls_back_to_the_merge_base(self):
        def git(command, **kwargs):
            if command[-1].startswith(GREEN) or command[1] == 'merge-base':
                raise subprocess.CalledProcessError(128, 'git')
            return b'apple/Apps/iOS/A.swift\0'
        for baseline in (lambda event: GREEN, lambda event: None):
            comparison = changed_paths(pull(), git, baseline=baseline)
            self.assertEqual((comparison.description, comparison.old), ('the merge base', None))

    def test_branch_push_compares_with_the_last_commit_that_passed(self):
        def git(command, **kwargs):
            self.assertEqual(command[-1], GREEN + '..' + HEAD)
            return b'windows/src/A.cs\0'
        comparison = changed_paths({'before': OLDER, 'after': HEAD, 'ref': 'refs/heads/main'}, git, baseline=lambda event: GREEN)
        self.assertEqual((comparison.paths, comparison.old, comparison.new), (['windows/src/A.cs'], GREEN, HEAD))
        unchanged = changed_paths({'before': OLDER, 'after': HEAD}, lambda *a, **k: b'', baseline=lambda event: None)
        self.assertEqual(tuple(unchanged), ([], 'the previous push', OLDER, HEAD))

    def test_push_and_missing_history(self):
        self.assertIsNone(changed_paths({'before': '0000', 'after': 'head'}).paths)
        def missing(*args, **kwargs): raise subprocess.CalledProcessError(1, 'git')
        self.assertIsNone(changed_paths({'before': 'base', 'after': 'head'}, missing).paths)
        self.assertIsNone(changed_paths(pull(), missing).paths)
        self.assertTrue(all(selection(changed_paths(pull(), missing)).values()))
        self.assertEqual(tuple(changed_paths({'before': 'base', 'after': 'head'}, lambda *a, **k: b'')),
                         ([], 'the previous push', 'base', 'head'))


WORKFLOW = """name: CI
on:
  pull_request:
jobs:
  changes:
    runs-on: ubuntu-latest
  apple-apps:
    timeout-minutes: 90
  ios-app:
    timeout-minutes: 65
  android:
    timeout-minutes: 60
"""


class WorkflowChangeTests(unittest.TestCase):
    def shows(self, before, after):
        def git(command, **kwargs):
            self.assertEqual(command[:2], ['git', 'show'])
            revision, path = command[2].split(':', 1)
            self.assertEqual(path, '.github/workflows/ci.yml')
            return (before if revision == 'old' else after).encode()
        return git

    def test_a_job_block_change_runs_only_that_job(self):
        after = WORKFLOW.replace('timeout-minutes: 65', 'timeout-minutes: 70')
        self.assertEqual(workflow_jobs('old', 'new', self.shows(WORKFLOW, after)), {'ios'})
        both = after.replace('timeout-minutes: 90', 'timeout-minutes: 95')
        self.assertEqual(workflow_jobs('old', 'new', self.shows(WORKFLOW, both)), {'ios', 'macos'})
        routing = WORKFLOW.replace('runs-on: ubuntu-latest', 'runs-on: ubuntu-24.04')
        self.assertEqual(workflow_jobs('old', 'new', self.shows(WORKFLOW, routing)), set())

    def test_header_new_or_unknown_jobs_run_everything(self):
        for after in (WORKFLOW.replace('pull_request:', 'pull_request:\n  push:'),
                      WORKFLOW + '  release-check:\n    runs-on: ubuntu-latest\n'):
            self.assertIsNone(workflow_jobs('old', 'new', self.shows(WORKFLOW, after)))
        def missing(*args, **kwargs): raise subprocess.CalledProcessError(128, 'git')
        self.assertIsNone(workflow_jobs('old', 'new', missing))

    def test_selection_combines_the_workflow_jobs_with_other_paths(self):
        after = WORKFLOW.replace('timeout-minutes: 60', 'timeout-minutes: 61')
        def git(command, **kwargs):
            if command[1] == 'show':
                return (WORKFLOW if command[2].startswith('old') else after).encode()
            return b'.github/workflows/ci.yml\0linux/a.swift\0'
        comparison = changed_paths({'before': 'old', 'after': 'new'}, git)
        self.assertEqual({k for k, v in selection(comparison, git).items() if v}, {'android', 'linux', 'localization'})
        self.assertTrue(all(select(['.github/workflows/ci.yml']).values()))


class ValidatedCommitTests(unittest.TestCase):
    def history(self, *shas):
        def git(command, **kwargs):
            self.assertEqual(command[:3], ['git', 'rev-list', '--max-count=5000'])
            self.assertEqual(command[-1], HEAD)
            return '\n'.join(shas).encode()
        return git

    def test_newest_passing_ancestor_from_the_same_repository(self):
        urls = []
        def fetch(url, token):
            urls.append(url)
            self.assertEqual(token, 'token')
            return {'workflow_runs': [run(HEAD), run('d' * 40), run(GREEN, repository='fork/repo'),
                                      run(GREEN, 'failure'), run(OLDER), run(GREEN)]}
        found = last_validated_commit(pull(), self.history(HEAD, GREEN, OLDER), fetch, ENVIRONMENT)
        self.assertEqual(found, OLDER)
        self.assertTrue(urls[0].startswith('https://api.github.com/repos/owner/repo/actions/workflows/ci.yml/runs?'))
        self.assertIn('branch=feature', urls[0])
        self.assertIn('status=success', urls[0])

    def test_branch_pushes_look_up_push_runs_of_their_branch(self):
        urls = []
        def fetch(url, token):
            urls.append(url)
            return {'workflow_runs': [run(GREEN, repository='fork/repo'), run(OLDER, repository='owner/repo')]}
        push = {'before': GREEN, 'after': HEAD, 'ref': 'refs/heads/main'}
        self.assertEqual(last_validated_commit(push, self.history(HEAD, GREEN, OLDER), fetch, ENVIRONMENT), OLDER)
        self.assertIn('event=push', urls[0])
        self.assertIn('branch=main', urls[0])
        for event in ({'before': GREEN, 'after': HEAD, 'ref': 'refs/tags/v1'}, {'before': GREEN, 'after': HEAD}):
            self.assertIsNone(last_validated_commit(event, self.history(HEAD), lambda *a: self.fail('no request'), ENVIRONMENT))

    def test_no_token_repository_or_history_means_no_baseline(self):
        never = lambda *a, **k: self.fail('no request expected')
        for environ in ({}, {'GITHUB_TOKEN': 'token'}, {'GITHUB_TOKEN': 'token', 'GITHUB_REPOSITORY': '../x'}):
            self.assertIsNone(last_validated_commit(pull(), self.history(GREEN), never, environ))
        self.assertIsNone(last_validated_commit(pull(ref=None), self.history(GREEN), never, ENVIRONMENT))
        def unavailable(url, token): raise OSError('offline')
        self.assertIsNone(last_validated_commit(pull(), self.history(GREEN), unavailable, ENVIRONMENT))
        def missing(*a, **k): raise subprocess.CalledProcessError(128, 'git')
        self.assertIsNone(last_validated_commit(pull(), missing, lambda u, t: {'workflow_runs': [run(GREEN)]}, ENVIRONMENT))
        self.assertIsNone(last_validated_commit(pull(), self.history(HEAD), lambda u, t: {'workflow_runs': [run(GREEN)]},
                                                ENVIRONMENT))


if __name__ == '__main__':
    unittest.main()
