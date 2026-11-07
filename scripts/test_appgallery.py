"""Exercise publishing boundaries without contacting Huawei."""
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

import appgallery


class PublishingTests(unittest.TestCase):
    def run_publish(self, api, draft=False, defer=False):
        with tempfile.TemporaryDirectory() as folder:
            apk = Path(folder) / 'app.apk'
            apk.write_bytes(b'fixture')
            with patch.dict(os.environ, {'HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON': '{}'}), \
                 patch('sys.argv', ['appgallery.py', '--apk', str(apk), '--version-code', '112'] + (['--draft'] if draft else []) + (['--defer-if-reviewing'] if defer else [])), \
                 patch.object(appgallery, 'Gallery', return_value=api):
                appgallery.main()

    def test_draft_upload_never_submits(self):
        api = Mock()
        api.call.side_effect = [
            {'appInfo': {'versionCode': 111, 'releaseState': 1}},
            {'uploadUrl': 'https://example.invalid/upload', 'authCode': 'fixture'},
            {'ret': {'code': 0}},
            {'appInfo': {'versionCode': 112}},
        ]
        response = Mock()
        response.json.return_value = {'result': {'UploadFileRsp': {'fileInfoList': [
            {'fileDestUlr': 'fixture'}], 'ifSuccess': 1}}}
        with patch.object(appgallery.requests, 'post', return_value=response), patch.object(appgallery.time, 'sleep'):
            self.run_publish(api, draft=True)
        self.assertFalse(any(call.args[1] == 'app-submit' for call in api.call.call_args_list))
        attached = [call.kwargs['body'] for call in api.call.call_args_list if call.args[1] == 'app-file-info']
        self.assertEqual(attached[0]['files'][0]['fileName'], 'app.apk')

    def test_existing_draft_is_not_submitted(self):
        api = Mock()
        api.call.return_value = {'appInfo': {'versionCode': 112, 'releaseState': 1}}
        self.run_publish(api, draft=True)
        self.assertEqual(api.call.call_count, 1)

    def test_already_submitted_version_does_not_upload(self):
        api = Mock()
        api.call.return_value = {'appInfo': {'versionCode': 112, 'releaseState': 4}}
        self.run_publish(api)
        self.assertEqual(api.call.call_count, 1)

    def test_active_review_is_never_cancelled(self):
        api = Mock()
        api.call.return_value = {'appInfo': {'versionCode': 111, 'releaseState': 4}}
        with self.assertRaisesRegex(RuntimeError, 'active review'):
            self.run_publish(api)
        self.assertEqual(api.call.call_count, 1)

    def test_draft_automation_defers_during_active_review(self):
        api = Mock()
        api.call.return_value = {'appInfo': {'versionCode': 111, 'releaseState': 4}}
        self.run_publish(api, draft=True, defer=True)
        self.assertEqual(api.call.call_count, 1)

    def test_parsed_binary_must_match_before_submit(self):
        api = Mock()
        api.call.side_effect = [
            {'appInfo': {'versionCode': 111, 'releaseState': 1}},
            {'uploadUrl': 'https://example.invalid/upload', 'authCode': 'fixture'},
            {'ret': {'code': 0}},
            {'appInfo': {'versionCode': 111}},
        ]
        response = Mock()
        response.json.return_value = {'result': {'UploadFileRsp': {'fileInfoList': [
            {'fileDestUlr': 'fixture'}], 'ifSuccess': 1}}}
        with patch.object(appgallery.requests, 'post', return_value=response), \
             patch.object(appgallery.time, 'sleep'), \
             self.assertRaisesRegex(RuntimeError, 'expected version code'):
            self.run_publish(api)
        self.assertFalse(any(call.args[1] == 'app-submit' for call in api.call.call_args_list))


if __name__ == '__main__':
    unittest.main()
