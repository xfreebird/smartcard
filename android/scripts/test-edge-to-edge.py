#!/usr/bin/env python3
"""Exercise phone/tablet, cutout, navigation, rotation, theme and IME bounds on a dedicated emulator."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('serial')
    parser.add_argument('output', type=Path, help='Fresh evidence directory; install the current Debug app/test APK first')
    args = parser.parse_args()
    if not args.serial.startswith('emulator-') or args.output.exists():
        parser.error('A dedicated emulator and a fresh evidence directory are required')
    args.output.mkdir(parents=True)
    adb = [os.environ.get('ADB', 'adb'), '-s', args.serial]

    def call(*parts):
        return subprocess.check_output(adb + list(parts), text=True).strip()

    def shell(*parts):
        return call('shell', *parts)

    original = {key: shell('settings', 'get', namespace, key) for namespace, key in [
        ('system', 'accelerometer_rotation'), ('system', 'user_rotation'), ('secure', 'show_ime_with_hard_keyboard')]}
    original['size'] = re.search(r'Override size: (\S+)', shell('wm', 'size'))
    original['density'] = re.search(r'Override density: (\S+)', shell('wm', 'density'))
    overlays = shell('cmd', 'overlay', 'list', '--user', '0')
    selected = re.findall(r'\[x\] (com\.android\.internal\.(?:systemui\.navbar|display\.cutout\.emulation)\.\S+)', overlays)
    cutout = 'com.android.internal.display.cutout.emulation.tall'
    results = []
    try:
        shell('settings', 'put', 'system', 'accelerometer_rotation', '0')
        shell('settings', 'put', 'secure', 'show_ime_with_hard_keyboard', '1')
        for form, size, density in [('phone', '1080x1920', '420'), ('tablet', '1600x2560', '240')]:
            shell('wm', 'size', size)
            shell('wm', 'density', density)
            shell('cmd', 'overlay', 'enable' if form == 'phone' else 'disable', '--user', '0', cutout)
            for navigation in ['gestural', 'threebutton']:
                shell('cmd', 'overlay', 'enable-exclusive', '--category', '--user', '0',
                      'com.android.internal.systemui.navbar.' + navigation)
                for rotation, name in [('0', 'portrait'), ('1', 'landscape')]:
                    shell('settings', 'put', 'system', 'user_rotation', rotation)
                    case = f'{form}-{navigation}-{name}'
                    text = call('shell', 'am', 'instrument', '-w', '-r', '-e', 'suite', 'edge-to-edge',
                                '-e', 'case', case, 'md.esemnbun.app.test/md.moldsign.app.FileProtectionInstrumentation')
                    (args.output / f'{case}.log').write_text(text + '\n')
                    if 'INSTRUMENTATION_CODE: -1' not in text or 'PASS: edge-to-edge' not in text or text.count(':pass') != 2:
                        raise RuntimeError(f'{case} failed: {text}')
                    for theme in ['light', 'dark']:
                        for view in ['workspace', 'keyboard']:
                            file = f'{case}-{theme}-{view}.png'
                            data = subprocess.check_output(adb + ['exec-out', 'run-as', 'md.esemnbun.app',
                                                                 'cat', 'cache/edge-to-edge/' + file])
                            (args.output / file).write_bytes(data)
                    results.append(case)
                    print(case + ': passed light/dark workspace and PIN keyboard bounds', flush=True)
    finally:
        shell('wm', 'size', original['size'][1] if original['size'] else 'reset')
        shell('wm', 'density', original['density'][1] if original['density'] else 'reset')
        shell('cmd', 'overlay', 'disable', '--user', '0', cutout)
        for overlay in selected:
            shell('cmd', 'overlay', 'enable', '--user', '0', overlay)
        for namespace, key in [('system', 'accelerometer_rotation'), ('system', 'user_rotation'),
                               ('secure', 'show_ime_with_hard_keyboard')]:
            value = original[key]
            shell('settings', 'delete', namespace, key) if value == 'null' else shell('settings', 'put', namespace, key, value)
    (args.output / 'summary.json').write_text(json.dumps({'cases': results, 'theme_cases': len(results) * 2,
        'screenshots': len(results) * 4, 'serial': args.serial}, indent=2) + '\n')


if __name__ == '__main__':
    main()
