#!/usr/bin/env python3
"""Capture isolated, localized Android guide fixtures on an explicit emulator."""
import hashlib,json,pathlib,subprocess,time,io,re,os
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[2]
ADB=os.environ.get('GUIDE_ADB',str(pathlib.Path.home()/'Library/Android/sdk/platform-tools/adb'))
SERIAL=os.environ.get('GUIDE_ANDROID_SERIAL','emulator-5562')
if not re.fullmatch(r'emulator-\d+', SERIAL): raise SystemExit('Choose an explicit Android emulator serial.')
APK=ROOT/'android/app/build/outputs/apk/debug/app-debug.apk'
OUT=ROOT/'website/static/img/guide'; XML=pathlib.Path('/tmp/esemnbun-android-guide-layouts'); XML.mkdir(exist_ok=True)
STATES=[('connect','permission','sign',None,None,False),('sign','batch','sign',None,None,False),('format','documents','sign','format-menu',None,False),('stamp','documents','sign',None,None,True),('pin','pin','sign',None,None,False),('results','results','sign',None,None,False),('verify','verify-valid','verify',None,None,False),('certificate','verify-valid','verify',None,'certificate',False),('original','verify-xml-missing','verify',None,None,False),('documents','cards','activity',None,None,False),('details','cards','activity','document-details',None,False),('history','history-review','activity','history',None,False),('browser','cards','browser',None,None,False),('card','cards','card',None,None,False),('about','cards','sign','about',None,False)]
STATES += [('sign-failure','sign-failure','sign',None,None,False),('sign-progress','documents','sign',None,None,False),('verify-invalid','verify-invalid','verify',None,None,False),('verify-unconfirmed','verify-unconfirmed','verify',None,None,False),('verify-none','verify-none','verify',None,None,False)]
STATES += [('settings','cards','sign','settings',None,False)]
STATES += [
    ('cards-current','cards','settings','settings',None,False),
    ('protect-menu-light','cards','activity','protect-menu',None,False),
    ('verify-technical','verify-valid','verify',None,'technical',False),
    ('verify-current','verify-review','verify',None,None,False),
    ('protect-password-light','cards','activity','protect-encrypt',None,False),
    ('protect-certificate-light','cards','activity','protect-certificate',None,False),
    ('protect-decrypt-light','cards','activity','protect-decrypt',None,False),
    ('protect-rsa-decrypt-light','cards','activity','protect-certificate-decrypt',None,False),
    ('protect-complete-light','cards','activity','protect-encrypt-complete',None,False),
    ('protect-decrypt-complete-light','cards','activity','protect-decrypt-complete',None,False),
]
if os.environ.get('GUIDE_CAPTURE_STATES'):
    selected=set(os.environ['GUIDE_CAPTURE_STATES'].split(',')); STATES=[state for state in STATES if state[0] in selected]
def run(*args,timeout=60):
    if args==('exec-out','screencap','-p') and os.environ.get('GUIDE_DISPLAY_ID'):args=(*args,'-d',os.environ['GUIDE_DISPLAY_ID'])
    return subprocess.check_output([ADB,'-s',SERIAL,*map(str,args)],stderr=subprocess.STDOUT,timeout=timeout)
def sh(*args):return run('shell',*args)
run('wait-for-device',timeout=120)
for _ in range(120):
    if sh('getprop','sys.boot_completed').strip()==b'1':break
    time.sleep(1)
else:raise RuntimeError('Android emulator boot did not complete')
run('install','-r',APK,timeout=120)
sh('wm','dismiss-keyguard')
sh('am','force-stop','md.esemnbun.app')
sh('run-as','md.esemnbun.app','mkdir','-p','cache/qa-capture','shared_prefs')
run('push',ROOT/'android/core/build/pades-test/sample-signed.pdf','/data/local/tmp/esb-guide-signed.pdf')
sh('run-as','md.esemnbun.app','cp','/data/local/tmp/esb-guide-signed.pdf','cache/qa-capture/signed.pdf')
notice=pathlib.Path('/tmp/esb-guide-notice.xml');notice.write_text('<?xml version="1.0" encoding="utf-8"?><map><boolean name="independence_notice_v1" value="true" /></map>')
run('push',notice,'/data/local/tmp/esb-guide-notice.xml');sh('run-as','md.esemnbun.app','cp','/data/local/tmp/esb-guide-notice.xml','shared_prefs/public_information.xml')
# Let AppCompat complete its one-time stored-language migration before choosing
# the first capture locale; migration can otherwise overwrite that first choice.
sh('am','start','-W','-n','md.esemnbun.app/md.moldsign.app.MainActivity','--es','demo','cards','--ez','store_capture','true')
time.sleep(2)
sh('am','force-stop','md.esemnbun.app')
sh('settings','put','system','accelerometer_rotation','0');sh('wm','user-rotation','lock','0');sh('cmd','uimode','night','no')
for key in ['window_animation_scale','transition_animation_scale','animator_duration_scale']:sh('settings','put','global',key,'0')
# Use Android's own screenshot clock and status icons in the documentation.
sh('settings','put','global','sysui_demo_allowed','1')
for command,options in [('enter',[]),('clock',['--es','hhmm','0941']),('notifications',['--es','visible','false'])]:
    sh('am','broadcast','-a','com.android.systemui.demo','--es','command',command,*options)
