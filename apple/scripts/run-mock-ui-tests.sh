#!/bin/bash
# Runs both the read-only state suite and interactive mock workflow suite on the specified native target.
set -euo pipefail
platform=${1:?ios|macos}; app=${2:?Debug app}; device=${3:?Simulator UUID or mac}; out=${4:?Fresh output directory}
repo=$(cd "$(dirname "$0")/../.." && pwd)
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory' >&2; exit 2; }
mkdir -p "$out"
status=0
suites=(VerificationJourneyUITests MockWorkflowUITests)
if [[ "$platform" == ios ]]; then suites+=(CardCarouselUITests DemoModeUITests); fi
for suite in "${suites[@]}"; do
    if ! MSIGN_UI_TEST_SOURCE="$repo/apple/Tests/InteractionUITests/$suite.swift" \
        bash "$repo/apple/scripts/run-verification-ui-tests.sh" "$platform" "$app" "$device" "$out/$suite"; then
        status=1
        continue
    fi
    result=Journeys.xcresult
    [[ "$platform" != ios ]] || result=GestureProof.xcresult
    case "$suite" in
        VerificationJourneyUITests) expected=5 ;;
        MockWorkflowUITests) expected=6 ;;
        CardCarouselUITests) expected=2 ;;
        DemoModeUITests) expected=1 ;;
    esac
    python3 "$repo/scripts/ci/check-xctest-result.py" "$out/$suite/$result" "$expected" || status=1
done
exit "$status"
