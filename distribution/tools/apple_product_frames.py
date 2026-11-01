"""Composite complete native captures into unmodified, licensed Apple product PNGs."""
import hashlib,json,os
from functools import lru_cache
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
CACHE=Path(os.environ.get('ESN_APPLE_BEZEL_CACHE',str(Path.home()/'Library/Caches/esemnbun-apple-bezels')))

@lru_cache(maxsize=3)
def frame_resource(family):
 manifest=CACHE/'frames.json'
 if not manifest.exists():raise RuntimeError('Official Apple bezels are required. Accept Apple’s Design Resources License, mount the resources, then run distribution/tools/import-apple-product-bezels.py.')
 item=json.loads(manifest.read_text())[family];path=CACHE/item['file']
 if hashlib.sha256(path.read_bytes()).hexdigest()!=item['sha256']:raise RuntimeError(f'Apple frame checksum changed: {path}')
 bezel=Image.open(path).convert('RGBA');x,y,w,h=item['screen']
 # Isolate the transparent display opening, excluding the exterior and camera hardware.
 alpha=bezel.getchannel('A').point(lambda value:255 if value else 0);ImageDraw.floodfill(alpha,(x+w//2,y+h//2),128,thresh=0)
 opening=alpha.point(lambda value:255 if value==128 else 0).filter(ImageFilter.MaxFilter(3))
 bounds=opening.getbbox()
 if not bounds or abs(bounds[0]-x)>2 or abs(bounds[1]-y)>2 or abs(bounds[2]-(x+w))>2 or abs(bounds[3]-(y+h))>2:raise RuntimeError(f'Unexpected Apple display opening: {family}: {bounds}')
 return bezel,opening,item

def device_frame(screenshot,family):
 if family not in ('iphone','duo-compact','duo-expanded'):return screenshot
 bezel,opening,item=frame_resource(family);x,y,w,h=item['screen']
 if screenshot.size!=(w,h):raise RuntimeError(f'{family} native screenshot {screenshot.size} does not match Apple display {(w,h)}; never stretch the UI.')
 layer=Image.new('RGBA',bezel.size);layer.paste(screenshot.convert('RGBA'),(x,y))
 layer.putalpha(opening)
 return Image.alpha_composite(layer,bezel)
