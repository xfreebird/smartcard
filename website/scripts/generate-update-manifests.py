#!/usr/bin/env python3
"""Write the stable standalone-desktop update channel from a published release tag."""
import argparse
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--version', required=True)
parser.add_argument('--out', type=Path, default=Path(__file__).resolve().parents[1] / 'static/updates')
args = parser.parse_args()
version = args.version.removeprefix('v')
if not re.fullmatch(r'\d+\.\d+\.\d+', version):
    parser.error('Use a stable x.y.z release version')
args.out.mkdir(parents=True, exist_ok=True)
for platform in ('macos', 'windows', 'linux'):
    (args.out / f'{platform}.json').write_text(json.dumps({
        'version': version,
        'downloadURL': 'https://esemnbun.md/downloads/',
    }, indent=2) + '\n')
