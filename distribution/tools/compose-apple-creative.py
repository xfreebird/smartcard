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
CARD_CROP = (86, 434, 1234, 1140)
CARD_SCALE = 2

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


def draw_connection(canvas, phone_xy, phone_size, reader_xy, reader_size):
    """Draw one physically coherent USB-C extension between reader and phone.

    The photographed reader's male USB-C plug faces right.  A small female
    extension attaches directly to that tip; the short lead sweeps into the
    phone's bottom port.  The part that passes under the phone is correctly
    occluded by the device frame when the final layer is drawn.
    """
    axis = phone_xy[0] + phone_size[0] / 2
    port = phone_xy[1] + round(phone_size[1] * 2970 / 3000)
    plug_bottom = port + 62
    # Measured from the reader source crop: the male plug reaches the right edge
    # at 48.9% of its height.  Keeping that anchor explicit prevents a cable that
    # appears to enter the reader shell or float above it.
    reader_tip = (reader_xy[0] + reader_size[0] - 5, reader_xy[1] + round(reader_size[1] * .489))
    socket_start = reader_xy[0] + reader_size[0] - round(reader_size[1] * .115)
    socket_end = (reader_tip[0] + 72, reader_tip[1])
    lane_x = max(phone_xy[0] - 90, socket_end[0] + 90)
    lane_y = plug_bottom + 95
    bend = 70
    points = [socket_end]
    points.append((lane_x - bend, socket_end[1]))
    curve(points, points[-1], (lane_x - 30, socket_end[1]),
          (lane_x, socket_end[1] + 30), (lane_x, socket_end[1] + bend))
    points.append((lane_x, lane_y - bend))
    curve(points, points[-1], (lane_x, lane_y - 30),
          (lane_x + 30, lane_y), (lane_x + bend, lane_y))
    points.append((axis - bend, lane_y))
    curve(points, points[-1], (axis - 30, lane_y),
          (axis, lane_y - 30), (axis, lane_y - bend))
    points.append((axis, plug_bottom))
    shadow = Image.new('RGBA', canvas.size)
    stroke(shadow, [(x, y + 7) for x, y in points], (20, 30, 55, 65), 36)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(9)))
    stroke(canvas, points, '#101217', 28); stroke(canvas, points, '#292c33', 18); stroke(canvas, [(x - 2, y - 3) for x, y in points], '#555964', 4)
    draw = ImageDraw.Draw(canvas)
    # Female extension collar over the photographed reader's USB-C male tip.
    socket_half_height = round(reader_size[1] * .088)
    draw.rounded_rectangle((socket_start, reader_tip[1] - socket_half_height, socket_end[0], reader_tip[1] + socket_half_height), radius=12, fill='#171a20', outline='#4b515c', width=2)
    draw.rounded_rectangle((axis - 36, port - 7, axis + 36, plug_bottom), radius=10, fill='#171a20', outline='#444852', width=2)
    draw.rectangle((axis - 25, port - 8, axis + 25, port + 8), fill='#969ba4')


