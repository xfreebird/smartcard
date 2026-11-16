#!/usr/bin/env python3
"""Capture actual localized Android mock UI for Play. Emulator only; no hardware/PIN."""
import argparse,subprocess,time,json,hashlib,re
import xml.etree.ElementTree as ET
from PIL import Image
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--adb',default=str(Path.home()/'Library/Android/sdk/platform-tools/adb'));p.add_argument('--serial',default='emulator-5560');p.add_argument('--output',type=Path,required=True);p.add_argument('--apk',type=Path,required=True);p.add_argument('--layouts',default='phone,seven-inch,ten-inch');p.add_argument('--languages',default='ro,en,ru');p.add_argument('--stories',default='sign,reader,card,verify');p.add_argument('--package',default='md.esemnbun.app');a=p.parse_args()
assert a.serial.startswith('emulator-'),'Dedicated emulator required'
def adb(*args,raw=False):
 r=subprocess.run([a.adb,'-s',a.serial,*args],check=True,stdout=subprocess.PIPE);return r.stdout if raw else r.stdout.decode().strip()

def hierarchy():
 for _ in range(3):
  try:
   adb('shell','rm','-f','/sdcard/store-review-window.xml')
   adb('shell','uiautomator','dump','/sdcard/store-review-window.xml')
   return ET.fromstring(adb('shell','cat','/sdcard/store-review-window.xml'))
  except (ET.ParseError, subprocess.CalledProcessError):
   time.sleep(1)
 raise RuntimeError('Could not read the current Android accessibility hierarchy')

def tap_label(tree, labels, description):
 for node in tree.iter('node'):
  if labels.intersection((node.get('text'), node.get('content-desc'))):
   bounds=list(map(int,re.findall(r'\d+',node.get('bounds',''))))
   if len(bounds)==4:
    adb('shell','input','tap',str((bounds[0]+bounds[2])//2),str((bounds[1]+bounds[3])//2))
    return
 raise RuntimeError(f'Cannot locate {description}: {sorted({n.get("text","") for n in tree.iter("node")})}')

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
 return tree

for _ in range(180):
 if adb('shell','getprop','sys.boot_completed')=='1':break
 time.sleep(.5)
else:raise RuntimeError('Emulator not ready')
adb('install','-r',str(a.apk))
selected=set(a.layouts.split(','))
languages=set(a.languages.split(','))
stories=set(a.stories.split(','))
previous=a.output/'capture-manifest.json'
audit=[x for x in json.loads(previous.read_text())
       if x['layout'] not in selected or x['locale'] not in languages or x['page'] not in stories] if previous.exists() else []
try:
 for layout,size,density in [('phone','1080x1920','360'),('seven-inch','1080x1920','240'),('ten-inch','1920x1080','240')]:
  if layout not in selected:continue
  adb('shell','wm','size',size);adb('shell','wm','density',density);adb('shell','settings','put','system','accelerometer_rotation','0');adb('shell','settings','put','system','user_rotation','0');time.sleep(2)
  for lang in ['ro','en','ru']:
   if lang not in languages:continue
   adb('shell','am','force-stop',a.package)
   adb('shell','cmd','locale','set-app-locales',a.package,'--user','0','--locales',lang)
   locale=adb('shell','cmd','locale','get-app-locales',a.package,'--user','0')
   if not re.search(r'\b'+lang+r'\b',locale):
    raise RuntimeError(f'Cannot set capture language {lang}: {locale}')
   adb('shell','cmd','uimode','night','no')
   for story,scenario,page,filename in [
       ('sign','cards','sign','01-sign.png'), ('reader','cards','sign','02-reader.png'),
       ('card','cards','card','02-card.png'), ('verify','verify','verify','03-verify.png'),
       ('browser','cards','browser','04-browser.png')]:
    if story not in stories:continue
    adb('shell','am','force-stop',a.package);adb('logcat','-c')
    adb('shell','am','start','-n',a.package+'/md.moldsign.app.MainActivity','--es','demo',scenario,'--es','demo_page',page,'--ez','store_capture','true')
    route = 'settings' if page == 'card' else page
    for _ in range(80):
     if f'ready:{route}' in adb('logcat','-d','-s','MoldSignDemo:I'):break
     time.sleep(.25)
    else: raise RuntimeError(f'Frame timeout {layout}/{lang}/{page}')
    time.sleep(1.5)
    tree=validate_frame(lang)
    if story == 'sign':
     nfc={'With your phone · NFC','Cu telefonul · NFC','Телефоном · NFC'}
     if not any('NFC' in (n.get('text','')+' '+n.get('content-desc','')) for n in tree.iter('node')):
      reader={'With a card reader','Cu un cititor de carduri','Через картридер'}
      if not any(reader.intersection((n.get('text'),n.get('content-desc'))) for n in tree.iter('node')):
       # The larger reader card may push the method selector below the short landscape viewport.
       width,height=map(int,size.split('x'))
       x=str(int(width*.44))
       adb('shell','input','swipe',x,str(int(height*.73)),x,str(int(height*.32)),'420')
       tree=validate_frame(lang)
       scrolled=True
      else:
       scrolled=False
      tap_label(tree,reader,'signing method')
      menu=hierarchy()
      tap_label(menu,nfc,'NFC option')
      if scrolled:
       adb('shell','input','swipe',x,str(int(height*.32)),x,str(int(height*.73)),'420')
      tree=validate_frame(lang)
      if not any('NFC' in n.get('text','') for n in tree.iter('node')):
       raise RuntimeError('Sign capture did not enter NFC mode')
    if story == 'reader':
     reader={'With a card reader','Cu un cititor de carduri','Через картридер'}
     if not any(reader.intersection((n.get('text'),n.get('content-desc'))) for n in tree.iter('node')):
      width,height=map(int,size.split('x'))
      x=str(int(width*.44))
      adb('shell','input','swipe',x,str(int(height*.72)),x,str(int(height*.53)),'550')
      tree=validate_frame(lang)
     texts={n.get(attribute,'') for n in tree.iter('node') for attribute in ('text','content-desc')}
     if not reader.intersection(texts) or not any('POPESCU' in text.upper() for text in texts):
      raise RuntimeError(f'Reader capture needs the selected method and a visible demo card: {layout}/{lang} {sorted(texts)}')
    target=a.output/lang/layout/filename;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(adb('exec-out','screencap','-p',raw=True));Image.open(target).convert('RGB').save(target)
    audit.append({'file':str(target),'locale':lang,'layout':layout,'scenario':scenario,'page':story,'apkSha256':hashlib.sha256(a.apk.read_bytes()).hexdigest()})
    print(target,flush=True)
finally:
 adb('shell','am','force-stop',a.package)
 a.output.mkdir(parents=True,exist_ok=True);(a.output/'capture-manifest.json').write_text(json.dumps(audit,indent=2)+'\n')
