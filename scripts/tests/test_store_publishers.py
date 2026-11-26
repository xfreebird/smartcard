"""Store publishing clients with simulated Google Play, AppGallery and Microsoft Store services."""
import base64
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import urllib.error
from urllib.parse import urlsplit
import zipfile

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
import requests

from support import REPO, TempCase, load, png, run

KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
PEM = KEY.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                        serialization.NoEncryption()).decode()


def b64decode(segment):
    return base64.urlsafe_b64decode(segment + '=' * (-len(segment) % 4))


class Reply:
    def __init__(self, status=200, payload=None, content=None):
        self.status_code = status
        self.ok = status < 400
        self.payload = payload
        self.content = content if content is not None else (b'{}' if payload is not None else b'')

    def json(self):
        if isinstance(self.payload, Exception):
            raise self.payload
        return self.payload

    def raise_for_status(self):
        if not self.ok:
            raise requests.HTTPError(str(self.status_code))


class PlayClientTests(TempCase):
    def setUp(self):
        super().setUp()
        self.play = load('scripts/play_publish.py')

    def api(self, *replies):
        session = Mock()
        session.headers = {}
        session.post.return_value = Reply(payload={'access_token': 'token-1'})
        session.request.side_effect = list(replies)
        fake_requests = SimpleNamespace(Session=Mock(return_value=session))
        fake_jwt = SimpleNamespace(encode=Mock(return_value='assertion'))
        with patch.dict(sys.modules, {'requests': fake_requests, 'jwt': fake_jwt}):
            api = self.play.PlayAPI({'client_email': 'ci@example.invalid', 'private_key': 'key'})
        claims = fake_jwt.encode.call_args.args[0]
        self.assertEqual(claims['scope'], 'https://www.googleapis.com/auth/androidpublisher')
        self.assertEqual(claims['exp'] - claims['iat'], 3600)
        self.assertEqual(session.headers['Authorization'], 'Bearer token-1')
        return api, session

    def test_call_routes_json_and_uploads(self):
        bundle = self.tmp / 'app.aab'
        bundle.write_bytes(b'aab')
        api, session = self.api(Reply(payload={'id': '7'}), Reply(payload={'versionCode': 3}), Reply(payload=None))
        self.assertEqual(api.call('POST', 'edits', {}), {'id': '7'})
        self.assertEqual(api.call('POST', 'edits/7/bundles?uploadType=media', upload=bundle), {'versionCode': 3})
        self.assertEqual(api.call('DELETE', 'edits/7'), {})
        first, upload, _ = session.request.call_args_list
        self.assertEqual(first.args[1], 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/md.esemnbun.app/edits')
        self.assertTrue(upload.args[1].startswith('https://androidpublisher.googleapis.com/upload/androidpublisher/'))
        self.assertEqual(upload.kwargs['headers'], {'Content-Type': 'application/octet-stream'})

    def test_errors_map_to_stable_reasons_without_provider_text(self):
        cases = [
            ({'error': {'details': [{}, {'reason': 'quotaExceeded'}]}}, 'quotaExceeded'),
            ({'error': {'message': 'changesNotSentForReview must not be set'}}, 'REVIEW_PARAMETER_NOT_ALLOWED'),
            ({'error': {'message': 'Changes in review cannot be sent'}}, 'CHANGES_ALREADY_IN_REVIEW'),
            ({'error': {'message': 'HALTED release must have fraction'}}, 'EXISTING_TRACK_STATE_REQUIRES_CONSOLE'),
            ({'error': {'message': 'other'}}, 'REQUEST_REJECTED'),
            ({}, 'REQUEST_REJECTED'),
            (ValueError('not json'), 'REQUEST_REJECTED'),
        ]
        api, _ = self.api(*[Reply(403, payload) for payload, _ in cases])
        for payload, reason in cases:
            with self.subTest(reason=reason), self.assertRaises(self.play.PlayError) as raised:
                api.call('GET', 'edits/1/tracks')
            self.assertEqual((raised.exception.status, raised.exception.reason), (403, reason))
            self.assertEqual(str(raised.exception), f'Play API 403: {reason}')

    def test_publish_rejects_unsupported_operations_and_notes_before_api(self):
        api = Mock()
        aab = self.tmp / 'app.aab'
        aab.write_bytes(b'x')
        for args, message in [
            (('promote', None, None), 'Unsupported'),
            (('closed_testing', 'alpha', [{'text': 'n' * 501}]), 'maximum 500'),
            (('closed_testing', 'beta', None), 'release notes'),
        ]:
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                self.play.publish(api, aab, 2, '1.0', *args)
        with self.assertRaisesRegex(ValueError, 'artifact identity'):
            self.play.publish(api, self.tmp / 'missing.aab', 2, '1.0', 'artifact_only')
        api.call.assert_not_called()

    def test_existing_bundle_with_other_version_and_missing_track_stop(self):
        aab = self.tmp / 'app.aab'
        aab.write_bytes(b'signed')
        digest = hashlib.sha256(b'signed').hexdigest()

        def responses(bundles, tracks):
            api = Mock()
            api.call.side_effect = lambda method, path, body=None, upload=None: (
                {'id': 'e'} if path == 'edits' else {'tracks': tracks} if path.endswith('/tracks')
                else {'bundles': bundles} if path.endswith('/bundles') else {})
            return api

        api = responses([{'versionCode': '9', 'sha256': digest.upper()}], [])
        with self.assertRaisesRegex(ValueError, 'Bundle identity differs'):
            self.play.publish(api, aab, 2, '1.0', 'artifact_only')
        self.assertIn(('DELETE', 'edits/e'), [call.args[:2] for call in api.call.call_args_list])
        api = responses([], [{'track': 'beta'}])
        with self.assertRaisesRegex(ValueError, 'does not already exist'):
            self.play.publish(api, aab, 2, '1.0', 'closed_testing', 'alpha', [{'language': 'en-US', 'text': 'n'}])
        api = responses([{'versionCode': '5', 'sha256': 'other'}], [])
        with self.assertRaisesRegex(ValueError, 'must exceed'):
            self.play.publish(api, aab, 2, '1.0', 'artifact_only')

    def test_post_commit_verification_failures_are_reported(self):
        aab = self.tmp / 'app.aab'
        aab.write_bytes(b'signed')
        digest = hashlib.sha256(b'signed').hexdigest()
        tracks = [{'track': 'alpha'}, {'track': 'internal'}]

        def scenario(live_bundles, live_tracks):
            calls = {'edits': 0}
            states = []

            def call(method, path, body=None, upload=None):
                if path == 'edits':
                    calls['edits'] += 1
                    return {'id': str(calls['edits'])}
                live = path.startswith('edits/2/')
                if path.endswith('/bundles'):
                    return {'bundles': live_bundles if live else []}
                if path.endswith('/tracks'):
                    return {'tracks': live_tracks if live else tracks}
                if 'uploadType' in path:
                    return {'versionCode': 2, 'sha256': digest}
                if method == 'PUT':
                    tracks[0] = body
                return {}
            api = Mock()
            api.call.side_effect = call
            return api, states

        uploaded = [{'versionCode': 2, 'sha256': digest}]
        for bundles, live_tracks, message in [
            ([], tracks, 'artifact verification'),
            (uploaded, [{'track': 'internal', 'releases': [1]}], 'unrequested track drift'),
        ]:
            api, states = scenario(bundles, live_tracks)
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                self.play.publish(api, aab, 2, '1.0', 'artifact_only', checkpoint=states.append)
            self.assertEqual(states[-1]['state'], 'outcome_unknown')
            self.assertIn(('DELETE', 'edits/2'), [call.args[:2] for call in api.call.call_args_list])
        api, states = scenario(uploaded, [{'track': 'alpha'}, {'track': 'internal'}])
        with self.assertRaisesRegex(ValueError, 'closed track verification'):
            self.play.publish(api, aab, 2, '1.0', 'closed_testing', 'alpha', [{'language': 'en-US', 'text': 'n'}])

    def test_rejected_commit_records_reason_and_keeps_edit(self):
        aab = self.tmp / 'app.aab'
        aab.write_bytes(b'signed')
        digest = hashlib.sha256(b'signed').hexdigest()
        states = []

        def call(method, path, body=None, upload=None):
            if path == 'edits':
                return {'id': '1'}
            if path.endswith(('/tracks', '/bundles')):
                return {}
            if 'uploadType' in path:
                return {'versionCode': 2, 'sha256': digest}
            if ':commit' in path:
                raise self.play.PlayError(409, 'CONFLICT')
            return {}
        api = Mock()
        api.call.side_effect = call
        with self.assertRaises(self.play.PlayError):
            self.play.publish(api, aab, 2, '1.0', 'artifact_only', checkpoint=states.append)
        self.assertEqual(states[-1], dict(states[-1], state='outcome_unknown', reason='CONFLICT'))
        self.assertNotIn(('DELETE', 'edits/1'), [c.args[:2] for c in api.call.call_args_list])

        def rejected(method, path, body=None, upload=None):
            if path.endswith('/tracks'):
                raise self.play.PlayError(400, 'INVALID')
            return {'id': '1'}
        api.call.side_effect = rejected
        with self.assertRaises(self.play.PlayError):
            self.play.publish(api, aab, 2, '1.0', 'artifact_only', checkpoint=states.append)
        self.assertEqual((states[-1]['state'], states[-1]['reason']), ('stopped', 'INVALID'))
        self.assertEqual(api.call.call_args_list[-1].args[:2], ('DELETE', 'edits/1'))

    def test_main_uses_catalog_notes_and_writes_result_and_summary(self):
        aab = self.tmp / 'app.aab'
        aab.write_bytes(b'x')
        result_file = self.tmp / 'result.json'
        summary = self.tmp / 'summary.md'
        captured = {}

        def publish(api, path, code, name, operation, track, notes, checkpoint):
            captured.update(notes=notes, operation=operation)
            checkpoint({'state': 'staging'})
            return {'state': 'deferred_review', 'versionCode': code}
        argv = ['play_publish.py', '--aab', str(aab), '--version-code', '5', '--version-name', '1.2',
                '--operation', 'closed_testing', '--track', 'beta', '--result', str(result_file)]
        out = io.StringIO()
        with patch.object(self.play, 'PlayAPI') as api, patch.object(self.play, 'publish', publish), \
                patch('sys.argv', argv), patch('sys.stdout', out), \
                patch.dict(os.environ, {'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON': '{"client_email": "a"}',
                                        'GITHUB_STEP_SUMMARY': str(summary)}):
            self.play.main()
        api.assert_called_once_with({'client_email': 'a'})
        catalog = json.loads((REPO / 'localization/catalog.json').read_text())['storeMetadata']
        self.assertEqual([n['language'] for n in captured['notes']], ['en-US', 'ro-RO', 'ru-RU'])
        self.assertEqual(captured['notes'][1]['text'], catalog['ro']['releaseNotesByPlatform']['android'])
        self.assertEqual(json.loads(result_file.read_text())['state'], 'deferred_review')
        self.assertIn('::warning::Existing Play review preserved', out.getvalue())
        self.assertIn('## Play result: deferred_review', summary.read_text())

        notes = self.tmp / 'notes.json'
        notes.write_text('[{"language": "en-US", "text": "Fixes"}]')
        with patch.object(self.play, 'PlayAPI'), patch.object(self.play, 'publish', publish), \
                patch('sys.argv', argv + ['--notes', str(notes)]), patch('sys.stdout', io.StringIO()), \
                patch.dict(os.environ, {'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON': '{}'}):
            os.environ.pop('GITHUB_STEP_SUMMARY', None)
            self.play.main()
        self.assertEqual(captured['notes'], [{'language': 'en-US', 'text': 'Fixes'}])

    def test_cli_failure_prints_only_error_class(self):
        aab = self.tmp / 'app.aab'
        aab.write_bytes(b'x')
        env = dict(os.environ)
        env.pop('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON', None)
        with patch.dict(os.environ, env, clear=True):
            result = run('scripts/play_publish.py', '--aab', aab, '--version-code', '2', '--version-name', '1',
                         '--operation', 'artifact_only', '--result', self.tmp / 'r.json')
        self.assertEqual((result.code, result.stderr), (1, 'Publishing stopped: KeyError\n'))


class AppGalleryTests(TempCase):
    def setUp(self):
        super().setUp()
        self.gallery = load('scripts/appgallery.py')
        self.account = {'key_id': 'kid-1', 'sub_account': 'sub-1', 'private_key': PEM}

    def test_token_is_a_verifiable_ps256_assertion_for_pem_and_der_keys(self):
        der = base64.b64encode(KEY.private_bytes(serialization.Encoding.DER, serialization.PrivateFormat.PKCS8,
                                                 serialization.NoEncryption())).decode()
        for private_key in (PEM, der):
            with self.subTest(pem=private_key == PEM):
                header, claims, signature = self.gallery.token(dict(self.account, private_key=private_key)).split('.')
                self.assertEqual(json.loads(b64decode(header)), {'alg': 'PS256', 'typ': 'JWT', 'kid': 'kid-1'})
                body = json.loads(b64decode(claims))
                self.assertEqual((body['iss'], body['exp'] - body['iat']), ('sub-1', 3600))
                KEY.public_key().verify(b64decode(signature), f'{header}.{claims}'.encode(),
                                        padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32), hashes.SHA256())

    def test_gallery_call_checks_huawei_result_codes(self):
        session = Mock(headers={})
        session.request.side_effect = [Reply(payload={'ret': '{"code": 0}', 'appInfo': {}}),
                                       Reply(payload={'ret': {'code': 204144647, 'msg': 'locked'}})]
        with patch.object(self.gallery.requests, 'Session', return_value=session):
            client = self.gallery.Gallery(self.account)
        self.assertTrue(session.headers['Authorization'].startswith('Bearer '))
        self.assertEqual(client.call('GET', 'app-info', lang='en-US'), {'ret': '{"code": 0}', 'appInfo': {}})
        self.assertEqual(session.request.call_args.kwargs['params'], {'appId': '119651007', 'lang': 'en-US'})
        with self.assertRaisesRegex(RuntimeError, 'upload-url: Huawei code 204144647: locked'):
            client.call('GET', 'upload-url')

    def publish(self, responses, *flags, upload=None, credential=None):
        apk = self.tmp / 'app.apk'
        apk.write_bytes(b'apk')
        api = Mock()
        api.call.side_effect = responses
        out = io.StringIO()
        argv = ['appgallery.py', *flags]
        if '--check' not in flags:
            argv += ['--apk', str(apk), '--version-code', '112']
        reply = Reply(payload=upload or {'result': {'UploadFileRsp': {
            'fileInfoList': [{'fileName': 'stored.apk', 'fileDestUlr': 'https://dest'}], 'ifSuccess': 'True'}}})
        with patch.dict(os.environ, {'HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON': credential or json.dumps(self.account)}), \
                patch('sys.argv', argv), patch('sys.stdout', out), \
                patch.object(self.gallery, 'Gallery', return_value=api) as gallery, \
                patch.object(self.gallery.requests, 'post', return_value=reply) as post, \
                patch.object(self.gallery.time, 'sleep'):
            self.gallery.main()
        return api, out.getvalue(), gallery, post

    def test_check_reads_credentials_file_and_prints_public_fields_only(self):
        path = self.tmp / 'account.json'
        path.write_text(json.dumps(self.account))
        api, out, gallery, _ = self.publish([{'appInfo': {'appId': 'x', 'versionCode': 3, 'secret': 's'}}],
                                            '--check', credential=str(path))
        gallery.assert_called_once_with(self.account)
        self.assertEqual(json.loads(out), {'appId': 'x', 'versionCode': 3})

    def test_submission_waits_for_parse_and_review_state(self):
        responses = [{'appInfo': {'versionCode': 111, 'releaseState': 1}},
                     {'uploadUrl': 'https://upload', 'authCode': 'code'}, {},
                     {'appInfo': {'versionCode': 111}}, {'appInfo': {'versionCode': 112}},
                     {}, {'appInfo': {'releaseState': 1}}, {'appInfo': {'releaseState': 5}}]
        api, out, _, post = self.publish(responses)
        self.assertEqual(api.call.call_args_list[2].kwargs['body']['files'][0],
                         {'fileName': 'stored.apk', 'fileDestUrl': 'https://dest'})
        self.assertEqual(post.call_args.kwargs['data'], {'authCode': 'code'})
        self.assertIn('Submitted build 112; SHA256=' + hashlib.sha256(b'apk').hexdigest(), out)

    def test_unconfirmed_upload_or_review_state_stops(self):
        with self.assertRaisesRegex(RuntimeError, 'did not confirm'):
            self.publish([{'appInfo': {'versionCode': 1}}, {'uploadUrl': 'u', 'authCode': 'c'}],
                         upload={'result': {'UploadFileRsp': {'ifSuccess': 0}}})
        responses = [{'appInfo': {'versionCode': 1}}, {'uploadUrl': 'u', 'authCode': 'c'}, {},
                     {'appInfo': {'versionCode': 112}}, {}] + [{'appInfo': {'releaseState': 1}}] * 12
        with self.assertRaisesRegex(RuntimeError, 'review state was not confirmed'):
            self.publish(responses)

    def test_existing_versions_are_not_uploaded_again(self):
        _, out, _, post = self.publish([{'appInfo': {'versionCode': 100, 'onShelfVersionCode': 112}}])
        self.assertIn('already uploaded or superseded', out)
        api, out, _, _ = self.publish([{'appInfo': {'versionCode': 112, 'releaseState': 1}}, {}])
        self.assertEqual(api.call.call_args_list[-1].args[:2], ('POST', 'app-submit'))
        self.assertIn('Resubmitted existing draft build 112.', out)
        _, out, _, _ = self.publish([{'appInfo': {'versionCode': 112, 'releaseState': 1}}], '--draft')
        self.assertIn('Draft build 112 is already attached; not submitted.', out)
        post.assert_not_called()

    def test_invalid_flag_combinations_exit_before_upload(self):
        for flags in (['--defer-if-reviewing'],):
            with self.subTest(flags=flags), self.assertRaises(SystemExit), patch('sys.stderr', io.StringIO()):
                self.publish([{'appInfo': {}}], *flags)
        api = Mock()
        api.call.return_value = {'appInfo': {}}
        with patch.dict(os.environ, {'HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON': '{}'}), \
                patch('sys.argv', ['appgallery.py', '--apk', 'app.aab', '--version-code', '1']), \
                patch.object(self.gallery, 'Gallery', return_value=api), patch('sys.stdout', io.StringIO()), \
                patch('sys.stderr', io.StringIO()) as err, self.assertRaises(SystemExit):
            self.gallery.main()
        self.assertIn('--apk and --version-code are required', err.getvalue())

    def test_cli_hides_http_details_and_reports_validation_errors(self):
        env = {'HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON': json.dumps(self.account)}
        with patch.object(requests.Session, 'request', side_effect=requests.ConnectionError('https://signed?auth=1')):
            result = run('scripts/appgallery.py', '--check', env=env)
        self.assertEqual(result.code, 1)
        self.assertNotIn('signed', result.stderr)
        self.assertIn('AppGallery HTTP request failed', result.stderr)
        result = run('scripts/appgallery.py', '--check', env={'HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON': '{}'})
        self.assertEqual((result.code, result.stderr), (1, "AppGallery: 'key_id'\n"))


