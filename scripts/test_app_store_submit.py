"""App Store review submission guards against a simulated App Store Connect API (no network, no credentials)."""
import copy
from pathlib import Path
import tempfile
import unittest

from app_store_submit import ASCError, run


class FakeASC:
    """Just enough App Store Connect state for one app: builds, versions, localizations and review submissions."""

    def __init__(self, version_state=None, attached=None, submissions=(), items=(), previous_release='AFTER_APPROVAL',
                 build_state='VALID', encryption=False, settle=True):
        self.calls = []
        self.settle = settle
        self.builds = [{'id': 'b218', 'attributes': {'processingState': build_state, 'expired': False,
                                                     'usesNonExemptEncryption': encryption}}]
        self.versions = [{'id': 'v14', 'attributes': {'versionString': '0.2.14', 'appVersionState': 'READY_FOR_DISTRIBUTION',
                                                      'releaseType': previous_release}}]
        self.build_of = {'v14': 'b217'}
        if version_state:
            self.versions.append({'id': 'v15', 'attributes': {'versionString': '0.2.15', 'appVersionState': version_state,
                                                              'releaseType': 'AFTER_APPROVAL'}})
            self.build_of['v15'] = attached
        self.localizations = {'v15': [{'id': 'l-en', 'attributes': {'locale': 'en-US', 'whatsNew': None}},
                                      {'id': 'l-ro', 'attributes': {'locale': 'ro', 'whatsNew': 'Old'}}]}
        self.submissions = [copy.deepcopy(s) for s in submissions]
        self.items = {s['id']: list(items) for s in self.submissions}

    def mutations(self):
        return [c for c in self.calls if c[0] != 'GET']

    def get(self, path, **params):
        return self.call('GET', path, params=params or None)

    def call(self, method, path, body=None, params=None):
        self.calls.append((method, path, body))
        if method == 'GET':
            if path == '/v1/builds':
                return {'data': copy.deepcopy(self.builds)}
            if path.endswith('/appStoreVersions'):
                return {'data': copy.deepcopy(self.versions)}
            if path.endswith('/appStoreVersionLocalizations'):
                return {'data': copy.deepcopy(self.localizations[path.split('/')[3]])}
            if path.endswith('/build'):
                build = self.build_of.get(path.split('/')[3])
                return {'data': {'type': 'builds', 'id': build} if build else None}
            if path == '/v1/reviewSubmissions':
                return {'data': copy.deepcopy(self.submissions)}
            if path.endswith('/items'):
                return {'data': [{'relationships': {'appStoreVersion': {'data': {'id': i}}}} for i in self.items[path.split('/')[3]]]}
            if path.startswith('/v1/reviewSubmissions/'):
                return {'data': next(copy.deepcopy(s) for s in self.submissions if s['id'] == path.split('/')[3])}
            if path.startswith('/v1/appStoreVersions/'):
                return {'data': next(copy.deepcopy(v) for v in self.versions if v['id'] == path.split('/')[3])}
        if method == 'POST' and path == '/v1/appStoreVersions':
            attributes = dict(body['data']['attributes'], appVersionState='PREPARE_FOR_SUBMISSION')
            self.versions.append({'id': 'v15', 'attributes': attributes})
            self.build_of['v15'] = None
            return {'data': copy.deepcopy(self.versions[-1])}
        if method == 'PATCH' and path.startswith('/v1/appStoreVersionLocalizations/'):
            loc = next(l for l in self.localizations['v15'] if l['id'] == body['data']['id'])
            loc['attributes'].update(body['data']['attributes'])
            return {}
        if method == 'PATCH' and path.endswith('/relationships/build'):
            self.build_of[path.split('/')[3]] = body['data']['id']
            return {}
        if method == 'POST' and path == '/v1/reviewSubmissions':
            self.submissions.append({'id': 's-new', 'attributes': {'state': 'READY_FOR_REVIEW'}})
            self.items['s-new'] = []
            return {'data': copy.deepcopy(self.submissions[-1])}
        if method == 'POST' and path == '/v1/reviewSubmissionItems':
            relationships = body['data']['relationships']
            self.items[relationships['reviewSubmission']['data']['id']].append(relationships['appStoreVersion']['data']['id'])
            return {}
        if method == 'PATCH' and path.startswith('/v1/reviewSubmissions/'):
            if self.settle:
                next(s for s in self.submissions if s['id'] == body['data']['id'])['attributes']['state'] = 'WAITING_FOR_REVIEW'
                next(v for v in self.versions if v['id'] == 'v15')['attributes']['appVersionState'] = 'WAITING_FOR_REVIEW'
            return {}
        raise AssertionError(f'unexpected {method} {path}')


