#!/bin/bash
# Run the Swift core (MoldSignKit) and app policy (apple/Package.swift) unit tests on an iOS simulator.
#
# Usage: run-ios-unit-tests.sh iPhone|iPad FRESH_OUTPUT_DIR
#
# xcodebuild opens the Xcode project that shares apple/ with its Package.swift, and the core package's
# macOS-only MCP and CLI targets do not build for iOS. The packages are therefore tested from a staging
# tree of symlinks: the core through a scheme that builds only MoldSignKitTests. spec/ sits at the same
# relative place, because the tests read its vectors through their source paths.
# MSIGN_UNIT_DEVICE selects a simulator explicitly (local runs); CI picks the family's simulator the same
# way as the UI journeys.
set -euo pipefail
family=${1:?Usage: run-ios-unit-tests.sh iPhone|iPad FRESH_OUTPUT_DIR}
out=${2:?Usage: run-ios-unit-tests.sh iPhone|iPad FRESH_OUTPUT_DIR}
[[ "$family" == iPhone || "$family" == iPad ]] || { echo 'The device family must be iPhone or iPad.' >&2; exit 2; }
repo=$(cd "$(dirname "$0")/../.." && pwd)
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory.' >&2; exit 2; }
mkdir -p "$out"
out=$(cd "$out" && pwd)

device=${MSIGN_UNIT_DEVICE:-}
if [[ -z "$device" ]]; then
    xcrun simctl list devices available -j > "$out/devices.json"
    xcrun simctl list runtimes -j > "$out/runtimes.json"
    python3 "$repo/scripts/ci/select_apple_ui_targets.py" "$out/devices.json" "$out/runtimes.json" \
        "$(xcrun --sdk iphonesimulator --show-sdk-version)" > "$out/targets.tsv"
    device=$(awk -F '\t' -v family="$family" '$1 == family { print $2 }' "$out/targets.tsv")
fi
[[ "$device" =~ ^[0-9A-Fa-f-]{36}$ ]] || { echo "No $family simulator selected." >&2; exit 1; }
echo "Unit tests on the $family simulator $device"
# Leave the simulator as found: the UI journeys boot the same device afterwards.
state=$(xcrun simctl list devices -j | python3 -c 'import json, sys
devices = [d for group in json.load(sys.stdin)["devices"].values() for d in group]
print(next((d["state"] for d in devices if d["udid"] == sys.argv[1]), "Unknown"))' "$device")
[[ "$state" == Booted ]] || trap 'xcrun simctl shutdown "$device" 2>/dev/null || true' EXIT

stage="$out/stage"
mkdir -p "$stage/apple" "$stage/swift/MoldSignKit/.swiftpm/xcode/xcshareddata/xcschemes"
ln -s "$repo/spec" "$stage/spec"
for entry in Package.swift Apps Helpers Tests; do ln -s "$repo/apple/$entry" "$stage/apple/$entry"; done
for entry in Package.swift Resources Sources Tests; do ln -s "$repo/swift/MoldSignKit/$entry" "$stage/swift/MoldSignKit/$entry"; done
reference='<BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "MoldSignKitTests" BuildableName = "MoldSignKitTests" BlueprintName = "MoldSignKitTests" ReferencedContainer = "container:"></BuildableReference>'
cat > "$stage/swift/MoldSignKit/.swiftpm/xcode/xcshareddata/xcschemes/MoldSignKitTests.xcscheme" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "NO" buildForProfiling = "NO" buildForArchiving = "NO" buildForAnalyzing = "NO">
            $reference
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference skipped = "NO">
            $reference
         </TestableReference>
      </Testables>
   </TestAction>
</Scheme>
XML

# A run that executes nothing, or fails any test, fails the step.
run() {
    local name=$1 package=$2 scheme=$3
    (cd "$stage/$package" && xcodebuild test -scheme "$scheme" -destination "id=$device" \
        -derivedDataPath "$out/DerivedData" -resultBundlePath "$out/$name.xcresult" > "$out/$name.log" 2>&1) || {
        grep -E 'error:|failed' "$out/$name.log" | tail -40 >&2
        echo "$name unit tests failed on the $family simulator; see $out/$name.log" >&2
        return 1
    }
    xcrun xcresulttool get test-results summary --path "$out/$name.xcresult" | python3 -c '
import json, sys
name, summary = sys.argv[1], json.load(sys.stdin)
passed, skipped, failed = (summary.get(key, 0) for key in ("passedTests", "skippedTests", "failedTests"))
print(f"{name}: {passed} passed, {skipped} skipped, {failed} failed")
if summary.get("result") != "Passed" or failed or not passed:
    raise SystemExit(f"{name}: expected passing tests and no failures")' "$name"
}
run core swift/MoldSignKit MoldSignKitTests
run app apple AppleAppPolicies-Package
