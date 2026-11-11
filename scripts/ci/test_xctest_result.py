import importlib.util
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
