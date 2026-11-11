#!/usr/bin/env python3
"""Reject empty, skipped or incomplete XCTest runs even when xcodebuild exits zero."""
import json
import os
import subprocess
import sys


def require_complete(summary, expected):
    if (summary.get('result') != 'Passed' or summary.get('passedTests') != expected
            or summary.get('totalTestCount') != expected or summary.get('failedTests') != 0
            or summary.get('skippedTests') != 0):
        raise ValueError(f'Expected {expected} passing tests without skips: {summary}')


def report_failures(summary):
    for failure in summary.get('testFailures', []):
        message = f"{failure.get('testIdentifierString', 'XCTest')}: {failure.get('failureText', 'Unknown failure')}"
        if os.environ.get('GITHUB_ACTIONS') == 'true':
            # Keep each assertion inside one workflow command, including multiline AX trees.
            message = message[:5000].replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
            print(f'::error title=Native XCTest failure::{message}')
        else:
            print(message)


if __name__ == '__main__':
    result = subprocess.check_output([
        'xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', sys.argv[1]])
    summary = json.loads(result)
    if sys.argv[2] == '--report-failures':
        report_failures(summary)
    else:
        require_complete(summary, int(sys.argv[2]))
