#!/usr/bin/env python3
import argparse,os,subprocess,time,json,re,xml.etree.ElementTree as E
from pathlib import Path
parser=argparse.ArgumentParser(description="English mock-emulator gesture and focused-PIN resize/cancel regression checks.")
parser.add_argument('output',type=Path)
parser.add_argument('--serial',default='emulator-5554')
args=parser.parse_args()
if not args.serial.startswith('emulator-'): raise SystemExit('Use a dedicated mock emulator.')
adb=os.environ.get('ADB',str(Path(os.environ.get('ANDROID_HOME',str(Path.home()/'Library/Android/sdk')))/'platform-tools/adb'))
serial=args.serial;root=args.output
for folder in ['phone','phone-landscape','tablet-landscape']:(root/folder).mkdir(parents=True,exist_ok=True)
verify=Path(__file__).with_name('verify-pin-visibility.py')
def call(*a):return subprocess.check_output([adb,'-s',serial,*a],stderr=subprocess.DEVNULL)
def shell(*a):return call('shell',*a)
def tree():
 shell('uiautomator','dump','/sdcard/esemnbun-interaction.xml')
 return E.fromstring(call('exec-out','cat','/sdcard/esemnbun-interaction.xml'))
def screenshot(p):p.write_bytes(call('exec-out','screencap','-p'))
def rect(n):return list(map(int,re.findall(r'\d+',n.get('bounds'))))
def start(scenario,page='sign'):
 shell('am','start','-W','-n','md.esemnbun.app/md.moldsign.app.MainActivity','--es','demo',scenario,'--es','demo_page',page)
 time.sleep(1.3)
# The installed app must expose isolated Debug fixtures; never operate a production app.
if b'DEBUGGABLE' not in shell('dumpsys','package','md.esemnbun.app'): raise SystemExit('Install the Debug mock APK first.')
# Real horizontal drag, not programmatic selection.
shell('wm','size','2560x1600');shell('wm','density','240');start('cards','card')
before=tree()
first=next(n for n in before.iter('node') if n.get('content-desc')=='Sign with ION POPESCU');b=rect(first)
screenshot(root/'tablet-landscape/swipe-before.png')
x=(b[0]+b[2])//2;y=(b[1]+b[3])//2
shell('input','swipe',str(x+250),str(y),str(x-350),str(y),'500');time.sleep(1)
after=tree()
second=next(n for n in after.iter('node') if n.get('content-desc')=='Sign with ANA-MARIA MÎNDRU');a=rect(second)
assert abs((a[0]+a[2])-(b[0]+b[2]))<=4,(a,b)
screenshot(root/'tablet-landscape/swipe-selected-second.png')
(root/'tablet-landscape/swipe-validation.json').write_text(json.dumps({'passed':True,'gesture':'native input swipe','beforeHolder':'ION POPESCU','afterHolder':'ANA-MARIA MÎNDRU','beforeBounds':b,'afterBounds':a},indent=2)+'\n')
# Resize with a focused, empty PIN dialog, then cancel through its actual native button.
shell('wm','size','1080x2400');shell('wm','density','420');start('pin')
subprocess.run(['python3',str(verify),serial,str(root/'phone/resize-before-layout.json')],check=True)
screenshot(root/'phone/resize-before.png')
shell('wm','size','2400x1080');time.sleep(1.2)
subprocess.run(['python3',str(verify),serial,str(root/'phone-landscape/resize-after-layout.json')],check=True)
screenshot(root/'phone-landscape/resize-after.png')
c=json.load(open(root/'phone-landscape/resize-after-layout.json'))['controls']['pin.cancel']
shell('input','tap',str((c[0]+c[2])//2),str((c[1]+c[3])//2));time.sleep(.7)
t=tree();assert not any(n.get('resource-id')=='pin.field' for n in t.iter('node'))
(root/'phone-landscape/resize-cancel-validation.json').write_text(json.dumps({'passed':True,'resizedWhileFocused':True,'cancelTapped':True,'pinDialogDismissed':True,'realPinEntered':False},indent=2)+'\n')
print('Native swipe centered card2; focused-PIN resize and visible Cancel action passed.')

# This driver owns the dedicated emulator profile. Restore its display defaults and leave no app request active.
shell('am','force-stop','md.esemnbun.app');shell('wm','size','reset');shell('wm','density','reset')
