import copy
import hashlib
from pathlib import Path
import tempfile
import unittest
from play_publish import PlayError, publish


class FakeAPI:
    def __init__(self, bundle, reviewing=False, existing=False, invalid_hash=False):
        self.calls=[];self.reviewing=reviewing;self.invalid_hash=invalid_hash
        self.bundle=bundle
        self.bundles=[bundle] if existing else []
        self.tracks=[{'track':'alpha'}, {'track':'internal','releases':[{'versionCodes':['1'],'status':'completed'}]}, {'track':'production'}]
    def call(self, method, path, body=None, upload=None):
        self.calls.append((method,path,body))
        if path=='edits':return {'id':str(len(self.calls))}
        if path.endswith('/tracks'):return {'tracks':copy.deepcopy(self.tracks)}
        if path.endswith('/bundles'):return {'bundles':copy.deepcopy(self.bundles)}
        if 'uploadType' in path:
            self.bundles=[dict(self.bundle,sha256='bad')] if self.invalid_hash else [self.bundle]
            return self.bundles[0]
        if method=='PUT':
            self.tracks=[body if t['track']==body['track'] else t for t in self.tracks];return body
        if ':commit' in path and self.reviewing:raise PlayError(400,'CHANGES_ALREADY_IN_REVIEW')
        return {}


class PublishingTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.aab=Path(self.temp.name)/'app.aab';self.aab.write_bytes(b'signed fixture')
        self.bundle={'versionCode':2,'sha256':hashlib.sha256(self.aab.read_bytes()).hexdigest()}
        self.notes=[{'language':'en-US','text':'Localized stamps and app settings.'}]
    def run_publish(self,api,mode='closed_testing',track='alpha'):
        return publish(api,self.aab,2,'0.2.6',mode,track,self.notes)
    def test_closed_changes_only_selected_track_and_verifies_after_commit(self):
        api=FakeAPI(self.bundle);before=api.tracks[1:]
        self.assertEqual(self.run_publish(api)['state'],'submitted')
        self.assertEqual(api.tracks[1:],before)
        puts=[c for c in api.calls if c[0]=='PUT'];self.assertEqual(len(puts),1);self.assertTrue(puts[0][1].endswith('/alpha'))
        commit=next(c[1] for c in api.calls if ':commit' in c[1]);self.assertIn('ERROR_IF_IN_REVIEW',commit)
        self.assertNotIn('changesNotSentForReview',commit)
    def test_artifact_only_never_updates_tracks(self):
        api=FakeAPI(self.bundle)
        self.assertEqual(self.run_publish(api,'artifact_only',None)['state'],'uploaded')
        self.assertFalse(any(c[0]=='PUT' for c in api.calls))
        self.assertIn('changesNotSentForReview=true',next(c[1] for c in api.calls if ':commit' in c[1]))
    def test_same_hash_is_not_uploaded_again(self):
        api=FakeAPI(self.bundle,existing=True)
        self.assertEqual(self.run_publish(api,'artifact_only',None)['state'],'already_uploaded')
        self.assertFalse(any('uploadType' in c[1] or ':commit' in c[1] for c in api.calls))
    def test_active_review_is_deferred_without_cancel(self):
        api=FakeAPI(self.bundle,reviewing=True)
        self.assertEqual(self.run_publish(api)['state'],'deferred_review')
        self.assertFalse(any('CANCEL_IN_REVIEW' in c[1] for c in api.calls))
    def test_wrong_hash_stops_before_track_mutation(self):
        api=FakeAPI(self.bundle,invalid_hash=True)
        with self.assertRaises(ValueError):self.run_publish(api)
        self.assertFalse(any(c[0]=='PUT' or ':commit' in c[1] for c in api.calls))
    def test_production_internal_and_implicit_track_forbidden_before_api(self):
        for track in ['production','internal',None]:
            api=FakeAPI(self.bundle)
            with self.assertRaises(ValueError):self.run_publish(api,track=track)
            self.assertEqual(api.calls,[])
    def test_downgrade_rejected(self):
        api=FakeAPI(self.bundle);api.tracks[0]['releases']=[{'versionCodes':['3']}]
        with self.assertRaises(ValueError):self.run_publish(api)
        self.assertFalse(any(c[0]=='PUT' for c in api.calls))
    def test_uncertain_commit_is_never_retried(self):
        api=FakeAPI(self.bundle);original=api.call
        def timeout(method,path,body=None,upload=None):
            if ':commit' in path:api.calls.append((method,path,body));raise TimeoutError()
            return original(method,path,body,upload)
        api.call=timeout
        with self.assertRaises(TimeoutError):self.run_publish(api)
        self.assertEqual(sum(':commit' in c[1] for c in api.calls),1)
    def test_noop_closed_release_is_idempotent(self):
        api=FakeAPI(self.bundle,existing=True);self.run_publish(api);api.calls=[]
        self.assertEqual(self.run_publish(api)['state'],'already_configured')
        self.assertFalse(any(':commit' in c[1] for c in api.calls))

    def test_only_known_artifact_review_parameter_error_gets_one_retry(self):
        api=FakeAPI(self.bundle);original=api.call
        def parameter_error(method,path,body=None,upload=None):
            if ':commit' in path and 'changesNotSentForReview' in path:
                api.calls.append((method,path,body));raise PlayError(400,'REVIEW_PARAMETER_NOT_ALLOWED')
            return original(method,path,body,upload)
        api.call=parameter_error
        self.assertEqual(self.run_publish(api,'artifact_only',None)['state'],'uploaded')
        commits=[c[1] for c in api.calls if ':commit' in c[1]]
        self.assertEqual(len(commits),2)
        self.assertTrue(all('ERROR_IF_IN_REVIEW' in c for c in commits))

    def test_unrequested_track_drift_stops_before_commit(self):
        api=FakeAPI(self.bundle);original=api.call
        def drift(method,path,body=None,upload=None):
            result=original(method,path,body,upload)
            if method=='PUT':api.tracks[1]['releases'][0]['versionCodes']=['99']
            return result
        api.call=drift
        with self.assertRaises(ValueError):self.run_publish(api)
        self.assertFalse(any(':commit' in c[1] for c in api.calls))

    def test_timeout_checkpoint_is_inspectable(self):
        api=FakeAPI(self.bundle);original=api.call;states=[]
        def timeout(method,path,body=None,upload=None):
            if ':commit' in path:raise TimeoutError()
            return original(method,path,body,upload)
        api.call=timeout
        with self.assertRaises(TimeoutError):
            publish(api,self.aab,2,'0.2.6','closed_testing','alpha',self.notes,checkpoint=states.append)
        self.assertEqual(states[-1]['state'],'outcome_unknown')
        self.assertEqual(states[-1]['editId'],'1')
