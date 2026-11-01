#!/usr/bin/env python3
"""Stage current source, build and capture fictional Windows UI in the Air VM's interactive session."""
import argparse,base64,json,subprocess,tarfile,tempfile,time,zipfile,shutil,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--air',default='user@192.168.50.126');p.add_argument('--guest',default='user@127.0.0.1');p.add_argument('--port',default='2223');p.add_argument('--stage',default='C:/Users/user/store-screenshot-refresh');p.add_argument('--timeout',type=int,default=1500);a=p.parse_args()
a.output=a.output/'microsoft/assets'
assert a.stage.lower().startswith('c:/users/') and 'screenshot' in a.stage.lower(), 'Use a dedicated screenshot staging folder below C:/Users'
assert all(c.isalnum() or c in ':/_-.' for c in a.stage),'Stage path must contain safe path characters only'
def ps(code,check=True):
 encoded=base64.b64encode(code.encode('utf-16le')).decode()
 for attempt in range(4):
  r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-J',a.air,'-p',a.port,a.guest,'powershell','-NoProfile','-EncodedCommand',encoded],capture_output=True,text=True)
  if r.returncode != 255:break
  if attempt<3:time.sleep(2)
 if check and r.returncode:raise RuntimeError(r.stderr.strip() or r.stdout.strip() or f'Guest SSH failed ({r.returncode})')
 return r.stdout.strip()
def scp(source,target):subprocess.run(['scp','-o',f'ProxyJump={a.air}','-P',a.port,str(source),target],check=True)
task='eSemnBun-store-capture-refresh'
ps(f"$existing=Get-ScheduledTask -TaskName '{task}' -ErrorAction SilentlyContinue; if($existing -and $existing.State -eq 'Running'){{ throw 'Another screenshot capture is already running' }}")
with tempfile.TemporaryDirectory(prefix='esemnbun-store-source-') as temp:
 archive=Path(temp)/'source.tgz'
 with tarfile.open(archive,'w:gz') as tar:
  for item in ('windows','spec','localization','distribution/tools/capture-windows-store.ps1','swift/MoldSignKit/Resources/localhost.p12'):
   def filt(member):
    parts=Path(member.name).parts
    return None if any(x in ('bin','obj','artifacts','.build','ShellPayload','HelperPayload') or x.startswith('._') for x in parts) else member
   tar.add(ROOT/item,arcname=item,filter=filt)
 ps(f"New-Item -ItemType Directory -Force '{a.stage}' | Out-Null")
 scp(archive,f'{a.guest}:{a.stage}/source.tgz')
 ps(f"foreach($name in @('windows','spec','localization','distribution','swift')){{ Remove-Item ('{a.stage}/'+$name) -Recurse -Force -ErrorAction SilentlyContinue }}; tar -xzf '{a.stage}/source.tgz' -C '{a.stage}'; if($LASTEXITCODE -ne 0){{throw 'Source extraction failed'}}")
 # Run in the logged-in desktop rather than an SSH child session (which can terminate GUI descendants).
 script=f'''$ErrorActionPreference='Stop'
$root='{a.stage}'
try {{
 Set-Location "$root/windows"
 & "$env:USERPROFILE/dotnet-x64/dotnet.exe" publish src/MoldSign.App -c Debug -r win-x64 -p:Platform=x64 --self-contained true -p:WindowsPackageType=None -o "$root/publish" *> "$root/build.log"
 if($LASTEXITCODE -ne 0){{throw 'Windows publish failed; inspect build.log'}}
 & "$root/distribution/tools/capture-windows-store.ps1" -App "$root/publish/eSemnBun.exe" -OutputDirectory "$root/raw"
 Compress-Archive -Path "$root/raw/*" -DestinationPath "$root/raw.zip" -Force
 'OK' | Set-Content "$root/result.txt"
}} catch {{ $_.ToString() | Set-Content "$root/result.txt"; exit 1 }}
'''
 encoded=base64.b64encode(script.encode('utf-8')).decode()
 ps(f"[IO.File]::WriteAllText('{a.stage}/run.ps1',[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('{encoded}'))); Remove-Item '{a.stage}/result.txt' -ErrorAction SilentlyContinue; $action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File {a.stage}/run.ps1'; $principal=New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive; Register-ScheduledTask -TaskName '{task}' -Action $action -Principal $principal -Force | Out-Null; Start-ScheduledTask -TaskName '{task}'")
 try:
  start=time.monotonic()
  while time.monotonic()-start<a.timeout:
   result=ps(f"if(Test-Path '{a.stage}/result.txt'){{Get-Content '{a.stage}/result.txt' -Raw}}")
   if result:
    if result!='OK':raise RuntimeError(result)
    break
   time.sleep(3)
  else:raise TimeoutError('Windows capture task timed out')
  outputzip=Path(temp)/'raw.zip';scp(f'{a.guest}:{a.stage}/raw.zip',str(outputzip))
  unpack=Path(temp)/'raw'
  with zipfile.ZipFile(outputzip) as capture_zip:
   for member in capture_zip.infolist():
    relative=Path(member.filename.replace('\\','/'))
    if relative.is_absolute() or '..' in relative.parts:raise RuntimeError('Unsafe capture archive path')
    target=unpack/relative
    if member.is_dir():target.mkdir(parents=True,exist_ok=True)
    else:target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(capture_zip.read(member))
  manifest=[]
  for tag,locale in [('ro-RO','ro'),('en-US','en'),('ru-RU','ru')]:
   for i,page in enumerate(('sign','card','verify','settings'),1):
    source=unpack/tag/f'{page}.png';target=a.output/locale/f'{i:02}-{page}.png';target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    manifest.append({'file':str(target),'locale':locale,'page':page,'sourceBuild':f'{a.stage}/publish/eSemnBun.exe','sourceArchiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'fixture':'two fictional cards','hardware':False})
  (a.output/'capture-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(f'Captured {len(manifest)} Windows screenshots; build retained at {a.stage}/publish')
 finally:ps(f"Unregister-ScheduledTask -TaskName '{task}' -Confirm:$false -ErrorAction SilentlyContinue",check=False)
