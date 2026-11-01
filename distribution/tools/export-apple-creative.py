#!/usr/bin/env python3
"""Export opaque universal Apple header/search artwork at the required dimensions."""
import argparse, hashlib, json
from pathlib import Path
import shutil
from PIL import Image, ImageOps
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--source',type=Path,default=Path(__file__).resolve().parents[1]/'apple/creative/source')
a=p.parse_args()
source=a.source
items=[]
for locale in ('en','ro','ru'):
 path=source/f'{locale}.png'
 if not path.exists():p.error(f'Missing localized artwork: {path}')
 image=ImageOps.fit(Image.open(path).convert('RGB'),(5244,2950),method=Image.Resampling.LANCZOS)
 dest=a.output/locale/'reader-signing.png';dest.parent.mkdir(parents=True,exist_ok=True)
 image.save(dest,optimize=True)
 assert Image.open(dest).mode=='RGB'
 items.append({'locale':locale,'path':str(dest.relative_to(a.output)),'dimensions':[5244,2950],'placements':['header','search-results'],'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
if (source/'composition-manifest.json').exists():shutil.copy2(source/'composition-manifest.json',a.output/'composition-manifest.json')
readme=Path(__file__).resolve().parents[1]/'apple/creative/README.md'
if readme.exists():shutil.copy2(readme,a.output/'README.md')
(a.output/'manifest.json').write_text(json.dumps(items,indent=2)+'\n')
print(f'Exported {len(items)} universal creative assets')
