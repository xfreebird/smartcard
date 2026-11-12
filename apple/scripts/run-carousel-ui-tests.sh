#!/bin/bash
# Native finger-gesture proof against the installed Debug simulator app, using an isolated test host.
set -euo pipefail
app=${1:?Usage: run-carousel-ui-tests.sh DEBUG_SIMULATOR_APP BOOTED_SIMULATOR_UUID OUTPUT_DIR}
device=${2:?Simulator UUID required}
out=${3:?Output directory required}
repo=$(cd "$(dirname "$0")/../.." && pwd)
command -v xcodegen >/dev/null || { echo 'xcodegen is required to generate the isolated UI-test host.' >&2; exit 1; }
python3 - "$app" <<'PY'
import plistlib,sys
from pathlib import Path
app=Path(sys.argv[1]); info=plistlib.loads((app/'Info.plist').read_bytes())
if info.get('CFBundleIdentifier')!='md.esemnbun.ios' or 'iPhoneSimulator' not in info.get('CFBundleSupportedPlatforms',[]):
    raise SystemExit('Use the eSemnBun iOS simulator app.')
binary=app/info['CFBundleExecutable']
payload = binary.read_bytes() + b''.join(p.read_bytes() for p in app.glob('*.debug.dylib'))
if b'MSIGN_DEMO_CARDS' not in payload:
    raise SystemExit('Debug mock-enabled simulator build required.')
PY
state=$(xcrun simctl list devices -j | python3 -c 'import json,sys; target=sys.argv[1]; print(next((d["state"] for group in json.load(sys.stdin)["devices"].values() for d in group if d["udid"]==target),"Missing"))' "$device")
[[ "$state" == Booted ]] || { echo 'Boot the dedicated test simulator first.' >&2; exit 1; }
mkdir -p "$out"
out=$(cd "$out" && pwd)
[[ ! -e "$out/GestureProof.xcresult" ]] || { echo 'Use a new output directory to preserve earlier test results.' >&2; exit 1; }
probe_dir=$(mktemp -d "${TMPDIR:-/tmp}/esemnbun-gesture.XXXXXX")
mkdir -p "$probe_dir/Host" "$probe_dir/Tests"
test_source=${MSIGN_UI_TEST_SOURCE:-$repo/apple/Tests/InteractionUITests/CardCarouselUITests.swift}
cp "$test_source" "$probe_dir/Tests/"
cp "$repo/apple/Tests/InteractionUITests/NativeUITestActions.swift" "$probe_dir/Tests/"
cp "$repo/apple/Tests/InteractionUITests/NativeFilePicker.swift" "$probe_dir/Tests/"
cat > "$probe_dir/Host/ProbeHost.swift" <<'SWIFT'
import SwiftUI
@main struct ProbeHost: App {
    var body: some Scene { WindowGroup { Color.clear } }
}
SWIFT
cat > "$probe_dir/project.yml" <<'YAML'
name: GestureProbe
options:
  deploymentTarget:
    iOS: '17.0'
settings:
  base:
    SWIFT_VERSION: '5.0'
    CODE_SIGNING_ALLOWED: NO
    GENERATE_INFOPLIST_FILE: YES
    TARGETED_DEVICE_FAMILY: '1,2'
targets:
  ProbeHost:
    type: application
    platform: iOS
    sources: [Host]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: md.esemnbun.qa.gesturehost
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
  GestureTests:
    type: bundle.ui-testing
    platform: iOS
    sources: [Tests]
    dependencies:
      - target: ProbeHost
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: md.esemnbun.qa.gesturetests
        TEST_TARGET_NAME: ProbeHost
schemes:
  GestureProbe:
    build:
      targets:
        ProbeHost: all
        GestureTests: [test]
    test:
      targets:
        - GestureTests
YAML
xcodegen generate --spec "$probe_dir/project.yml"
if [[ ${MSIGN_UI_APP_INSTALLED:-0} != 1 ]]; then
    xcrun simctl install "$device" "$app"
fi
python3 "$repo/apple/scripts/capture-test-display.py" "$device" "$out/active-display" \
    xcodebuild test -project "$probe_dir/GestureProbe.xcodeproj" -scheme GestureProbe \
    -destination "id=$device" -parallel-testing-enabled NO \
    -derivedDataPath "$out/DerivedData" -resultBundlePath "$out/GestureProof.xcresult" \
    CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$out/test.log"
printf 'Native test results: %s\nGenerated runner project: %s\n' "$out/GestureProof.xcresult" "$probe_dir"
