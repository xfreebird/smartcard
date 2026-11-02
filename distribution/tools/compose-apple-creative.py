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


def curve(points, p0, p1, p2, p3):
    for step in range(1, 81):
        t = step / 80; u = 1 - t
        points.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                       u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))


def stroke(image, points, color, width):
    draw = ImageDraw.Draw(image); points = [(round(x), round(y)) for x, y in points]
    draw.line(points, fill=color, width=width)
    radius = width / 2
    for x, y in points:
        draw.ellipse((round(x - radius), round(y - radius), round(x + radius), round(y + radius)), fill=color)


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


def reader_asset(height):
    source = Image.open(ROOT / 'distribution/apple/creative/assets/reader.png').convert('RGBA').crop((449, 44, 1314, 977))
    source.putalpha(source.getchannel('A').point(lambda value: 255 if value > 200 else value))
    return source.resize((round(source.width * height / source.height), height), Image.Resampling.LANCZOS)


def phone_asset(screen, width):
    return device_frame(screen, 'iphone').resize((width, round(3000 * width / 1470)), Image.Resampling.LANCZOS)


def draw_cable(canvas, phone_xy, phone_size, reader_xy, layout):
    axis = phone_xy[0] + phone_size[0] / 2
    port = phone_xy[1] + round(phone_size[1] * 2970 / 3000)
    plug_bottom = port + 76
    if layout == 'header':
        points = [(axis, plug_bottom), (axis, 1560)]
        curve(points, points[-1], (axis, 1610), (1840, 1604), (2000, 1580))
        points.append((reader_xy[0] - 80, 1580))
        curve(points, points[-1], (reader_xy[0] - 25, 1580), (reader_xy[0] - 15, 1320), (reader_xy[0] + 70, 1250))
    else:
        points = [(axis, plug_bottom), (axis, 2390)]
        curve(points, points[-1], (axis, 2480), (1500, 2480), (1660, 2410))
        points.append((reader_xy[0] - 100, 2410))
        curve(points, points[-1], (reader_xy[0] - 20, 2410), (reader_xy[0] - 20, 1850), (reader_xy[0] + 65, 1740))
    shadow = Image.new('RGBA', canvas.size)
    stroke(shadow, [(x, y + 9) for x, y in points], (20, 30, 55, 65), 40)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(9)))
    stroke(canvas, points, '#101217', 32); stroke(canvas, points, '#292c33', 21); stroke(canvas, [(x - 2, y - 3) for x, y in points], '#555964', 5)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((axis - 40, port - 7, axis + 40, plug_bottom), radius=11, fill='#171a20', outline='#444852', width=2)
    draw.rectangle((axis - 28, port - 8, axis + 28, port + 8), fill='#969ba4')
    draw.rounded_rectangle((axis - 21, plug_bottom - 7, axis + 21, plug_bottom + 22), radius=8, fill='#22262d')