def compose(locale, layout, screen, card, catalog):
    width, height, placement = SPECS[layout]
    canvas = Image.new('RGBA', (width, height)); draw = ImageDraw.Draw(canvas)
    icon = Image.open(ROOT / 'apple/Apps/iOS/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png').convert('RGBA')
    icon = icon.resize((88, 88), Image.Resampling.LANCZOS)
    icon_mask = Image.new('L', icon.size); ImageDraw.Draw(icon_mask).rounded_rectangle((0, 0, 87, 87), radius=21, fill=255); icon.putalpha(icon_mask)

    # Preserve placement-specific composition; align the copy with the card below.
    if layout == 'header':
        phone_xy, phone_width = (2400, 180), 600
        reader_xy, reader_height = (1660, 925), 620
        copy_xy, copy_width = (1130, 485), 1320
        headline_size, summary_size, icon_xy = 88, 38, (1130, 350)
        trust_y = 860
    else:
        phone_xy, phone_width = (2700, 470), 820
        reader_xy, reader_height = (1640, 1455), 960
        copy_xy, copy_width = (890, 720), 1700
        headline_size, summary_size, icon_xy = 112, 48, (890, 580)
        trust_y = 1310

    phone = phone_asset(screen, phone_width)
    reader = reader_asset(reader_height)
    # Scale reader and card together, preserving the original insertion proportions.
    card_height = CARD_SCALE * round(reader_height / CARD_SCALE * .98)
    card_width = round(card_height * card.width / card.height)
    card_xy = (reader_xy[0] - card_width + round(reader_height * .24), reader_xy[1] + round((reader_height - card_height) / 2))
    copy_xy = (card_xy[0], copy_xy[1])
    icon_xy = (card_xy[0], icon_xy[1])
    physical_card = card.resize((card_width, card_height), Image.Resampling.LANCZOS)
    place(canvas, physical_card, card_xy, blur=10, opacity=42, offset=(0, 8))
    place(canvas, reader, reader_xy, blur=11, opacity=38, offset=(0, 8))
    place(canvas, phone, phone_xy, blur=18, opacity=42, offset=(0, 10))
    # Hardware sits above the card's entering edge.  Only the leading portion is
    # occluded, leaving the identity card visible as an inserted physical object.
    place(canvas, physical_card, card_xy, opacity=0)
    place(canvas, reader, reader_xy, opacity=0)
    place(canvas, phone, phone_xy, opacity=0)
    # Draw the socket last so it sleeves the entire male metal connector.
    draw_connection(canvas, phone_xy, phone.size, reader_xy, reader.size)
    canvas.alpha_composite(icon, icon_xy)
    textblock(draw, catalog['storeMetadata'][locale]['name'], (icon_xy[0] + 110, icon_xy[1] + 8), 64, 580, '#243a62', True)
    # Preserve two deliberate lines in every language while fitting the longest
    # localized line. Supporting copy remains independently large and readable.
    headline = catalog['storeCreative']['headline'][locale]
    while max(draw.textlength(line, font=ImageFont.truetype(FONT_BOLD, headline_size)) for line in headline.split('\n')) > copy_width:
        headline_size -= 1
    y = textblock(draw, headline, copy_xy, headline_size, copy_width, '#1c3055', True)
    textblock(draw, catalog['storeCreative']['featureSummary'][locale], (copy_xy[0], y + 30), summary_size, copy_width, '#405775')
    if layout == 'header':
        textblock(draw, catalog['storeCreative']['keyPrivacy'][locale], (copy_xy[0], trust_y), 30, copy_width, '#526582')
    else:
        # A compact process line supports the illustration without competing
        # with the two-line headline or adding small peripheral labels.
        steps = '  ·  '.join(catalog['storeCreative'][key][locale]
                            for key in ('stepConnect', 'stepChoose', 'stepConfirm'))
        textblock(draw, steps, (copy_xy[0], 1230), 38, copy_width, '#3157db', True)
        textblock(draw, catalog['storeCreative']['keyPrivacy'][locale],
                  (copy_xy[0], trust_y), 32, copy_width, '#526582')
    content_bounds = list(canvas.getbbox())
    final = background(width, height)
    # Broad tonal panels make the artwork full-bleed without adding information
    # at the edges that would be lost in the Store's adaptive crops.
    backdrop = Image.new('RGBA', final.size)
    bd = ImageDraw.Draw(backdrop)
    bd.ellipse((width * .43, -height * .55, width * 1.28, height * 1.55), fill=(89, 123, 225, 24))
    bd.ellipse((width * .62, -height * .2, width * 1.2, height * 1.2), fill=(255, 255, 255, 42))
    final.alpha_composite(backdrop)
    final.alpha_composite(canvas)
    return final.convert('RGB'), {
        'locale': locale, 'layout': layout, 'placement': placement, 'dimensions': [width, height],
        'phoneScreenshot': 'iphone/02-batch.png', 'cardScreenshot': 'iphone/01-sign.png',
        'copyLeft': copy_xy[0], 'cardLeft': card_xy[0], 'cardCrop': list(CARD_CROP), 'cardScale': CARD_SCALE, 'cardDimensions': list(physical_card.size), 'deviceFrame': frame_resource('iphone')[2],
        'readerAssetSha256': hashlib.sha256((ROOT / 'distribution/apple/creative/assets/reader.png').read_bytes()).hexdigest(),
        'marketingCopySource': 'localization/catalog.json/storeCreative', 'physicalChipCovered': True, 'readerDimensions': list(reader.size),
        'appleTemplateSafeArea': list(SAFE_AREAS[layout]),
        'contentBounds': content_bounds,
        'safeForPlacementAspect': 'copy aligned to card left edge; composition extends beyond central safe area; verify adaptive crops in App Store Connect',
    }


catalog = json.loads((ROOT / 'localization/catalog.json').read_text())
manifest = []
for locale in ('en', 'ro', 'ru'):
    screen_path = args.raw / locale / 'iphone' / '02-batch.png'
    card_path = args.raw / locale / 'iphone' / '01-sign.png'
    screen = Image.open(screen_path).convert('RGBA'); assert screen.size == (1320, 2868)
    capture = Image.open(card_path).convert('RGBA'); assert capture.size == (1320, 2868)
    card = capture.crop(CARD_CROP)
    mask = Image.new('L', card.size); ImageDraw.Draw(mask).rounded_rectangle((0, 0, card.width - 1, card.height - 1), radius=52, fill=255); card.putalpha(mask)
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
