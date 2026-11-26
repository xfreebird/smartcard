#!/usr/bin/env python3
"""Build and capture isolated, mock-only Apple store screenshots on modern runtimes."""
import argparse,json,os,pathlib,subprocess,tempfile,uuid
R=pathlib.Path(__file__).resolve().parents[2];T=R/'distribution/tools'
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--families',default='iphone,ipad,macos');p.add_argument('--developer-dir',default=os.environ.get('DEVELOPER_DIR','/Applications/Xcode-27.1-rc.app/Contents/Developer' if pathlib.Path('/Applications/Xcode-27.1-rc.app/Contents/Developer').exists() else subprocess.check_output(['xcode-select','-p'],text=True).strip()));p.add_argument('--ios-app');p.add_argument('--macos-app');p.add_argument('--duo-device',help='A task-owned, booted Duo already selected and oriented in foreground Device Hub');a=p.parse_args();os.environ['DEVELOPER_DIR']=a.developer_dir
out=pathlib.Path(a.output).expanduser().resolve()/'apple';raw=out/'raw';raw.mkdir(parents=True,exist_ok=True)
def run(*v,cwd=R):subprocess.check_call([str(x) for x in v],cwd=cwd)
def data(*v):return json.loads(subprocess.check_output(v,text=True))
families=a.families.split(',');devices=[];tag=uuid.uuid4().hex[:8]
if any(f not in {'iphone','ipad','duo-compact','duo-expanded','macos'} for f in families):p.error('Unknown Apple screenshot family')
with tempfile.TemporaryDirectory(prefix='esemnbun-store-build-') as temp:
 temp=pathlib.Path(temp)
 if set(families)&{'iphone','ipad','duo-compact','duo-expanded'}:
  ios=a.ios_app
  if not ios:
   run('xcodebuild','-project','apple/eSemnBun.xcodeproj','-scheme','eSemnBun-iOS','-configuration','Debug','-destination','generic/platform=iOS Simulator','-derivedDataPath',temp/'ios','CODE_SIGNING_ALLOWED=NO','build');ios=temp/'ios/Build/Products/Debug-iphonesimulator/eSemnBun.app'
  runtimes=[r for r in data('xcrun','simctl','list','runtimes','--json')['runtimes'] if r.get('isAvailable') and r['identifier'].startswith('com.apple.CoreSimulator.SimRuntime.iOS-') and int(r['version'].split('.')[0])>=26]
  if not runtimes:raise SystemExit('Install an iOS 26 or newer simulator runtime')
  stable=[r for r in runtimes if int(r['version'].split('.')[0])==26]
  runtime=max(stable or runtimes,key=lambda r:tuple(map(int,r['version'].split('.'))))
  try:
   for family in [f for f in families if f in ['iphone','ipad']]:
    typ='com.apple.CoreSimulator.SimDeviceType.'+('iPhone-17-Pro-Max' if family=='iphone' else 'iPad-Pro-13-inch-M5-12GB')
    udid=subprocess.check_output(['xcrun','simctl','create','eSemnBun-store-'+family+'-'+tag,typ,runtime['identifier']],text=True).strip();devices.append(udid)
    try:run('python3',T/'apple_capture.py','--app',(R/ios).resolve(),'--device',udid,'--family',family,cwd=raw)
    finally:
     subprocess.run(['xcrun','simctl','shutdown',udid],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);run('xcrun','simctl','delete',udid);devices.remove(udid)
  finally:
   for udid in devices:
    subprocess.run(['xcrun','simctl','shutdown',udid],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);run('xcrun','simctl','delete',udid)
 if any(f.startswith('duo-') for f in families):
  duoFamilies=[f for f in families if f.startswith('duo-')]
  if len(duoFamilies)!=1 or not a.duo_device:raise SystemExit('Duo capture needs one manually prepared family at a time: --families duo-compact|duo-expanded --duo-device UDID. Select a task-owned eSemnBun-store-* device in foreground Device Hub and set its fold state/orientation first.')
  available=[d for group in data('xcrun','simctl','list','devices','--json')['devices'].values() for d in group]
  device=next(d for d in available if d['udid']==a.duo_device)
  if device['state']!='Booted' or not device['name'].startswith('eSemnBun-store-'):raise SystemExit('Only a booted task-owned eSemnBun-store-* simulator is accepted')
  helper=temp/'devicehub-capture';run('swiftc',T/'devicehub-capture.swift','-o',helper)
  run('python3',T/'apple_capture.py','--app',(R/ios).resolve(),'--device',a.duo_device,'--family',duoFamilies[0],'--devicehub-helper',helper,'--keep-booted',cwd=raw)
 if 'macos' in families:
  mac=a.macos_app
  if not mac:
   run('xcodebuild','-project','apple/eSemnBun.xcodeproj','-scheme','eSemnBun-macOS','-configuration','Debug','-derivedDataPath',temp/'mac','CODE_SIGNING_ALLOWED=NO','build');mac=temp/'mac/Build/Products/Debug/eSemnBun.app'
  run('python3',T/'apple_capture_macos.py','--app',mac,'--output',raw)
 run('python3',T/'apple_render.py','--raw',raw,'--output',out/'screenshots','--supplemental-output',out/'supplemental')
 if set(families)>={'iphone','ipad','macos'}:run('python3',T/'apple_validate.py',out/'screenshots')
