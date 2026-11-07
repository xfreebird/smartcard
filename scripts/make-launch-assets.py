#!/usr/bin/env python3
"""Generate Apple and Android launch assets from the shared brand mark; requires rsvg-convert."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('app_icons', ROOT / 'scripts/make-app-icons.py')
icons = importlib.util.module_from_spec(spec)
spec.loader.exec_module(icons)
converter = shutil.which('rsvg-convert')
if not converter:
    raise SystemExit('Install librsvg (rsvg-convert) to generate launch assets')
masters = ROOT / 'design/launch-screen'
masters.mkdir(parents=True, exist_ok=True)
assets = ROOT / 'apple/Apps/iOS/LaunchResources'
for name, source, size in [
    ('LaunchBackground', icons.svg(512, 512, '<defs>' + icons.plate_gradient('launch') + '</defs><rect width="512" height="512" fill="url(#plate-launch)"/>'), 1024),
    ('LaunchMark', icons.svg(256, 256, icons.mark('launch')), 384),
]:
    svg = masters / f'{name}.svg'
    svg.write_text(source + '\n')
    folder = assets
    folder.mkdir(parents=True, exist_ok=True)
    subprocess.run([converter, '-w', str(size), '-h', str(size), '-o', str(folder / f'{name}.png'), str(svg)], check=True)

# Android uses the same mark and palette; the launch artwork includes the title.
android = ROOT / 'android/app/src/main/res/drawable-nodpi'
android.mkdir(parents=True, exist_ok=True)
branding = masters / 'AndroidLaunchBranding.svg'
branding.write_text(icons.svg(256, 352, icons.mark('android-launch') + '<text x="128" y="310" text-anchor="middle" font-family="sans-serif" font-size="28" font-weight="600" fill="white">eSemnBun</text>') + '\n')
subprocess.run([converter, '-w', '768', '-h', '1056', '-o', str(android / 'launch_branding.png'), str(branding)], check=True)

# Android 12+ draws its icon into a 288dp splash slot. The adaptive launcher
# foreground is only 108dp; reusing that bitmap enlarges it by 2.67x and blurs
# the signature. Rasterize the same vector master at native splash densities.
foreground = ROOT / 'design/app-icon/android-foreground.svg'
for density, pixels in [('mdpi', 288), ('hdpi', 432), ('xhdpi', 576), ('xxhdpi', 864), ('xxxhdpi', 1152)]:
    folder = ROOT / f'android/app/src/main/res/drawable-{density}'
    folder.mkdir(parents=True, exist_ok=True)
    subprocess.run([converter, '-w', str(pixels), '-h', str(pixels),
                    '-o', str(folder / 'launch_icon.png'), str(foreground)], check=True)
