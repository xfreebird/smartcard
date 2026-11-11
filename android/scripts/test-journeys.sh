#!/bin/bash
set -euo pipefail
serial=${1:?Usage: test-journeys.sh EMULATOR_SERIAL APP_APK TEST_APK OUTPUT}
app=${2:?App APK required}
tests=${3:?Test APK required}
out=${4:?Fresh output directory required}
adb=${ADB:-adb}
[[ "$serial" == emulator-* ]] || { echo 'A dedicated emulator serial is required.' >&2; exit 2; }
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory.' >&2; exit 2; }
mkdir -p "$out"
"$adb" -s "$serial" install -r "$app"
"$adb" -s "$serial" install -r "$tests"
"$adb" -s "$serial" shell am instrument -w -r -e suite journeys \
    md.esemnbun.app.test/md.moldsign.app.FileProtectionInstrumentation | tee "$out/journeys.log"
# am instrument can exit successfully even when Instrumentation reports failure.
python3 - "$out/journeys.log" <<'PY'
import pathlib, sys
s=pathlib.Path(sys.argv[1]).read_text()
assert 'INSTRUMENTATION_CODE: -1' in s and 'FAIL:' not in s, s
assert s.count(':pass') == 28, 'Missing scenario completions: '+s
PY
