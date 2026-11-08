#!/usr/bin/env python3
"""Check localized illustrated documentation coverage and static asset references."""
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[2]
navigation = json.loads((root / 'website/src/data/guide-navigation.json').read_text())
platforms = {item['id']: item['assetPlatform'] for item in navigation['platforms']}
errors, guides, checked_assets = [], [], set()
for language in ('en', 'ro', 'ru'):
    base = root / ('website/docs' if language == 'en' else
                   f'website/i18n/{language}/docusaurus-plugin-content-docs/current')
    for page, asset_platform in platforms.items():
        path = base / 'platforms' / f'{page}.md'
        if not path.is_file():
            errors.append(f'Missing localized guide: {path.relative_to(root)}')
            continue
        overview = path.read_text()
        if '<GuideDirectory ' not in overview or '<GuideScreenshot ' in overview:
            errors.append(f'{language}/{page}: overview must be a task directory')
        entry = next(item for item in navigation['platforms'] if item['id'] == page)
        texts = []
        for index, topic in enumerate(entry['topics']):
            task = base / 'platforms' / page / f"{topic['id']}.md"
            if not task.exists():
                errors.append(f'Missing task page: {task}')
                continue
            content = task.read_text()
            if page in ('windows', 'windows-cli') and '<GuideScreenshot ' not in content:
                errors.append(f'{task}: Windows task requires numbered visual instructions')
            if content.count('<GuideScreenshot ') != topic['panels'][language]:
                errors.append(f'{language}/{page}/{topic["id"]}: changed illustration coverage')
            if len(re.findall(r'^## ', content, re.M)) > 8:
                errors.append(f'{language}/{page}/{topic["id"]}: task is too broad')
            for target in re.findall(r'pagination_(?:prev|next): "([^"]+)"', content):
                if target != f'platforms/{page}' and not target.startswith(f'platforms/{page}/'):
                    errors.append(f'{task}: pagination leaves device')
            texts.append(content)
        text = '\n'.join(texts)
        images = re.findall(r'<GuideScreenshot\b[^>]*?\bsrc=[\"\']([^\"\']+)', text, re.S)
        for panel in re.findall(r'<GuideScreenshot\b[\s\S]*?/>', text):
            if not re.search(r'\bx[\"\']?\s*:\s*\d', panel) or not re.search(r'\by[\"\']?\s*:\s*\d', panel):
                errors.append(f'{language}/{page}: screenshot panel has no numbered target')
        minimum = 3 if page.endswith('-cli') else 6
        if len(images) < minimum:
            errors.append(f'{language}/{page}: {len(images)} illustrated panels; at least {minimum} required')
        if '0.2.0' in text:
            errors.append(f'{language}/{page}: obsolete version statement')
        for image in images:
            asset = root / 'website/static' / image.lstrip('/')
            if not asset.is_file():
                errors.append(f'{language}/{page}: missing asset {image}')
            if asset.is_file() and asset not in checked_assets:
                checked_assets.add(asset)
                if asset.suffix == '.png':
                    data = asset.read_bytes()
                    if not data.startswith(bytes.fromhex('89504e470d0a1a0a')) or not data.endswith(bytes.fromhex('0000000049454e44ae426082')):
                        errors.append(f'Truncated or invalid PNG: {image}')
                elif asset.suffix == '.svg':
                    try:
                        ET.parse(asset)
                    except ET.ParseError as error:
                        errors.append(f'Invalid SVG: {image}: {error}')
            allowed_platforms = [asset_platform] + ([asset_platform[:-4]] if asset_platform.endswith('-cli') else [])
            if not any(image.startswith(f'/img/guide/{allowed}/{language}/') for allowed in allowed_platforms):
                errors.append(f'{language}/{page}: incorrect platform or native locale in {image}')
        for coordinate in re.findall(r"\b[xy][\"']?\s*:\s*(-?\d+(?:\.\d+)?)", text):
            if not 0 <= float(coordinate) <= 100:
                errors.append(f'{language}/{page}: callout outside image ({coordinate})')
        guides.append({'locale': language, 'platform': page, 'panels': len(images),
                       'assets': len(set(images))})
result = {'guides': guides, 'guideCount': len(guides), 'taskPageCount': sum(len(item['topics']) for item in navigation['platforms']) * 3,
          'panelCount': sum(guide['panels'] for guide in guides), 'errors': errors}
print(json.dumps(result, ensure_ascii=False, indent=2))
raise SystemExit(bool(errors))
