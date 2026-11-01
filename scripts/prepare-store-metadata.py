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

def platform_copy(m, platform):
    return m['description'] + '\n\n' + m['platformNotes'][platform]

def validate_text(value, limit, label, byte_limit=False):
    length = len(value.encode('utf-8')) if byte_limit else len(value)
    if not value or length > limit:
        raise SystemExit(f'{label}: {length} exceeds {limit} or is empty')
outputs = {}
for lang in config['locales']:
    m = metadata[lang]
    for field, limit in [('name', 30), ('subtitle', 30), ('shortDescription', 80), ('promotionalText', 170), ('releaseNotes', 4000)]:
        validate_text(m[field], limit, f'{lang}/{field}')
    validate_text(m['keywords'], 100, f'{lang}/keywords UTF-8', byte_limit=True)
    for platform in ['ios', 'macos', 'android', 'windows']:
        validate_text(platform_copy(m, platform), 4000, f'{lang}/{platform}/description')
    outputs[f'distribution/metadata/{lang}.json'] = json.dumps(m, ensure_ascii=False, indent=2) + '\n'
    for platform in ['ios', 'macos']:
        folder = f'distribution/apple/{platform}/{locales[lang]}'
        for key, source in {'name': 'name', 'subtitle': 'subtitle', 'description': 'description', 'keywords': 'keywords', 'release_notes': 'releaseNotes', 'promotional_text': 'promotionalText'}.items():
            outputs[f'{folder}/{key}.txt'] = (platform_copy(m, platform) if source == 'description' else m[source]) + '\n'
        for field, target in {'supportURL': 'support_url', 'privacyPolicyURL': 'privacy_url', 'marketingURL': 'marketing_url'}.items():
            if config[field]:
                outputs[f'{folder}/{target}.txt'] = config[field] + '\n'
    folder = f'distribution/google/metadata/android/{locales[lang]}'
    for key, source in {'title': 'name', 'short_description': 'shortDescription', 'full_description': 'description'}.items():
        outputs[f'{folder}/{key}.txt'] = (platform_copy(m, 'android') if source == 'description' else m[source]) + '\n'
    for store in ['microsoft', 'huawei']:
        platform = 'windows' if store == 'microsoft' else 'android'
        listing = dict(m, description=platform_copy(m, platform), languageCode=config.get('storeLocales', {}).get(store, {}).get(lang, locales[lang]), website=config['marketingURL'], supportURL=config['supportURL'], privacyPolicyURL=config['privacyPolicyURL'], termsURL=config['termsURL'], searchTerms=m['keywords'].split(',')[:7])
        if any(len(term) > 40 for term in listing['searchTerms']):
            raise SystemExit(f'{lang}: Microsoft search term exceeds 40 characters')
        outputs[f'distribution/{store}/listings/{lang}.json'] = json.dumps(listing, ensure_ascii=False, indent=2) + '\n'
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
    print('esemnbun.md URL paths are reserved placeholders; publish content and verify reachability before submission.')
