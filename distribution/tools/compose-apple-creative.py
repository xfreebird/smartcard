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
FONT_REGULAR = '/System/Library/Fonts/Supplemental/Arial.ttf'
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


def textblock(draw, text, xy, size, width, color, bold=False, line_spacing=1.16):
    font = ImageFont.truetype(FONT_BOLD if bold else FONT_REGULAR, size); y = xy[1]
    for paragraph in text.split('\n'):
        line = ''
        for word in paragraph.split():
            candidate = (line + ' ' + word).strip()
            if draw.textlength(candidate, font=font) > width and line:
                draw.text((xy[0], y), line, font=font, fill=color); y += round(size * line_spacing); line = word
            else:
                line = candidate
        draw.text((xy[0], y), line, font=font, fill=color); y += round(size * line_spacing)
    return y


def compose(locale, layout, screens, catalog):
    width, height, placement = SPECS[layout]
    left, top, right, bottom = SAFE_AREAS[layout]
    safe_height = bottom - top
    canvas = background(width, height)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((width * .47, -height * .4, width * 1.18, height * 1.4), fill='#dce5fc')

    phone_height = round(safe_height * .82)
    phones = []
    for screen in screens:
        phone = device_frame(screen, 'iphone')
        phone_width = round(phone.width * phone_height / phone.height)
        phones.append(phone.resize((phone_width, phone_height), Image.Resampling.LANCZOS))
    gap = 34
    phone_x = right - sum(phone.width for phone in phones) - gap - 32
    x = phone_x
    for phone in phones:
        place(canvas, phone, (x, top + (safe_height - phone_height) // 2))
        x += phone.width + gap

    copy_x = left + 44
    copy_width = phone_x - copy_x - 82
    copy_y = top + round(safe_height * .22)
    creative = catalog['storeCreative']
    title = creative['mobileSigningHeadline'][locale]
    summary = creative['mobileSigningSummary'][locale]
    title_size = 84 if layout == 'header' else 106
    summary_size = 40 if layout == 'header' else 49

    y = textblock(draw, 'eSemnBun', (copy_x, copy_y), 37, copy_width, '#435d91', True)
    y = textblock(draw, title, (copy_x, y + 18), title_size, copy_width, '#16294c', True)
    y = textblock(draw, summary, (copy_x, y + 28), summary_size, copy_width, '#405775')
    if y > bottom - 24:
        raise ValueError(f'Localized copy exceeds Apple safe area: {locale}/{layout}')
    return canvas.convert('RGB'), {
        'locale': locale,
        'layout': layout,
        'placement': placement,
        'dimensions': [width, height],
        'phoneScreenshots': ['iphone/01-sign.png', 'iphone/02-reader.png'],
        'deviceFrame': frame_resource('iphone')[2],
        'marketingCopySource': 'localization/catalog.json/storeCreative',
        'appleTemplateSafeArea': list(SAFE_AREAS[layout]),
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
