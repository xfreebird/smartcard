#!/usr/bin/env python3
"""Generates the Windows app's icons from the SVG sources in windows/design/icons (UX-11, WIN-08).

    python3 windows/scripts/make-icons.py [--rsvg /opt/homebrew/bin/rsvg-convert]

Outputs (committed, so the Windows build needs neither rsvg-convert nor Python):
  src/MoldSign.App/Assets/Tray/tray-<state>-<taskbar>.ico
      state   = connected (green dot: a card is inserted) | none (gray dot)   (docs/10 §0.2b, UX-11)
      taskbar = dark (white glyph) | light (near-black glyph): the glyph stays monochrome so it fits the
                taskbar, only the dot carries color (TrayIconService picks the variant from SystemUsesLightTheme)
      frames  = 16, 20, 24, 32, 48 (32-bit BMP with alpha) + 256 (PNG)
  src/MoldSign.App/Assets/AppIcon.ico         exe / Start menu / Add-Remove Programs icon
  src/MoldSign.App/Assets/*.png               MSIX logos (the WinUI template set)

Plain Python 3.9+, no packages: rsvg-convert renders PNGs, this script decodes them and packs the ICO.
"""
import argparse
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
WINDOWS = os.path.dirname(HERE)
SOURCES = os.path.join(WINDOWS, "design", "icons")
ASSETS = os.path.join(WINDOWS, "src", "MoldSign.App", "Assets")
SVG_NS = "http://www.w3.org/2000/svg"

TRAY_SIZES = [16, 20, 24, 32, 48, 256]
APP_SIZES = [16, 20, 24, 32, 40, 48, 64, 256]

# Glyph color + idle dimming per taskbar theme; dot colors pass 3:1 against the taskbar (WCAG 1.4.11).
TASKBARS = {
    "dark": {"glyph": "#FFFFFF", "dots": {"connected": "#4ADE80", "none": "#9CA3AF"}},
    "light": {"glyph": "#1F1F1F", "dots": {"connected": "#15803D", "none": "#6B7280"}},
}
STATES = ["connected", "none"]

# MSIX logos: file name -> (canvas width, canvas height, icon size inside the canvas)
MSIX_ASSETS = {
    "Square44x44Logo.scale-200.png": (88, 88, 88),
    "Square44x44Logo.targetsize-24_altform-unplated.png": (24, 24, 24),
    "Square150x150Logo.scale-200.png": (300, 300, 200),
    "Wide310x150Logo.scale-200.png": (620, 300, 200),
    "SplashScreen.scale-200.png": (1240, 600, 300),
    "LockScreenLogo.scale-200.png": (48, 48, 48),
    "StoreLogo.png": (50, 50, 50),
}


# --- SVG -> PNG ----------------------------------------------------------------------------------------------

def render(rsvg, svg_text, width, height, tmp):
    src = os.path.join(tmp, "in.svg")
    out = os.path.join(tmp, "out.png")
    with open(src, "w", encoding="utf-8") as f:
        f.write(svg_text)
    subprocess.run([rsvg, "-w", str(width), "-h", str(height), "-f", "png", "-o", out, src], check=True)
    with open(out, "rb") as f:
        return f.read()


def tray_svg(source, taskbar, state):
    ET.register_namespace("", SVG_NS)
    root = ET.fromstring(source)
    theme = TASKBARS[taskbar]
    root.set("color", theme["glyph"])
    dot = root.find(f".//{{{SVG_NS}}}circle[@id='dot']")
    dot.set("fill", theme["dots"][state])
    return ET.tostring(root, encoding="unicode")


def placed_svg(app_source, width, height, icon):
    """The app icon centered on a transparent canvas (MSIX tiles and splash)."""
    inner = re.sub(r"<\?xml[^>]*\?>|<!--.*?-->", "", app_source, flags=re.S).strip()
    inner = re.sub(r"^<svg[^>]*>", "", inner, count=1, flags=re.S)
    inner = re.sub(r"</svg>\s*$", "", inner, flags=re.S)
    x, y = (width - icon) / 2, (height - icon) / 2
    return (f'<svg xmlns="{SVG_NS}" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
            f'<svg x="{x}" y="{y}" width="{icon}" height="{icon}" viewBox="0 0 256 256">{inner}</svg></svg>')