def compose(locale, layout, screen, card, catalog):
    width, height, placement = SPECS[layout]
    canvas = background(width, height); draw = ImageDraw.Draw(canvas)
    icon = Image.open(ROOT / 'apple/Apps/iOS/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png').convert('RGBA')
    icon = icon.resize((88, 88), Image.Resampling.LANCZOS)
    icon_mask = Image.new('L', icon.size); ImageDraw.Draw(icon_mask).rounded_rectangle((0, 0, 87, 87), radius=21, fill=255); icon.putalpha(icon_mask)

    if layout == 'header':
        phone_xy, phone_width = (175, 88), 690
        card_xy, card_width = (1730, 835), 900
        reader_xy, reader_height = (2390, 725), 670
        copy_xy, copy_width = (1100, 172), 1220
        headline_size, summary_size, icon_xy = 96, 40, (1100, 62)
    else:
        phone_xy, phone_width = (170, 700), 810
        card_xy, card_width = (1360, 1260), 1170
        reader_xy, reader_height = (2290, 1130), 870
        copy_xy, copy_width = (1180, 180), 2250
        headline_size, summary_size, icon_xy = 128, 52, (1180, 60)

    phone = phone_asset(screen, phone_width)
    physical_card = card.resize((card_width, round(card.height * card_width / card.width)), Image.Resampling.LANCZOS)
    reader = reader_asset(reader_height)
    place(canvas, physical_card, card_xy, blur=10, opacity=42, offset=(0, 8))
    place(canvas, reader, reader_xy, blur=11, opacity=38, offset=(0, 8))
    place(canvas, phone, phone_xy, blur=18, opacity=42, offset=(0, 10))
    draw_cable(canvas, phone_xy, phone.size, reader_xy, layout)
    # Hardware sits above the cable; the reader therefore fully hides the printed contact chip.
    place(canvas, physical_card, card_xy, opacity=0)
    place(canvas, reader, reader_xy, opacity=0)
    canvas.alpha_composite(icon, icon_xy)
    textblock(draw, catalog['storeMetadata'][locale]['name'], (icon_xy[0] + 110, icon_xy[1] + 8), 64, 580, '#243a62', True)
    y = textblock(draw, catalog['storeCreative']['headline'][locale], copy_xy, headline_size, copy_width, '#1c3055', True)
    textblock(draw, catalog['storeCreative']['featureSummary'][locale], (copy_xy[0], y + 30), summary_size, copy_width, '#405775')
    if layout == 'header':
        textblock(draw, catalog['storeCreative']['keyPrivacy'][locale], (copy_xy[0], 590), 34, copy_width, '#526582')
    else:
        for index, key in enumerate(('stepConnect', 'stepChoose', 'stepConfirm')):
            row_y = 725 + index * 115
            draw.ellipse((copy_xy[0], row_y, copy_xy[0] + 54, row_y + 54), fill='#3157db')
            font = ImageFont.truetype(FONT_BOLD, 30); label = str(index + 1); box = draw.textbbox((0, 0), label, font=font)
            draw.text((copy_xy[0] + 27 - (box[2] - box[0]) / 2, row_y + 9), label, font=font, fill='white')
            textblock(draw, catalog['storeCreative'][key][locale], (copy_xy[0] + 78, row_y + 7), 40, 1760, '#263d61')
        textblock(draw, catalog['storeCreative']['keyPrivacy'][locale], (copy_xy[0], 2390), 38, 2000, '#526582')
    return canvas.convert('RGB'), {
        'locale': locale, 'layout': layout, 'placement': placement, 'dimensions': [width, height],
        'phoneScreenshot': 'iphone/02-batch.png', 'cardScreenshot': 'iphone/01-sign.png',
        'cardCrop': [120, 540, 1200, 1207], 'deviceFrame': frame_resource('iphone')[2],
        'readerAssetSha256': hashlib.sha256((ROOT / 'distribution/apple/creative/assets/reader.png').read_bytes()).hexdigest(),
        'marketingCopySource': 'localization/catalog.json/storeCreative', 'physicalChipCovered': True,
        'safeForPlacementAspect': 'dedicated artwork; no placement crop required',
    }


catalog = json.loads((ROOT / 'localization/catalog.json').read_text())
manifest = []
for locale in ('en', 'ro', 'ru'):
    screen_path = args.raw / locale / 'iphone' / '02-batch.png'
    card_path = args.raw / locale / 'iphone' / '01-sign.png'
    screen = Image.open(screen_path).convert('RGBA'); assert screen.size == (1320, 2868)
    capture = Image.open(card_path).convert('RGBA'); assert capture.size == (1320, 2868)
    card = capture.crop((120, 540, 1200, 1207))
    mask = Image.new('L', card.size); ImageDraw.Draw(mask).rounded_rectangle((0, 0, card.width - 1, card.height - 1), radius=49, fill=255); card.putalpha(mask)
    for layout in SPECS:
        image, entry = compose(locale, layout, screen, card, catalog)
        destination = args.output / f'{locale}-{layout}.png'; image.save(destination, optimize=True)
        entry['path'] = destination.name
        entry['phoneScreenshotSha256'] = hashlib.sha256(screen_path.read_bytes()).hexdigest()
        entry['cardScreenshotSha256'] = hashlib.sha256(card_path.read_bytes()).hexdigest()
        entry['sha256'] = hashlib.sha256(destination.read_bytes()).hexdigest()
        manifest.append(entry)
(args.output / 'composition-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print('Composed dedicated header and search-result artwork from exact native app screenshots and ID-card crops')
