#!/usr/bin/env python3
"""Inspect, prepare or submit an App Store version for an already processed build.

status   read-only: build processing, version state, attached build and open review submissions.
prepare  create or reuse the editable version, set What's New for every existing localization from
         distribution/apple/<platform>/<locale>/release_notes.txt and attach the build. No submission.
submit   prepare, then add the version to a review submission and submit it for App Review.

Never uploads binaries, edits other metadata or screenshots, or cancels/replaces an existing review.
A new version inherits the release type (manual or after approval) of the previous version.
"""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import time

API = 'https://api.appstoreconnect.apple.com'
APPS = {'ios': ('6826865290', 'IOS'), 'macos': ('6829451042', 'MAC_OS')}
OPERATIONS = ('status', 'prepare', 'submit')
EDITABLE = {'PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED',
            'INVALID_BINARY'}
REVIEWING = {'WAITING_FOR_REVIEW', 'IN_REVIEW'}
LIVE = {'READY_FOR_DISTRIBUTION', 'READY_FOR_SALE'}
# Submitted or approved and not yet live: no other version may be created meanwhile.
PENDING = REVIEWING | {'ACCEPTED', 'PENDING_DEVELOPER_RELEASE', 'PENDING_APPLE_RELEASE', 'PROCESSING_FOR_DISTRIBUTION',
                       'WAITING_FOR_EXPORT_COMPLIANCE'}
OPEN_SUBMISSION = ('READY_FOR_REVIEW', 'UNRESOLVED_ISSUES')
BUSY_SUBMISSION = ('WAITING_FOR_REVIEW', 'IN_REVIEW', 'CANCELING', 'COMPLETING')
NOTES_ROOT = Path(__file__).resolve().parents[1] / 'distribution/apple'


class ASCError(Exception):
    def __init__(self, status, code, detail=''):
        self.status, self.code, self.detail = status, code, detail
        super().__init__(f'App Store Connect {status}: {code}' + (f' ({detail})' if detail else ''))


class ASC:
    def __init__(self, key_id, issuer_id, private_key, session=None):
        import jwt
        now = int(time.time())
        # Apple refuses tokens valid for more than 20 minutes.
        token = jwt.encode({'iss': issuer_id, 'iat': now, 'exp': now + 1100, 'aud': 'appstoreconnect-v1'},
                           private_key, algorithm='ES256', headers={'kid': key_id, 'typ': 'JWT'})
        if session is None:
            import requests
            session = requests.Session()
        self.session = session
        self.session.headers['Authorization'] = 'Bearer ' + token

    def call(self, method, path, body=None, params=None):
        reply = self.session.request(method, API + path, json=body, params=params, timeout=60)
        if not reply.ok:
            try:
                error = reply.json()['errors'][0]
                code, detail = error.get('code', 'REQUEST_REJECTED'), str(error.get('detail', ''))[:300]
            except (ValueError, KeyError, IndexError, TypeError):
                code, detail = 'REQUEST_REJECTED', ''
            raise ASCError(reply.status_code, code, detail)
        return reply.json() if reply.content else {}

    def get(self, path, **params):
        return self.call('GET', path, params=params or None)


def state_of(version):
    attributes = version['attributes']
    return attributes.get('appVersionState') or attributes.get('appStoreState')


def version_key(text):
    return tuple(int(part) for part in text.split('.'))


def release_notes(root, platform, locale):
    path = root / platform / locale / 'release_notes.txt'
    if not path.is_file():
        raise ValueError(f'No release notes for {platform} locale {locale} ({path.relative_to(root.parent.parent)})')
    text = path.read_text(encoding='utf-8').strip()
    if not 0 < len(text) <= 4000:
        raise ValueError(f'Release notes for {platform} {locale} must be 1-4000 characters')
    return text


