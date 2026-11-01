#!/usr/bin/env python3
"""Cache licensed Apple product PNGs from user-authorized mounted design resources."""
import argparse, hashlib, json
from pathlib import Path
import shutil
from PIL import Image
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--iphone17-volume',type=Path,default=Path('/Volumes/Bezel-iPhone-17'))
p.add_argument('--duo-volume',type=Path,default=Path('/Volumes/Bezel-iPhone-Duo'))
p.add_argument('--cache',type=Path,default=Path.home()/'Library/Caches/esemnbun-apple-bezels')
a=p.parse_args();a.cache.mkdir(parents=True,exist_ok=True)
assets={
 'iphone':(a.iphone17_volume/'PNG/iPhone 17 Pro Max/iPhone 17 Pro Max - Deep Blue - Portrait.png',[75,66,1320,2868],'iPhone 17 Pro Max — Deep Blue','Bezel-iPhone-17.dmg'),
 'duo-compact':(a.duo_volume/'PNG/iPhone Duo - Night Sky - Outer Closed Portrait.png',[88,80,1398,2034],'iPhone Duo — Night Sky — Outer Closed Portrait','Bezel-iPhone-Duo.dmg'),
 'duo-expanded':(a.duo_volume/'PNG/iPhone Duo - Night Sky - Inner Open Landscape.png',[120,120,2853,2007],'iPhone Duo — Night Sky — Inner Open Landscape','Bezel-iPhone-Duo.dmg')}
manifest={}
for family,(source,screen,model,archive) in assets.items():
 if not source.is_file():p.error(f'Missing {source}; download and mount Apple resources after accepting their license.')
 image=Image.open(source);assert image.mode=='RGBA',(source,image.mode)
 x,y,w,h=screen;assert image.getpixel((x+w//2,y+h//2))[3]==0
 target=a.cache/f'{family}.png';shutil.copy2(source,target)
 manifest[family]={'file':target.name,'screen':screen,'model':model,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'source':f'https://devimages-cdn.apple.com/design/resources/download/{archive}'}
for volume in (a.iphone17_volume,a.duo_volume):
 source=volume/'Apple Design Resources License.rtf'
 if source.exists():shutil.copy2(source,a.cache/(volume.name+'-License.rtf'))
(a.cache/'frames.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(f'Cached {len(manifest)} original Apple PNG frames: {a.cache}')
