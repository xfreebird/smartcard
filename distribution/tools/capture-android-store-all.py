#!/usr/bin/env python3
"""Build current Android app and capture all store layouts using a task-owned read-only emulator."""
import argparse,os,subprocess,tempfile,time,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--sdk',type=Path,default=Path(os.environ.get('ANDROID_HOME',Path.home()/'Library/Android/sdk')));p.add_argument('--avd',default='eSemnBun-mock');p.add_argument('--port',type=int,default=5562);a=p.parse_args()
adb=a.sdk/'platform-tools/adb';emulator=a.sdk/'emulator/emulator';serial=f'emulator-{a.port}'
assert a.port%2==0 and 5554<=a.port<=5682,'Use an even dedicated emulator port'
devices=subprocess.check_output([str(adb),'devices'],text=True)
if any(line.split() and line.split()[0]==serial for line in devices.splitlines()):raise SystemExit(f'{serial} is already in use; choose --port')
avds=subprocess.check_output([str(emulator),'-list-avds'],text=True).splitlines()
if a.avd not in avds:raise SystemExit(f'AVD {a.avd!r} not installed. Available: {avds}; pass --avd to select a test-compatible AVD.')
subprocess.run([str(ROOT/'android/gradlew'),':app:assembleDebug'],cwd=ROOT/'android',check=True)
with tempfile.TemporaryDirectory(prefix='esemnbun-android-store-') as task:
 with open(Path(task)/'emulator.log','w') as log:
  process=subprocess.Popen([str(emulator),'-avd',a.avd,'-read-only','-no-snapshot','-no-window','-no-audio','-port',str(a.port)],stdout=log,stderr=subprocess.STDOUT)
  try:
   for _ in range(240):
    if process.poll() is not None:raise RuntimeError('Test emulator exited; '+(Path(task)/'emulator.log').read_text()[-2000:])
    ready=subprocess.run([str(adb),'-s',serial,'shell','getprop','sys.boot_completed'],capture_output=True,text=True)
    if ready.returncode==0 and ready.stdout.strip()=='1':break
    time.sleep(.5)
   else:raise TimeoutError('Test emulator boot timed out')
   subprocess.run(['python3',str(ROOT/'distribution/tools/capture-android-store.py'),'--adb',str(adb),'--serial',serial,'--apk',str(ROOT/'android/app/build/outputs/apk/debug/app-debug.apk'),'--output',str(a.output/'google/assets/android')],check=True)
  finally:
   subprocess.run([str(adb),'-s',serial,'emu','kill'],capture_output=True)
   try:process.wait(timeout=20)
   except subprocess.TimeoutExpired:process.terminate();process.wait(timeout=10)
print('Android screenshot capture complete; read-only emulator stopped')