class FakeResponse(io.BytesIO):
    def __init__(self, payload=b'{}', status=200):
        super().__init__(payload if isinstance(payload, bytes) else json.dumps(payload).encode())
        self.status = status

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


class MicrosoftCredentialCheckTests(unittest.TestCase):
    ENV = {'MSSTORE_TENANT_ID': '00000000-0000-4000-8000-000000000001', 'MSSTORE_SELLER_ID': '123',
           'MSSTORE_CLIENT_ID': '00000000-0000-4000-8000-000000000002', 'MSSTORE_CLIENT_SECRET': 'secret'}

    def check(self, responses, **env):
        requests_seen = []

        def urlopen(request, timeout):
            requests_seen.append(request)
            response = responses.pop(0)
            if isinstance(response, Exception):
                raise response
            return FakeResponse(response)
        with patch('urllib.request.urlopen', urlopen):
            return run('scripts/check-msstore-credentials.py', env={**self.ENV, **env}), requests_seen

    def test_valid_credentials_read_the_application_only(self):
        result, seen = self.check([{'access_token': 'abc'}, {'id': '9PDPR6RNT42S'}])
        self.assertEqual(result.code, 0)
        self.assertIn('Store credentials validated', result.stdout)
        self.assertIn(b'client_secret=secret', seen[0].data)
        self.assertEqual(seen[1].get_header('Authorization'), 'Bearer abc')
        self.assertIsNone(seen[1].data)

    def test_failures_never_echo_credentials(self):
        cases = [
            ({'MSSTORE_CLIENT_SECRET': ' '}, []),
            ({'MSSTORE_TENANT_ID': 'not-a-uuid'}, []),
            ({'MSSTORE_SELLER_ID': '12a'}, []),
            ({}, [{'access_token': 'abc'}, {'id': 'other'}]),
            ({}, [urllib.error.URLError('down')]),
        ]
        for env, responses in cases:
            with self.subTest(env=env):
                result, _ = self.check(responses, **env)
                self.assertEqual(result.code, 1)
                self.assertEqual(result.stderr, 'Microsoft Store credential check failed; check credential '
                                                'configuration and connectivity.\n')
        result, _ = self.check([urllib.error.HTTPError('u', 401, 'no', {}, io.BytesIO())])
        self.assertEqual(result.stderr, 'Microsoft Store credential check failed: HTTP 401.\n')


