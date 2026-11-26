#!/bin/bash
# Runs both the read-only state suite and interactive mock workflow suite on the specified native target.
set -euo pipefail
platform=${1:?ios|macos}; app=${2:?Debug app}; device=${3:?Simulator UUID or mac}; out=${4:?Fresh output directory}
repo=$(cd "$(dirname "$0")/../.." && pwd)
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory' >&2; exit 2; }
mkdir -p "$out"
if [[ "$platform" == ios ]]; then
    # Files retains provider URLs. Keep one app data container for all seeded suites.
    xcrun simctl install "$device" "$app"
    export MSIGN_UI_APP_INSTALLED=1
    if [[ -n ${MSIGN_UI_RESOURCES_DIR:-} ]]; then
        MSIGN_UI_XCTESTRUN=$(cat "$MSIGN_UI_RESOURCES_DIR/xctestrun-path.txt")
        export MSIGN_UI_DOCUMENT_FIXTURES="$MSIGN_UI_RESOURCES_DIR/fixtures"
    else
        MSIGN_UI_BUILD_ONLY=1 bash "$repo/apple/scripts/run-carousel-ui-tests.sh" "$app" "$device" "$out/TestHost"
        MSIGN_UI_XCTESTRUN=$(python3 - "$out/TestHost/DerivedData/Build/Products" <<'PYTHON'
from pathlib import Path
import sys
manifests = list(Path(sys.argv[1]).glob('*.xctestrun'))
if len(manifests) != 1:
    raise SystemExit('Expected exactly one prepared XCTest manifest')
print(manifests[0].resolve())
PYTHON
)
    fi
    [[ -f "$MSIGN_UI_XCTESTRUN" ]] || { echo 'Prepared XCTest manifest is missing.' >&2; exit 1; }
    export MSIGN_UI_XCTESTRUN
    if [[ ${MSIGN_UI_SINGLE_SESSION:-0} == 1 ]]; then
        exec bash "$repo/apple/scripts/run-ios-ui-batch.sh" "$app" "$device" "$out"
    fi
fi
status=0
report_failure() {
    printf 'Native UI failure: %s/%s on %s\n' "$platform" "$suite" "$device" >&2
    if [[ ${GITHUB_ACTIONS:-false} == true ]]; then
        printf '::error title=Native UI failure::%s/%s failed on %s. Inspect its XCTest bundle and runner post-checks.\n' "$platform" "$suite" "$device"
    fi
    bundle="$out/$suite/$result"
    [[ -d "$bundle" ]] || bundle="$out/$suite/native/$result"
    if [[ -d "$bundle" ]]; then
        xcrun xcresulttool get test-results summary --path "$bundle" |
            python3 "$repo/scripts/ci/check-xctest-result.py" --report-failures || true
    fi
    status=1
    # CI stops after diagnostics; local investigations still collect every suite by default.
    if [[ ${MSIGN_UI_FAIL_FAST:-0} == 1 ]]; then
        exit "$status"
    fi
}
suites=(VerificationJourneyUITests MockWorkflowUITests)
if [[ "$platform" == macos ]]; then suites+=(MacFloatingActionUITests); fi
if [[ "$platform" == ios ]]; then suites+=(CardCarouselUITests NFCSigningChoiceUITests PINActionsUITests SharedCardPINUITests SettingsNavigationUITests DemoModeUITests ProtectionFlowUITests DocumentsUITests FloatingActionUITests); fi
for suite in "${suites[@]}"; do
    result=Journeys.xcresult
    [[ "$platform" != ios ]] || result=GestureProof.xcresult
    runner="$repo/apple/scripts/run-verification-ui-tests.sh"
    [[ "$suite" != ProtectionFlowUITests ]] || runner="$repo/apple/scripts/run-protection-ui-tests.sh"
    [[ "$suite" != DocumentsUITests ]] || runner="$repo/apple/scripts/run-documents-ui-tests.sh"
    if ! MSIGN_UI_TEST_SOURCE="$repo/apple/Tests/InteractionUITests/$suite.swift" \
        bash "$runner" "$platform" "$app" "$device" "$out/$suite"; then
        report_failure
        continue
    fi
    case "$suite" in
        VerificationJourneyUITests) expected=5 ;;
        MockWorkflowUITests) expected=6 ;;
        CardCarouselUITests|PINActionsUITests) expected=2 ;;
        DocumentsUITests|SharedCardPINUITests) expected=3 ;;
        NFCSigningChoiceUITests) expected=7 ;;
        FloatingActionUITests|MacFloatingActionUITests) expected=4 ;;
        DemoModeUITests|ProtectionFlowUITests|SettingsNavigationUITests) expected=1 ;;
    esac
    if ! xcrun xcresulttool get test-results summary --path "$out/$suite/$result" |
            python3 "$repo/scripts/ci/check-xctest-result.py" "$expected"; then
        report_failure
    fi
done
exit "$status"
