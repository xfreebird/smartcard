#!/usr/bin/env python3
"""Reject empty, skipped or incomplete XCTest runs even when xcodebuild exits zero.

  check-xctest-result.py RESULT COUNT                    require COUNT passing tests
  check-xctest-result.py RESULT --report-failures        annotate each failure
  check-xctest-result.py RESULT --retry-plan SKIP_FILE   write the passed tests to skip on one rerun, or fail
  check-xctest-result.py RESULT --combined RERUN COUNT   require the run and its rerun to pass COUNT tests together
"""
import json
import os
import re
import subprocess
import sys

# XCTest reports these when it loses the app process on a loaded CI simulator; no assertion reads like them.
INFRASTRUCTURE = re.compile(r"does not have a process ID|Failed to terminate md\.esemnbun\.ios"
                            r"|lost connection to the application|Couldn.t communicate with a helper application",
                            re.IGNORECASE)
# Stopping on the first failure cancels the case that had just started.
CANCELLED = 'Testing was canceled'
# These suites change seeded files that a later phase verifies, so an interrupted case cannot run again.
FIXTURE_SUITES = ('DocumentsUITests/', 'ProtectionFlowUITests/')


def require_complete(summary, expected):
    if (summary.get('result') != 'Passed' or summary.get('passedTests') != expected
            or summary.get('totalTestCount') != expected or summary.get('failedTests') != 0
            or summary.get('skippedTests') != 0):
        raise ValueError(f'Expected {expected} passing tests without skips: {summary}')


def annotate(summary, level, title):
    for failure in summary.get('testFailures', []):
        message = f"{failure.get('testIdentifierString', 'XCTest')}: {failure.get('failureText', 'Unknown failure')}"
        if os.environ.get('GITHUB_ACTIONS') == 'true':
            # Keep each assertion inside one workflow command, including multiline AX trees.
            message = message[:5000].replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
            print(f'::{level} title={title}::{message}')
        else:
            print(message)


def report_failures(summary):
    annotate(summary, 'error', 'Native XCTest failure')


def passed_cases(tree):
    """Identifiers of the passed test cases, as `Suite/testName()`."""
    passed = set()
    nodes = list(tree.get('testNodes', []))
    while nodes:
        node = nodes.pop()
        if node.get('nodeType') == 'Test Case' and node.get('result') == 'Passed':
            passed.add(node['nodeIdentifier'])
        nodes.extend(node.get('children', []))
    return passed


def retry_plan(summary, tree):
    """The passed cases to skip when every failure is the app process being lost, otherwise None."""
    failures = summary.get('testFailures', [])
    if not any(INFRASTRUCTURE.search(f.get('failureText', '')) for f in failures):
        return None
    for failure in failures:
        text = failure.get('failureText', '')
        if not (INFRASTRUCTURE.search(text) or text.startswith(CANCELLED)):
            return None
        if failure.get('testIdentifierString', '').startswith(FIXTURE_SUITES):
            return None
    return sorted(passed_cases(tree))


def require_combined(first, rerun_summary, rerun, expected):
    """The rerun ran exactly the cases the first run did not pass, and all of them passed."""
    require_complete(rerun_summary, expected - len(first))
    if first & rerun or len(first | rerun) != expected:
        raise ValueError(f'The rerun must pass exactly the {expected - len(first)} cases the first run did not')


def load(kind, path):
    return json.loads(subprocess.check_output(['xcrun', 'xcresulttool', 'get', 'test-results', kind, '--path', path]))


def main(argv):
    path, mode, *rest = argv
    if mode == '--report-failures':
        report_failures(load('summary', path))
    elif mode == '--retry-plan':
        summary = load('summary', path)
        skip = retry_plan(summary, load('tests', path))
        if skip is None:
            report_failures(summary)
            return 1
        annotate(summary, 'warning', 'XCTest lost the app; rerunning the cases that did not pass')
        with open(rest[0], 'w') as output:
            output.writelines(identifier.removesuffix('()') + '\n' for identifier in skip)
    elif mode == '--combined':
        rerun, expected = rest
        require_combined(passed_cases(load('tests', path)), load('summary', rerun),
                         passed_cases(load('tests', rerun)), int(expected))
    else:
        require_complete(load('summary', path), int(mode))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
