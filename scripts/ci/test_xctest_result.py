import contextlib
import importlib.util
import io
import os
import tempfile
from unittest.mock import patch
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('xctest', Path(__file__).with_name('check-xctest-result.py'))
xctest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(xctest)


class XCTestCompletionTests(unittest.TestCase):
    def result(self, **changes):
        return dict(result='Passed', passedTests=6, totalTestCount=6,
                    failedTests=0, skippedTests=0) | changes

    def test_complete_run_passes(self):
        xctest.require_complete(self.result(), 6)

    def test_empty_partial_skipped_and_failed_runs_fail(self):
        for result in ({}, self.result(passedTests=0, totalTestCount=0),
                       self.result(passedTests=5), self.result(skippedTests=1),
                       self.result(failedTests=1), self.result(result='Failed'),
                       self.result(totalTestCount=7)):
            with self.subTest(result=result), self.assertRaises(ValueError):
                xctest.require_complete(result, 6)


class XCTestFailureReportingTests(unittest.TestCase):
    def test_multiline_assertion_cannot_inject_another_workflow_command(self):
        output = io.StringIO()
        failure = {'testIdentifierString': 'Documents/testPicker()',
                   'failureText': '50% loaded\r\n::warning::injected'}
        with patch.dict(os.environ, GITHUB_ACTIONS='true'), contextlib.redirect_stdout(output):
            xctest.report_failures({'testFailures': [failure]})
        self.assertEqual(output.getvalue().splitlines(), [
            '::error title=Native XCTest failure::Documents/testPicker(): 50%25 loaded%0D%0A::warning::injected'])

    def test_no_assertion_failures_emits_no_false_annotation(self):
        output = io.StringIO()
        with patch.dict(os.environ, GITHUB_ACTIONS='true'), contextlib.redirect_stdout(output):
            xctest.report_failures({'testFailures': []})
        self.assertEqual(output.getvalue(), '')


def tree(**cases):
    """An xcresulttool `tests` tree with one suite per case name `Suite_test`."""
    return {'testNodes': [{'nodeType': 'Test Plan', 'children': [{'nodeType': 'UI test bundle', 'children': [
        {'nodeType': 'Test Suite', 'children': [
            {'nodeType': 'Test Case', 'nodeIdentifier': name.replace('_', '/') + '()', 'result': result}]}
        for name, result in cases.items()]}]}]}


def failures(*pairs):
    return {'testFailures': [{'testIdentifierString': test, 'failureText': text} for test, text in pairs]}


LOST = "Application 'md.esemnbun.ios' does not have a process ID"


