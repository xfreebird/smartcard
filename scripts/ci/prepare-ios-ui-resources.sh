#!/bin/bash
# Compile the test harness and generate native document fixtures before the UI budget starts.
set -euo pipefail
app=${1:?Debug simulator app required}; out=${2:?Fresh output directory required}
repo=$(cd "$(dirname "$0")/../.." && pwd)
[[ ! -e "$out" ]] || { echo 'Use a fresh UI resources directory.' >&2; exit 2; }
mkdir -p "$out"
out=$(cd "$out" && pwd)
MSIGN_UI_BUILD_ONLY=1 bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" build "$out/TestHost"
python3 - "$out" <<'PYTHON'
from pathlib import Path
import sys
out = Path(sys.argv[1])
manifest = list((out / 'TestHost/DerivedData/Build/Products').glob('*.xctestrun'))
if len(manifest) != 1:
    raise SystemExit('Expected exactly one prepared XCTest manifest')
(out / 'xctestrun-path.txt').write_text(str(manifest[0].resolve()) + '\n')
PYTHON
MSIGN_TEST_EXPORT_DIRECTORY="$out/fixtures" swift test --package-path "$repo/swift/MoldSignKit" \
    --filter BridgeEndToEndTests/testDetachedMissingOriginalIsIncompleteAndSelectedBytesResolveIt \
    > "$out/fixture-generation.log" 2>&1
python3 - "$out/fixtures" <<'PYTHON'
from pathlib import Path
import sys
fixtures = Path(sys.argv[1])
if not (fixtures / 'detached-signature.xml').is_file() or not list(fixtures.glob('*.txt')):
    raise SystemExit('Native document fixture generation did not produce the required files')
PYTHON
