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
def family(name):
    if name.endswith('.dmg'): return 'macos'
    if name.endswith('.msi'): return 'windows'
    if name.endswith('.apk'): return 'android'
    if name.endswith('.flatpak'): return 'flatpak'
    if name.endswith(('.deb', '.rpm', '.tar.gz')): return 'linux'
    return None

previous = json.loads(args.out.read_text()) if args.out.exists() else {'assets': []}
assets = []
prefix = f'https://github.com/xfreebird/smartcard/releases/download/{release["tag_name"]}/'
for asset in release['assets']:
    url = asset['browser_download_url']
    if not url.startswith(prefix):
        parser.error('Unexpected release asset host or tag')
    assets.append({'name': asset['name'], 'url': url, 'size': asset['size']})
# Keep a working previous installer when a platform did not build in this release.
current_families = {family(asset['name']) for asset in assets}
assets.extend(asset for asset in previous['assets']
              if family(asset['name']) and family(asset['name']) not in current_families)
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps({'version': version, 'url': release['html_url'], 'assets': assets}, indent=2) + '\n')