IDENTITY = {'Name': 'NicolaeGhimbovschi.eSemnBun', 'Publisher': 'CN=3AAF334E-BE21-4B3F-8FDE-FBEDDF7498EE',
            'Version': '1.2.205.0', 'ProcessorArchitecture': 'x64'}


def msix(path, identity=IDENTITY, signed=True):
    manifest = '<Package/>'
    if identity is not None:
        attributes = ' '.join(f'{key}="{value}"' for key, value in identity.items())
        manifest = ('<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10">'
                    f'<Identity {attributes}/></Package>')
    with zipfile.ZipFile(path, 'w') as archive:
        archive.writestr('AppxManifest.xml', manifest)
        if signed:
            archive.writestr('AppxSignature.p7x', b'sig')
    return hashlib.sha256(path.read_bytes()).hexdigest()


class MicrosoftScreenshotTests(TempCase):
    def setUp(self):
        super().setUp()
        self.tool = load('distribution/tools/upload-microsoft-screenshots.py')
        self.assets = self.tmp / 'assets'
        for language in ('en', 'ro', 'ru'):
            for index in range(4):
                png(self.assets / language / f'{index}.png', color=(index, 1, 2, 255))
            (self.assets / language / 'captions.json').write_text(json.dumps([f'{language} {i}' for i in range(4)]))
        self.credentials = self.tmp / 'credentials.json'
        self.credentials.write_text(json.dumps({'MSSTORE_CLIENT_ID': 'c', 'MSSTORE_CLIENT_SECRET': 's',
                                                'MSSTORE_TENANT_ID': 't'}))

    def submission(self, status='PendingCommit', **extra):
        listing = {'baseListing': {'images': [{'fileName': 'old.png', 'imageType': 'Screenshot', 'fileStatus': 'Uploaded'},
                                              {'fileName': 'logo.png', 'imageType': 'StoreLogo'}]}}
        return {'id': 'S1', 'status': status, 'listings': {locale: json.loads(json.dumps(listing))
                                                         for locale in ('en-us', 'ro-ro', 'ru-ru')}, **extra}

    def store(self, submission, pending=True, upload_url='https://acct.blob.core.windows.net/x?sig=1',
              upload_status=201, readback=None):
        state = {'requests': [], 'uploaded': None}

        def urlopen(request, timeout):
            url = request.full_url
            state['requests'].append((request.get_method(), url))
            if 'oauth2/token' in url:
                return FakeResponse({'access_token': 'tok'})
            if url.endswith('/applications/9PDPR6RNT42S'):
                return FakeResponse({'pendingApplicationSubmission': {'id': 'S1'} if pending else None})
            if urlsplit(url).hostname == 'acct.blob.core.windows.net':
                state['uploaded'] = request.data
                return FakeResponse(b'', upload_status)
            if request.get_method() == 'PUT':
                state['staged'] = json.loads(request.data)
                return FakeResponse(dict(state['staged'], fileUploadUrl=upload_url))
            if state.get('staged') is not None:
                return FakeResponse(readback(state['staged']) if readback else state['staged'])
            return FakeResponse(submission)
        return state, urlopen

    def main(self, urlopen, *flags):
        out = io.StringIO()
        argv = ['upload.py', '--credentials', str(self.credentials), '--assets', str(self.assets), *flags]
        with patch('sys.argv', argv), patch('sys.stdout', out), patch.object(self.tool.urllib.request, 'urlopen', urlopen):
            self.tool.main()
        return [json.loads(line) for line in out.getvalue().splitlines()]

    def test_package_identity_is_checked_before_store_access(self):
        package = self.tmp / 'app.msix'
        digest = msix(package)
        data, info, actual, signed = self.tool.inspect_package(package, '1.2.205.0', digest.upper())
        self.assertEqual((info['Version'], actual, signed, data), ('1.2.205.0', digest, True, package.read_bytes()))
        cases = [
            (IDENTITY, '1.2.205.0', 'other', 'checksum differs'),
            (None, '1.2.205.0', None, 'identity is missing'),
            (dict(IDENTITY, Name='Other'), '1.2.205.0', None, 'does not match the Store app'),
            (IDENTITY, '1.2.206.0', None, 'version differs'),
            (dict(IDENTITY, Version='1.2.70000.0'), '1.2.70000.0', None, 'four valid MSIX version components'),
        ]
        for identity, version, expected, message in cases:
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                digest = msix(package, identity)
                self.tool.inspect_package(package, version, expected or digest)

    def test_inspect_only_prints_the_pending_draft(self):
        state, urlopen = self.store(self.submission(status='CommitStarted'))
        rows = self.main(urlopen)
        self.assertEqual(rows, [{'id': 'S1', 'status': 'CommitStarted', 'targetPublishMode': None,
                                 'targetPublishDate': None, 'statusDetails': None}])
        self.assertTrue(all(method == 'GET' for method, url in state['requests'] if 'oauth2' not in url))

    def test_prepare_in_memory_replaces_same_architecture_package_and_screenshots(self):
        package = self.tmp / 'app.msix'
        digest = msix(package)
        submission = self.submission(applicationPackages=[
            {'fileName': 'old-x64.msix', 'version': '1.2.204.0', 'architecture': 'X64', 'fileStatus': 'Uploaded'},
            {'fileName': 'old-arm.msix', 'version': '1.2.204.0', 'architecture': 'arm64', 'fileStatus': 'Uploaded'},
            {'fileName': 'gone.msix', 'version': '9.9.9.9', 'fileStatus': 'PendingDelete'}])
        state, urlopen = self.store(submission)
        rows = self.main(urlopen, '--submission', 'S1', '--package', str(package), '--expected-version', '1.2.205.0',
                         '--expected-sha256', digest)
        prepared = rows[-1]
        self.assertEqual(prepared['result'], 'prepared in memory; no Store changes')
        self.assertEqual(prepared['package'], f'esemnbun-1.2.205.0-{digest[:12]}.msix')
        self.assertTrue(prepared['packageSignaturePresent'])
        self.assertFalse(any(method == 'PUT' for method, _ in state['requests']))

    def test_upload_stages_archive_and_verifies_read_back(self):
        state, urlopen = self.store(self.submission())
        rows = self.main(urlopen, '--submission', 'S1', '--upload')
        self.assertEqual(rows[-1]['result'], 'archive uploaded and draft references verified; not committed')
        with zipfile.ZipFile(io.BytesIO(state['uploaded'])) as archive:
            names = archive.namelist()
        self.assertEqual(len(names), 12)
        images = state['staged']['listings']['ro-ro']['baseListing']['images']
        self.assertEqual(images[0]['fileStatus'], 'PendingDelete')
        self.assertEqual([image['description'] for image in images[2:]], [f'ro {i}' for i in range(4)])

    def test_upload_package_requires_read_back_of_the_new_package(self):
        package = self.tmp / 'app.msix'
        digest = msix(package, signed=False)

        def drop_package(staged):
            return dict(staged, applicationPackages=[])
        state, urlopen = self.store(self.submission(), readback=drop_package)
        with self.assertRaisesRegex(ValueError, 'package read-back'):
            self.main(urlopen, '--submission', 'S1', '--upload', '--package', str(package),
                      '--expected-version', '1.2.205.0', '--expected-sha256', digest)

    def test_unsafe_or_ambiguous_drafts_are_refused(self):
        older = {'applicationPackages': [{'version': '1.2.205.0', 'fileStatus': 'Uploaded'}]}
        pending_image = self.submission()
        pending_image['listings']['en-us']['baseListing']['images'].append({'fileStatus': 'PendingUpload'})

        def unexpected_screens(staged):
            staged['listings']['ru-ru']['baseListing']['images'] = []
            return staged
        package = self.tmp / 'app.msix'
        digest = msix(package)
        cases = [
            (self.store(self.submission(), pending=False), ['--upload'], 'No pending submission'),
            (self.store(self.submission()), ['--submission', 'S2'], 'differs from requested ID'),
            (self.store(self.submission()), ['--upload'], 'exact submission ID'),
            (self.store(self.submission(status='CommitFailed')), ['--submission', 'S1', '--upload'], 'PendingCommit'),
            (self.store(self.submission(applicationPackages=[{'fileStatus': 'PendingUpload'}])),
             ['--submission', 'S1', '--upload'], 'Pending package upload'),
            (self.store(self.submission(trailers=[{}])), ['--submission', 'S1', '--upload'], 'Trailer assets'),
            (self.store(self.submission(extra={'nested': [{'fileStatus': 'PendingUpload'}]})),
             ['--submission', 'S1', '--upload'], 'Existing pending upload'),
            (self.store(pending_image), ['--submission', 'S1', '--upload'], 'Existing pending upload'),
            (self.store(self.submission(**older)), ['--submission', 'S1', '--package', str(package),
             '--expected-version', '1.2.205.0', '--expected-sha256', digest], 'must exceed'),
            (self.store(self.submission(), upload_url='https://evil.example/x'), ['--submission', 'S1', '--upload'],
             'Unexpected upload URL origin'),
            (self.store(self.submission(), upload_status=500), ['--submission', 'S1', '--upload'], 'upload failed'),
            (self.store(self.submission(), readback=unexpected_screens), ['--submission', 'S1', '--upload'],
             'read-back differs for ru-ru'),
        ]
        for (state, urlopen), flags, message in cases:
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                self.main(urlopen, *flags)

    def test_missing_screenshots_are_refused(self):
        (self.assets / 'ru' / '3.png').unlink()
        _, urlopen = self.store(self.submission())
        with self.assertRaisesRegex(ValueError, 'four screenshots and captions for ru-ru'):
            self.main(urlopen, '--submission', 'S1', '--upload')

    def test_cli_reports_sanitized_errors(self):
        with patch('sys.stderr', io.StringIO()):
            partial = run('distribution/tools/upload-microsoft-screenshots.py', '--package', 'x.msix')
        self.assertEqual(partial.code, 2)

        def http_error(request, timeout):
            raise urllib.error.HTTPError(request.full_url, 403, 'forbidden', {}, io.BytesIO())
        with patch('urllib.request.urlopen', http_error):
            result = run('distribution/tools/upload-microsoft-screenshots.py', '--credentials', self.credentials)
        self.assertEqual(result.code, 'Microsoft Store HTTP 403; inspect current draft before retrying')
        package = self.tmp / 'bad.msix'
        package.write_bytes(b'not a zip')
        result = run('distribution/tools/upload-microsoft-screenshots.py', '--package', package,
                     '--expected-version', '1.0.0.0', '--expected-sha256', hashlib.sha256(b'not a zip').hexdigest())
        self.assertEqual(result.code, 'Microsoft screenshot operation stopped: BadZipFile')
        result = run('distribution/tools/upload-microsoft-screenshots.py', '--package', package,
                     '--expected-version', '1.0.0.0', '--expected-sha256', '00')
        self.assertEqual(result.code, 'Microsoft screenshot operation stopped: MSIX checksum differs from expected '
                                      'release artifact')


