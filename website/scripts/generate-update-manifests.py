#!/usr/bin/env python3
"""Write the stable standalone-desktop update channel from a published release tag."""
import argparse
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--version', required=True)
parser.add_argument('--release-data', type=Path)
parser.add_argument('--out', type=Path, default=Path(__file__).resolve().parents[1] / 'static/updates')
args = parser.parse_args()
version = args.version.removeprefix('v')
if not re.fullmatch(r'\d+\.\d+\.\d+', version):
    parser.error('Use a stable x.y.z release version')
args.out.mkdir(parents=True, exist_ok=True)
release = json.loads(args.release_data.read_text()) if args.release_data else None
for platform in ('macos', 'windows', 'linux'):
    platform_version = version
    if release:
        suffixes = {'macos': ('.dmg',), 'windows': ('.msi',), 'linux': ('.deb', '.rpm', '.flatpak')}[platform]
        matches = [re.search(r'(\d+\.\d+\.\d+)', a['name']) for a in release['assets'] if a['name'].endswith(suffixes)]
        versions = [m.group(1) for m in matches if m]
        if not versions: continue
        platform_version = max(versions, key=lambda v: tuple(map(int, v.split('.'))))
    (args.out / f'{platform}.json').write_text(json.dumps({
        'version': platform_version,
        'downloadURL': 'https://esemnbun.md/downloads/',
    }, indent=2) + '\n')
