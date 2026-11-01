#!/usr/bin/env python3
"""Capture localized fictional Apple app screens. Requires a Debug app; never uses a card."""
import argparse, json, os, pathlib, subprocess, time, shutil
R=pathlib.Path(__file__).resolve().parents[2]
def run(*a,**kw): return subprocess.check_output(a,text=True,**kw).strip()
p=argparse.ArgumentParser();p.add_argument('--app',required=True);p.add_argument('--device',required=True);p.add_argument('--family',choices=['iphone','ipad'],required=True);p.add_argument('--output',required=True);a=p.parse_args()
app=pathlib.Path(a.app); assert any(b'MSIGN_DEMO_SCENARIO' in f.read_bytes() for f in app.iterdir() if f.is_file() and f.suffix in ('','.dylib')), 'Debug fixture app required'
d=a.device; out=pathlib.Path(a.output);out.mkdir(parents=True,exist_ok=True)
subprocess.run(['xcrun','simctl','boot',d],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
run('xcrun','simctl','bootstatus',d,'-b');run('xcrun','simctl','install',d,str(app))
run('xcrun','simctl','status_bar',d,'override','--time','9:41','--batteryState','charged','--batteryLevel','100','--wifiMode','active','--wifiBars','3','--cellularMode','active','--cellularBars','4')
container=pathlib.Path(run('xcrun','simctl','get_app_container',d,'md.esemnbun.ios','data'));files=container/'Documents'/'Store Fixtures';files.mkdir(parents=True,exist_ok=True)
manifest=[]
try:
 for lang,names in {'ro':['Contract','Cerere','Declaratie'],'en':['Contract','Application','Declaration'],'ru':['Договор','Заявление','Декларация']}.items():
  docs=[]
  for n in names:
   f=files/(n+'.pdf');shutil.copyfile(R/'swift/MoldSignKit/Resources/test.pdf',f);docs.append(str(f))
  for key,scenario,tab,count,theme in [('01-sign','ready','sign','1','light'),('02-batch','multiple','sign','3','dark'),('03-consent','pin','sign','1','light'),('04-verify','ready','verify','1','light'),('05-card','multiple','card','3','dark')]:
   subprocess.run(['xcrun','simctl','terminate',d,'md.esemnbun.ios'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
   run('xcrun','simctl','ui',d,'appearance',theme)
   env=os.environ.copy();env.update({f'SIMCTL_CHILD_{k}':v for k,v in {'MSIGN_DEMO_CARDS':count,'MSIGN_DEMO_SCENARIO':scenario,'MSIGN_DEMO_PREFERENCES_SUITE':'md.esemnbun.qa.store.capture','MSIGN_QA_NO_HARDWARE':'1','MSIGN_SCREENSHOT_CAPTURE':'1','MSIGN_DEMO_TAB':tab,'MSIGN_DEMO_FILES':':'.join(docs),'MSIGN_DEMO_SELECTED':'0'}.items()})
   run('xcrun','simctl','launch',d,'md.esemnbun.ios','-appLanguage',lang,'-appTheme',theme,'-AppleLanguages',f'({lang})',env=env)
   time.sleep(3)
   dest=out/lang/a.family/(key+'.png');dest.parent.mkdir(parents=True,exist_ok=True)
   run('xcrun','simctl','io',d,'screenshot',str(dest))
   manifest.append({'path':str(dest.relative_to(out)),'language':lang,'family':a.family,'scenario':scenario,'tab':tab,'mock':True,'sourceApp':str(app)})
 (out/f'manifest-{a.family}.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
finally:
 subprocess.run(['xcrun','simctl','terminate',d,'md.esemnbun.ios'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 subprocess.run(['xcrun','simctl','shutdown',d],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
