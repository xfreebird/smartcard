#!/usr/bin/env python3
"""Capture a Debug app's localized fictional window; no reader or bridge operations."""
import argparse,json,os,pathlib,subprocess,tempfile,time
R=pathlib.Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--app',required=True);p.add_argument('--output',required=True);p.add_argument('--browser-only',action='store_true');a=p.parse_args();out=pathlib.Path(a.output)
with tempfile.TemporaryDirectory(prefix='esemnbun-store-mac-') as t:
 t=pathlib.Path(t); sw=t/'windows.swift';sw.write_text('''import Foundation
import CoreGraphics
let p=Int(CommandLine.arguments[1])!
for i in (CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements],kCGNullWindowID) as? [[String:Any]] ?? []) where i[kCGWindowOwnerPID as String] as? Int == p {
 let b=i[kCGWindowBounds as String] as? [String:Double] ?? [:]
 if CommandLine.arguments[2] == "pin" ? (i[kCGWindowLayer as String] as? Int == 3) : ((i[kCGWindowLayer as String] as? Int)==0 && (b["Width"] ?? 0)>600) { print(i[kCGWindowNumber as String]!);break }
}
''');helper=t/'windows';subprocess.check_call(['swiftc',str(sw),'-o',str(helper)])
 app=pathlib.Path(a.app);binary=app/'Contents/MacOS/eSemnBun';assert b'MSIGN_DEMO_SCENARIO' in (binary.parent/'eSemnBun.debug.dylib').read_bytes()
 manifest=[]
 for lang in ['ro','en','ru']:
  for key,scenario,tab,count,theme in [('01-sign','ready','sign','1','light'),('02-batch','multiple','sign','3','dark'),('03-consent','pin','sign','1','light'),('04-verify','ready','verify','1','light'),('05-card','multiple','card','3','dark'),('06-browser','ready','browser','1','light')]:
   if a.browser_only and tab!='browser':continue
   env=os.environ.copy();env.update({'MSIGN_DEMO_CARDS':count,'MSIGN_DEMO_SCENARIO':scenario,'MSIGN_DEMO_PREFERENCES_SUITE':'md.esemnbun.qa.store.assets','MSIGN_QA_NO_HARDWARE':'1','MSIGN_SCREENSHOT_CAPTURE':'1','MSIGN_QA_HIDE_TRAY':'1','MSIGN_DEMO_PREVIEW':'0','MSIGN_BROWSER_URL':'https://msign.gov.md/#/','MSIGN_DEMO_FILES':str(R/'swift/MoldSignKit/Resources/test.pdf')})
   if theme=='dark':env['MSIGN_DEMO_DARK']='1'
   process=subprocess.Popen([str(binary),'--show-main-window','-mainSection',tab,'-appLanguage',lang,'-appTheme',theme,'-AppleLanguages',f'({lang})'],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
   try:
    window=''
    for _ in range(25):
     window=subprocess.check_output([str(helper),str(process.pid),scenario],text=True).strip()
     if window:break
     time.sleep(.5)
    if not window:raise RuntimeError('No mock app window')
    if scenario != 'pin':
     script=f'tell application "System Events" to tell (first application process whose unix id is {process.pid}) to set size of first window to {{1280, 800}}'
     subprocess.run(['osascript','-e',script],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    time.sleep(8 if tab=='browser' else 2)
    dest=out/lang/'macos'/(key+'.png');dest.parent.mkdir(parents=True,exist_ok=True)
    subprocess.check_call(['/usr/sbin/screencapture','-x','-o','-l',window,str(dest)])
    manifest.append({'path':str(dest.relative_to(out)),'language':lang,'family':'macos','scenario':scenario,'tab':tab,'mock':True,'sourceApp':str(app)})
   finally:process.terminate();process.wait(timeout=10)
 (out/('manifest-macos-browser.json' if a.browser_only else 'manifest-macos.json')).write_text(json.dumps(manifest,indent=2)+'\n')
