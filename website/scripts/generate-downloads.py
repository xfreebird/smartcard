#!/usr/bin/env python3
"""Snapshot actual published release assets for the static downloads page."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('release', type=Path, help='GitHub releases/latest API response')
parser.add_argument('--out', type=Path, default=Path(__file__).resolve().parents[1] / 'src/data/release.json')
parser.add_argument('--public-dir', type=Path, help='Stage verified installers for the public website')
args = parser.parse_args()
repo = 'xfreebird/smartcard'
github_downloads = f'https://github.com/{repo}/releases/download/'
public_downloads = 'https://esemnbun.md/release-downloads/'
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
    version_match = (re.search(r'[-_](\d+\.\d+\.\d+)(?=[._-])', name)
                     or re.search(r'/downloads?/v([^/]+)/', asset['url']))
    return {**asset, 'platform': platform,
            'version': version_match.group(1) if version_match else version,
            'format': 'TAR.GZ' if name.endswith('.tar.gz') else name.rsplit('.', 1)[1].upper(),
            'architecture': 'x64' if re.search(r'amd64|x86_64|x64', name) else
                            'ARM64' if re.search(r'aarch64|arm64', name) else
                            'Apple silicon / Intel' if kind == 'macos' else None}


assets = []
prefix = f'{github_downloads}{release["tag_name"]}/'
for asset in release['assets']:
    name = asset['name']
    if name.startswith('esemnbun-package-') or (not family(name) and name not in ('SHA256SUMS.txt', 'eSemnBun-self-signed.cer')):
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
def version_key(asset):
    value = describe(asset).get('version', '0.0.0')
    return tuple(map(int, value.split('.'))) if re.fullmatch(r'\d+\.\d+\.\d+', value) else (0, 0, 0)

for asset in sorted(previous['assets'], key=version_key, reverse=True):
    key = package_key(asset)
    if family(asset['name']) and key not in current_packages:
        assets.append(asset)
        current_packages.add(key)

if args.public_dir:
    args.public_dir.mkdir(parents=True, exist_ok=True)
    releases = {release['tag_name']: release}
    for asset in assets:
        url = asset['url']
        if not url.startswith((github_downloads, public_downloads)):
            continue
        tag, name = url.rsplit('/', 2)[-2:]
        if not re.fullmatch(r'v\d+\.\d+\.\d+', tag) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*', name) or name != asset['name']:
            parser.error(f'Invalid download path for {asset["name"]}')
        if tag not in releases:
            releases[tag] = json.loads(subprocess.check_output(['gh', 'api', f'repos/{repo}/releases/tags/{tag}']))
        source_release = releases[tag]
        source = next((item for item in source_release['assets'] if item['name'] == name), None)
        if source_release['draft'] or source_release['prerelease'] or source is None or source['browser_download_url'] != f'{github_downloads}{tag}/{name}':
            parser.error(f'No matching stable release asset for {tag}/{name}')
        directory = args.public_dir / tag
        directory.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryFile(dir=directory) as binary:
            subprocess.run(['gh', 'api', f'repos/{repo}/releases/assets/{int(source["id"])}',
                            '-H', 'Accept: application/octet-stream'], stdout=binary, check=True)
            size = binary.tell()
            binary.seek(0)
            digest = hashlib.file_digest(binary, 'sha256').hexdigest()
            if size != source['size'] or source['digest'] != 'sha256:' + digest:
                parser.error(f'Published asset verification failed for {tag}/{name}')
            binary.seek(0)
            with (directory / name).open('wb') as target:
                shutil.copyfileobj(binary, target, length=1024 * 1024)
        asset.update(url=f'{public_downloads}{tag}/{name}', size=size)
        print(f'Staged {tag}/{name} ({size} bytes, SHA-256 verified)', flush=True)

args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps({**previous, 'version': version, 'url': release['html_url'],
                               'assets': [describe(asset) for asset in assets]}, ensure_ascii=False, indent=2) + '\n')
