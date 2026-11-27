#!/usr/bin/env python3
"""Select native CI from the event diff; unknown or unavailable history fails open to full CI.

A pull request push is compared with the newest earlier commit of the same pull request whose CI run
passed, when that commit is an ancestor of the new head: every platform was validated there, so only
what changed since needs to run again. Without such a run, or when the GitHub API is unavailable,
the whole pull request is compared with its merge base. A ci.yml change runs only the jobs whose
blocks changed, unless its header or another job changed.
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
from typing import NamedTuple, Optional
import urllib.parse
import urllib.request

JOBS = ('localization', 'swift', 'macos', 'ios', 'linux', 'android', 'windows')
APPLE = ('macos', 'ios')

# Checked before the directory rules below; the first matching prefix wins.
EXACT_RULES = (
    # The automation job and the routing checks run these on every event.
    (('scripts/ci/test_', 'scripts/ci/select_jobs.py', 'scripts/tests/', 'scripts/agents/',
      'scripts/test_play_publish.py', 'scripts/test_appgallery.py', 'apple/Tests/Scripts/'), ()),
    # Used only by the Sonar or release workflows, which validate them.
    (('scripts/ci/sonar-', 'scripts/ci/lock-publisher-wheels.py', 'scripts/ci/reserve-android-version.sh',
      '.sonarcloud.properties'), ()),
    (('scripts/ci/android_build_policy.py', 'scripts/ci/check-emulator-resources.py',
      'scripts/ci/prepare-android-ui.py', 'scripts/ci/robolectric-cache.sh'), ('android',)),
    (('scripts/ci/apt-install.sh', 'scripts/ci/check-linux-design-system.py'), ('linux',)),
    (('scripts/ci/prepare-ios-ui-resources.sh', 'scripts/ci/run-ios-ui-devices.py'), ('ios',)),
    (('scripts/ci/check-xctest-result.py', 'scripts/ci/test-apple-ui.sh', 'scripts/ci/select_apple_ui_targets.py'), APPLE),
    # iOS app, its share extension and the scripts only the iOS job runs.
    (('apple/Apps/iOS/', 'apple/ShareExtension/', 'apple/scripts/run-ios-ui-batch.sh', 'apple/scripts/require-ios-sdk.sh',
      'apple/scripts/capture-phone-screenshots.sh', 'apple/scripts/collect-nfc-diagnostics.sh'), ('ios', 'localization')),
    # macOS app, its reader watcher, the package tests the macOS job runs and macOS-only scripts.
    (('apple/Apps/macOS/', 'apple/Helpers/', 'apple/scripts/build-reader-watcher.sh', 'apple/scripts/require-siri-sdk.sh',
      'apple/scripts/test-macos-', 'apple/scripts/test-demo-insertion-helper.py', 'apple/scripts/verify-macos-distribution.sh',
      'apple/scripts/package-app-store.sh', 'apple/Package.swift', 'apple/Package.resolved', 'apple/Tests/AppBatchTests/', 'apple/Tests/DemoModePolicyTests/',
      'apple/Tests/DocumentLibraryTests/', 'apple/Tests/MainWindowPolicyTests/', 'apple/Tests/MobileServicesTests/',
      'apple/Tests/ReaderInsertionPolicyTests/', 'apple/Tests/VerificationPoliciesTests/'), ('macos', 'localization')),
)


WORKFLOW = '.github/workflows/ci.yml'
# CI job keys and what a change to that job alone needs to run. The others always run.
WORKFLOW_JOBS = {'localization': ('localization',), 'swift-macos': ('swift',), 'apple-apps': ('macos',),
                 'ios-app': ('ios',), 'linux': ('linux',), 'android': ('android',), 'windows': ('windows',),
                 'changes': (), 'automation': (), 'result': ()}
JOB_KEY = re.compile(r'  ([A-Za-z0-9_-]+):\s*')


def workflow_sections(text):
    """The workflow's header and each job's block, keyed by job name ('' for the header)."""
    header, separator, jobs = text.partition('\njobs:\n')
    sections, name = {'': header + separator}, ''
    for line in jobs.splitlines(keepends=True):
        match = JOB_KEY.fullmatch(line.rstrip('\n'))
        if match:
            name = match.group(1)
            sections[name] = ''
        sections[name] += line
    return sections


def workflow_jobs(old, new, git=subprocess.check_output):
    """The native jobs a ci.yml change affects, or None when it may affect all of them."""
    try:
        before, after = (workflow_sections(git(['git', 'show', f'{revision}:{WORKFLOW}'], stderr=subprocess.DEVNULL)
                                           .decode('utf-8')) for revision in (old, new))
    except (subprocess.CalledProcessError, OSError, UnicodeDecodeError):
        return None
    changed = {name for name in before.keys() | after.keys() if before.get(name) != after.get(name)}
    if any(name not in WORKFLOW_JOBS for name in changed):
        return None
    return {job for name in changed for job in WORKFLOW_JOBS[name]}


def select(paths, workflow=None):
    """`workflow` lists the jobs a ci.yml change affects; None runs every job for it."""
    jobs = set()
    for path in paths:
        if path == WORKFLOW and workflow is not None:
            jobs.update(workflow)
            continue
        if path.rsplit('/', 1)[-1] in ('README.md', 'AGENTS.md', 'CLAUDE.md', 'SIGNING.md'):
            continue
        rule = next((selected for prefixes, selected in EXACT_RULES if path.startswith(prefixes)), None)
        if rule is not None:
            jobs.update(rule)
        elif path.startswith(('spec/', 'localization/', 'scripts/ci/')) or path in (
                '.github/workflows/ci.yml', 'Gemfile', 'Gemfile.lock'):
            jobs.update(JOBS)
        elif path.startswith('swift/'):
            jobs.update(('swift', 'macos', 'ios', 'linux'))
        elif path.startswith('apple/'):
            # Shared app code, the project, UI tests and their runners.
            jobs.update(('macos', 'ios', 'localization'))
        elif path.startswith('android/'):
            jobs.update(('android', 'localization'))
        elif path.startswith('windows/'):
            jobs.update(('windows', 'localization'))
        elif path.startswith('linux/'):
            jobs.update(('linux', 'localization'))
        elif path.startswith(('scripts/package-', 'scripts/test-portable', 'scripts/test-mcp',
                              'scripts/localize', 'scripts/export-', 'scripts/prepare-',
                              'scripts/check-android', 'scripts/gradle-ci', 'fastlane/')):
            jobs.update(JOBS)
        elif path.startswith(('docs/', 'website/', '.agents/', 'scripts/docs/', 'scripts/documentation/',
                              'scripts/packages/', '.github/workflows/')) or path.endswith('.md') or path in (
                              '.gitignore', '.github/actionlint.yaml') or path.startswith(('scripts/play_publish', 'scripts/test_play_publish')):
            pass  # Automation contract checks still run. Website has its own validation workflow.
        else:
            jobs.update(JOBS)
    return {name: name in jobs for name in JOBS}


API = 'https://api.github.com'
# GitHub owners are letters, digits and hyphens; repository names never consist of dots alone.
REPOSITORY = re.compile(r'[A-Za-z0-9-]+/(?!\.+$)[A-Za-z0-9_.-]+')


def github_json(url, token):
    request = urllib.request.Request(url, headers={'Accept': 'application/vnd.github+json',
                                                   'Authorization': f'Bearer {token}',
                                                   'X-GitHub-Api-Version': '2022-11-28'})
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def last_validated_commit(event, git=subprocess.check_output, fetch=github_json, environ=os.environ):
    """The newest earlier head of this pull request whose CI run passed and that the new head contains."""
    token, repository = environ.get('GITHUB_TOKEN'), environ.get('GITHUB_REPOSITORY', '')
    pull = event['pull_request']
    head, branch = pull['head']['sha'], pull['head'].get('ref')
    head_repository = (pull['head'].get('repo') or {}).get('full_name')
    if not token or not REPOSITORY.fullmatch(repository) or not branch or not head_repository:
        return None
    owner, name = (urllib.parse.quote(part, safe='') for part in repository.split('/'))
    query = urllib.parse.urlencode({'event': 'pull_request', 'status': 'success', 'branch': branch, 'per_page': 50})
    try:
        runs = fetch(f'{API}/repos/{owner}/{name}/actions/workflows/ci.yml/runs?{query}', token).get('workflow_runs', [])
        # Git, not the API response, supplies the commit used in later commands.
        ancestors = {sha: sha for sha in git(['git', 'rev-list', '--max-count=5000', head],
                                             stderr=subprocess.DEVNULL).decode().split()}
    except (OSError, ValueError, subprocess.CalledProcessError):
        return None
    for run in runs:
        validated = ancestors.get(run.get('head_sha'))
        if (validated and validated != head and run.get('conclusion') == 'success'
                and (run.get('head_repository') or {}).get('full_name') == head_repository):
            return validated
    return None


def diff(revision, git):
    try:
        return [p.decode('utf-8', errors='replace') for p in
                git(['git', 'diff', '--name-only', '-z', revision], stderr=subprocess.DEVNULL).split(b'\0') if p]
    except (subprocess.CalledProcessError, OSError):
        return None


class Comparison(NamedTuple):
    paths: Optional[list]
    description: Optional[str] = None
    old: Optional[str] = None
    new: Optional[str] = None


def changed_paths(event, git=subprocess.check_output, baseline=None):
    """What changed and against which commit; `paths` is None when history is unavailable."""
    if 'pull_request' in event:
        head = event['pull_request']['head']['sha']
        validated = baseline(event) if baseline else None
        if validated:
            paths = diff(validated + '..' + head, git)
            if paths is not None:
                return Comparison(paths, f'the last commit that passed CI ({validated[:12]})', validated, head)
        base = event['pull_request']['base']['sha']
        paths = diff(base + '...' + head, git)
        if paths is None:
            return Comparison(None)
        try:
            fork = git(['git', 'merge-base', base, head], stderr=subprocess.DEVNULL).decode().strip() or None
        except (subprocess.CalledProcessError, OSError):
            fork = None
        return Comparison(paths, 'the merge base', fork, head)
    base, head = event.get('before', ''), event.get('after', '')
    if not base or not head or set(base) == {'0'}:
        return Comparison(None)
    paths = diff(base + '..' + head, git)
    return Comparison(paths, 'the previous push', base, head) if paths is not None else Comparison(None)


def selection(comparison, git=subprocess.check_output):
    if comparison.paths is None:
        return {job: True for job in JOBS}
    workflow = None
    if WORKFLOW in comparison.paths and comparison.old and comparison.new:
        workflow = workflow_jobs(comparison.old, comparison.new, git)
    return select(comparison.paths, workflow)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--event', default=os.environ.get('GITHUB_EVENT_PATH'))
    parser.add_argument('--output', default=os.environ.get('GITHUB_OUTPUT'))
    args = parser.parse_args()
    event = json.loads(Path(args.event).read_text())
    comparison = changed_paths(event, baseline=last_validated_commit)
    selected = selection(comparison)
    lines = ''.join(f'{key}={str(value).lower()}\n' for key, value in selected.items())
    if args.output:
        with open(args.output, 'a') as output:
            output.write(lines)
    print(lines, end='')
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a') as output:
            output.write('## Native CI selection\n\n' + ('Full CI: history unavailable.\n' if comparison.paths is None
                                                          else f'{len(comparison.paths)} changed paths since {comparison.description}.\n'))
            output.write('\n' + '\n'.join(f'- {job}: {"run" if enabled else "skip"}' for job, enabled in selected.items()) + '\n')


if __name__ == '__main__':
    main()