class XCTestRetryPlanTests(unittest.TestCase):
    results = tree(Verification_testA='Passed', Mock_testB='Failed', NFC_testC='Failed')

    def test_lost_app_process_reruns_everything_that_did_not_pass(self):
        for text in (LOST, 'Failed to terminate md.esemnbun.ios:26246: Failed to terminate md.esemnbun.ios:0',
                     'Failed to get matching snapshots: Lost connection to the application (pid 36163).',
                     'Couldn’t communicate with a helper application.'):
            with self.subTest(text=text):
                plan = xctest.retry_plan(failures(('Mock/testB()', text), ('NFC/testC()', 'Testing was canceled')),
                                         self.results)
                self.assertEqual(plan, ['Verification/testA()'])

    def test_assertions_cancellation_alone_and_fixture_suites_are_not_rerun(self):
        for summary in (failures(('Mock/testB()', 'XCTAssertTrue failed - Clear results must stay')),
                        failures(('Mock/testB()', LOST), ('NFC/testC()', 'XCTAssertEqual failed')),
                        failures(('NFC/testC()', 'Testing was canceled')),
                        failures(('DocumentsUITests/testDetachedOriginalPicker()', LOST)),
                        failures(('Mock/testB()', LOST), ('ProtectionFlowUITests/testProtect()', 'Testing was canceled')),
                        failures()):
            with self.subTest(summary=summary):
                self.assertIsNone(xctest.retry_plan(summary, self.results))

    def test_rerun_must_pass_exactly_the_remaining_cases(self):
        first = {'A/a()', 'B/b()'}
        complete = dict(result='Passed', passedTests=2, totalTestCount=2, failedTests=0, skippedTests=0)
        xctest.require_combined(first, complete, {'C/c()', 'D/d()'}, 4)
        for summary, rerun in ((complete, {'A/a()', 'D/d()'}),
                               (complete | {'passedTests': 1, 'failedTests': 1}, {'C/c()'}),
                               (complete | {'passedTests': 4, 'totalTestCount': 4}, {'A/a()', 'B/b()', 'C/c()', 'D/d()'})):
            with self.subTest(rerun=rerun), self.assertRaises(ValueError):
                xctest.require_combined(first, summary, rerun, 4)

    def test_retry_plan_writes_skip_filters_and_warns_instead_of_failing(self):
        summary = failures(('Mock/testB()', LOST), ('NFC/testC()', 'Testing was canceled'))
        loaded = {'summary': summary, 'tests': self.results}
        with tempfile.TemporaryDirectory() as folder:
            skip = Path(folder) / 'passed'
            output = io.StringIO()
            with patch.object(xctest, 'load', lambda kind, path: loaded[kind]), \
                    patch.dict(os.environ, GITHUB_ACTIONS='true'), contextlib.redirect_stdout(output):
                self.assertEqual(xctest.main(['First.xcresult', '--retry-plan', str(skip)]), 0)
            self.assertEqual(skip.read_text(), 'Verification/testA\n')
            self.assertNotIn('::error', output.getvalue())
            self.assertIn('::warning title=XCTest lost the app', output.getvalue())

    def test_refused_retry_plan_reports_errors_and_writes_nothing(self):
        summary = failures(('Mock/testB()', 'XCTAssertTrue failed'))
        loaded = {'summary': summary, 'tests': self.results}
        with tempfile.TemporaryDirectory() as folder:
            skip = Path(folder) / 'passed'
            output = io.StringIO()
            with patch.object(xctest, 'load', lambda kind, path: loaded[kind]), \
                    patch.dict(os.environ, GITHUB_ACTIONS='true'), contextlib.redirect_stdout(output):
                self.assertEqual(xctest.main(['First.xcresult', '--retry-plan', str(skip)]), 1)
            self.assertFalse(skip.exists())
            self.assertIn('::error title=Native XCTest failure::Mock/testB(): XCTAssertTrue failed', output.getvalue())

    def test_count_and_combined_modes_read_the_result_bundles(self):
        complete = dict(result='Passed', passedTests=1, totalTestCount=1, failedTests=0, skippedTests=0)
        bundles = {('summary', 'Rerun.xcresult'): complete, ('summary', 'First.xcresult'): complete,
                   ('tests', 'First.xcresult'): tree(Verification_testA='Passed', Mock_testB='Failed'),
                   ('tests', 'Rerun.xcresult'): tree(Mock_testB='Passed')}
        with patch.object(xctest, 'load', lambda kind, path: bundles[kind, path]):
            self.assertEqual(xctest.main(['First.xcresult', '--combined', 'Rerun.xcresult', '2']), 0)
            self.assertEqual(xctest.main(['First.xcresult', '1']), 0)
            with self.assertRaises(ValueError):
                xctest.main(['First.xcresult', '--combined', 'Rerun.xcresult', '3'])

    def test_report_mode_annotates_every_failure(self):
        output = io.StringIO()
        with patch.object(xctest, 'load', lambda kind, path: failures(('Mock/testB()', LOST))), \
                patch.dict(os.environ, GITHUB_ACTIONS='false'), contextlib.redirect_stdout(output):
            self.assertEqual(xctest.main(['First.xcresult', '--report-failures']), 0)
        self.assertEqual(output.getvalue(), f'Mock/testB(): {LOST}\n')
