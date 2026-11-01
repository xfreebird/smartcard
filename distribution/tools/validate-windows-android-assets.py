#!/usr/bin/env python3
"""Validate store image geometry/modes and produce a checksummed asset manifest."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json
R=Path(__file__).resolve().parents[2];records=[]
for store,root in [('google',R/'distribution/google/assets/android'),('microsoft',R/'distribution/microsoft/assets')]:
 for p in sorted(root.rglob('*.png')):
  im=Image.open(p);w,h=im.size
  assert im.mode in ('RGB','RGBA'),(p,im.mode)
  assert p.stat().st_size<50*1024*1024,p
  if store=='google':
   assert im.mode=='RGB',(p,'no alpha allowed')
   if p.name=='feature-graphic.png':assert (w,h)==(1024,500),p
   elif p.name=='app-icon-512.png':assert (w,h)==(512,512),p
   else:assert min(w,h)>=1080 and max(w,h)<=7680 and (abs(w/h-9/16)<.001 or abs(w/h-16/9)<.001),(p,im.size)
  elif p.name=='hero-1920x1080.png':assert (w,h)==(1920,1080),p
  elif p.name=='app-tile-300.png':assert (w,h)==(300,300),p
  else:assert w>=1366 and h>=768,(p,im.size)
  records.append({'file':str(p.relative_to(R)),'width':w,'height':h,'mode':im.mode,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
output=R/'distribution/windows-android-assets.json';output.write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n');print(f'Validated {len(records)} store PNGs')
# Reviewer contact sheet (not uploaded).
selected=[]
for lang in ('ro','en','ru'):
 for layout in ('phone','seven-inch','ten-inch'):
  p=R/f'distribution/google/assets/android/{lang}/{layout}/01-sign.png'
  if p.exists():selected.append(p)
for lang in ('ro','en','ru'):
 p=R/f'distribution/microsoft/assets/{lang}/01-sign.png'
 if p.exists():selected.append(p)
thumbw,thumbh=310,260;sheet=Image.new('RGB',(thumbw*4,thumbh*((len(selected)+3)//4)),'#E9EDFA');d=ImageDraw.Draw(sheet)
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',13)
for i,p in enumerate(selected):
 im=Image.open(p).convert('RGB');im.thumbnail((290,225));x=(i%4)*thumbw+(thumbw-im.width)//2;y=(i//4)*thumbh+26;sheet.paste(im,(x,y));d.text(((i%4)*thumbw+10,(i//4)*thumbh+7),'/'.join(p.parts[-3:]),fill='#152542',font=font)
sheet.save(R/'distribution/windows-android-contact-sheet.jpg',quality=90)
