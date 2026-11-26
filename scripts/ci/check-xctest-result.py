#!/usr/bin/env python3
"""Reject empty, skipped or incomplete XCTest runs even when xcodebuild exits zero.

The callers run `xcrun xcresulttool get test-results <report> --path <bundle>` and pipe the JSON reports here, in
the order each mode lists; this script only reads standard input.

  check-xctest-result.py COUNT              summary                   require COUNT passing tests
  check-xctest-result.py --report-failures  summary                   annotate each failure
  check-xctest-result.py --retry-plan       summary, tests            allow one rerun, or report the failures
  check-xctest-result.py --skip-list        tests                     print the passed cases a rerun may skip
  check-xctest-result.py --combined COUNT   tests, rerun summary,     require the run and its rerun to pass
                                            rerun tests               COUNT tests together
"""
import json
import os
import re
import sys

# XCTest reports these when it loses the app process on a loaded CI simulator; no assertion reads like them.
INFRASTRUCTURE = re.compile(r"does not have a process ID|Failed to (?:launch|terminate) md\.esemnbun\.ios"
                            r"|lost connection to the application|Couldn.t communicate with a helper application",
                            re.IGNORECASE)
# Stopping on the first failure cancels the case that had just started.
CANCELLED = 'Testing was canceled'
# These suites change seeded files that a later phase verifies. A rerun starts from an erased simulator with
# freshly seeded files, so it runs them again in full.
FIXTURE_SUITES = ('DocumentsUITests/', 'ProtectionFlowUITests/')
MODES = {'--report-failures': 1, '--retry-plan': 2, '--skip-list': 1, '--combined': 3}


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


def kept_cases(tree):
    """Passed cases a rerun on an erased simulator need not repeat: all but the fixture suites."""
    return {case for case in passed_cases(tree) if not case.startswith(FIXTURE_SUITES)}


def retry_plan(summary, tree):
    """The passed cases a rerun may skip when every failure is the app process being lost, otherwise None."""
    failures = summary.get('testFailures', [])
    if not any(INFRASTRUCTURE.search(f.get('failureText', '')) for f in failures):
        return None
    if not all(INFRASTRUCTURE.search(f.get('failureText', '')) or f.get('failureText', '').startswith(CANCELLED)
               for f in failures):
        return None
    return sorted(kept_cases(tree))


def require_combined(first, rerun_summary, rerun, expected):
    """The rerun ran exactly the cases the first run did not keep, and all of them passed."""
    require_complete(rerun_summary, expected - len(first))
    if first & rerun or len(first | rerun) != expected:
        raise ValueError(f'The rerun must pass exactly the {expected - len(first)} cases the first run did not')


def reports(text, count):
    """The `count` JSON documents xcresulttool wrote one after another."""
    decoder, documents, position = json.JSONDecoder(), [], 0
    while len(documents) < count:
        while position < len(text) and text[position].isspace():
            position += 1
        if position == len(text):
            raise ValueError(f'Expected {count} xcresulttool reports on standard input, got {len(documents)}')
        document, position = decoder.raw_decode(text, position)
        documents.append(document)
    if text[position:].strip():
        raise ValueError(f'Expected {count} xcresulttool reports on standard input, got more')
    return documents


def main(argv, stdin):
    mode, *rest = argv
    documents = reports(stdin.read(), MODES.get(mode, 1))
    if mode == '--report-failures':
        report_failures(documents[0])
    elif mode == '--retry-plan':
        if retry_plan(*documents) is None:
            report_failures(documents[0])
            return 1
        annotate(documents[0], 'warning', 'XCTest lost the app; rerunning the cases that did not pass')
    elif mode == '--skip-list':
        for case in sorted(kept_cases(documents[0])):
            print(case.removesuffix('()'))
    elif mode == '--combined':
        first, rerun_summary, rerun = documents
        require_combined(kept_cases(first), rerun_summary, passed_cases(rerun), int(rest[0]))
    else:
        require_complete(documents[0], int(mode))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:], sys.stdin))
