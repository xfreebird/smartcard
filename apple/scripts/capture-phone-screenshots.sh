#!/bin/bash
# Finite standard-iPhone mock matrix; the shared driver validates the Debug binary and readiness.
set -euo pipefail
app=${1:?Usage: capture-phone-screenshots.sh APP_PATH OUTPUT_DIR SIMULATOR_UDID}
out=${2:?OUTPUT_DIR required}
device=${3:?SIMULATOR_UDID required}
script_dir=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
fixture_dir=$(mktemp -d -t esemnbun-phone-files)
trap 'rm "$fixture_dir/Cerere.pdf" "$fixture_dir/Declaratie.pdf" "$fixture_dir/Contract.pdf"; rmdir "$fixture_dir"' EXIT
for name in Cerere Declaratie Contract; do cp "$root/swift/MoldSignKit/Resources/test.pdf" "$fixture_dir/$name.pdf"; done
files="$fixture_dir/Cerere.pdf:$fixture_dir/Declaratie.pdf:$fixture_dir/Contract.pdf"
MSIGN_CAPTURE_TAB=sign MSIGN_CAPTURE_SCENARIOS='ready multiple pin' MSIGN_CAPTURE_FILES="$files" \
    "$script_dir/capture-screenshots.sh" ios "$app" "$out/sign-documents" "$device"
MSIGN_CAPTURE_TAB=sign MSIGN_CAPTURE_SCENARIOS=no-reader MSIGN_CAPTURE_FILES=: \
    "$script_dir/capture-screenshots.sh" ios "$app" "$out/sign-empty" "$device"
for page in card browser verify; do
    scenario=ready; [[ "$page" == card ]] && scenario=multiple
    MSIGN_CAPTURE_TAB="$page" MSIGN_CAPTURE_SCENARIOS="$scenario" MSIGN_CAPTURE_FILES=: \
        "$script_dir/capture-screenshots.sh" ios "$app" "$out/$page" "$device"
done
python3 - "$out" "$device" <<'PYTHON'
import json,pathlib,struct,sys
root=pathlib.Path(sys.argv[1])
cases=[('sign-documents','ready','sign'),('sign-documents','multiple','sign'),
       ('sign-documents','pin','sign'),('sign-empty','no-reader','sign'),
       ('card','multiple','card'),('browser','ready','browser'),('verify','ready','verify')]
images=[]
for folder,scenario,page in cases:
    for theme in ['light','dark']:
        path=root/folder/f'{scenario}-{theme}.png'
        data=path.read_bytes()
        if data[:8]!=b'\x89PNG\r\n\x1a\n': raise SystemExit(f'Invalid PNG: {path}')
        width,height=struct.unpack('>II',data[16:24])
        images.append({'path':str(path.relative_to(root)),'page':page,'scenario':scenario,
                       'theme':theme,'width':width,'height':height})
(root/'matrix.json').write_text(json.dumps({'device':sys.argv[2],'language':'ro','mockCardBackend':True,
    'pinEntered':False,'readiness':'Debug marker and per-launch MSIGN_DEMO_READY',
    'browserContent':'Public portal may load; card bridge remains disconnected',
    'images':images},indent=2)+'\n')
print(f'Captured {len(images)} standard-iPhone states')
PYTHON