# --- PNG decode (8-bit RGBA / RGB, non-interlaced: what rsvg-convert writes) ---------------------------------

def decode_png(data):
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos, idat, header = 8, b"", None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    width, height, depth, color, _, _, interlace = header
    if depth != 8 or color not in (2, 6) or interlace:
        raise ValueError(f"unsupported PNG (depth {depth}, color {color}, interlace {interlace})")
    bpp = 4 if color == 6 else 3
    raw = zlib.decompress(idat)
    stride = width * bpp
    rows, previous, pos = [], bytearray(stride), 0
    for _ in range(height):
        kind, line = raw[pos], bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = previous[i]
            c = previous[i - bpp] if i >= bpp else 0
            if kind == 1:
                line[i] = (line[i] + a) & 0xFF
            elif kind == 2:
                line[i] = (line[i] + b) & 0xFF
            elif kind == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 0xFF
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 0xFF
        rows.append(bytes(line) if bpp == 4 else bytes(
            v for px in range(width) for v in (*line[px * 3:px * 3 + 3], 255)))
        previous = line
    return width, height, rows  # rows of RGBA bytes, top-down


# --- ICO ----------------------------------------------------------------------------------------------------

def bmp_frame(png):
    """32-bit BGRA DIB (bottom-up) + 1-bit AND mask: the classic ICO frame every Windows API reads."""
    width, height, rows = decode_png(png)
    pixels = bytearray()
    for row in reversed(rows):
        for px in range(width):
            r, g, b, a = row[px * 4:px * 4 + 4]
            pixels += bytes((b, g, r, a))
    mask_stride = ((width + 31) // 32) * 4
    mask = bytearray()
    for row in reversed(rows):
        line = bytearray(mask_stride)
        for px in range(width):
            if row[px * 4 + 3] == 0:
                line[px // 8] |= 0x80 >> (px % 8)
        mask += line
    header = struct.pack("<IiiHHIIiiII", 40, width, height * 2, 1, 32, 0, len(pixels) + len(mask), 0, 0, 0, 0)
    return header + bytes(pixels) + bytes(mask)


def write_ico(path, frames):
    """frames: list of (size, png bytes). Sizes >= 256 stay PNG-compressed (Vista+), smaller ones become BMP."""
    images = [(size, png if size >= 256 else bmp_frame(png)) for size, png in frames]
    offset = 6 + 16 * len(images)
    out = bytearray(struct.pack("<HHH", 0, 1, len(images)))
    for size, blob in images:
        dim = 0 if size >= 256 else size
        out += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(blob), offset)
        offset += len(blob)
    for _, blob in images:
        out += blob
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--rsvg", default=shutil.which("rsvg-convert") or "/opt/homebrew/bin/rsvg-convert")
    args = parser.parse_args()
    if not os.path.exists(args.rsvg):
        sys.exit("rsvg-convert not found (brew install librsvg / apt install librsvg2-bin), or pass --rsvg")

    with open(os.path.join(SOURCES, "tray.svg"), encoding="utf-8") as f:
        tray_source = f.read()
    with open(os.path.join(SOURCES, "app.svg"), encoding="utf-8") as f:
        app_source = f.read()

    with tempfile.TemporaryDirectory() as tmp:
        for taskbar in TASKBARS:
            for state in STATES:
                svg = tray_svg(tray_source, taskbar, state)
                path = os.path.join(ASSETS, "Tray", f"tray-{state}-{taskbar}.ico")
                write_ico(path, [(s, render(args.rsvg, svg, s, s, tmp)) for s in TRAY_SIZES])
                print("wrote", os.path.relpath(path, WINDOWS))

        path = os.path.join(ASSETS, "AppIcon.ico")
        write_ico(path, [(s, render(args.rsvg, app_source, s, s, tmp)) for s in APP_SIZES])
        print("wrote", os.path.relpath(path, WINDOWS))

        for name, (width, height, icon) in MSIX_ASSETS.items():
            path = os.path.join(ASSETS, name)
            with open(path, "wb") as f:
                f.write(render(args.rsvg, placed_svg(app_source, width, height, icon), width, height, tmp))
            print("wrote", os.path.relpath(path, WINDOWS))


if __name__ == "__main__":
    main()
