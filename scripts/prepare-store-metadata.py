#!/usr/bin/env python3
"""Export local store metadata from the shared localization catalog. Never uploads."""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--check', action='store_true', help='Validate required fields and generated export drift without writing')
a = p.parse_args()
config = json.loads((ROOT / 'distribution/stores.json').read_text())
metadata = json.loads((ROOT / 'localization/catalog.json').read_text())['storeMetadata']
locales = {'ro': 'ro', 'en': 'en-US', 'ru': 'ru'}
outputs = {}
for lang in config['locales']:
    m = metadata[lang]
    if len(m['name']) > 30 or len(m['subtitle']) > 30 or len(m['keywords']) > 100 or len(m['shortDescription']) > 80:
        raise SystemExit(f'Listing length limit exceeded for {lang}')
    outputs[f'distribution/metadata/{lang}.json'] = json.dumps(m, ensure_ascii=False, indent=2) + '\n'
    for platform in ['ios', 'macos']:
        folder = f'distribution/apple/{platform}/{locales[lang]}'
        for key, source in {'name': 'name', 'subtitle': 'subtitle', 'description': 'description', 'keywords': 'keywords', 'release_notes': 'releaseNotes'}.items():
            outputs[f'{folder}/{key}.txt'] = m[source] + '\n'
        for field, target in {'supportURL': 'support_url', 'privacyPolicyURL': 'privacy_url'}.items():
            if config[field]:
                outputs[f'{folder}/{target}.txt'] = config[field] + '\n'
    folder = f'distribution/google/metadata/android/{locales[lang]}'
    for key, source in {'title': 'name', 'short_description': 'shortDescription', 'full_description': 'description'}.items():
        outputs[f'{folder}/{key}.txt'] = m[source] + '\n'
    for store in ['microsoft', 'huawei']:
        outputs[f'distribution/{store}/listings/{lang}.json'] = json.dumps(m, ensure_ascii=False, indent=2) + '\n'
failed = []
for path, body in outputs.items():
    file = ROOT / path
    if a.check:
        if not file.exists() or file.read_text() != body:
            failed.append(path)
    else:
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(body)
missing = [k for k in ['privacyPolicyURL', 'supportURL'] if not config[k]]
if missing:
    print('Submission fields still required: ' + ', '.join(missing))
    if a.check:
        sys.exit(1)
if failed:
    print('Store exports differ:\n' + '\n'.join(failed), file=sys.stderr)
    sys.exit(1)
print('Local metadata ' + ('matches' if a.check else 'exported') + ' for Apple, Google, Microsoft and Huawei.')
if config.get('usesPlaceholderURLs'):
    print('Support/privacy URLs are intentional placeholders; replace before submission.')