class MicrosoftImportTests(TempCase):
    def test_partner_center_csv_is_filled_from_listings_and_pack(self):
        pack = self.tmp / 'pack'
        for language in ('ro', 'en', 'ru'):
            for index in range(2):
                png(pack / f'microsoft/assets/{language}/{index}-shot.png')
            (pack / f'microsoft/assets/{language}/captions.json').write_text(json.dumps([f'{language} caption']))
        template = self.tmp / 'template.csv'
        fields = ['Description', 'Title', 'Feature1', 'Feature9', 'SearchTerm2', 'DesktopScreenshot1',
                  'DesktopScreenshot5', 'DesktopScreenshotCaption1', 'DesktopScreenshotCaption2', 'Unknown']
        with template.open('w', encoding='utf-8-sig', newline='') as stream:
            csv.writer(stream).writerows([['Field', 'ID', 'Type', 'Default', 'x', 'y']] +
                                         [[field, str(i), 'Text', 'old', 'a', 'b'] for i, field in enumerate(fields)])
        output = self.tmp / 'Import'
        result = run('distribution/tools/prepare-microsoft-import.py', '--template', template, '--pack', pack,
                     '--output', output)
        self.assertEqual(result.stdout.strip(), str(output / 'listings.csv'))
        with (output / 'listings.csv').open(encoding='utf-8-sig') as stream:
            rows = {row[0]: row for row in csv.reader(stream)}
        english = json.loads((REPO / 'distribution/microsoft/listings/en.json').read_text())
        self.assertEqual(rows['Field'][3:], ['Default', 'ro-ro', 'en-us', 'ru-ru'])
        self.assertEqual(rows['Title'][5], english['name'])
        self.assertEqual(rows['Feature1'][5], english['features'][0])
        self.assertEqual(rows['Feature9'][5], '')
        self.assertEqual(rows['SearchTerm2'][5], english['searchTerms'][1])
        self.assertEqual(rows['DesktopScreenshot1'][4], 'Import/images/ro/0-shot.png')
        self.assertTrue((output / 'images/ru/0-shot.png').is_file())
        self.assertEqual(rows['DesktopScreenshot5'][4:], ['', '', ''])
        self.assertEqual((rows['DesktopScreenshotCaption1'][6], rows['DesktopScreenshotCaption2'][6]), ('ru caption', ''))
        self.assertEqual(rows['Unknown'][3:], ['', '', '', ''])
        self.assertTrue(Path(REPO / 'distribution/microsoft/listings/ro.json').is_file())
