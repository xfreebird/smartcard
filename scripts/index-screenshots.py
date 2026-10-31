#!/usr/bin/env python3
"""Index dated native mock screenshots without modifying image pixels."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('root',type=Path)
p.add_argument('--date',default='2026-10-30')
a=p.parse_args()
entries=[]
for platform in ['macos','ios','android','windows','linux']:
    for file in sorted((a.root/platform/a.date).rglob('*.png')):
        data=file.read_bytes()
        if data[:8]!=b'\x89PNG\r\n\x1a\n':raise SystemExit(f'Invalid PNG: {file}')
        width,height=struct.unpack('>II',data[16:24])
        entries.append({'platform':platform,'path':str(file.relative_to(a.root)),'width':width,'height':height,
                        'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
index={'date':a.date,'description':'Mock UI captures; counts do not prove semantic or hardware correctness.',
       'counts':{platform:sum(e['platform']==platform for e in entries) for platform in ['macos','ios','android','windows','linux']},
       'images':entries}
out=a.root/f'{a.date}-index.json'
out.write_text(json.dumps(index,indent=2)+'\n')
print(json.dumps(index['counts']))
print(out)
