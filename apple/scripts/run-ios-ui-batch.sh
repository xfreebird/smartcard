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
if ! bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" "$device" "$out/NativeBatch"; then
    python3 "$repo/scripts/ci/check-xctest-result.py" "$out/NativeBatch/GestureProof.xcresult" --report-failures || true
    exit 1
fi
python3 "$repo/scripts/ci/check-xctest-result.py" "$out/NativeBatch/GestureProof.xcresult" 35
for fixture in protection documents; do
    MSIGN_UI_FIXTURE_PHASE=verify bash "$repo/apple/scripts/run-$fixture-ui-tests.sh" ios "$app" "$device" "$out/$fixture"
done