apk_sha=hashlib.sha256(APK.read_bytes()).hexdigest()
source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
source_dirty=bool(subprocess.check_output(['git','status','--porcelain','--','android'],cwd=ROOT,text=True).strip())
records=[]
evidence=ROOT/'docs/user-guide/android-evidence.json'
if evidence.exists(): records=json.loads(evidence.read_text()).get('screenshots',[])
for platform,w,h,density in [('android-phone',1080,2400,420),('android-tablet',1600,1100,160)]:
    sh('am','force-stop','md.esemnbun.app');sh('wm','size',f'{w}x{h}');sh('wm','density',density);time.sleep(1)
    for lang in ['en','ro','ru']:
        sh('am','force-stop','md.esemnbun.app');sh('cmd','locale','set-app-locales','md.esemnbun.app','--locales',lang)
        folder=OUT/platform/lang;folder.mkdir(parents=True,exist_ok=True)
        for name,scenario,page,dialog,expand,stamp in STATES:
            path=folder/(name+'.png');xmlpath=XML/f'{platform}-{lang}-{name}.xml'
            if path.exists() and xmlpath.exists() and os.environ.get('GUIDE_CAPTURE_REFRESH') != '1':continue
            if os.environ.get('GUIDE_CAPTURE_RESUME') and path.exists() and xmlpath.exists():
                digest=hashlib.sha256(path.read_bytes()).hexdigest()
                if b'package="md.esemnbun.app"' in xmlpath.read_bytes() and any(
                    r.get('apkSha256')==apk_sha and r.get('imageSha256')==digest and r['file']==str(path.relative_to(ROOT)) for r in records
                ): continue
            # MainActivity resets navigation and dialog state for each Debug screenshot intent.
            run('logcat','-c')
            args=['am','start','-W','--activity-single-top','-n','md.esemnbun.app/md.moldsign.app.MainActivity','--es','demo',scenario,'--es','demo_page',page,'--ez','store_capture','true']
            if dialog:args+=['--es','capture_dialog',dialog]
            if expand:args+=['--es','capture_expand',expand]
            if stamp:args+=['--ez','stamp_preview','true']
            if name=='sign-progress':args+=['--es','capture_step','Signing']
            sh(*args)
            expected='capture-ready:activity' if dialog=='document-details' else 'capture-scroll-ready:'+page if name in ['sign-failure','sign-progress','verify-invalid','verify-unconfirmed','verify-none'] else 'ready:'+page
            for _ in range(100):
                if expected in run('logcat','-d','-s','MoldSignDemo:I').decode(errors='replace'):break
                time.sleep(.15)
            else:raise RuntimeError(f'Not ready: {platform}/{lang}/{name}')
            time.sleep(1)
            if name=='pin':sh('input','keyevent','4');time.sleep(.25)
            # Certificate details are below the result summary on compact screens.
            if name in ('certificate','verify-technical'):
                for _ in range(2):sh('input','swipe',int(w*.6),int(h*.78),int(w*.6),int(h*.3),'250');time.sleep(.2)
            if name=='browser':
                sh('input','swipe',int(w*.7),int(h*.75),int(w*.7),int(h*.25),'250');time.sleep(.3)
            sh('uiautomator','dump','--compressed','/sdcard/esb-guide.xml')
            xml=sh('cat','/sdcard/esb-guide.xml')
            if b'package="md.esemnbun.app"' not in xml: raise RuntimeError(f'Unexpected foreground window: {platform}/{lang}/{name}')
            if name=='results' and b'DEMO-Application-NOT-SIGNED.pdf' not in xml:
                raise RuntimeError(f'Completed sample files missing: {platform}/{lang}/{name}')
            xmlpath.write_bytes(xml)
            if b'demo.banner' in xml:raise RuntimeError('Demo banner present')
            data=run('exec-out','screencap','-p');im=Image.open(io.BytesIO(data));im.load()
            if im.size!=(w,h):raise RuntimeError(f'Unexpected size {im.size}')
            path.write_bytes(data)
            rec={'staticSigningStep':'Signing' if name=='sign-progress' else None,'file':str(path.relative_to(ROOT)),'platform':platform,'language':lang,'pixels':list(im.size),'scenario':scenario,'page':page,'dialog':dialog,'expanded':expand,'theme':'light','synthetic':True,'bannerHidden':True,'serial':SERIAL,'apkSha256':apk_sha,'imageSha256':hashlib.sha256(data).hexdigest(),'capturedAt':time.time()}
            if os.environ.get('GUIDE_CAPTURE_HOST'):rec['captureHost']=os.environ['GUIDE_CAPTURE_HOST']
            rec['sourceCommit']=source_commit
            rec['sourceHasLocalChanges']=source_dirty
            records=[r for r in records if r['file']!=rec['file']]+[rec]
            evidence.parent.mkdir(exist_ok=True,parents=True)
            summary=json.loads(evidence.read_text()) if evidence.exists() else {'commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'build':'current source Debug APK','hardwareUsed':False,'realPinEntered':False,'validationLimits':['Mock presentation captures do not prove USB or physical card signing.','About may report Debug marketing version; use release availability from Downloads.','Certificate verification fixture details include deliberate example wording.']}
            summary['screenshots']=records
            evidence.write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
            print(platform,lang,name,flush=True)
sh('am','force-stop','md.esemnbun.app');sh('wm','size','reset');sh('wm','density','reset')
