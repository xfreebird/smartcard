#!/usr/bin/env python3
"""Snapshot actual published release assets for the static downloads page."""
import argparse
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('release', type=Path, help='GitHub releases/latest API response')
parser.add_argument('--out', type=Path, default=Path(__file__).resolve().parents[1] / 'src/data/release.json')
args = parser.parse_args()
release = json.loads(args.release.read_text())
version = release['tag_name'].removeprefix('v')
if not re.fullmatch(r'\d+\.\d+\.\d+', version) or release.get('draft') or release.get('prerelease'):
    parser.error('Expected a published stable x.y.z release')
assets = []
prefix = f'https://github.com/xfreebird/smartcard/releases/download/{release["tag_name"]}/'
for asset in release['assets']:
    url = asset['browser_download_url']
    if not url.startswith(prefix):
        parser.error('Unexpected release asset host or tag')
    assets.append({'name': asset['name'], 'url': url, 'size': asset['size']})
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps({'version': version, 'url': release['html_url'], 'assets': assets}, indent=2) + '\n')
