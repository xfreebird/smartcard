#!/usr/bin/env python3
"""Capture actual localized Android mock UI for Play. Emulator only; no hardware/PIN."""
import argparse,subprocess,time,json,hashlib,re
import xml.etree.ElementTree as ET
from PIL import Image
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--adb',default=str(Path.home()/'Library/Android/sdk/platform-tools/adb'));p.add_argument('--serial',default='emulator-5560');p.add_argument('--output',type=Path,required=True);p.add_argument('--apk',type=Path,required=True);p.add_argument('--layouts',default='phone,seven-inch,ten-inch');a=p.parse_args()
assert a.serial.startswith('emulator-'),'Dedicated emulator required'
def adb(*args,raw=False):
 r=subprocess.run([a.adb,'-s',a.serial,*args],check=True,stdout=subprocess.PIPE);return r.stdout if raw else r.stdout.decode().strip()

def hierarchy():
 adb('shell','uiautomator','dump','/sdcard/store-review-window.xml')
 return ET.fromstring(adb('shell','cat','/sdcard/store-review-window.xml'))

def validate_frame(lang):
 tree=hierarchy()
 buttons={'Continue','Continuă','Продолжить'}
 for node in tree.iter('node'):
  if node.get('text') in buttons:
   bounds=list(map(int,re.findall(r'\d+',node.get('bounds',''))))
   if len(bounds)!=4:raise RuntimeError('Disclosure button has no bounds')
   adb('shell','input','tap',str((bounds[0]+bounds[2])//2),str((bounds[1]+bounds[3])//2))
   time.sleep(1)
   tree=hierarchy()
   break
 texts={n.get('text','') for n in tree.iter('node')}
 titles={'Independent app · official sources','Aplicație independentă · surse oficiale','Независимое приложение · официальные источники'}
 if texts & (buttons | titles):raise RuntimeError('Disclosure still covers capture')
 expected={'ro':{'Semnează','Semnare'},'en':{'Sign'},'ru':{'Подписать','Подпись'}}[lang]
 if not expected & texts:raise RuntimeError(f'Wrong capture language {lang}: {sorted(texts)}')
 return texts

for _ in range(180):
 if adb('shell','getprop','sys.boot_completed')=='1':break
 time.sleep(.5)
else:raise RuntimeError('Emulator not ready')
adb('install','-r',str(a.apk));selected=set(a.layouts.split(','));previous=a.output/'capture-manifest.json';audit=[x for x in json.loads(previous.read_text()) if x['layout'] not in selected] if previous.exists() else []
try:
 for layout,size,density in [('phone','1080x1920','360'),('seven-inch','1080x1920','240'),('ten-inch','1920x1080','240')]:
  if layout not in selected:continue
  adb('shell','wm','size',size);adb('shell','wm','density',density);adb('shell','settings','put','system','accelerometer_rotation','0');adb('shell','settings','put','system','user_rotation','0');time.sleep(2)
  for lang in ['ro','en','ru']:
   adb('shell','am','force-stop','md.esemnbun.app')
   adb('shell','cmd','locale','set-app-locales','md.esemnbun.app','--locales',lang)
   adb('shell','cmd','uimode','night','no')
   for order,(scenario,page) in enumerate([('documents','sign'),('cards','card'),('cards','verify'),('cards','browser')],1):
    adb('shell','am','force-stop','md.esemnbun.app');adb('logcat','-c')
    adb('shell','am','start','-W','-n','md.esemnbun.app/md.moldsign.app.MainActivity','--es','demo',scenario,'--es','demo_page',page,'--ez','store_capture','true')
    for _ in range(80):
     if f'ready:{page}' in adb('logcat','-d','-s','MoldSignDemo:I'):break
     time.sleep(.25)
    else: raise RuntimeError(f'Frame timeout {layout}/{lang}/{page}')
    time.sleep(1.5)
    validate_frame(lang)
    target=a.output/lang/layout/f'{order:02}-{page}.png';target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(adb('exec-out','screencap','-p',raw=True));Image.open(target).convert('RGB').save(target)
    audit.append({'file':str(target),'locale':lang,'layout':layout,'scenario':scenario,'page':page,'apkSha256':hashlib.sha256(a.apk.read_bytes()).hexdigest()})
    print(target,flush=True)
finally:
 adb('shell','am','force-stop','md.esemnbun.app')
 a.output.mkdir(parents=True,exist_ok=True);(a.output/'capture-manifest.json').write_text(json.dumps(audit,indent=2)+'\n')
