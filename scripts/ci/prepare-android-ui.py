#!/usr/bin/env python3
"""Establish a healthy launcher before installing the app on a fresh CI emulator."""
import argparse
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path


def inspect_hierarchy(xml):
    nodes = list(ET.fromstring(xml).iter('node'))
    if any(node.get('text') == "System UI isn't responding" for node in nodes):
        wait = next((node for node in nodes if node.get('resource-id') == 'android:id/aerr_wait'), None)
        if wait is None:
            raise RuntimeError('System UI boot dialog has no native Wait action')
        bounds = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', wait.get('bounds', ''))
        if bounds is None:
            raise RuntimeError('System UI Wait action has no usable bounds')
        left, top, right, bottom = map(int, bounds.groups())
        return 'system-ui', ((left + right) // 2, (top + bottom) // 2)
    # An unrelated ANR or permission dialog must never be dismissed by this setup step.
    if any(node.get('resource-id', '').startswith('android:id/aerr_') for node in nodes):
        raise RuntimeError('Unexpected application error before test installation')
    launcher = any(node.get('package') in ('com.android.launcher3', 'com.google.android.apps.nexuslauncher')
                   for node in nodes)
    return ('ready' if launcher else 'waiting'), None


def prepare(serial, output, adb='adb'):
    if not serial.startswith('emulator-'):
        raise ValueError('A dedicated emulator is required')
    output.mkdir(parents=True, exist_ok=False)
    def command(*args):
        return subprocess.check_output([adb, '-s', serial, *args], timeout=20)
    command('shell', 'wm', 'dismiss-keyguard')
    command('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    deadline = time.monotonic() + 90
    recovered_at = None
    stable = 0
    events = []
    try:
        while time.monotonic() < deadline:
            # A failed dump must not leave a previous healthy hierarchy to reuse.
            command('shell', 'rm', '-f', '/sdcard/ci-boot.xml')
            command('shell', 'uiautomator', 'dump', '/sdcard/ci-boot.xml')
            xml = command('exec-out', 'cat', '/sdcard/ci-boot.xml').decode()
            (output / f'hierarchy-{len(events):02d}.xml').write_text(xml)
            try:
                state, point = inspect_hierarchy(xml)
            except ET.ParseError:
                # Boot completion precedes the first accessible window on cold images.
                state, point = 'waiting-accessibility', None
            events.append(state)
            if state == 'system-ui':
                if recovered_at is None:
                    (output / 'boot-dialog.png').write_bytes(command('exec-out', 'screencap', '-p'))
                    command('shell', 'input', 'tap', str(point[0]), str(point[1]))
                    recovered_at = time.monotonic()
                    stable = 0
                    command('shell', 'wm', 'dismiss-keyguard')
                    command('shell', 'input', 'keyevent', 'KEYCODE_HOME')
                    print('Acknowledged the initial System UI cold-boot dialog before app installation.', flush=True)
                elif stable or time.monotonic() - recovered_at > 15:
                    raise RuntimeError('System UI did not recover; application tests were not started')
            elif state == 'ready':
                stable += 1
                if stable == 3:
                    print('Launcher remained healthy across three readiness checks.', flush=True)
                    return
            else:
                stable = 0
            time.sleep(2)
        raise RuntimeError('Emulator launcher did not become ready; application tests were not started')
    finally:
        (output / 'readiness.json').write_text(json.dumps({'states': events, 'bootDialogAcknowledged': recovered_at is not None}, indent=2))
        try:
            (output / 'boot-logcat.txt').write_bytes(command('logcat', '-d'))
        except (OSError, subprocess.SubprocessError) as error:
            (output / 'diagnostic-error.txt').write_text(str(error))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('serial')
    parser.add_argument('output', type=Path)
    arguments = parser.parse_args()
    prepare(arguments.serial, arguments.output)
