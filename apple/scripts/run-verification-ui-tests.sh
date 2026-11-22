#!/bin/bash
set -euo pipefail
platform=${1:?Usage: run-verification-ui-tests.sh ios|macos DEBUG_APP DEVICE_OR_MAC OUTPUT}
app=${2:?Debug app required}
device=${3:?Simulator UUID or mac required}
out=${4:?Fresh output directory required}
repo=$(cd "$(dirname "$0")/../.." && pwd)
source_file=${MSIGN_UI_TEST_SOURCE:-$repo/apple/Tests/InteractionUITests/VerificationJourneyUITests.swift}
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory' >&2; exit 2; }
if [[ "$platform" == ios ]]; then
    MSIGN_UI_TEST_SOURCE="$source_file" bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" "$device" "$out"
    exit
fi
[[ "$platform" == macos && "$device" == mac ]] || { echo 'Unsupported platform/device' >&2; exit 2; }
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory' >&2; exit 2; }
if [[ ${MSIGN_UI_BUILD_ONLY:-0} != 1 ]] && python3 - <<'PYTHON'
import subprocess
pids = subprocess.run(['pgrep', '-x', 'eSemnBun'], capture_output=True, text=True).stdout.split()
paths = [subprocess.run(['ps', '-p', pid, '-o', 'comm='], capture_output=True, text=True).stdout.strip() for pid in pids]
raise SystemExit(0 if any(path.endswith('/Contents/MacOS/eSemnBun') for path in paths) else 1)
PYTHON
then
    echo 'Close the running eSemnBun app before the isolated desktop suite.' >&2; exit 2
fi
command -v xcodegen >/dev/null
python3 - "$app" <<'PY'
import pathlib, plistlib, sys
p=pathlib.Path(sys.argv[1]).resolve()
i=plistlib.loads((p/'Contents/Info.plist').read_bytes())
assert i['CFBundleIdentifier']=='md.esemnbun.mac'
binary=p/'Contents/MacOS'/i['CFBundleExecutable']
assert b'MSIGN_DEMO_CARDS' in binary.read_bytes()+b''.join(f.read_bytes() for f in (p/'Contents/MacOS').glob('*.debug.dylib')), 'Debug app required'
PY
mkdir -p "$out"
out=$(cd "$out" && pwd)
host=$(mktemp -d "${TMPDIR:-/tmp}/esemnbun-ui-host.XXXXXX")
mkdir -p "$host/Host" "$host/Tests"
cp "$source_file" "$host/Tests/"
cp "$repo/apple/Tests/InteractionUITests/NativeUITestActions.swift" "$host/Tests/"
cp "$repo/apple/Tests/InteractionUITests/NativeFilePicker.swift" "$host/Tests/"
python3 - "$app" "$host/Tests/TestApplication.swift" <<'PYTHON'
import base64
from pathlib import Path
import sys
encoded = base64.b64encode(str(Path(sys.argv[1]).resolve()).encode()).decode()
Path(sys.argv[2]).write_text('''import XCTest
@MainActor
func makeMacTestApplication() -> XCUIApplication {
    let path = String(data: Data(base64Encoded: "''' + encoded + '''")!, encoding: .utf8)!
    return XCUIApplication(url: URL(fileURLWithPath: path))
}
''')
PYTHON
cat > "$host/Host/Host.swift" <<'SWIFT'
import SwiftUI
@main struct Host: App { var body: some Scene { WindowGroup { Color.clear } } }
SWIFT
cat > "$host/project.yml" <<'YAML'
name: JourneyHost
options:
  deploymentTarget:
    macOS: '15.0'
settings:
  base:
    SWIFT_VERSION: '5.0'
    GENERATE_INFOPLIST_FILE: YES
    CODE_SIGN_IDENTITY: '-'
targets:
  Host:
    type: application
    platform: macOS
    sources: [Host]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: md.esemnbun.qa.journeyhost
  JourneyTests:
    type: bundle.ui-testing
    platform: macOS
    sources: [Tests]
    dependencies:
      - target: Host
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: md.esemnbun.qa.journeytests
        TEST_TARGET_NAME: Host
schemes:
  JourneyHost:
    build:
      targets:
        Host: all
        JourneyTests: [test]
    test:
      targets: [JourneyTests]
YAML
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
xcodegen generate --spec "$host/project.yml"
xcodebuild build-for-testing -project "$host/JourneyHost.xcodeproj" -scheme JourneyHost -destination 'platform=macOS' \
    -collect-test-diagnostics never \
    -parallel-testing-enabled NO -derivedDataPath "$out/DerivedData" -resultBundlePath "$out/Build.xcresult" 2>&1 | tee "$out/build.log"
# Xcode's copied UI runner has its own sandbox entitlement, independent of
# ENABLE_APP_SANDBOX. A sandboxed NSWorkspace launch drops the fixture settings.
# Re-sign only this generated QA runner; the tested application keeps its signature.
python3 - "$out/DerivedData/Build/Products/Debug/JourneyTests-Runner.app" "$out/runner-entitlements.plist" <<'PYTHON'
import pathlib, plistlib, subprocess, sys
runner, output = map(pathlib.Path, sys.argv[1:])
info = plistlib.loads((runner/'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'md.esemnbun.qa.journeytests.xctrunner'
raw = subprocess.check_output(['codesign', '-d', '--entitlements', ':-', str(runner)], stderr=subprocess.DEVNULL)
entitlements = plistlib.loads(raw)
entitlements.pop('com.apple.security.app-sandbox', None)
output.write_bytes(plistlib.dumps(entitlements))
subprocess.run(['codesign', '--force', '--sign', '-', '--entitlements', str(output), '--timestamp=none', str(runner)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(runner)], check=True)
actual = plistlib.loads(subprocess.check_output(['codesign', '-d', '--entitlements', ':-', str(runner)], stderr=subprocess.DEVNULL))
assert not actual.get('com.apple.security.app-sandbox') and actual.get('com.apple.security.get-task-allow')
PYTHON
[[ ${MSIGN_UI_BUILD_ONLY:-0} != 1 ]] || exit 0
manifests=("$out/DerivedData/Build/Products/"*.xctestrun)
[[ ${#manifests[@]} == 1 && -f "${manifests[0]}" ]] || { echo 'Expected one native XCTest manifest.' >&2; exit 1; }
xcodebuild test-without-building -xctestrun "${manifests[0]}" -destination 'platform=macOS' \
    -collect-test-diagnostics never -parallel-testing-enabled NO \
    -resultBundlePath "$out/Journeys.xcresult" 2>&1 | tee "$out/test.log"
