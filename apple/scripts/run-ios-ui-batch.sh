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
# Print the named xcresulttool reports of one result bundle, for check-xctest-result.py's standard input.
reports() {
    local bundle=$1 report
    for report in "${@:2}"; do xcrun xcresulttool get test-results "$report" --path "$bundle"; done
}
first="$out/NativeBatch/GestureProof.xcresult"
fixtures="$out"
if bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" "$device" "$out/NativeBatch"; then
    reports "$first" summary | python3 "$check" 35
else
    # XCTest sometimes loses the app process on a loaded CI simulator. Only then, rerun once on an erased simulator
    # the cases that did not pass and both fixture suites, whose files are seeded again. Any assertion fails here.
    reports "$first" summary tests | python3 "$check" --retry-plan || exit 1
    reports "$first" tests | python3 "$check" --skip-list > "$out/NativeBatch/skip.txt"
    xcrun simctl shutdown "$device" 2>/dev/null || true
    xcrun simctl erase "$device"
    xcrun simctl boot "$device"
    xcrun simctl bootstatus "$device" -b
    xcrun simctl install "$device" "$app"
    fixtures="$out/Rerun"
    for fixture in protection documents; do
        MSIGN_UI_FIXTURE_PHASE=prepare bash "$repo/apple/scripts/run-$fixture-ui-tests.sh" ios "$app" "$device" "$fixtures/$fixture"
    done
    if ! MSIGN_UI_SKIP_TESTS="$(cat "$out/NativeBatch/skip.txt")" \
            bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" "$device" "$out/NativeRerun"; then
        reports "$out/NativeRerun/GestureProof.xcresult" summary | python3 "$check" --report-failures || true
        exit 1
    fi
    { reports "$first" tests; reports "$out/NativeRerun/GestureProof.xcresult" summary tests; } |
        python3 "$check" --combined 35
fi
for fixture in protection documents; do
    MSIGN_UI_FIXTURE_PHASE=verify bash "$repo/apple/scripts/run-$fixture-ui-tests.sh" ios "$app" "$device" "$fixtures/$fixture"
done
