#!/bin/bash
# Capture aligned website states from one freshly built, Debug-only native app.
set -euo pipefail
app=${1:?Usage: capture-macos-story.sh DEBUG_APP OUTPUT_DIR [LANGUAGE]}
out=${2:?OUTPUT_DIR required}
language=${3:-en}
root=$(cd "$(dirname "$0")/../.." && pwd)
binary="$app/Contents/MacOS/eSemnBun"
python3 - "$binary" <<'PY'
from pathlib import Path
import sys
binary=Path(sys.argv[1])
assert any(b'MSIGN_DEMO_SCENARIO' in p.read_bytes() for p in [binary,*binary.parent.glob('*.debug.dylib')]), 'Debug mock-enabled app required'
PY
mkdir -p "$out"
tmp=$(mktemp -d -t esemnbun-website-story)
pid=
trap 'if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; fi; rm -rf "$tmp"' EXIT
cp "$root/swift/MoldSignKit/Resources/test.pdf" "$tmp/Sample-contract.pdf"
cat > "$tmp/window.swift" <<'SWIFT'
import Foundation
import CoreGraphics
let pid = Int(CommandLine.arguments[1])!
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for window in windows where window[kCGWindowOwnerPID as String] as? Int == pid {
    let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
    guard (window[kCGWindowLayer as String] as? Int ?? 0) == 0, (bounds["Width"] ?? 0) >= 860 else { continue }
    let data: [String: Any] = ["id": window[kCGWindowNumber as String]!, "title": window[kCGWindowName as String] ?? "", "bounds": bounds]
    print(String(data: try! JSONSerialization.data(withJSONObject: data, options: [.sortedKeys]), encoding: .utf8)!)
    break
}
SWIFT
swiftc "$tmp/window.swift" -o "$tmp/window"
for scenario in no-reader empty-reader ready; do
    case "$scenario" in no-reader) name=macos-disconnected;; empty-reader) name=macos-reader;; ready) name=macos;; esac
    MSIGN_QA_NO_HARDWARE=1 MSIGN_QA_HIDE_TRAY=1 MSIGN_SCREENSHOT_CAPTURE=1 \
    MSIGN_DEMO_PREVIEW=0 MSIGN_DEMO_CARDS=1 MSIGN_DEMO_SCENARIO="$scenario" \
    MSIGN_DEMO_FILES="$tmp/Sample-contract.pdf" MSIGN_DEMO_PREFERENCES_SUITE="md.esemnbun.qa.website.$$.${language}" \
        "$binary" --show-main-window -mainSection sign -appTheme light -appLanguage "$language" \
        -AppleLanguages "($language)" > "$tmp/ready.log" 2>&1 &
    pid=$!
    window=
    for attempt in {1..80}; do
        if grep -q MSIGN_DEMO_READY "$tmp/ready.log"; then window=$("$tmp/window" "$pid"); fi
        [[ -n "$window" ]] && break
        sleep .25
    done
    [[ -n "$window" ]] || { cat "$tmp/ready.log" >&2; echo "Native window unavailable: $scenario" >&2; exit 1; }
    printf '%s\n' "$window" > "$out/$name.json"
    id=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' <<< "$window")
    sleep 1
    /usr/sbin/screencapture -x -o -l "$id" "$out/$name.png"
    kill "$pid"; wait "$pid" 2>/dev/null || true; pid=
done
python3 - "$out" "$language" <<'PY'
from pathlib import Path
import hashlib,json,struct,sys
out=Path(sys.argv[1]); records=[]
for name in ['macos-disconnected','macos-reader','macos']:
    record=json.loads((out/f'{name}.json').read_text())
    width,height=struct.unpack('>II',(out/f'{name}.png').read_bytes()[16:24])
    records.append({'file':name+'.png','sha256':hashlib.sha256((out/f'{name}.png').read_bytes()).hexdigest(),'title':record['title'],'dimensions':[width,height], 'windowSize':[record['bounds']['Width'],record['bounds']['Height']]})
assert len({tuple(r['dimensions']) for r in records})==1, 'Capture dimensions changed between states'
assert len({r['title'] for r in records})==1, 'Window title changed between states'
assert all('preview' not in r['title'].lower() for r in records), 'Preview window was captured'
(out/'macos-story.json').write_text(json.dumps({'locale':sys.argv[2],'theme':'light','document':'Sample-contract.pdf','states':records},indent=2)+'\n')
print(json.dumps(records))
PY
