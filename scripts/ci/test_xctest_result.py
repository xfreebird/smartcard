import contextlib
import importlib.util
import io
import json
import os
from unittest.mock import patch
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('xctest', Path(__file__).with_name('check-xctest-result.py'))
xctest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(xctest)


def tree(**cases):
    """An xcresulttool `tests` tree with one suite per case name `Suite_test`."""
    return {'testNodes': [{'nodeType': 'Test Plan', 'children': [{'nodeType': 'UI test bundle', 'children': [
        {'nodeType': 'Test Suite', 'children': [
            {'nodeType': 'Test Case', 'nodeIdentifier': name.replace('_', '/') + '()', 'result': result}]}
        for name, result in cases.items()]}]}]}


def failures(*pairs):
    return {'testFailures': [{'testIdentifierString': test, 'failureText': text} for test, text in pairs]}


def complete(count):
    return dict(result='Passed', passedTests=count, totalTestCount=count, failedTests=0, skippedTests=0)


def check(*argv, reports=(), github=False):
    """Run the checker as the runners do: xcresulttool's JSON reports piped in, one after another."""
    output = io.StringIO()
    stdin = io.StringIO('\n'.join(json.dumps(report, indent=2) for report in reports))
    with patch.dict(os.environ, GITHUB_ACTIONS=str(github).lower()), contextlib.redirect_stdout(output):
        code = xctest.main(list(argv), stdin)
    return code, output.getvalue()


LOST = "Application 'md.esemnbun.ios' does not have a process ID"


class XCTestCompletionTests(unittest.TestCase):
    def test_complete_run_passes(self):
        xctest.require_complete(complete(6), 6)
        self.assertEqual(check('6', reports=[complete(6)]), (0, ''))

    def test_empty_partial_skipped_and_failed_runs_fail(self):
        for result in ({}, complete(0), complete(6) | {'passedTests': 5}, complete(6) | {'skippedTests': 1},
                       complete(6) | {'failedTests': 1}, complete(6) | {'result': 'Failed'},
                       complete(6) | {'totalTestCount': 7}):
            with self.subTest(result=result), self.assertRaises(ValueError):
                check('6', reports=[result])

    def test_missing_or_extra_reports_are_rejected(self):
        for reports in ((), (complete(1), complete(1))):
            with self.subTest(count=len(reports)), self.assertRaisesRegex(ValueError, 'xcresulttool reports'):
                check('1', reports=reports)


class XCTestFailureReportingTests(unittest.TestCase):
    def test_multiline_assertion_cannot_inject_another_workflow_command(self):
        summary = failures(('Documents/testPicker()', '50% loaded\r\n::warning::injected'))
        self.assertEqual(check('--report-failures', reports=[summary], github=True), (0,
            '::error title=Native XCTest failure::Documents/testPicker(): 50%25 loaded%0D%0A::warning::injected\n'))

    def test_no_assertion_failures_emits_no_false_annotation(self):
        self.assertEqual(check('--report-failures', reports=[failures()], github=True), (0, ''))

    def test_local_reports_are_plain_text(self):
        self.assertEqual(check('--report-failures', reports=[failures(('Mock/testB()', LOST))]),
                         (0, f'Mock/testB(): {LOST}\n'))


class XCTestRetryPlanTests(unittest.TestCase):
    results = tree(Verification_testA='Passed', DocumentsUITests_testSaved='Passed', Mock_testB='Failed',
                   NFC_testC='Failed')

    def test_lost_app_process_reruns_everything_that_did_not_pass(self):
        for text in (LOST, 'Failed to terminate md.esemnbun.ios:26246: Failed to terminate md.esemnbun.ios:0',
                     'Failed to get matching snapshots: Lost connection to the application (pid 36163).',
                     'Couldn’t communicate with a helper application.',
                     'Failed to launch md.esemnbun.ios: Timed out attempting to launch app.'):
            with self.subTest(text=text):
                plan = xctest.retry_plan(failures(('Mock/testB()', text), ('NFC/testC()', 'Testing was canceled')),
                                         self.results)
                self.assertEqual(plan, ['Verification/testA()'])

    def test_fixture_suites_rerun_in_full_on_the_erased_simulator(self):
        # Their passed cases are not skipped: the rerun seeds and verifies new fixture files.
        for summary in (failures(('DocumentsUITests/testDetachedOriginalPicker()', LOST)),
                        failures(('Mock/testB()', LOST), ('ProtectionFlowUITests/testProtect()', 'Testing was canceled'))):
            with self.subTest(summary=summary):
                self.assertEqual(xctest.retry_plan(summary, self.results), ['Verification/testA()'])

    def test_assertions_and_cancellation_alone_are_not_rerun(self):
        for summary in (failures(('Mock/testB()', 'XCTAssertTrue failed - Clear results must stay')),
                        failures(('Mock/testB()', LOST), ('NFC/testC()', 'XCTAssertEqual failed')),
                        failures(('DocumentsUITests/testDuoDocumentModal()', 'XCTAssertTrue failed'), ('Mock/testB()', LOST)),
                        failures(('NFC/testC()', 'Testing was canceled')),
                        failures()):
            with self.subTest(summary=summary):
                self.assertIsNone(xctest.retry_plan(summary, self.results))

    def test_rerun_must_pass_exactly_the_remaining_cases(self):
        first = {'A/a()', 'B/b()'}
        xctest.require_combined(first, complete(2), {'C/c()', 'D/d()'}, 4)
        for summary, rerun in ((complete(2), {'A/a()', 'D/d()'}),
                               (complete(2) | {'passedTests': 1, 'failedTests': 1}, {'C/c()'}),
                               (complete(4), {'A/a()', 'B/b()', 'C/c()', 'D/d()'})):
            with self.subTest(rerun=rerun), self.assertRaises(ValueError):
                xctest.require_combined(first, summary, rerun, 4)

    def test_retry_plan_warns_instead_of_failing_and_skip_list_names_the_kept_cases(self):
        summary = failures(('Mock/testB()', LOST), ('NFC/testC()', 'Testing was canceled'))
        code, output = check('--retry-plan', reports=[summary, self.results], github=True)
        self.assertEqual(code, 0)
        self.assertNotIn('::error', output)
        self.assertIn('::warning title=XCTest lost the app', output)
        self.assertEqual(check('--skip-list', reports=[self.results]), (0, 'Verification/testA\n'))

    def test_refused_retry_plan_reports_errors(self):
        code, output = check('--retry-plan', reports=[failures(('Mock/testB()', 'XCTAssertTrue failed')), self.results],
                             github=True)
        self.assertEqual(code, 1)
        self.assertIn('::error title=Native XCTest failure::Mock/testB(): XCTAssertTrue failed', output)

    def test_combined_mode_counts_the_kept_cases_and_the_rerun(self):
        first = tree(Verification_testA='Passed', DocumentsUITests_testSaved='Passed', Mock_testB='Failed')
        rerun = tree(DocumentsUITests_testSaved='Passed', Mock_testB='Passed')
        self.assertEqual(check('--combined', '3', reports=[first, complete(2), rerun]), (0, ''))
        with self.assertRaises(ValueError):
            check('--combined', '4', reports=[first, complete(2), rerun])


if __name__ == '__main__':
    unittest.main()