def run(api, platform, version, build_number, operation, notes_root=NOTES_ROOT, checkpoint=None, sleep=time.sleep):
    if platform not in APPS or operation not in OPERATIONS:
        raise ValueError('Unsupported platform or operation')
    if not re.fullmatch(r'\d+\.\d+(\.\d+)?', version or '') or not re.fullmatch(r'[1-9]\d{0,8}', build_number or ''):
        raise ValueError('Version must be x.y[.z] and build a positive integer')
    app, store_platform = APPS[platform]
    result = {'platform': platform, 'version': version, 'build': build_number, 'operation': operation}
    record = checkpoint or (lambda value: None)
    mutated = submit_sent = False

    def finish(**values):
        record(dict(result, **values))
        return dict(result, **values)

    try:
        # 1. The exact processed build.
        builds = api.get('/v1/builds', **{'filter[app]': app, 'filter[version]': build_number,
                                          'filter[preReleaseVersion.version]': version, 'limit': 5})['data']
        if len(builds) > 1:
            raise ValueError(f'Several builds match {version} ({build_number})')
        build = builds[0] if builds else None
        build_state = build['attributes']['processingState'] if build else 'NOT_FOUND'
        result.update(buildId=build and build['id'], buildState=build_state)

        # 2. The App Store version and the others that could conflict with it.
        versions = api.get(f'/v1/apps/{app}/appStoreVersions', **{'filter[platform]': store_platform, 'limit': 50})['data']
        target = next((v for v in versions if v['attributes']['versionString'] == version), None)
        attached = None
        if target:
            attached = (api.get(f"/v1/appStoreVersions/{target['id']}/build").get('data') or {}).get('id')
            result.update(versionId=target['id'], versionState=state_of(target), attachedBuildId=attached)
        submissions = api.get('/v1/reviewSubmissions', **{'filter[app]': app, 'filter[platform]': store_platform,
            'filter[state]': ','.join(OPEN_SUBMISSION + BUSY_SUBMISSION), 'limit': 10})['data']
        result['openSubmissions'] = [{'id': s['id'], 'state': s['attributes']['state']} for s in submissions]

        if operation == 'status':
            return finish(state='status')
        if build_state != 'VALID' or build['attributes'].get('expired'):
            raise ValueError(f'Build {build_number} is {build_state}; App Review needs a processed, unexpired build')
        if build['attributes'].get('usesNonExemptEncryption') is None:
            raise ValueError('The build has no export-compliance answer; set it explicitly before submission')

        if target and state_of(target) in PENDING | LIVE:
            if attached == build['id']:
                return finish(state='already_submitted')
            raise ValueError(f'Version {version} is {state_of(target)} with another build; not replacing it')

        # 3. Create or reuse the editable version.
        if target is None:
            others = [v for v in versions if state_of(v) in EDITABLE | PENDING]
            if others:
                raise ValueError(f"Version {others[0]['attributes']['versionString']} is {state_of(others[0])}; "
                                 'finish or remove it before creating another')
            previous = max(versions, key=lambda v: version_key(v['attributes']['versionString']), default=None)
            if previous and version_key(previous['attributes']['versionString']) >= version_key(version):
                raise ValueError(f"Version {version} is not newer than {previous['attributes']['versionString']}")
            release_type = (previous or {}).get('attributes', {}).get('releaseType')
            if release_type not in ('MANUAL', 'AFTER_APPROVAL'):
                release_type = 'MANUAL'  # a scheduled date is never carried over
            mutated = True
            record(dict(result, state='creating_version'))
            target = api.call('POST', '/v1/appStoreVersions', {'data': {'type': 'appStoreVersions',
                'attributes': {'platform': store_platform, 'versionString': version, 'releaseType': release_type},
                'relationships': {'app': {'data': {'type': 'apps', 'id': app}}}}})['data']
            attached = None
            result.update(versionId=target['id'], versionState=state_of(target), releaseType=release_type)
        elif state_of(target) not in EDITABLE:
            raise ValueError(f'Version {version} is {state_of(target)}; not editable')
        result.setdefault('releaseType', target['attributes'].get('releaseType'))
        version_id = target['id']

        # 4. What's New for every localization the version has, from the committed notes.
        localizations = api.get(f'/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations', limit=50)['data']
        if not localizations:
            raise ValueError(f'Version {version} has no localizations')
        wanted = {loc['id']: release_notes(notes_root, platform, loc['attributes']['locale']) for loc in localizations}
        for loc in localizations:
            if loc['attributes'].get('whatsNew') != wanted[loc['id']]:
                mutated = True
                api.call('PATCH', f"/v1/appStoreVersionLocalizations/{loc['id']}", {'data': {
                    'type': 'appStoreVersionLocalizations', 'id': loc['id'], 'attributes': {'whatsNew': wanted[loc['id']]}}})
        result['locales'] = sorted(loc['attributes']['locale'] for loc in localizations)

        # 5. Attach the build and read the relationship back.
        if attached != build['id']:
            mutated = True
            api.call('PATCH', f'/v1/appStoreVersions/{version_id}/relationships/build',
                     {'data': {'type': 'builds', 'id': build['id']}})
        confirmed = (api.get(f'/v1/appStoreVersions/{version_id}/build').get('data') or {}).get('id')
        if confirmed != build['id']:
            raise ValueError('Build attachment was not confirmed')
        result['attachedBuildId'] = confirmed
        if operation == 'prepare':
            return finish(state='prepared')

        # 6. One review submission holding only this version; never replace an active review.
        active = [s for s in submissions if s['attributes']['state'] in BUSY_SUBMISSION]
        if active:
            raise ValueError(f"Submission {active[0]['id']} is already {active[0]['attributes']['state']}; not replacing it")
        open_ones = [s for s in submissions if s['attributes']['state'] in OPEN_SUBMISSION]
        if len(open_ones) > 1:
            raise ValueError('Several open review submissions exist; resolve them in App Store Connect')
        if open_ones:
            submission = open_ones[0]
            items = api.get(f"/v1/reviewSubmissions/{submission['id']}/items", include='appStoreVersion', limit=50)['data']
            versions_in = [(i.get('relationships', {}).get('appStoreVersion', {}).get('data') or {}).get('id') for i in items]
            if any(v != version_id for v in versions_in):
                raise ValueError(f"Open submission {submission['id']} holds other items; resolve it in App Store Connect")
        else:
            mutated = True
            submission = api.call('POST', '/v1/reviewSubmissions', {'data': {'type': 'reviewSubmissions',
                'attributes': {'platform': store_platform}, 'relationships': {'app': {'data': {'type': 'apps', 'id': app}}}}})['data']
            versions_in = []
        result['submissionId'] = submission['id']
        if version_id not in versions_in:
            mutated = True
            api.call('POST', '/v1/reviewSubmissionItems', {'data': {'type': 'reviewSubmissionItems', 'relationships': {
                'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': submission['id']}},
                'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}}}})
        mutated = submit_sent = True
        record(dict(result, state='submit_pending'))
        api.call('PATCH', f"/v1/reviewSubmissions/{submission['id']}", {'data': {'type': 'reviewSubmissions',
            'id': submission['id'], 'attributes': {'submitted': True}}})

        # 7. Independent read-back; Apple can take a moment to move the version.
        for attempt in range(12):
            submission_state = api.get(f"/v1/reviewSubmissions/{submission['id']}")['data']['attributes']['state']
            version_state = state_of(api.get(f'/v1/appStoreVersions/{version_id}')['data'])
            result.update(submissionState=submission_state, versionState=version_state)
            if submission_state in REVIEWING and version_state in REVIEWING:
                return finish(state='submitted')
            if attempt < 11:
                sleep(10)
        return finish(state='outcome_unknown')
    except Exception as error:
        # A rejected request changed nothing; a timeout after the submit request may have submitted.
        uncertain = submit_sent and not (isinstance(error, ASCError) and 400 <= error.status < 500)
        record(dict(result, state='outcome_unknown' if uncertain else 'stopped', changesMade=mutated,
                    reason=str(error) if isinstance(error, (ASCError, ValueError)) else type(error).__name__))
        raise


def credentials():
    key = os.environ.get('ASC_KEY_P8') or ''
    if not key and os.environ.get('ASC_KEY_PATH'):
        key = Path(os.environ['ASC_KEY_PATH']).expanduser().read_text()
    if '\n' not in key.strip():
        key = key.replace('\\n', '\n')  # a PEM pasted with escaped line breaks
    key_id, issuer = os.environ.get('ASC_KEY_ID'), os.environ.get('ASC_ISSUER_ID')
    if not (key_id and issuer and key):
        raise ValueError('Set ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_P8 (or ASC_KEY_PATH)')
    return key_id, issuer, key


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--platform', choices=sorted(APPS), required=True)
    parser.add_argument('--version', required=True, help='Marketing version of the build, e.g. 0.2.15')
    parser.add_argument('--build', required=True, help='Build number already uploaded and processed')
    parser.add_argument('--operation', choices=OPERATIONS, default='status')
    parser.add_argument('--result', type=Path, help='Write the result (and checkpoints) as JSON here')
    args = parser.parse_args()
    write = (lambda value: args.result.write_text(json.dumps(value, indent=2) + '\n')) if args.result else None
    result = run(ASC(*credentials()), args.platform, args.version, args.build, args.operation, checkpoint=write)
    print(json.dumps(result))
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a') as out:
            out.write(f"## App Store {args.platform}: {result['state']}\n\n"
                      f"Version {args.version} build {args.build}: version {result.get('versionState')}, "
                      f"build {result.get('buildState')}.\n\n")
            if result['state'] in ('submitted', 'already_submitted'):
                out.write('Waiting for review is not approval or release. Check App Store Connect for the review result.\n')
    if result['state'] == 'outcome_unknown':
        print('::error::Submitted, but App Store Connect did not confirm the review state. Run status before retrying.')
        sys.exit(1)


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Never print tokens, key material or a traceback that may contain them.
        print(f'App Store submission stopped: {error if isinstance(error, (ASCError, ValueError)) else type(error).__name__}',
              file=sys.stderr)
        sys.exit(1)
