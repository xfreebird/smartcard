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
    if name.endswith('.dmg') or ('macos' in name and name.endswith('.tar.gz')): return 'macos'
    if name.endswith('.msi') or ('windows' in name and name.endswith('.zip')): return 'windows'
    if name.endswith('.apk'): return 'android'
    if name.endswith('.flatpak'): return 'flatpak'
    if name.endswith(('.deb', '.rpm', '.tar.gz')): return 'linux'
    return None

manifest = Path(__file__).resolve().parents[1] / 'src/data/release.json'
previous = json.loads((args.out if args.out.exists() else manifest).read_text())

def describe(asset):
    name = asset['name']
    kind = family(name)
    if not kind:
        return asset
    platform = 'linux' if kind in ('flatpak', 'linux') else kind
    if kind == 'linux' and (name.startswith('esemnbun-cli') or name.endswith('.tar.gz')):
        platform = 'linux-cli'
    version_match = re.search(r'/downloads?/v([^/]+)/', asset['url'])
    return {**asset, 'platform': platform,
            'version': version_match.group(1) if version_match else version,
            'format': 'TAR.GZ' if name.endswith('.tar.gz') else name.rsplit('.', 1)[1].upper(),
            'architecture': 'x64' if re.search(r'amd64|x86_64|x64', name) else
                            'ARM64' if re.search(r'aarch64|arm64', name) else
                            'Apple silicon / Intel' if kind == 'macos' else None}


assets = []
prefix = f'https://github.com/xfreebird/smartcard/releases/download/{release["tag_name"]}/'
for asset in release['assets']:
    if asset['name'].startswith('esemnbun-package-') or asset['name'].endswith('.nupkg'):
        continue
    url = asset['browser_download_url']
    if not url.startswith(prefix):
        parser.error('Unexpected release asset host or tag')
    if any(a['name']=='esemnbun-package-repositories.tar.gz' for a in release['assets']):
        name=asset['name']
        if name in (f'esemnbun-{version}-macos-universal.tar.gz', f'esemnbun-{version}-linux-x86_64.tar.gz', f'esemnbun-cli-{version}-windows-x64.zip'):
            url=f'https://esemnbun.md/packages/downloads/v{version}/{name}'
        elif name.startswith('esemnbun-cli_') and name.endswith('.deb'):
            url=f'https://esemnbun.md/packages/apt/pool/main/e/esemnbun-cli/{name}'
        elif name.startswith('esemnbun-cli-') and name.endswith('.rpm'):
            url=f'https://esemnbun.md/packages/rpm/x86_64/{name}'
    assets.append({'name': asset['name'], 'url': url, 'size': asset['size']})
# Preserve each missing package/architecture independently (including desktop vs CLI).
def package_key(asset):
    info = describe(asset)
    return (info.get('platform'), info.get('format'), info.get('architecture'))

current_packages = {package_key(asset) for asset in assets}
assets.extend(asset for asset in previous['assets']
              if family(asset['name']) and package_key(asset) not in current_packages)
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps({**previous, 'version': version, 'url': release['html_url'],
                               'assets': [describe(asset) for asset in assets]}, ensure_ascii=False, indent=2) + '\n')