def submission(state, ident='s1'):
    return {'id': ident, 'attributes': {'state': state}}


class AppStoreSubmitTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.notes = Path(temp.name) / 'distribution/apple'
        for locale, text in [('en-US', 'Faster signing.'), ('ro', 'Semnare mai rapidă.')]:
            (self.notes / 'ios' / locale).mkdir(parents=True)
            (self.notes / 'ios' / locale / 'release_notes.txt').write_text(text + '\n', encoding='utf-8')
        self.states = []

    def run_tool(self, api, operation='submit', version='0.2.15'):
        return run(api, 'ios', version, '218', operation, notes_root=self.notes, checkpoint=self.states.append,
                   sleep=lambda seconds: None)

    def test_status_is_read_only(self):
        api = FakeASC('WAITING_FOR_REVIEW', 'b218', [submission('WAITING_FOR_REVIEW')])
        result = self.run_tool(api, 'status')
        self.assertEqual((result['state'], result['versionState'], result['attachedBuildId']), ('status', 'WAITING_FOR_REVIEW', 'b218'))
        self.assertEqual(api.mutations(), [])

    def test_submit_creates_version_with_inherited_release_type_notes_build_and_submission(self):
        api = FakeASC(previous_release='MANUAL')
        result = self.run_tool(api)
        self.assertEqual(result['state'], 'submitted')
        created = next(c for c in api.calls if c[:2] == ('POST', '/v1/appStoreVersions'))
        self.assertEqual(created[2]['data']['attributes'], {'platform': 'IOS', 'versionString': '0.2.15', 'releaseType': 'MANUAL'})
        self.assertEqual({l['attributes']['locale']: l['attributes']['whatsNew'] for l in api.localizations['v15']},
                         {'en-US': 'Faster signing.', 'ro': 'Semnare mai rapidă.'})
        self.assertEqual(api.build_of['v15'], 'b218')
        self.assertEqual(api.items['s-new'], ['v15'])
        self.assertEqual(api.versions[0]['attributes']['appVersionState'], 'READY_FOR_DISTRIBUTION')
        self.assertEqual(self.states[-1]['state'], 'submitted')

    def test_prepare_stops_before_any_review_submission(self):
        api = FakeASC()
        self.assertEqual(self.run_tool(api, 'prepare')['state'], 'prepared')
        self.assertEqual(api.build_of['v15'], 'b218')
        self.assertFalse(any('reviewSubmission' in c[1] for c in api.mutations()))

    def test_already_submitted_with_this_build_changes_nothing(self):
        for state in ['WAITING_FOR_REVIEW', 'IN_REVIEW', 'PENDING_DEVELOPER_RELEASE', 'READY_FOR_DISTRIBUTION']:
            api = FakeASC(state, 'b218', [submission('WAITING_FOR_REVIEW')])
            with self.subTest(state=state):
                self.assertEqual(self.run_tool(api)['state'], 'already_submitted')
                self.assertEqual(api.mutations(), [])

    def test_version_in_review_with_another_build_is_not_replaced(self):
        api = FakeASC('WAITING_FOR_REVIEW', 'b217', [submission('WAITING_FOR_REVIEW')])
        with self.assertRaisesRegex(ValueError, 'another build'):
            self.run_tool(api)
        self.assertEqual(api.mutations(), [])

    def test_active_review_of_another_version_is_never_replaced(self):
        for state in ['WAITING_FOR_REVIEW', 'IN_REVIEW', 'CANCELING']:
            api = FakeASC('PREPARE_FOR_SUBMISSION', None, [submission(state)], items=['v99'])
            with self.subTest(state=state), self.assertRaisesRegex(ValueError, 'not replacing it'):
                self.run_tool(api)
            self.assertFalse(any('reviewSubmission' in c[1] for c in api.mutations()))

    def test_open_submission_with_other_items_is_refused_and_own_draft_is_reused(self):
        api = FakeASC('PREPARE_FOR_SUBMISSION', None, [submission('READY_FOR_REVIEW')], items=['v99'])
        with self.assertRaisesRegex(ValueError, 'holds other items'):
            self.run_tool(api)
        self.assertFalse(any(c[0] == 'PATCH' and c[1].startswith('/v1/reviewSubmissions/') for c in api.calls))
        api = FakeASC('REJECTED', 'b217', [submission('UNRESOLVED_ISSUES')], items=['v15'])
        self.assertEqual(self.run_tool(api)['state'], 'submitted')
        self.assertFalse(any(c[1] in ('/v1/reviewSubmissions', '/v1/reviewSubmissionItems') for c in api.mutations()))
        self.assertEqual(api.build_of['v15'], 'b218')

    def test_unprocessed_or_undeclared_builds_stop_before_changes(self):
        for kwargs, message in [({'build_state': 'PROCESSING'}, 'PROCESSING'), ({'encryption': None}, 'export-compliance')]:
            api = FakeASC(**kwargs)
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                self.run_tool(api)
            self.assertEqual(api.mutations(), [])
        api = FakeASC()
        api.builds = []
        with self.assertRaisesRegex(ValueError, 'NOT_FOUND'):
            self.run_tool(api)

    def test_other_unfinished_version_blocks_creation(self):
        api = FakeASC()
        api.versions.append({'id': 'v16', 'attributes': {'versionString': '0.2.16', 'appVersionState': 'PREPARE_FOR_SUBMISSION'}})
        with self.assertRaisesRegex(ValueError, '0.2.16 is PREPARE_FOR_SUBMISSION'):
            self.run_tool(api)
        self.assertEqual(api.mutations(), [])
        with self.assertRaisesRegex(ValueError, 'not newer'):
            self.run_tool(FakeASC(), version='0.2.13')

    def test_missing_notes_for_an_existing_locale_stop_before_build_or_review_changes(self):
        api = FakeASC('PREPARE_FOR_SUBMISSION')
        api.localizations['v15'].append({'id': 'l-ru', 'attributes': {'locale': 'ru', 'whatsNew': None}})
        with self.assertRaisesRegex(ValueError, 'No release notes for ios locale ru'):
            self.run_tool(api)
        self.assertEqual(api.mutations(), [])

    def test_unconfirmed_review_state_is_outcome_unknown(self):
        api = FakeASC(settle=False)
        self.assertEqual(self.run_tool(api)['state'], 'outcome_unknown')
        self.assertEqual(sum(c[0] == 'PATCH' and c[1] == '/v1/reviewSubmissions/s-new' for c in api.calls), 1)

    def test_timeout_after_submit_request_is_uncertain_but_rejection_is_not(self):
        for error, expected in [(TimeoutError(), 'outcome_unknown'), (ASCError(409, 'STATE_ERROR'), 'stopped')]:
            api = FakeASC()
            original = api.call

            def failing(method, path, body=None, params=None, error=error, original=original):
                if method == 'PATCH' and path.startswith('/v1/reviewSubmissions/'):
                    api.calls.append((method, path, body))
                    raise error
                return original(method, path, body, params)
            api.call = failing
            with self.subTest(expected=expected), self.assertRaises(type(error)):
                self.run_tool(api)
            self.assertEqual(self.states[-1]['state'], expected)
            self.assertTrue(self.states[-1]['changesMade'])

    def test_invalid_inputs_fail_before_api(self):
        api = FakeASC()
        for args in [('ios', '0.2', '0', 'submit'), ('ios', 'v0.2.15', '218', 'submit'), ('tvos', '0.2.15', '218', 'submit'),
                     ('ios', '0.2.15', '218', 'release')]:
            with self.subTest(args=args), self.assertRaises(ValueError):
                run(api, *args, notes_root=self.notes)
        self.assertEqual(api.calls, [])


if __name__ == '__main__':
    unittest.main()
