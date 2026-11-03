#!/usr/bin/env python3
"""Upload a signed Android APK to AppGallery and submit its existing listing."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import sys
import time

import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

BASE = 'https://connect-api.cloud.huawei.com/api/publish/v2/'
APP_ID = '119651007'


def token(account):
    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value).encode()).rstrip(b'=')
    now = int(time.time())
    data = encode({'alg': 'PS256', 'typ': 'JWT', 'kid': account['key_id']}) + b'.' + encode({
        'iss': account['sub_account'], 'aud': 'https://oauth-login.cloud.huawei.com/oauth2/v3/token',
        'iat': now, 'exp': now + 3600})
    raw = account['private_key'].encode()
    key = (serialization.load_pem_private_key(raw, None) if b'BEGIN' in raw
           else serialization.load_der_private_key(base64.b64decode(raw), None))
    signature = key.sign(data, padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32), hashes.SHA256())
    return (data + b'.' + base64.urlsafe_b64encode(signature).rstrip(b'=')).decode()


class Gallery:
    def __init__(self, account):
        self.session = requests.Session()
        self.session.headers['Authorization'] = 'Bearer ' + token(account)

    def call(self, method, route, body=None, **query):
        response = self.session.request(method, BASE + route,
                                        params={'appId': APP_ID, **query}, json=body, timeout=90)
        response.raise_for_status()
        result = response.json()
        ret = result.get('ret', {})
        if isinstance(ret, str):
            ret = json.loads(ret)
        if str(ret.get('code')) != '0':
            raise RuntimeError(f"{route}: Huawei code {ret.get('code')}: {ret.get('msg')}")
        return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path)
    parser.add_argument('--version-code', type=int)
    parser.add_argument('--check', action='store_true', help='Read-only API authentication check')
    args = parser.parse_args()
    credential = os.environ['HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON']
    account = json.loads(credential if credential.lstrip().startswith('{') else Path(credential).read_text())
    gallery = Gallery(account)
    info = gallery.call('GET', 'app-info', lang='en-US')
    app = info['appInfo']
    print(json.dumps({k: v for k, v in app.items() if k in
                      ('appId', 'packageName', 'versionCode', 'versionName', 'releaseState', 'appName')}))
    if args.check:
        return
    if not args.apk or not args.version_code or args.apk.suffix != '.apk':
        parser.error('--apk and --version-code are required for publishing')
    current = int(app.get('versionCode') or 0)
    if current >= args.version_code:
        print(f'Build {args.version_code} already uploaded or superseded; no submission needed.')
        return
    # Never cancel an active review to replace its binary.
    if str(app.get('releaseState')) == '4':
        raise RuntimeError('Huawei has an active review. Retry after the current review finishes.')
    upload = gallery.call('GET', 'upload-url', suffix='apk')
    with args.apk.open('rb') as binary:
        response = requests.post(upload['uploadUrl'], data={'authCode': upload['authCode']},
                                 files={'file': (args.apk.name, binary, 'application/vnd.android.package-archive')},
                                 timeout=600)
    response.raise_for_status()
    uploaded = response.json()
    file_info = uploaded['result']['UploadFileRsp']['fileInfoList'][0]
    gallery.call('PUT', 'app-file-info', body={'fileType': 5, 'files': [
        {'fileName': file_info['fileName'], 'fileDestUrl': file_info['fileDestUlr']} ]})
    print('APK uploaded; waiting for Huawei package parsing.')
    time.sleep(120)
    parsed = gallery.call('GET', 'app-info', lang='en-US')['appInfo']
    if int(parsed.get('versionCode') or 0) != args.version_code:
        raise RuntimeError('Huawei has not attached the expected version code; refusing to submit another binary.')
    gallery.call('POST', 'app-submit', body={'releaseType': 1})
    for _ in range(12):
        state = gallery.call('GET', 'app-info', lang='en-US')['appInfo']
        if str(state.get('releaseState')) == '4':
            break
        time.sleep(10)
    else:
        raise RuntimeError('Huawei accepted submission but review state was not confirmed; inspect the portal before retrying.')
    print(f'Submitted build {args.version_code}; SHA256={hashlib.sha256(args.apk.read_bytes()).hexdigest()}')


if __name__ == '__main__':
    try:
        main()
    except requests.RequestException:
        # Signed upload URLs and authorization codes must not appear in CI logs.
        print('AppGallery HTTP request failed; check Huawei service status and credential permissions.', file=sys.stderr)
        sys.exit(1)
    except (RuntimeError, KeyError, ValueError) as error:
        print(f'AppGallery: {error}', file=sys.stderr)
        sys.exit(1)
