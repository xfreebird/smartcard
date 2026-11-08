#!/usr/bin/env python3
"""Select native CI from the event diff; unknown or unavailable history fails open to full CI."""
import argparse
import json
import os
from pathlib import Path
import subprocess

JOBS = ('localization', 'swift', 'macos', 'ios', 'linux', 'android', 'windows')


def select(paths):
    jobs = set()
    for path in paths:
        if path.rsplit('/', 1)[-1] in ('README.md', 'AGENTS.md', 'CLAUDE.md', 'SIGNING.md'):
            continue
        if path.startswith(('spec/', 'localization/', 'scripts/ci/')) or path in (
                '.github/workflows/ci.yml', 'Gemfile', 'Gemfile.lock'):
            jobs.update(JOBS)
        elif path.startswith('swift/'):
            jobs.update(('swift', 'macos', 'ios', 'linux'))
        elif path.startswith('apple/'):
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


def changed_paths(event, git=subprocess.check_output):
    if 'pull_request' in event:
        base = event['pull_request']['base']['sha']
        head = event['pull_request']['head']['sha']
        revision = base + '...' + head
    else:
        base, head = event.get('before', ''), event.get('after', '')
        if not base or not head or set(base) == {'0'}:
            return None
        revision = base + '..' + head
    try:
        return [p.decode('utf-8', errors='replace') for p in
                git(['git', 'diff', '--name-only', '-z', revision], stderr=subprocess.DEVNULL).split(b'\0') if p]
    except (subprocess.CalledProcessError, OSError):
        return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--event', default=os.environ.get('GITHUB_EVENT_PATH'))
    parser.add_argument('--output', default=os.environ.get('GITHUB_OUTPUT'))
    args = parser.parse_args()
    event = json.loads(Path(args.event).read_text())
    paths = changed_paths(event)
    selected = {job: True for job in JOBS} if paths is None else select(paths)
    lines = ''.join(f'{key}={str(value).lower()}\n' for key, value in selected.items())
    if args.output:
        with open(args.output, 'a') as output:
            output.write(lines)
    print(lines, end='')
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a') as output:
            output.write('## Native CI selection\n\n' + ('Full CI: history unavailable.\n' if paths is None else f'{len(paths)} changed paths.\n'))
            output.write('\n' + '\n'.join(f'- {job}: {"run" if enabled else "skip"}' for job, enabled in selected.items()) + '\n')


if __name__ == '__main__':
    main()
