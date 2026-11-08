#!/usr/bin/env python3
"""Run on an Apple build host. Captures isolated Debug native guide fixtures only."""
import argparse, hashlib, json, os, pathlib, select, subprocess, time
p=argparse.ArgumentParser();p.add_argument('device');p.add_argument('app');p.add_argument('output');args=p.parse_args()
os.environ['DEVELOPER_DIR']='/Applications/Xcode-27.1-rc.app/Contents/Developer'
app=pathlib.Path(args.app)
images=[app/'eSemnBun']+list(app.glob('*.debug.dylib'))
if not any(b'MSIGN_DEMO_SCENARIO' in image.read_bytes() for image in images if image.is_file()):
 raise SystemExit('An isolated Debug build with mock scenarios is required.')
out=pathlib.Path(args.output);out.mkdir(parents=True,exist_ok=True)
scenarios=[
 ('connect','sign','no-reader',False,{}),('empty-reader','sign','empty-reader',False,{}),
 ('sign','sign','ready',True,{}),('cards','sign','multiple',True,{}),
 ('stamp','sign','ready',True,{'MSIGN_QA_STAMP_PREVIEW':'1','MSIGN_DEMO_FILES':'fixture-single'}),
 ('consent','sign','consent-batch',True,{}),('pin','sign','pin',True,{}),
 ('progress','sign','signing',True,{}),('success','sign','success',True,{}),
 ('file-error','sign','sign-failure',True,{}),
 ('verify','verify','verify-valid',False,{}),('certificate','verify','verify-valid',False,{'MSIGN_CAPTURE_EXPAND':'certificate'}),
 ('invalid','verify','verify-invalid',False,{}),('incomplete','verify','verify-incomplete',False,{}),
 ('untrusted','verify','verify-untrusted',False,{}),('unsigned','verify','verify-unsigned',False,{}),
 ('documents','documents','documents-populated',False,{}),('details','documents','documents-details-valid',False,{}),
 ('history','documents','history-populated',False,{}),('browser','browser','ready',False,{}),
 ('card','card','ready',False,{}),('settings','card','ready',False,{'MSIGN_CAPTURE_SHEET':'settings'})]
records=[]
for lang in ['en','ro','ru']:
 for name,tab,scenario,files,extra in scenarios:
  folder=out/lang;folder.mkdir(exist_ok=True)
  subprocess.run(['xcrun','simctl','terminate',args.device,'md.esemnbun.ios'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  env=os.environ.copy()
  params={'MSIGN_QA_NO_HARDWARE':'1','MSIGN_SCREENSHOT_CAPTURE':'1','MSIGN_DEMO_PREFERENCES_SUITE':'md.esemnbun.qa.guides.mobile.'+lang,'MSIGN_DEMO_CARDS':'3' if scenario=='multiple' else '1','MSIGN_DEMO_TAB':tab,'MSIGN_DEMO_SCENARIO':scenario,'MSIGN_DEMO_FILES':'fixture' if files else ':',**extra}
  env.update({'SIMCTL_CHILD_'+k:v for k,v in params.items()})
  proc=subprocess.Popen(['xcrun','simctl','launch','--console',args.device,'md.esemnbun.ios','-appTheme','light','-appLanguage',lang,'-AppleLanguages','('+lang+')','-bridgeEnabled','NO'],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
  ready=False;lines=[];deadline=time.time()+35
  while time.time()<deadline:
   readable,_,_=select.select([proc.stdout],[],[],1)
   if readable:
    line=proc.stdout.readline().decode(errors='replace');lines.append(line)
    if 'MSIGN_DEMO_READY' in line: ready=True;break
   if proc.poll() is not None:break
  if not ready:
   proc.terminate();raise RuntimeError('not ready '+name+''.join(lines)[-2000:])
  time.sleep(2.5 if name in ['stamp','settings','details','certificate','pin','consent'] else 1.3)
  path=folder/(name+'.png')
  subprocess.run(['xcrun','simctl','io',args.device,'screenshot',str(path)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  records.append({'locale':lang,'name':name,'scenario':scenario,'tab':tab,'readiness':'MSIGN_DEMO_READY','sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
  subprocess.run(['xcrun','simctl','terminate',args.device,'md.esemnbun.ios'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  try:proc.wait(timeout=5)
  except subprocess.TimeoutExpired:proc.terminate()
  (out/'capture.json').write_text(json.dumps({'device':args.device,'binarySha256':hashlib.sha256((pathlib.Path(args.app)/'eSemnBun').read_bytes()).hexdigest(),'mock':True,'theme':'light','records':records},indent=2))
  print(lang,name,flush=True)
