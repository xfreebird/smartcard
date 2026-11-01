#!/usr/bin/env python3
"""Capture localized fictional Apple app screens. Requires a Debug app; never uses a card."""
import argparse, json, os, pathlib, subprocess, time, shutil, tempfile
from PIL import Image
R=pathlib.Path(__file__).resolve().parents[2]
def run(*a,**kw): return subprocess.check_output(a,text=True,**kw).strip()
p=argparse.ArgumentParser();p.add_argument('--app',required=True);p.add_argument('--device',required=True);p.add_argument('--family',choices=['iphone','ipad','duo-compact','duo-expanded'],required=True);p.add_argument('--output',required=True);p.add_argument('--display',default='internal');p.add_argument('--devicehub-helper');p.add_argument('--keep-booted',action='store_true');p.add_argument('--stories',default='01-sign,02-batch,03-consent,04-verify,05-card');p.add_argument('--languages',default='ro,en,ru');a=p.parse_args()
app=pathlib.Path(a.app); assert any(b'MSIGN_DEMO_SCENARIO' in f.read_bytes() for f in app.iterdir() if f.is_file() and f.suffix in ('','.dylib')), 'Debug fixture app required'
d=a.device; out=pathlib.Path(a.output);out.mkdir(parents=True,exist_ok=True)
allDevices=json.loads(run('xcrun','simctl','list','devices','--json'))['devices'];device=next(x for v in allDevices.values() for x in v if x['udid']==d);deviceName=device['name']
subprocess.run(['xcrun','simctl','boot',d],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
run('xcrun','simctl','bootstatus',d,'-b');run('xcrun','simctl','install',d,str(app))
run('xcrun','simctl','status_bar',d,'override','--time','9:41','--batteryState','charged','--batteryLevel','100','--wifiMode','active','--wifiBars','3','--cellularMode','active','--cellularBars','4')
container=pathlib.Path(run('xcrun','simctl','get_app_container',d,'md.esemnbun.ios','data'));files=container/'Documents'/'Store Fixtures';files.mkdir(parents=True,exist_ok=True)
devices=json.loads(run('xcrun','simctl','list','devices','--json'))['devices'];runtimeID=next(k for k,v in devices.items() if any(x['udid']==d for x in v));runtime=next(r for r in json.loads(run('xcrun','simctl','list','runtimes','--json'))['runtimes'] if r['identifier']==runtimeID);sdk=run('xcrun','--sdk','iphonesimulator','--show-sdk-version');
if int(runtime['version'].split('.')[0])<26:raise RuntimeError('Store capture requires iOS 26 or newer for native Liquid Glass')
manifest=[]
try:
 for lang,names in {'ro':['Contract','Cerere','Declaratie'],'en':['Contract','Application','Declaration'],'ru':['Договор','Заявление','Декларация']}.items():
  if lang not in a.languages.split(','):continue
  docs=[]
  for n in names:
   f=files/(n+'.pdf');shutil.copyfile(R/'swift/MoldSignKit/Resources/test.pdf',f);docs.append(str(f))
  for key,scenario,tab,count,theme in [('01-sign','ready','sign','1','light'),('02-batch','multiple','sign','3','dark'),('03-consent','pin','sign','1','light'),('04-verify','ready','verify','1','light'),('05-card','multiple','card','3','dark')]:
   if key not in a.stories.split(','):continue
   subprocess.run(['xcrun','simctl','terminate',d,'md.esemnbun.ios'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
   run('xcrun','simctl','ui',d,'appearance',theme)
   env=os.environ.copy();env.update({f'SIMCTL_CHILD_{k}':v for k,v in {'MSIGN_DEMO_CARDS':count,'MSIGN_DEMO_SCENARIO':scenario,'MSIGN_DEMO_PREFERENCES_SUITE':'md.esemnbun.qa.store.capture','MSIGN_QA_NO_HARDWARE':'1','MSIGN_SCREENSHOT_CAPTURE':'1','MSIGN_DEMO_TAB':tab,'MSIGN_DEMO_FILES':':'.join(docs if scenario=='multiple' else docs[:1]),'MSIGN_DEMO_SELECTED':'0'}.items()})
   readyPath='/tmp/esemnbun-store-'+d+'.log';readyLog=pathlib.Path(str(container).split('/Containers/Data/Application/')[0]+readyPath);readyLog.unlink(missing_ok=True)
   run('xcrun','simctl','launch','--stdout='+readyPath,d,'md.esemnbun.ios','-appLanguage',lang,'-appTheme',theme,'-AppleLanguages',f'({lang})',env=env)
   for attempt in range(90):
    if readyLog.exists() and "MSIGN_DEMO_READY" in readyLog.read_text(errors="replace"):break
    time.sleep(1)
   else:raise RuntimeError("Mock presentation did not become ready")
   readyLog.unlink(missing_ok=True)
   time.sleep(2)
   dest=out/lang/a.family/(key+'.png');dest.parent.mkdir(parents=True,exist_ok=True)
   if a.devicehub_helper:
    desktop=pathlib.Path.home()/'Desktop'; before=set(desktop.glob('Screenshot '+deviceName+'*.png'))
    print(run(a.devicehub_helper,deviceName,'Screenshot'),flush=True)
    for attempt in range(50):
     created=set(desktop.glob('Screenshot '+deviceName+'*.png'))-before
     if created:break
     time.sleep(.2)
    if not created:raise RuntimeError('Device Hub did not write native screenshot')
    capture=max(created,key=lambda f:f.stat().st_mtime);shutil.move(str(capture),str(dest))
   else:
    temporary=pathlib.Path(tempfile.gettempdir())/('esemnbun-store-'+d+'.png')
    run('xcrun','simctl','io',d,'screenshot','--display='+a.display,str(temporary));shutil.move(str(temporary),str(dest))
   sourceSize=Image.open(dest).size
   if a.family=='duo-expanded' and sourceSize!=(2853,2007):
    dest.unlink();raise RuntimeError('Expected expanded landscape Duo, got '+str(sourceSize))
   if a.family=='duo-compact' and sourceSize!=(1398,2034):
    dest.unlink();raise RuntimeError('Expected compact portrait Duo, got '+str(sourceSize))
   manifest.append({'foldState':a.family.removeprefix('duo-') if a.family.startswith('duo-') else None,'orientation':'landscape' if sourceSize[0]>sourceSize[1] else 'portrait','sourceDimensions':sourceSize,'path':str(dest.relative_to(out)),'language':lang,'family':a.family,'scenario':scenario,'tab':tab,'mock':True,'sourceApp':str(app),'simulatorUDID':d,'runtime':runtime['name'],'runtimeVersion':runtime['version'],'runtimeBuild':runtime.get('buildversion'),'sdkVersion':sdk,'display':a.display,'captureBackend':'DeviceHub native compositor' if a.devicehub_helper else 'simctl framebuffer'})
 manifestPath=out/f'manifest-{a.family}.json'
 if manifestPath.exists():
  updated={item['path']:item for item in json.loads(manifestPath.read_text())};updated.update({item['path']:item for item in manifest});manifest=list(updated.values())
 manifestPath.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
finally:
 subprocess.run(['xcrun','simctl','terminate',d,'md.esemnbun.ios'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 if not a.keep_booted: subprocess.run(['xcrun','simctl','shutdown',d],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
