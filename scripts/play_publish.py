#!/usr/bin/env python3
"""Publish an exact signed AAB; no builds, internal promotion, listing edits, or review cancellation."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time

PACKAGE = 'md.esemnbun.app'


class PlayError(Exception):
    def __init__(self, status, reason):
        self.status, self.reason = status, reason
        super().__init__(f'Play API {status}: {reason}')


class PlayAPI:
    def __init__(self, credentials):
        import jwt
        import requests
        self.session = requests.Session()
        now = int(time.time())
        assertion = jwt.encode({'iss': credentials['client_email'], 'scope': 'https://www.googleapis.com/auth/androidpublisher',
            'aud': 'https://oauth2.googleapis.com/token', 'iat': now, 'exp': now + 3600}, credentials['private_key'], algorithm='RS256')
        reply = self.session.post('https://oauth2.googleapis.com/token', data={
            'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion': assertion}, timeout=40)
        reply.raise_for_status()
        self.session.headers['Authorization'] = 'Bearer ' + reply.json()['access_token']

    def call(self, method, path, body=None, upload=None):
        prefix = 'upload/androidpublisher' if upload else 'androidpublisher'
        url = f'https://androidpublisher.googleapis.com/{prefix}/v3/applications/{PACKAGE}/{path}'
        if upload:
            with open(upload, 'rb') as stream:
                reply = self.session.request(method, url, data=stream,
                    headers={'Content-Type': 'application/octet-stream'}, timeout=600)
        else:
            reply = self.session.request(method, url, json=body, timeout=90)
        if not reply.ok:
            try:
                error = reply.json()['error']
                reason = next((d.get('reason') for d in error.get('details', []) if d.get('reason')), None)
                message = error.get('message', '')
                if not reason and 'changesNotSentForReview must not be set' in message:
                    reason = 'REVIEW_PARAMETER_NOT_ALLOWED'
                if not reason and 'changes in review' in message.lower():
                    reason = 'CHANGES_ALREADY_IN_REVIEW'
                if not reason and 'HALTED release must have fraction' in message:
                    reason = 'EXISTING_TRACK_STATE_REQUIRES_CONSOLE'
            except (ValueError, KeyError):
                reason = None
            raise PlayError(reply.status_code, reason or 'REQUEST_REJECTED')
        return reply.json() if reply.content else {}


def publish(api, aab, version_code, version_name, mode, track=None, notes=None, checkpoint=None):
    if mode not in ('artifact_only', 'closed_testing'):
        raise ValueError('Unsupported operation')
    if (mode == 'closed_testing' and track not in ('alpha', 'beta')) or (mode == 'artifact_only' and track is not None):
        raise ValueError('Only an explicitly selected closed track may change')
    if not 0 < version_code <= 2100000000 or not version_name or not aab.is_file():
        raise ValueError('Invalid artifact identity')
    if mode == 'closed_testing' and (not notes or any(not n.get('text') or len(n['text']) > 500 for n in notes)):
        raise ValueError('Localized release notes are required (maximum 500 characters per locale)')
    digest = hashlib.sha256(aab.read_bytes()).hexdigest()
    edit = api.call('POST', 'edits', {})['id']
    commit_started = False
    result = {'operation': mode, 'versionCode': version_code, 'versionName': version_name, 'sha256': digest, 'editId': edit}
    record = checkpoint or (lambda value: None)
    record(dict(result, state='staging'))
    try:
        before = api.call('GET', f'edits/{edit}/tracks').get('tracks', [])
        bundles = api.call('GET', f'edits/{edit}/bundles').get('bundles', [])
        existing = next((b for b in bundles if b['sha256'].lower() == digest), None)
        if existing and int(existing['versionCode']) != version_code:
            raise ValueError('Bundle identity differs from the selected APK')
        if mode == 'closed_testing':
            current = next((t for t in before if t['track'] == track), None)
            if current is None:
                raise ValueError('Selected closed track does not already exist')
            assigned = [int(c) for release in current.get('releases', []) for c in release.get('versionCodes', [])]
            if assigned and max(assigned) > version_code:
                raise ValueError('Refusing to downgrade the selected track')
            wanted = {'track': track, 'releases': [{'name': f'{version_name} ({version_code})',
                'versionCodes': [str(version_code)], 'status': 'completed', 'releaseNotes': notes}]}
            if existing and current == wanted:
                api.call('DELETE', f'edits/{edit}')
                return dict(result, state='already_configured', track=track)
        if existing and mode == 'artifact_only':
            api.call('DELETE', f'edits/{edit}')
            return dict(result, state='already_uploaded')
        if not existing:
            if version_code <= max((int(b['versionCode']) for b in bundles), default=0):
                raise ValueError('Version code must exceed all uploaded bundles')
            bundle = api.call('POST', f'edits/{edit}/bundles?uploadType=media', upload=aab)
            if int(bundle['versionCode']) != version_code or bundle['sha256'].lower() != digest:
                raise ValueError('Uploaded bundle hash or version code mismatch')
        if mode == 'closed_testing':
            api.call('PUT', f'edits/{edit}/tracks/{track}', wanted)
        after = api.call('GET', f'edits/{edit}/tracks').get('tracks', [])
        untouched = lambda tracks: sorted((t for t in tracks if mode == 'artifact_only' or t['track'] != track), key=lambda t: t['track'])
        if untouched(before) != untouched(after):
            raise ValueError('An unrequested track changed')
        api.call('POST', f'edits/{edit}:validate')
        commit_started = True
        record(dict(result, state='commit_pending'))
        suffix = '?changesInReviewBehavior=ERROR_IF_IN_REVIEW'
        if mode == 'artifact_only':
            suffix += '&changesNotSentForReview=true'
        try:
            api.call('POST', f'edits/{edit}:commit{suffix}')
        except PlayError as error:
            if mode == 'artifact_only' and error.reason == 'REVIEW_PARAMETER_NOT_ALLOWED':
                api.call('POST', f'edits/{edit}:commit?changesInReviewBehavior=ERROR_IF_IN_REVIEW')
            else:
                raise
        # Independent post-commit read. Never re-run upload/signing after an uncertain commit.
        verify = api.call('POST', 'edits', {})['id']
        try:
            live_bundles = api.call('GET', f'edits/{verify}/bundles').get('bundles', [])
            if not any(int(b['versionCode']) == version_code and b['sha256'].lower() == digest for b in live_bundles):
                raise ValueError('Post-commit artifact verification failed')
            live_tracks = api.call('GET', f'edits/{verify}/tracks').get('tracks', [])
            if untouched(before) != untouched(live_tracks):
                raise ValueError('Post-commit unrequested track drift')
            if mode == 'closed_testing' and next((t for t in live_tracks if t['track'] == track), None) != wanted:
                raise ValueError('Post-commit closed track verification failed')
        finally:
            api.call('DELETE', f'edits/{verify}')
        return dict(result, state='submitted' if mode == 'closed_testing' else 'uploaded', track=track)
    except PlayError as error:
        if error.reason == 'CHANGES_ALREADY_IN_REVIEW':
            api.call('DELETE', f'edits/{edit}')
            return dict(result, state='deferred_review', track=track)
        record(dict(result, state='outcome_unknown' if commit_started else 'stopped', reason=error.reason))
        if not commit_started:
            api.call('DELETE', f'edits/{edit}')
        raise
    except Exception:
        record(dict(result, state='outcome_unknown' if commit_started else 'stopped'))
        if not commit_started:
            api.call('DELETE', f'edits/{edit}')
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--aab', type=Path, required=True)
    parser.add_argument('--version-code', type=int, required=True)
    parser.add_argument('--version-name', required=True)
    parser.add_argument('--operation', choices=['artifact_only', 'closed_testing'], required=True)
    parser.add_argument('--track', choices=['alpha', 'beta'])
    parser.add_argument('--notes', type=Path, help='JSON releaseNotes array; otherwise use the shared catalog')
    parser.add_argument('--result', type=Path, required=True)
    args = parser.parse_args()
    notes = None
    if args.operation == 'closed_testing':
        if args.notes:
            notes = json.loads(args.notes.read_text())
        else:
            catalog = json.loads((Path(__file__).resolve().parents[1] / 'localization/catalog.json').read_text())['storeMetadata']
            notes = [{'language': locale, 'text': catalog[lang]['releaseNotesByPlatform']['android']}
                     for lang, locale in [('en', 'en-US'), ('ro', 'ro-RO'), ('ru', 'ru-RU')]]
    api = PlayAPI(json.loads(os.environ['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON']))
    result = publish(api, args.aab, args.version_code, args.version_name, args.operation, args.track, notes,
        checkpoint=lambda value: args.result.write_text(json.dumps(value, indent=2) + '\n'))
    args.result.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
    if result['state'] == 'deferred_review':
        print('::warning::Existing Play review preserved. Nothing was submitted; rerun after review completes.')
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a') as out:
            out.write(f"## Play result: {result['state']}\n\nVersion: {args.version_name} ({args.version_code})\n\n")
            out.write('Submitted is not approved or available to testers. Verify Publishing overview.\n')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Never print auth responses, environment values, provider JSON, or a traceback containing credentials.
        print(f'Publishing stopped: {error if isinstance(error, (PlayError, ValueError)) else type(error).__name__}', file=sys.stderr)
        sys.exit(1)
