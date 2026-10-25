#!/usr/bin/env python3
"""Generates the eSemnBun app icon for every platform from one design (docs/10 §0.2b "App icon").

The mark is the tray glyph's motif: a white disc with the signature cut out of it (transparent, so the plate shows
through), on the brand-blue plate. Edit the constants below, then run:

    python3 scripts/make-app-icons.py            # needs rsvg-convert (librsvg) and Pillow

Writes:
    apple/Apps/iOS/Assets.xcassets/AppIcon.appiconset      1024 px, full bleed, opaque (iOS masks the corners)
    apple/Apps/macOS/Assets.xcassets/AppIcon.appiconset    16…1024 px on Apple's macOS grid (824 px body, shadow)
    android/app/src/main/res/drawable-*dpi/ic_launcher_foreground.png   adaptive-icon foreground + monochrome
    android/app/src/main/res/drawable/ic_launcher_background.xml        adaptive-icon background (gradient)
    android/design/play-store-icon-512.png                 Play Console listing icon
    windows/design/icons/app.svg                           then windows/scripts/make-icons.py renders .ico + MSIX
    linux/data/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg
    design/app-icon/*.svg                                  the masters, for reference
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RSVG = shutil.which("rsvg-convert") or "/opt/homebrew/bin/rsvg-convert"

# --- the design (256-unit canvas) -------------------------------------------------------------------------------
PLATE_TOP, PLATE_BOTTOM = "#3F6EF5", "#1A39A6"          # brand gradient (docs/10 §2 `brand` #2350D8)
DISC = (128, 128, 88)                                    # cx, cy, r
# The signature, drawn on the tray glyph's 32-unit grid (windows/design/icons/tray.svg) and placed on the disc;
# finer strokes than the 16 px tray version.
SIGNATURE = [
    "M6 11.5l3.5 3.5M9.5 11.5L6 15",
    "M12 16.5C12.5 11 14 6.5 16.5 7.2C18.6 7.8 15.6 14 15 16.4C14.6 18 18 12.5 19.6 13.2C20.6 13.6 20.2 15.4 22.6 14.6",
    "M6 20.5H19",
]
SIGNATURE_TRANSFORM = "translate(36.5 41.6) scale(6.4)"
SIGNATURE_STROKE = 2.2


def mark(uid):
    """White disc with the signature cut out (256 units, transparent around the disc)."""
    paths = "".join(f'<path d="{d}"/>' for d in SIGNATURE)
    cx, cy, r = DISC
    return (f'<mask id="cut-{uid}" maskUnits="userSpaceOnUse" x="0" y="0" width="256" height="256">'
            f'<rect width="256" height="256" fill="#fff"/>'
            f'<g transform="{SIGNATURE_TRANSFORM}" fill="none" stroke="#000" stroke-width="{SIGNATURE_STROKE}" '
            f'stroke-linecap="round" stroke-linejoin="round">{paths}</g></mask>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#FFFFFF" mask="url(#cut-{uid})"/>')


def plate_gradient(uid):
    return (f'<linearGradient id="plate-{uid}" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{PLATE_TOP}"/><stop offset="1" stop-color="{PLATE_BOTTOM}"/></linearGradient>')


def svg(width, height, body, viewbox=None):
    vb = viewbox or f"0 0 {width} {height}"
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{vb}">{body}</svg>'


def full_bleed():
    """Square plate edge to edge (iOS, Play): the platform applies its own corner mask."""
    return svg(256, 256, f'<defs>{plate_gradient("fb")}</defs><rect width="256" height="256" fill="url(#plate-fb)"/>'
                         f'{mark("fb")}')


def rounded(size, inset, radius, shadow):
    """Plate as a rounded square inside a transparent canvas of `size` units (macOS grid, Windows, GNOME)."""
    body_size = size - 2 * inset
    scale = body_size / 256
    shadow_defs = shadow_use = ""
    if shadow:
        blur, dy, opacity = shadow
        shadow_defs = (f'<filter id="sh" x="-20%" y="-20%" width="140%" height="140%">'
                       f'<feGaussianBlur stdDeviation="{blur}"/></filter>')
        shadow_use = (f'<rect x="{inset}" y="{inset + dy}" width="{body_size}" height="{body_size}" rx="{radius}" '
                      f'fill="#000" opacity="{opacity}" filter="url(#sh)"/>')
    return svg(size, size,
               f'<defs>{plate_gradient("r")}{shadow_defs}</defs>{shadow_use}'
               f'<rect x="{inset}" y="{inset}" width="{body_size}" height="{body_size}" rx="{radius}" fill="url(#plate-r)"/>'
               f'<g transform="translate({inset} {inset}) scale({scale})">{mark("r")}</g>')


def android_foreground():
    """108 dp adaptive-icon foreground: the disc inside the 66 dp safe circle, transparent elsewhere."""
    r = 30
    scale = r / DISC[2]
    t = 54 - DISC[0] * scale
    return svg(108, 108, f'<g transform="translate({t} {t}) scale({scale})">{mark("a")}</g>')


# --- rendering ---------------------------------------------------------------------------------------------------

def render(svg_text, px, out, opaque=False):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg_text)
    try:
        subprocess.run([RSVG, "-w", str(px), "-h", str(px), "-o", out, f.name], check=True)
    finally:
        os.unlink(f.name)
    if opaque:  # App Store rejects app icons with an alpha channel
        Image.open(out).convert("RGB").save(out)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote", os.path.relpath(path, ROOT))


def main():
    if not os.path.exists(RSVG):
        sys.exit("rsvg-convert not found (brew install librsvg / apt install librsvg2-bin)")

    masters = {
        "full-bleed.svg": full_bleed(),
        "macos.svg": rounded(1024, 100, 185, (14, 12, 0.32)),     # Apple macOS grid: 824 body in 1024
        "rounded.svg": rounded(256, 0, 56, None),                # Windows (exe, MSIX tiles)
        "gnome.svg": rounded(128, 8, 26, (2, 2, 0.25)),          # GNOME: 112 body on the 128 grid
        "android-foreground.svg": android_foreground(),
    }
    for name, text in masters.items():
        write(os.path.join(ROOT, "design", "app-icon", name), text)

    # iOS: one 1024 px opaque image
    ios = os.path.join(ROOT, "apple/Apps/iOS/Assets.xcassets/AppIcon.appiconset")
    render(masters["full-bleed.svg"], 1024, os.path.join(ios, "AppIcon-1024.png"), opaque=True)
    write(os.path.join(ios, "Contents.json"), json.dumps({
        "images": [{"filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")

    # macOS: 16…512 @1x/@2x
    mac = os.path.join(ROOT, "apple/Apps/macOS/Assets.xcassets/AppIcon.appiconset")
    images = []
    for size in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            name = f"icon_{size}x{size}{'@2x' if scale == 2 else ''}.png"
            render(masters["macos.svg"], size * scale, os.path.join(mac, name))
            images.append({"filename": name, "idiom": "mac", "scale": f"{scale}x", "size": f"{size}x{size}"})
    write(os.path.join(mac, "Contents.json"),
          json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")

    # Android: adaptive icon (foreground PNGs + gradient background), Play listing icon
    res = os.path.join(ROOT, "android/app/src/main/res")
    for density, px in (("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324), ("xxxhdpi", 432)):
        out = os.path.join(res, f"drawable-{density}", "ic_launcher_foreground.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        render(masters["android-foreground.svg"], px, out)
    write(os.path.join(res, "drawable", "ic_launcher_background.xml"), f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by scripts/make-app-icons.py: adaptive-icon background, the brand plate gradient. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:pathData="M0,0h108v108h-108z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="linear" android:startX="0" android:startY="0" android:endX="108" android:endY="108">
                <item android:offset="0" android:color="#FF{PLATE_TOP[1:]}" />
                <item android:offset="1" android:color="#FF{PLATE_BOTTOM[1:]}" />
            </gradient>
        </aapt:attr>
    </path>
</vector>
''')
    render(masters["full-bleed.svg"], 512, os.path.join(ROOT, "android/design/play-store-icon-512.png"))

    # Windows: app.svg feeds windows/scripts/make-icons.py (AppIcon.ico + MSIX tiles)
    write(os.path.join(ROOT, "windows/design/icons/app.svg"), masters["rounded.svg"])
    subprocess.run([sys.executable, os.path.join(ROOT, "windows/scripts/make-icons.py")], check=True)

    # GNOME
    write(os.path.join(ROOT, "linux/data/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg"), masters["gnome.svg"])


if __name__ == "__main__":
    main()
