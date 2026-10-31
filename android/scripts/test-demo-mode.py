#!/usr/bin/env python3
"""Native settings/confirmation/persistence/preview/share checks on a dedicated English mock emulator."""
import argparse, hashlib, json, re, subprocess, time
from pathlib import Path
import xml.etree.ElementTree as E
p=argparse.ArgumentParser();p.add_argument('serial');p.add_argument('output', type=Path);p.add_argument('--allow-release',action='store_true');args=p.parse_args()
if not args.serial.startswith('emulator-'):raise SystemExit('Use a dedicated emulator only.')
adb=str(Path.home()/'Library/Android/sdk/platform-tools/adb');out=args.output;out.mkdir(parents=True,exist_ok=True)
def call(*a):return subprocess.check_output([adb,'-s',args.serial,*a])
def shell(*a):return call('shell',*a)
def tree():
 shell('uiautomator','dump','/sdcard/esemnbun-demo-mode.xml')
 return E.fromstring(call('exec-out','cat','/sdcard/esemnbun-demo-mode.xml'))
def tap(n):
 b=list(map(int,re.findall(r'\d+',n.get('bounds'))));shell('input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2));time.sleep(.5)
def wait(pred,seconds=15):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  r=tree();n=next((n for n in r.iter('node') if pred(n)),None)
  if n is not None:return n
  time.sleep(.25)
 raise AssertionError('Expected UI control did not appear.')
def text(value):return wait(lambda n:n.get('text')==value)
def snap(name):
 (out/(name+'.png')).write_bytes(call('exec-out','screencap','-p'))
 (out/(name+'.xml')).write_bytes(E.tostring(tree()))
def settings():tap(wait(lambda n:n.get('content-desc')=='Settings'))
def switch():return wait(lambda n:n.get('checkable')=='true')
def launch():shell('am','start','-W','-n','md.esemnbun.app/md.moldsign.app.MainActivity')
debuggable=b'DEBUGGABLE' in shell('dumpsys','package','md.esemnbun.app')
if not debuggable and not args.allow_release:raise SystemExit('Use --allow-release for the explicitly installed local Release validation APK.')
shell('am','force-stop','md.esemnbun.app');launch();settings()
if switch().get('checked')=='true':
 tap(switch());settings()
assert switch().get('checked')=='false'
snap('01-settings-off');tap(switch());text('Enable demo mode');snap('02-disclaimer-confirmation')
tap(text('Enable demo mode'));text('DEMO MODE — fictional data. Signatures are not valid.')
text('DEMO-contract.pdf');snap('03-demo-banner-samples')
shell('am','force-stop','md.esemnbun.app');launch();text('DEMO MODE — fictional data. Signatures are not valid.');snap('04-cold-launch-persisted')
# Compose's floating action is visibly rendered but omitted by this emulator's UIAutomator tree.
# Use a native touch at the action's verified location in the 1080x2400 phone captures above.
size=shell('wm','size').decode()
assert '1080x2400' in size, 'Use the standard 1080x2400 mock phone profile.'
shell('input','tap','800','2015')
text('Choose documents');snap('05-preview-complete')
tap(text('Activity'));text('DEMO-contract-NOT-SIGNED.pdf');text('DEMO-request-NOT-SIGNED.pdf');snap('06-demo-output-activity')
tap(wait(lambda n:n.get('content-desc')=='More actions'));tap(text('Share'));time.sleep(.7);snap('07-native-share')
shell('input','keyevent','4');time.sleep(.5)
settings();assert switch().get('checked')=='true';tap(switch());text('Connect the reader');snap('08-demo-disabled')
settings();assert switch().get('checked')=='false';shell('input','keyevent','4')
apk_path=shell('pm','path','md.esemnbun.app').decode().strip().removeprefix('package:')
installed_hash=hashlib.sha256(call('exec-out','cat',apk_path)).hexdigest()
(out/'validation.json').write_text(json.dumps({'installedApkSha256':installed_hash,'passed':True,'debuggable':debuggable,'nativeSettingsToggle':True,'explicitDisclaimerConfirmed':True,'coldLaunchPersists':True,'previewNoRealSignature':True,'nativeShareOpened':True,'disabledRestoresNormalMode':True,'physicalCardAccess':False,'pinEntered':False},indent=2)+'\n')
