#!/usr/bin/env python3
"""Capture, render and inventory the localized store pack with isolated mock apps."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[2]
TOOLS = Path(__file__).resolve().parent

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path.home() / 'Desktop/esemnbun-store-submission' / datetime.now(ZoneInfo('Europe/Chisinau')).strftime('%Y-%m-%d') / 'revision2')
    parser.add_argument('--platforms', default='apple,windows,android')
    parser.add_argument('--render-only', action='store_true', help='Reuse existing raw captures; regenerate presentations and validate.')
    parser.add_argument('--dry-run', action='store_true', help='Print the pipeline without launching apps or VMs.')
    args = parser.parse_args()
    platforms = args.platforms.split(',')
    if not platforms or any(p not in ('apple', 'windows', 'android') for p in platforms):
        parser.error('platforms must contain apple,windows,android')
    output = args.output.expanduser().resolve()
    commands = []
    # Run heavy emulator families sequentially. Drivers own and clean up their disposable instances.
    drivers = {'apple': 'apple_capture_all.py', 'windows': 'capture-windows-store-remote.py', 'android': 'capture-android-store-all.py'}
    if not args.render_only:
        for platform in platforms:
            commands.append([sys.executable, str(TOOLS / drivers[platform]), '--output', str(output)])
    if 'apple' in platforms:
        commands += [[sys.executable, str(TOOLS / 'apple_render.py'), '--raw', str(output / 'apple/raw'), '--output', str(output / 'apple/screenshots'), '--supplemental-output', str(output / 'apple/supplemental')],
                     [sys.executable, str(TOOLS / 'apple_validate.py'), str(output / 'apple/screenshots')]]
    if any(p in platforms for p in ('windows', 'android')):
        commands.append([sys.executable, str(TOOLS / 'render-crossplatform-promos.py'), '--output', str(output / 'promotional'), '--android-raw', str(output / 'google/assets/android'), '--windows-raw', str(output / 'microsoft/assets'), '--stores', ','.join(p for p in ('android','windows') if p in platforms)])
    commands += [[sys.executable, str(ROOT / 'scripts/prepare-store-metadata.py'), '--check'],
                 [sys.executable, str(ROOT / 'scripts/localize.py'), '--check', '--require-complete']]
    if args.dry_run:
        print(json.dumps({'output': str(output), 'commands': commands}, indent=2))
        return
    output.mkdir(parents=True, exist_ok=True)
    for command in commands:
        print('Running:', ' '.join(command), flush=True)
        subprocess.run(command, cwd=ROOT, check=True)
    for platform in ('apple', 'google', 'microsoft'):
        if platform == 'apple' and 'apple' not in platforms: continue
        if platform == 'google' and 'android' not in platforms: continue
        if platform == 'microsoft' and 'windows' not in platforms: continue
        shutil.copytree(ROOT / 'distribution' / platform, output / 'metadata' / platform,
                        dirs_exist_ok=True, ignore=shutil.ignore_patterns('assets', 'screenshots'))
    # Carry optional store artwork/captions without replacing fresh native screenshots.
    extras = []
    if 'android' in platforms:
        extras.append('google/assets/android/app-icon-512.png')
        extras += [f'google/assets/android/{lang}/{name}' for lang in ('ro','en','ru') for name in ('feature-graphic.png','captions.json')]
    if 'windows' in platforms:
        extras += ['microsoft/assets/hero-1920x1080.png', 'microsoft/assets/app-tile-300.png']
        extras += [f'microsoft/assets/{lang}/captions.json' for lang in ('ro','en','ru')]
    for relative in extras:
        source = ROOT / 'distribution' / relative
        if source.exists():
            target = output / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    for name in ('REGENERATING-SCREENSHOTS.md', 'STORE-ASSET-GUIDELINES.md', 'SUBMISSION-METADATA.md'):
        source = ROOT / 'distribution' / name
        if source.exists(): shutil.copy2(source, output / name)
    from PIL import Image
    images = []
    for path in sorted(output.rglob('*.png')):
        with Image.open(path) as picture:
            images.append({'path': str(path.relative_to(output)), 'width': picture.width, 'height': picture.height,
                           'mode': picture.mode, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    (output / 'pack-manifest.json').write_text(json.dumps({'createdUTC': datetime.now(timezone.utc).isoformat(),
        'sourceCommit': commit, 'workingTreeChanges': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT)),
        'platforms': platforms, 'captureMode': 'isolated-debug-mocks-no-demo-banner', 'images': images}, indent=2) + '\n')
    print(f'Prepared {len(images)} PNG files: {output}')

if __name__ == '__main__':
    main()
