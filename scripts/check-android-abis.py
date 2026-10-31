#!/usr/bin/env python3
"""Check that an APK/AAB has matching native libraries with correct ARM/x86 ELF headers."""
import argparse
from pathlib import Path
import struct
import zipfile

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('package',type=Path)
a=p.parse_args()
expected={'armeabi-v7a':(1,40),'arm64-v8a':(2,183),'x86':(1,3),'x86_64':(2,62)}
libs={abi:set() for abi in expected}
with zipfile.ZipFile(a.package) as z:
    for name in z.namelist():
        parts=name.split('/')
        if name.startswith('base/lib/'):parts=parts[1:]
        if len(parts)!=3 or parts[0]!='lib' or not parts[2].endswith('.so'):continue
        _,abi,library=parts
        if abi not in expected:continue
        data=z.read(name)
        if data[:4]!=b'\x7fELF':raise SystemExit(f'Invalid native library: {name}')
        byte_order='<' if data[5]==1 else '>'
        actual=(data[4],struct.unpack(byte_order+'H',data[18:20])[0])
        if actual!=expected[abi]:raise SystemExit(f'Wrong ELF architecture: {name}: {actual}')
        libs[abi].add(library)
reference=libs['arm64-v8a']
if not reference:raise SystemExit('ARM64 native libraries missing')
for abi,names in libs.items():
    if names!=reference:raise SystemExit(f'Native library mismatch for {abi}: {sorted(names)} vs {sorted(reference)}')
print('Native libraries verified for '+', '.join(expected)+': '+', '.join(sorted(reference)))
print('This is package verification; runtime checks are separate.')
