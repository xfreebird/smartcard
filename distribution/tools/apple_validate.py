#!/usr/bin/env python3
"""Check final Apple screenshot slots, localization coverage and PNG format."""
import argparse,hashlib,json,pathlib
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('directory');p.add_argument('--duo-directory');a=p.parse_args();root=pathlib.Path(a.directory)
spec={'iphone':(1320,2868,5),'ipad':(2064,2752,5),'macos':(2880,1800,6)}
items=[]
for lang in ['ro','en','ru']:
 for family,(w,h,n) in spec.items():
  files=sorted((root/lang/family).glob('*.png'));assert len(files)==n,(lang,family,len(files))
  for path in files:
   im=Image.open(path);assert im.size==(w,h),(path,im.size);assert im.mode=='RGB',(path,im.mode);assert im.format=='PNG'
   items.append({'path':str(path.relative_to(root)),'locale':{'ro':'ro','en':'en-US','ru':'ru'}[lang],'family':family,'width':w,'height':h,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
if a.duo_directory:
 duo=pathlib.Path(a.duo_directory)
 for lang in ['ro','en','ru']:
  for family,size in {'duo-compact':(1398,2034),'duo-expanded':(2853,2007)}.items():
   files=sorted((duo/lang/family).glob('*.png'));assert len(files)==5,(lang,family,len(files))
   for path in files:
    im=Image.open(path);assert im.size==size and im.mode=='RGB',(path,im.size,im.mode)
    items.append({'path':str(path.relative_to(duo)),'locale':{'ro':'ro','en':'en-US','ru':'ru'}[lang],'family':family,'width':im.width,'height':im.height,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(root/'submission-index.json').write_text(json.dumps({'guidelinesChecked':'2026-11-01','status':'prepared-not-uploaded','assets':items},indent=2)+'\n')
print(f'PASS: {len(items)} opaque localized Apple screenshots, exact accepted sizes')
