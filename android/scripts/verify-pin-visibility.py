#!/usr/bin/env python3
"""Verify the mock PIN field and actions are visible above a real emulator IME window."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('serial')
parser.add_argument('output', type=Path)
args = parser.parse_args()
if not args.serial.startswith('emulator-'):
    raise SystemExit('Use the dedicated mock emulator.')
adb = os.environ.get('ADB', str(Path(os.environ.get('ANDROID_HOME', str(Path.home()/'Library/Android/sdk')))/'platform-tools/adb'))
def run(*command):
    return subprocess.check_output([adb, '-s', args.serial, *command], text=True, stderr=subprocess.DEVNULL)
def bounds(value):
    return list(map(int, re.findall(r'\d+', value)))

density_values = re.findall(r'\d+', run('shell', 'wm', 'density'))
density = int(density_values[-1]) / 160
minimum_heights = {'pin.field': round(56 * density), 'pin.cancel': round(48 * density), 'pin.confirm': round(48 * density)}
last = None
for attempt in range(10):
    run('shell', 'uiautomator', 'dump', '/sdcard/esemnbun-pin-layout.xml')
    tree = ET.fromstring(run('exec-out', 'cat', '/sdcard/esemnbun-pin-layout.xml'))
    nodes = {node.get('resource-id'): bounds(node.get('bounds', '')) for node in tree.iter('node')}
    windows = run('shell', 'dumpsys', 'window', 'windows')
    keyboard = []
    for line in windows.splitlines():
        if 'ime' in line.lower() and 'visible=true' in line.lower():
            match = re.search(r'frame=(\[\d+,\d+\]\[\d+,\d+\])', line, re.I)
            if match:
                rect = bounds(match.group(1))
                if rect[3] > rect[1] > 0:
                    keyboard.append(rect)
    if not keyboard:
        # Some Android releases print InsetsState only in the unfiltered dump.
        windows = run('shell', 'dumpsys', 'window')
        for line in windows.splitlines():
            if 'type=ime' in line.lower() and 'visible=true' in line.lower():
                match = re.search(r'frame=(\[\d+,\d+\]\[\d+,\d+\])', line, re.I)
                if match:
                    rect = bounds(match.group(1))
                    if rect[3] > rect[1] > 0:
                        keyboard.append(rect)
    ime_top = min((rect[1] for rect in keyboard), default=None)
    controls = {key: nodes.get(key) for key in ['pin.field', 'pin.cancel', 'pin.confirm']}
    passed = ime_top is not None and all(rect and len(rect) == 4 and rect[2] > rect[0] and
        rect[1] >= 0 and rect[3] - rect[1] >= minimum_heights[key] - 1 and rect[3] <= ime_top
        for key, rect in controls.items())
    last = {'passed': bool(passed), 'serial': args.serial, 'keyboardTop': ime_top,
            'controls': controls, 'minimumControlHeights': minimum_heights, 'realPinEntered': False, 'capturedAt': time.time()}
    if passed:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(last, indent=2)+'\n')
        print('PIN field and both actions are fully above the visible keyboard.')
        break
    time.sleep(0.2)
else:
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(last, indent=2)+'\n')
    raise SystemExit('PIN visibility failed: '+json.dumps(last))
