#!/usr/bin/env python3
"""Check Store publishing authentication without creating or changing submissions."""
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid


def main():
    names = ('MSSTORE_TENANT_ID', 'MSSTORE_SELLER_ID', 'MSSTORE_CLIENT_ID', 'MSSTORE_CLIENT_SECRET')
    credentials = {name: os.environ.get(name, '').strip() for name in names}
    missing = [name for name, value in credentials.items() if not value]
    if missing:
        raise ValueError('Missing credentials: ' + ', '.join(missing))
    for name in ('MSSTORE_TENANT_ID', 'MSSTORE_CLIENT_ID'):
        uuid.UUID(credentials[name])
    if not credentials['MSSTORE_SELLER_ID'].isascii() or not credentials['MSSTORE_SELLER_ID'].isdigit():
        raise ValueError('MSSTORE_SELLER_ID must be a numeric seller account ID')
    body = urllib.parse.urlencode({
        'grant_type': 'client_credentials',
        'client_id': credentials['MSSTORE_CLIENT_ID'],
        'client_secret': credentials['MSSTORE_CLIENT_SECRET'],
        'resource': 'https://manage.devcenter.microsoft.com',
    }).encode()
    request = urllib.request.Request(
        'https://login.microsoftonline.com/' + credentials['MSSTORE_TENANT_ID'] + '/oauth2/token', data=body)
    with urllib.request.urlopen(request, timeout=30) as response:
        access_token = json.load(response)['access_token']
    request = urllib.request.Request(
        'https://manage.devcenter.microsoft.com/v1.0/my/applications/9PDPR6RNT42S',
        headers={'Authorization': 'Bearer ' + access_token})
    with urllib.request.urlopen(request, timeout=30) as response:
        app = json.load(response)
    if app.get('id') != '9PDPR6RNT42S':
        raise ValueError('Store API returned an unexpected application')
    print('Store credentials validated: eSemnBun (9PDPR6RNT42S). No submissions changed.')


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f'Microsoft Store credential check failed: HTTP {error.code}.', file=sys.stderr)
        sys.exit(1)
    except (ValueError, KeyError, urllib.error.URLError, TimeoutError):
        # Never print a token response, request body, client secret or access token.
        print('Microsoft Store credential check failed; check credential configuration and connectivity.', file=sys.stderr)
        sys.exit(1)
