#!/usr/bin/env python3
"""Additional UI journeys: file-format popup and the empty embedded browser."""
import pathlib,subprocess,time,re,json,hashlib,xml.etree.ElementTree as ET,io
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[2];ADB=str(pathlib.Path.home()/'Library/Android/sdk/platform-tools/adb');S='emulator-5562'
XML=pathlib.Path('/tmp/esemnbun-android-guide-layouts');EVIDENCE=ROOT/'docs/user-guide/android-evidence.json'
def run(*a):return subprocess.check_output([ADB,'-s',S,*map(str,a)],timeout=60,stderr=subprocess.STDOUT)
def sh(*a):return run('shell',*a)
def layout():
 sh('uiautomator','dump','--compressed','/sdcard/esb-guide.xml');return sh('cat','/sdcard/esb-guide.xml')
def tap(label,partial=False):
 for _ in range(3):
  nodes=list(ET.fromstring(layout()).iter('node'))
  for n in nodes:
   v=n.get('text') or n.get('content-desc') or ''
   if v==label or (partial and label in v):
    b=list(map(int,re.findall(r'\d+',n.get('bounds',''))))
    if len(b)==4 and b[2]>b[0] and b[3]>b[1]:sh('input','tap',(b[0]+b[2])//2,(b[1]+b[3])//2);time.sleep(.4);return
  time.sleep(.5)
 raise RuntimeError('Cannot find '+label)
def save(platform,lang,name,mode):
 time.sleep(.4);xml=layout();(XML/f'{platform}-{lang}-{name}.xml').write_bytes(xml)
 data=run('exec-out','screencap','-p');path=ROOT/f'website/static/img/guide/{platform}/{lang}/{name}.png';path.write_bytes(data)
 j=json.loads(EVIDENCE.read_text());record={'file':str(path.relative_to(ROOT)),'platform':platform,'language':lang,'pixels':list(Image.open(io.BytesIO(data)).size),'theme':'light','synthetic':mode=='mock','dataSource':'fictional fixture' if mode=='mock' else 'empty emulator browser, no account or identity; public default service','bannerHidden':True,'serial':S,'imageSha256':hashlib.sha256(data).hexdigest(),'capturedAt':time.time()};j['screenshots']=[r for r in j['screenshots'] if r['file']!=record['file']]+[record];EVIDENCE.write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n');print(platform,lang,name,flush=True)
for platform,w,h,d in [('android-phone',1080,2400,420),('android-tablet',1600,1100,160)]:
 sh('am','force-stop','md.esemnbun.app');sh('wm','size',f'{w}x{h}');sh('wm','density',d);time.sleep(.8)
 for lang in ['en','ro','ru']:
  strings={n.get('name'):''.join(n.itertext()) for n in ET.parse(ROOT/f'android/app/src/main/res/{"values" if lang=="ro" else "values-"+lang}/strings.xml').getroot()}
  sh('am','force-stop','md.esemnbun.app');sh('cmd','locale','set-app-locales','md.esemnbun.app','--locales',lang)
  sh('am','start','-W','-n','md.esemnbun.app/md.moldsign.app.MainActivity','--es','demo','documents','--es','demo_page','sign','--ez','store_capture','true');time.sleep(1)
  tap(strings['file_options']);save(platform,lang,'format','mock')
  # A real empty emulator session is necessary because demo intentionally disables the browser.
  # No accounts, card, PIN or user files are used. Stop the app bridge immediately after capture.
  sh('am','force-stop','md.esemnbun.app');sh('am','start','-W','-n','md.esemnbun.app/md.moldsign.app.MainActivity');time.sleep(1)
  tap(strings['nav_browser']);time.sleep(.5)
  # Find the open action by scrolling the browser content; no navigation or bridge toggle is touched.
  for attempt in range(3):
   try:tap(strings['browser_open_in_app']);break
   except RuntimeError:sh('input','swipe',int(w*.7),int(h*.75),int(w*.7),int(h*.3),'250');time.sleep(.3)
  else:raise RuntimeError('No embedded-browser entry')
  time.sleep(1);tap(strings['browser_services']);save(platform,lang,'browser-menu','empty')
  tap(strings['browser_bookmark_add']);save(platform,lang,'bookmark','empty');sh('input','keyevent','4');time.sleep(.3)
  tap(strings['browser_services']);tap(strings['browser_clear_data']);save(platform,lang,'browser-data','empty');sh('input','keyevent','4');time.sleep(.3)
  tap(strings['browser_services']);tap(strings['browser_bookmark_manage']);save(platform,lang,'bookmarks','empty')
sh('am','force-stop','md.esemnbun.app');sh('wm','size','reset');sh('wm','density','reset')
