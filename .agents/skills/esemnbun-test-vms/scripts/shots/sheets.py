import glob, os
from PIL import Image, ImageDraw, ImageFont
root = os.path.expanduser('~/Desktop/esemnbun-screenshots')
try: font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 15)
except Exception: font = ImageFont.load_default()
for plat in ('macos', 'linux', 'windows'):
    for theme in ('light', 'dark'):
        files = sorted(f for f in glob.glob(f'{root}/{plat}/*.png') if f'-{theme}' in os.path.basename(f))
        if not files: continue
        tw, th, cols = 420, 300, 4
        rows = (len(files) + cols - 1) // cols
        sheet = Image.new('RGB', (cols * tw, rows * (th + 26)), 'white')
        d = ImageDraw.Draw(sheet)
        for i, f in enumerate(files):
            im = Image.open(f).convert('RGB'); im.thumbnail((tw - 10, th - 6))
            x, y = (i % cols) * tw, (i // cols) * (th + 26)
            sheet.paste(im, (x + (tw - im.size[0]) // 2, y + 4))
            d.text((x + 6, y + th + 4), os.path.basename(f)[:52], fill='black', font=font)
        sheet.save(f'{root}/{plat}-{theme}-contact-sheet.png')
        print(plat, theme, len(files))
