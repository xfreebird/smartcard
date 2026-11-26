#!/bin/bash
# Keep all 35 required cases in one XCTest session; preserve native file postchecks.
set -euo pipefail
app=${1:?Debug app}; device=${2:?Dedicated simulator}; out=${3:?Prepared output directory}
repo=$(cd "$(dirname "$0")/../.." && pwd)
for fixture in protection documents; do
    MSIGN_UI_FIXTURE_PHASE=prepare bash "$repo/apple/scripts/run-$fixture-ui-tests.sh" ios "$app" "$device" "$out/$fixture"
done
export MSIGN_UI_TEST_SUITES='VerificationJourneyUITests MockWorkflowUITests CardCarouselUITests NFCSigningChoiceUITests PINActionsUITests SharedCardPINUITests SettingsNavigationUITests DemoModeUITests ProtectionFlowUITests DocumentsUITests FloatingActionUITests'
export MSIGN_UI_STOP_ON_FAILURE=1
check="$repo/scripts/ci/check-xctest-result.py"
first="$out/NativeBatch/GestureProof.xcresult"
if bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" "$device" "$out/NativeBatch"; then
    python3 "$check" "$first" 35
else
    # XCTest sometimes loses the app process on a loaded CI simulator. Only then, rerun once the cases that did
    # not pass; any assertion, or an interrupted fixture suite, fails the batch here.
    python3 "$check" "$first" --retry-plan "$out/NativeBatch/passed.txt" || exit 1
    xcrun simctl terminate "$device" md.esemnbun.ios 2>/dev/null || true
    if ! MSIGN_UI_SKIP_TESTS="$(cat "$out/NativeBatch/passed.txt")" \
            bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" "$device" "$out/NativeRerun"; then
        python3 "$check" "$out/NativeRerun/GestureProof.xcresult" --report-failures || true
        exit 1
    fi
    python3 "$check" "$first" --combined "$out/NativeRerun/GestureProof.xcresult" 35
fi
for fixture in protection documents; do
    MSIGN_UI_FIXTURE_PHASE=verify bash "$repo/apple/scripts/run-$fixture-ui-tests.sh" ios "$app" "$device" "$out/$fixture"
done
