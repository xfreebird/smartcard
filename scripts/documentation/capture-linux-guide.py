#!/usr/bin/env python3
"""Capture native GTK guide fixtures on the owner's isolated Fedora test VM."""
import subprocess, shlex, json, time, hashlib, uuid
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
AIR='user@192.168.50.126'
BASE='/tmp/esemnbun-guide-linux-capture'
BIN='/tmp/esemnbun-guide-linux-src/linux/.build/debug/esemnbun-gnome'
RUN='guide-linux-20261108-'+uuid.uuid4().hex
def air(command): return subprocess.check_output(['ssh',AIR,command],text=True)
def guest(command): return subprocess.check_output(['ssh','-J',AIR,'-p','2222','user@127.0.0.1',command],text=True)
def vnc(*args): return air(' '.join(shlex.quote(str(x)) for x in ['/Users/user/VMs/shots/venv/bin/python','/Users/user/VMs/shots/vshot.py','5901',*args]))
def launch(name,lang,scenario=None,cards='1',page='sign'):
 marker=f'{BASE}/{lang}-{name}.json'
 guest("pkill -f '^"+BIN+"$' || true")
 env={'XDG_RUNTIME_DIR':'/run/user/1000','WAYLAND_DISPLAY':'wayland-0','DBUS_SESSION_BUS_ADDRESS':'unix:path=/run/user/1000/bus','XDG_CONFIG_HOME':BASE+'/config','XDG_DATA_HOME':BASE+'/data','MSIGN_SCREENSHOT_CAPTURE':'1','MSIGN_DEMO_WORK_DIR':BASE+'/fixtures','MSIGN_DEMO_RUN_ID':RUN,'MSIGN_DEMO_READY_FILE':marker,'MSIGN_DEMO_LANGUAGE':lang,'MSIGN_DEMO_CARDS':cards,'MSIGN_DEMO_PAGE':page,'MSIGN_DEMO_DARK':'0','MSIGN_DEMO_WINDOW':'1100x780'}
 if scenario:env['MSIGN_DEMO_SCENARIO']=scenario
 command='env '+' '.join(k+'='+shlex.quote(v) for k,v in env.items())+' nohup '+BIN+' >'+BASE+'/'+lang+'-'+name+'.log 2>&1 </dev/null &'
 guest(command)

 markerdata={}
 for attempt in range(100):
  try:
   markerdata=json.loads(guest('cat '+shlex.quote(marker)+' 2>/dev/null || true'))
   if markerdata.get('run')==RUN:break
  except json.JSONDecodeError:pass
  time.sleep(.15)
 assert markerdata['run']==RUN and markerdata['language']==lang and markerdata['scenario']==(scenario or 'baseline'),markerdata
 return markerdata
SCENARIOS=[('connect',None,'noreader','sign',[]),('empty',None,'empty','sign',[]),('cards',None,'3','card',[]),('sign','documents','1','sign',[]),('format','documents','1','sign',['click',1055,510,'sleep',.3]),('stamp','documents','1','sign',['click',1055,510,'sleep',.3,'click',1055,764,'sleep',.5]),('pin','pin','1','sign',[]),('progress','signing','1','sign',[]),('success','success','1','sign',[]),('failure','signing-error','1','sign',[]),('verify','verify-valid','1','verify',[]),('invalid','verify-invalid','1','verify',[]),('untrusted','verify-unknown','1','verify',[]),('unsigned','verify-unsigned','1','verify',[]),('documents','activity','1','activity',[]),('details','activity','1','activity',['click',675,324,'sleep',.8]),('history','activity','1','activity',['click',463,218,'sleep',.3]),('settings','settings','1','sign',[])]
SCENARIOS += [('certificate','verify-valid','1','verify',[]),('background','settings','1','sign',[]),('about','settings','1','sign',['click',880,176,'sleep',.4]),('menu',None,'1','sign',['click',1287,149,'sleep',.3]),('history-confirm','activity','1','activity',['click',463,218,'sleep',.2,'click',1115,283,'sleep',.3])]
def main():
 guest('mkdir -p '+BASE+'/config '+BASE+'/data '+BASE+'/fixtures')
 records=ROOT/'docs/user-guide/linux-capture-records.json'
 evidence=json.loads(records.read_text()) if records.exists() else []
 for lang in ['en','ro','ru']:
  out=ROOT/'website/static/img/guide/linux'/lang;out.mkdir(parents=True,exist_ok=True)
  for name,scenario,cards,page,actions in SCENARIOS:
   target=out/(name+'.png')
   if target.is_file():continue
   info=launch(name,lang,scenario,cards,page)
   if actions:vnc(*actions)
   if name=='certificate':
    vnc('click',1110,855,'sleep',.2)
    air('~/VMs/shots/venv/bin/python ~/VMs/shots/scroll.py 5901 5 5')
   if name=='background':air('~/VMs/shots/venv/bin/python ~/VMs/shots/scroll.py 5901 5 10')
   vnc('move',1500,950,'sleep',.4,'shot','/tmp/guide-linux-current.png')
   tmp=Path('/tmp/guide-linux-current.png');subprocess.run(['scp','-q',AIR+':/tmp/guide-linux-current.png',str(tmp)],check=True)
   with Image.open(tmp) as im:
    box={'en':(1197,178,1378,333),'ro':(1205,178,1371,333),'ru':(1185,178,1396,333)}[lang] if name=='menu' else (250,126,1350,906)
    im.crop(box).save(target,optimize=True)
   evidence=[entry for entry in evidence if entry['path']!=str(target.relative_to(ROOT))]
   evidence.append({'path':str(target.relative_to(ROOT)),'locale':lang,'scenario':scenario or 'baseline','cards':cards,'page':page,'ready':info,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'dimensions':list(Image.open(target).size)})
   print(lang,name,flush=True)
 (ROOT/'docs/user-guide/linux-capture-records.json').write_text(json.dumps(evidence,indent=2)+'\n')
 guest("pkill -f '^"+BIN+"$' || true")
if __name__=='__main__':main()
