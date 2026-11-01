#!/usr/bin/env python3
"""Export opaque universal Apple header/search artwork at the required dimensions."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image, ImageOps
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--output', type=Path, required=True)
a=p.parse_args()
source=Path(__file__).resolve().parents[1]/'apple/creative/source'
items=[]
for locale in ('en','ro','ru'):
 path=source/f'{locale}.png'
 if not path.exists():continue
 image=ImageOps.fit(Image.open(path).convert('RGB'),(5244,2950),method=Image.Resampling.LANCZOS)
 dest=a.output/locale/'reader-signing.png';dest.parent.mkdir(parents=True,exist_ok=True)
 image.save(dest,optimize=True)
 assert Image.open(dest).mode=='RGB'
 items.append({'locale':locale,'path':str(dest.relative_to(a.output)),'dimensions':[5244,2950],'placements':['header','search-results'],'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(a.output/'manifest.json').write_text(json.dumps(items,indent=2)+'\n')
print(f'Exported {len(items)} universal creative assets')
