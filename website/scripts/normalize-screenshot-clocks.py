#!/usr/bin/env python3
"""Apply reviewed native 09:41 clock crops and optional status-bar strips.

Requires Pillow. The manifest records original and resulting SHA-256 hashes, source
crops and exact edit rectangles. Repeated runs skip already-normalized images.
"""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'website/static/img/screenshot-clocks.json'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verify published bytes without editing')
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    from PIL import Image, ImageChops, ImageStat

    changed = 0
    for row in manifest['images']:
        path = ROOT / row['path']
        current = sha(path)
        if current == row.get('sha256'):
            continue
        if args.check:
            raise SystemExit(f'Screenshot changed without clock review: {path}')
        if current != row['originalSha256']:
            raise SystemExit(f'Unexpected source screenshot: {path}')
        original = Image.open(path)
        image = original.convert('RGB')
        box = row['rectangle']
        crop = image.crop(box)
        background = tuple(round(v) for v in ImageStat.Stat(crop).median)
        pixels = list(crop.getdata())
        foreground = max(pixels, key=lambda p: sum(abs(a-b) for a, b in zip(p, background)))

        donor = Image.open(ROOT / row['clockCrop']).convert('RGB')
        donor_bg = donor.getpixel((0, 0))
        difference = ImageChops.difference(donor, Image.new('RGB', donor.size, donor_bg)).convert('L')
        peak = max(difference.getdata())
        mask = difference.point(lambda v: round(v * 255 / peak))
        mask = mask.crop(mask.getbbox()).resize(tuple(row['clockSize']), Image.Resampling.LANCZOS)

        # Sample the unmodified margins for each row, retaining any status-bar gradient.
        for y in range(box[1], box[3]):
            left, right = image.getpixel((box[0], y)), image.getpixel((box[2]-1, y))
            for x in range(box[0], box[2]):
                t = (x-box[0]) / max(1, box[2]-box[0]-1)
                image.putpixel((x, y), tuple(round(a+(b-a)*t) for a, b in zip(left, right)))
        image.paste(foreground, tuple(row['clockPosition']), mask)

        difference = ImageChops.difference(original.convert('RGB'), image)
        difference.paste(0, box)
        if difference.getbbox() is not None:
            raise SystemExit(f'Edit escaped the clock rectangle: {path}')
        if status_bar := row.get('statusBar'):
            source = ROOT / status_bar['source']
            if sha(source) != status_bar['sourceSha256']:
                raise SystemExit(f'Status-bar donor changed: {source}')
            band = status_bar['rectangle']
            strip = Image.open(source).convert('RGB').crop(status_bar['crop'])
            strip = strip.resize((band[2]-band[0], band[3]-band[1]), Image.Resampling.LANCZOS)
            image.paste(strip, (band[0], band[1]))
            difference = ImageChops.difference(original.convert('RGB'), image)
            difference.paste(0, band)
            if difference.getbbox() is not None:
                raise SystemExit(f'Edit escaped the status-bar band: {path}')
        if original.mode == 'RGBA':
            image.putalpha(original.getchannel('A'))
        image.save(path, optimize=True)
        row['sha256'] = sha(path)
        changed += 1
    if not args.check:
        MANIFEST.write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'{len(manifest["images"])} clock records verified; {changed} images normalized')


if __name__ == '__main__':
    main()
