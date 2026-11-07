#!/usr/bin/env python3
"""Inspect or stage screenshots and an optional MSIX in an editable Store draft.

Never creates, commits, publishes or cancels a submission. Credentials come from
MSSTORE_* environment variables or an owner-controlled JSON file outside git.
"""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
import xml.etree.ElementTree as ET

APP = '9PDPR6RNT42S'
BASE = 'https://manage.devcenter.microsoft.com/v1.0/my/'


def inspect_package(path, expected_version, expected_sha256):
    """Validate identity and expected bytes; signature trust is checked by release CI."""
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest.lower() != expected_sha256.lower():
        raise ValueError('MSIX checksum differs from expected release artifact')
    with zipfile.ZipFile(io.BytesIO(data)) as package:
        if 'AppxSignature.p7x' not in package.namelist():
            raise ValueError('MSIX has no signature file')
        root = ET.fromstring(package.read('AppxManifest.xml'))
    identity = root.find('{http://schemas.microsoft.com/appx/manifest/foundation/windows10}Identity')
    if identity is None:
        raise ValueError('MSIX identity is missing')
    info = identity.attrib
    if info.get('Name') != 'NicolaeGhimbovschi.eSemnBun' or info.get('Publisher') != 'CN=3AAF334E-BE21-4B3F-8FDE-FBEDDF7498EE':
        raise ValueError('MSIX identity does not match the Store app')
    if info.get('Version') != expected_version:
        raise ValueError('MSIX version differs from expected release version')
    version = tuple(int(part) for part in expected_version.split('.'))
    if len(version) != 4 or any(part < 0 or part > 65535 for part in version):
        raise ValueError('Expected version must be four valid MSIX version components')
    return data, info, digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--credentials', type=Path)
    parser.add_argument('--assets', type=Path, default=Path(__file__).resolve().parents[1] / 'microsoft/assets')
    parser.add_argument('--submission', help='Exact pending draft ID required for upload')
    parser.add_argument('--package', type=Path, help='Signed MSIX to include with screenshots')
    parser.add_argument('--expected-version', help='Exact MSIX identity version, for example 1.2.205.0')
    parser.add_argument('--expected-sha256', help='Expected release artifact SHA-256')
    parser.add_argument('--upload', action='store_true', help='Upload the prepared archive; leave draft uncommitted')
    args = parser.parse_args()
    package_options = (args.package, args.expected_version, args.expected_sha256)
    if any(package_options) and not all(package_options):
        parser.error('--package requires --expected-version and --expected-sha256 together')
    package = inspect_package(args.package, args.expected_version, args.expected_sha256) if args.package else None
    credentials = json.loads(args.credentials.read_text()) if args.credentials else os.environ
    body = urllib.parse.urlencode({
        'grant_type': 'client_credentials', 'client_id': credentials['MSSTORE_CLIENT_ID'],
        'client_secret': credentials['MSSTORE_CLIENT_SECRET'],
        'resource': 'https://manage.devcenter.microsoft.com',
    }).encode()
    request = urllib.request.Request('https://login.microsoftonline.com/' + credentials['MSSTORE_TENANT_ID'] + '/oauth2/token', data=body)
    with urllib.request.urlopen(request, timeout=30) as response:
        token = json.load(response)['access_token']

    def api(path, payload=None):
        headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}
        request = urllib.request.Request(BASE + path, headers=headers,
            data=json.dumps(payload).encode() if payload is not None else None,
            method='PUT' if payload is not None else 'GET')
        with urllib.request.urlopen(request, timeout=120) as response:
            return json.load(response)

    app = api('applications/' + APP)
    pending = app.get('pendingApplicationSubmission')
    if not pending:
        raise ValueError('No pending submission; create the replacement draft separately')
    submission_id = pending['id']
    if args.submission and args.submission != submission_id:
        raise ValueError('Pending submission differs from requested ID')
    endpoint = f'applications/{APP}/submissions/{submission_id}'
    submission = api(endpoint)
    print(json.dumps({key: submission.get(key) for key in
        ('id', 'status', 'targetPublishMode', 'targetPublishDate', 'statusDetails')}, ensure_ascii=False))
    if not args.upload and not package:
        return
    if not args.submission or submission['status'] != 'PendingCommit':
        raise ValueError('Staging requires an exact submission ID and PendingCommit status')
    # Uploading a new ZIP replaces the ingestion archive; do not discard another
    # uploader's package/trailer/image files that have not finished ingestion.
    if any(item.get('fileStatus') == 'PendingUpload' for item in submission.get('applicationPackages', [])):
        raise ValueError('Pending package upload: combine packages and images in one archive instead')
    if submission.get('trailers'):
        raise ValueError('Trailer assets require a combined archive; refusing screenshot-only upload')
    def has_pending_upload(value):
        if isinstance(value, dict):
            return value.get('fileStatus') == 'PendingUpload' or any(has_pending_upload(item) for item in value.values())
        return isinstance(value, list) and any(has_pending_upload(item) for item in value)
    if has_pending_upload(submission):
        raise ValueError('Existing pending upload found; inspect all draft assets before replacement')
    archive = io.BytesIO()
    expected = {}
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        package_name = None
        if package:
            data, identity, digest = package
            architecture = identity.get('ProcessorArchitecture', 'neutral').lower()
            old_packages = submission.get('applicationPackages', [])
            version = tuple(int(part) for part in identity['Version'].split('.'))
            for old in old_packages:
                if old.get('fileStatus') == 'PendingDelete':
                    continue
                old_version = tuple(int(part) for part in old['version'].split('.'))
                if version <= old_version:
                    raise ValueError('Replacement MSIX must exceed every retained package version')
                if old.get('architecture', '').lower() == architecture:
                    old['fileStatus'] = 'PendingDelete'
            package_name = 'esemnbun-' + identity['Version'] + '-' + digest[:12] + '.msix'
            zip_file.writestr(package_name, data, compress_type=zipfile.ZIP_STORED)
            old_packages.append({'fileName': package_name, 'fileStatus': 'PendingUpload'})
            submission['applicationPackages'] = old_packages
        for locale, language in [('en-us', 'en'), ('ro-ro', 'ro'), ('ru-ru', 'ru')]:
            listing = submission['listings'][locale]['baseListing']
            images = listing.get('images', [])
            if any(image.get('fileStatus') == 'PendingUpload' for image in images):
                raise ValueError('Pending image upload found; inspect draft before replacing it')
            paths = sorted((args.assets / language).glob('*.png'))
            captions = json.loads((args.assets / language / 'captions.json').read_text())
            if len(paths) != 4 or len(captions) != 4:
                raise ValueError('Expected four screenshots and captions for ' + locale)
            for image in images:
                if image.get('imageType') == 'Screenshot':
                    image['fileStatus'] = 'PendingDelete'
            expected[locale] = []
            for path, caption in zip(paths, captions):
                data = path.read_bytes()
                name = language + '-' + hashlib.sha256(data).hexdigest()[:12] + '-' + path.name
                zip_file.writestr(name, data)
                images.append({'fileName': name, 'fileStatus': 'PendingUpload',
                    'imageType': 'Screenshot', 'description': caption})
                expected[locale].append(name)
            listing['images'] = images
    summary = {'submission': submission_id, 'screenshots': 12,
        'package': package_name, 'packageVersion': args.expected_version,
        'packageSha256': args.expected_sha256, 'archiveBytes': archive.tell()}
    if not args.upload:
        print(json.dumps(dict(summary, result='prepared in memory; no Store changes')))
        return
    updated = api(endpoint, submission)
    url = updated['fileUploadUrl']
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != 'https' or not parsed.hostname.endswith('.blob.core.windows.net'):
        raise ValueError('Unexpected upload URL origin')
    request = urllib.request.Request(url, data=archive.getvalue(), method='PUT',
        headers={'x-ms-blob-type': 'BlockBlob', 'x-ms-version': '2021-12-02', 'Content-Type': 'application/zip'})
    with urllib.request.urlopen(request, timeout=180) as response:
        if response.status not in (200, 201):
            raise ValueError('Image archive upload failed')
    verified = api(endpoint)
    if package_name and not any(item.get('fileName') == package_name and item.get('fileStatus') != 'PendingDelete'
                               for item in verified.get('applicationPackages', [])):
        raise ValueError('Draft package read-back differs from uploaded archive')
    for locale, names in expected.items():
        actual = [image['fileName'] for image in verified['listings'][locale]['baseListing']['images']
                  if image.get('imageType') == 'Screenshot' and image.get('fileStatus') != 'PendingDelete']
        if sorted(actual) != sorted(names):
            raise ValueError('Draft screenshot read-back differs for ' + locale)
    print(json.dumps(dict(summary, result='archive uploaded and draft references verified; not committed')))


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as error:
        sys.exit(f'Microsoft Store HTTP {error.code}; inspect current draft before retrying')
    except (ValueError, KeyError, OSError, zipfile.BadZipFile, ET.ParseError) as error:
        # Do not print raw request/response exceptions: upload URLs carry SAS keys.
        sys.exit('Microsoft screenshot operation stopped: ' + (str(error) if isinstance(error, ValueError) else type(error).__name__))
