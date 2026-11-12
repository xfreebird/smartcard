#!/bin/bash
# Seed one synthetic file in a dedicated simulator; native Files UI selects it.
set -euo pipefail
platform=${1:?ios}; app=${2:?Debug app}; device=${3:?Dedicated simulator}; out=${4:?Fresh output}
[[ "$platform" == ios ]] || { echo 'Protection picker suite requires iOS.' >&2; exit 2; }
repo=$(cd "$(dirname "$0")/../.." && pwd)
if [[ ${MSIGN_UI_APP_INSTALLED:-0} != 1 ]]; then
    xcrun simctl install "$device" "$app"
fi
container=$(xcrun simctl get_app_container "$device" md.esemnbun.ios data)
mkdir -p "$out"
python3 - "$container" "$out" "$repo/swift/MoldSignKit/Resources/test.pdf" <<'PY'
import json, pathlib, shutil, sys
root, out, sample = map(pathlib.Path, sys.argv[1:])
source = root / 'Documents/ProtectionSource.pdf'
if source.exists():
    raise SystemExit('Use a fresh dedicated simulator: protection fixture already exists')
source.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(sample, source)
(out / 'existing-outputs.json').write_text(json.dumps([str(p.relative_to(root)) for p in (root / 'Documents/Protected').rglob('*') if p.is_file()]))
PY
MSIGN_UI_APP_INSTALLED=1 MSIGN_UI_TEST_SOURCE="$repo/apple/Tests/InteractionUITests/ProtectionFlowUITests.swift" \
    bash "$repo/apple/scripts/run-verification-ui-tests.sh" ios "$app" "$device" "$out/native"
# Keep the generic batch result validator pointed at the actual bundle.
ln -s native/GestureProof.xcresult "$out/GestureProof.xcresult"
# Resolve the live container again for post-run filesystem checks.
container=$(xcrun simctl get_app_container "$device" md.esemnbun.ios data)
python3 - "$container" "$out" "$repo/swift/MoldSignKit/Resources/test.pdf" <<'PY'
import hashlib, json, pathlib, stat, sys
root, out, sample = map(pathlib.Path, sys.argv[1:])
existing = set(json.loads((out / 'existing-outputs.json').read_text()))
outputs = [p for p in (root / 'Documents/Protected').rglob('*') if p.is_file() and str(p.relative_to(root)) not in existing]
restored = [p for p in outputs if p.name == 'decrypted-ProtectionSource.pdf']
encrypted = [p for p in outputs if p.name == 'ProtectionSource.pdf.symmetric.p7m']
assert len(restored) == len(encrypted) == 1, outputs
assert restored[0].read_bytes() == sample.read_bytes() == (root / 'Documents/ProtectionSource.pdf').read_bytes()
assert all(stat.S_IMODE(p.stat().st_mode) == 0o600 for p in outputs)
(out / 'roundtrip.json').write_text(json.dumps({'passed': True, 'outputs': len(outputs),
    'sourcePreserved': True, 'privatePermissions': True,
    'restoredSHA256': hashlib.sha256(restored[0].read_bytes()).hexdigest()}, indent=2))
PY
