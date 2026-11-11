#!/usr/bin/env python3
"""Reject empty, skipped or incomplete XCTest runs even when xcodebuild exits zero."""
import json
import subprocess
import sys


def require_complete(summary, expected):
    if (summary.get('result') != 'Passed' or summary.get('passedTests') != expected
            or summary.get('totalTestCount') != expected or summary.get('failedTests') != 0
            or summary.get('skippedTests') != 0):
        raise ValueError(f'Expected {expected} passing tests without skips: {summary}')


if __name__ == '__main__':
    result = subprocess.check_output([
        'xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', sys.argv[1]])
    require_complete(json.loads(result), int(sys.argv[2]))
