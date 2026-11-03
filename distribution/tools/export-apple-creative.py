#!/usr/bin/env python3
"""Export opaque Apple artwork at the native aspect ratio of each placement."""
import argparse, hashlib, json
from pathlib import Path
import shutil
from PIL import Image, ImageOps
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--source',type=Path,default=Path(__file__).resolve().parents[1]/'apple/creative/source')
a=p.parse_args()
source=a.source
layouts = {
    'header': ((3840, 1646), 'PRODUCT_PAGE_HEADER_ASSET'),
    'search-results': ((3840, 2560), 'APP_STORE_SEARCH_RESULTS_ASSET'),
}
items=[]
for locale in ('en','ro','ru'):
 for layout, (dimensions, placement) in layouts.items():
  path=source/f'{locale}-{layout}.png'
  if not path.exists():p.error(f'Missing localized artwork: {path}')
  image=Image.open(path).convert('RGB')
  if image.size != dimensions:p.error(f'Artwork must have exact placement dimensions; refusing to crop {path}: {image.size}')
  dest=a.output/locale/f'{layout}-reader-signing.png';dest.parent.mkdir(parents=True,exist_ok=True)
  image.save(dest,optimize=True)
  assert Image.open(dest).mode=='RGB' and Image.open(dest).size == dimensions
  items.append({'locale':locale,'layout':layout,'path':str(dest.relative_to(a.output)),'dimensions':list(dimensions),'placements':[placement],'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
if (source/'composition-manifest.json').exists():shutil.copy2(source/'composition-manifest.json',a.output/'composition-manifest.json')
readme=Path(__file__).resolve().parents[1]/'apple/creative/README.md'
if readme.exists():shutil.copy2(readme,a.output/'README.md')
(a.output/'manifest.json').write_text(json.dumps(items,indent=2)+'\n')
print(f'Exported {len(items)} placement-specific creative assets')
