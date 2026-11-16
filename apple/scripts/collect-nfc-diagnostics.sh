#!/bin/bash
# Copy only development NFC metadata into a fresh local evidence directory.
set -euo pipefail
device=${1:?Usage: collect-nfc-diagnostics.sh DEVICE_UDID FRESH_OUTPUT_DIRECTORY}
out=${2:?Fresh output directory required}
[[ ! -e "$out" ]] || { echo 'Use a fresh directory to preserve previous evidence.' >&2; exit 2; }
mkdir -p "$out"
xcrun devicectl device copy from --device "$device" --domain-type appDataContainer \
    --domain-identifier md.esemnbun.ios --source Library/Caches/NFCDiagnostics \
    --destination "$out/raw" --json-output "$out/transfer.json" --timeout 30
python3 - "$out" <<'PY'
import hashlib, json, sys
from pathlib import Path
out = Path(sys.argv[1])
root_keys = {'id', 'purpose', 'events', 'appVersion', 'build'}
event_keys = {'event', 'time', 'instruction', 'secure', 'responseBytes', 'status',
              'errorDomain', 'errorCode', 'underlyingDomain', 'underlyingCode'}
manifest = []
for path in sorted((out / 'raw').rglob('nfc-*.json')):
    raw = path.read_bytes()
    report = json.loads(raw)
    if set(report) - root_keys or any(set(e) - event_keys for e in report['events']):
        raise SystemExit('Unexpected diagnostic fields: keep this evidence private and review the schema.')
    manifest.append({'file': str(path.relative_to(out)), 'sha256': hashlib.sha256(raw).hexdigest(),
                     'bytes': len(raw), 'build': report.get('build'), 'purpose': report['purpose']})
if not manifest:
    raise SystemExit('No NFC reports were found. Complete one scan in the diagnostic build first.')
(out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(f'Collected and hashed {len(manifest)} NFC metadata reports. No documents or card contents copied.')
PY
