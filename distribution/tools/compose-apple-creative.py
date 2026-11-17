#!/usr/bin/env python3
"""Compose aspect-specific Apple product-header and search-result artwork from native captures."""
import argparse, hashlib, json, math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from apple_product_frames import device_frame, frame_resource

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--raw', type=Path, required=True)
parser.add_argument('--output', type=Path, default=ROOT / 'distribution/apple/creative/source')
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)

SPECS = {
    'header': (3840, 1646, 'PRODUCT_PAGE_HEADER_ASSET'),
    'search-results': (3840, 2560, 'APP_STORE_SEARCH_RESULTS_ASSET'),
}
# Bounds of Apple's named `Art Safe Area` layers in the official static PSDs.
# https://developer.apple.com/app-store/asset-best-practices/
SAFE_AREAS = {
    'header': (1097, 493, 2743, 1154),
    'search-results': (836, 765, 3004, 1795),
}
FONT_BOLD = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'


def background(width, height):
    small = Image.new('RGB', (640, 360)); pixels = small.load()
    for y in range(360):
        for x in range(640):
            glow = math.exp(-((x - 345) ** 2 / (410 ** 2) + (y - 155) ** 2 / (245 ** 2)))
            mix = .32 * x / 639 + .68 * y / 359
            pixels[x, y] = tuple(round(start * (1 - mix) + end * mix + glow * 5)
                                 for start, end in ((238, 201), (243, 214), (255, 244)))
    return small.resize((width, height), Image.Resampling.BICUBIC).convert('RGBA')


def place(canvas, image, xy, blur=12, opacity=42, offset=(0, 9)):
    if opacity:
        shadow = Image.new('RGBA', canvas.size)
        alpha = image.getchannel('A').point(lambda value: round(value * opacity / 255))
        shadow.paste((24, 40, 75, 255), xy, alpha)
        shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
        shifted = Image.new('RGBA', canvas.size); shifted.alpha_composite(shadow, offset)
        canvas.alpha_composite(shifted)
    canvas.alpha_composite(image, xy)


def compose(locale, layout, screens, catalog):
    width, height, placement = SPECS[layout]
    left, top, right, bottom = SAFE_AREAS[layout]
    canvas = background(width, height)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((width * .47, -height * .4, width * 1.18, height * 1.4), fill='#dce5fc')

    # Keep the complete signing message inside the safe area.
    # Phone bodies extend into the auxiliary area instead of shrinking every
    # element into the center. Do not add small explanatory paragraphs here.
    creative = catalog['storeCreative']
    headline = creative['featuredSigningTitle'][locale]
    bounds = []

    def centered(text, center_x, y, size, max_width, color='#16294c'):
        font = ImageFont.truetype(FONT_BOLD, size)
        while draw.textlength(text, font=font) > max_width and size > 140:
            size -= 2
            font = ImageFont.truetype(FONT_BOLD, size)
        if draw.textlength(text, font=font) > max_width:
            raise ValueError(f'Featured copy too wide: {locale}/{layout}/{text}')
        box = draw.textbbox((0, 0), text, font=font)
        x = round(center_x - (box[2] - box[0]) / 2)
        draw.text((x, y - box[1]), text, font=font, fill=color)
        bounds.append([x, y, x + box[2] - box[0], y + box[3] - box[1]])

    if layout == 'header':
        phone_height = 1280
        phone_centers = [740, 3100]
        phone_y = 260
        centered(headline, width // 2, 550, 166, 1600)
        centered(creative['featuredNFC'][locale], width // 2, 790, 148, 1600, '#3155ce')
        centered(creative['featuredOrReader'][locale], width // 2, 990, 112, 1600)
    else:
        phone_height = 2000
        phone_centers = [720, 3120]
        phone_y = 280
        lines = creative['featuredSigningTitleStacked'][locale].split('\n')
        for index, line in enumerate(lines):
            centered(line, width // 2, 820 + index * 240, 204, 1360)
        centered(creative['featuredNFC'][locale], width // 2, 1380, 180, 1360, '#3155ce')
        centered(creative['featuredOrReader'][locale], width // 2, 1630, 140, 1360)

    for screen, center in zip(screens, phone_centers):
        phone = device_frame(screen, 'iphone')
        phone_width = round(phone.width * phone_height / phone.height)
        phone = phone.resize((phone_width, phone_height), Image.Resampling.LANCZOS)
        place(canvas, phone, (round(center - phone_width / 2), phone_y), blur=22, opacity=48)

    for box in bounds:
        if box[0] < left or box[1] < top or box[2] > right or box[3] > bottom:
            raise ValueError(f'Key message exceeds Apple safe area: {locale}/{layout}/{box}')
    return canvas.convert('RGB'), {
        'locale': locale,
        'layout': layout,
        'placement': placement,
        'dimensions': [width, height],
        'phoneScreenshots': ['iphone/01-sign.png', 'iphone/02-reader.png'],
        'deviceFrame': frame_resource('iphone')[2],
        'marketingCopySource': 'localization/catalog.json/storeCreative',
        'appleTemplateSafeArea': list(SAFE_AREAS[layout]),
        'messageBounds': bounds,
        'phoneHeight': phone_height,
        'composition': 'large-native-phones-short-safe-area-message',
    }


catalog = json.loads((ROOT / 'localization/catalog.json').read_text())
manifest = []
for locale in ('en', 'ro', 'ru'):
    source_paths = [args.raw / locale / 'iphone' / name for name in ('01-sign.png', '02-reader.png')]
    screens = [Image.open(path).convert('RGBA') for path in source_paths]
    if any(screen.size != (1320, 2868) for screen in screens):
        raise ValueError(f'Expected native 1320 × 2868 captures for {locale}')
    for layout in SPECS:
        image, entry = compose(locale, layout, screens, catalog)
        destination = args.output / f'{locale}-{layout}.png'
        image.save(destination, optimize=True)
        entry['path'] = destination.name
        entry['phoneScreenshotSha256'] = [hashlib.sha256(path.read_bytes()).hexdigest() for path in source_paths]
        entry['sha256'] = hashlib.sha256(destination.read_bytes()).hexdigest()
        manifest.append(entry)
(args.output / 'composition-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print('Composed six localized Header and Search Results assets showing both signing methods')
