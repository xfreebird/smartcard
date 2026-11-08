import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT=Path(__file__).with_name('reserve-android-version.sh')


class VersionReservationTests(unittest.TestCase):
    def probe(self, number='', same=True, api_fails=False):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);tools=root/'bin';tools.mkdir()
            git=tools/'git';git.write_text('''#!/bin/bash
case "$1" in
fetch) exit 0;;
tag) printf '%s\\n' android-play-vc-1793624681 android-play-vc-1793624684;;
rev-parse) printf '%s\\n' "$TEST_SOURCE";;
*) exit 1;;
esac
''');git.chmod(0o755)
            gh=tools/'gh';gh.write_text('''#!/bin/bash
printf '%s\\n' "$*" >> "$TEST_CALLS"
exit "$TEST_EXIT"
''');gh.chmod(0o755)
            env=dict(os.environ,PATH=str(tools)+os.pathsep+os.environ['PATH'],BUILD_NUMBER_INPUT=number,
                     GITHUB_SHA='source',GITHUB_REPOSITORY='owner/repo',GITHUB_ENV=str(root/'env'),
                     TEST_SOURCE='source' if same else 'other',TEST_CALLS=str(root/'calls'),TEST_EXIT='1' if api_fails else '0')
            result=subprocess.run(['bash',str(SCRIPT)],env=env,capture_output=True,text=True)
            return result.returncode,(root/'env').read_text() if (root/'env').exists() else '',(root/'calls').read_text() if (root/'calls').exists() else ''
    def test_next_code_is_reserved_before_export(self):
        code,env,calls=self.probe();self.assertEqual(code,0);self.assertIn('BUILD_NUMBER=1793624685',env);self.assertIn('ref=refs/tags/android-play-vc-1793624685',calls)
    def test_same_source_reuses_explicit_reserved_code(self):
        code,env,calls=self.probe('1793624684');self.assertEqual(code,0);self.assertIn('1793624684',env);self.assertEqual(calls,'')
    def test_other_source_cannot_reuse_code(self):
        code,env,calls=self.probe('1793624684',same=False);self.assertNotEqual(code,0);self.assertEqual(env,'');self.assertEqual(calls,'')
    def test_invalid_and_oversized_codes_never_reserve(self):
        for value in ['0','-1','01','abc','2100000001','9'*100]:
            code,env,calls=self.probe(value);self.assertNotEqual(code,0);self.assertEqual(env,'');self.assertEqual(calls,'')
    def test_failed_reservation_never_exports_build_number(self):
        code,env,calls=self.probe(api_fails=True);self.assertNotEqual(code,0);self.assertEqual(env,'');self.assertTrue(calls)
