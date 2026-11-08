#!/usr/bin/env python3
"""Keep the browser's client catalog and downloadable skill aligned with the pack."""
import json
from export_integrations import ROOT, CLIENTS, SKILL
value = {'clients': [{'id': key, 'name': row[0], 'configPath': row[1], 'instructionsPath': row[2]} for key, row in CLIENTS.items()], 'skill': SKILL.read_text()}
(ROOT / 'website/src/data/agent-integrations.json').write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')
