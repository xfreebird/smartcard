#!/usr/bin/env bash
# Run one SwiftPM suite and export its genuine LLVM line coverage for SonarQube Cloud.
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
package=${1:?Package path relative to the repository required}
source=${2:?Production source directory relative to the repository required}
report=${3:?Output XML path required}
scratch=${4:?Dedicated SwiftPM scratch path required}

cd "$repo"
swift test --package-path "$package" --scratch-path "$scratch" --enable-code-coverage
products=$(swift build --package-path "$package" --scratch-path "$scratch" --show-bin-path)
objects=()
for test in "$products"/*.xctest; do
    [[ -e "$test" ]] || continue
    if [[ -d "$test" ]]; then
        test="$test/Contents/MacOS/$(basename "$test" .xctest)"
    fi
    objects+=(-object "$test")
done
if [[ ${#objects[@]} == 0 ]]; then
    echo "No SwiftPM XCTest binaries under $products" >&2
    exit 1
fi

llvm=(llvm-cov)
if [[ $(uname -s) == Darwin ]]; then llvm=(xcrun llvm-cov); fi
"${llvm[@]}" export -format=lcov -instr-profile "$products/codecov/default.profdata" \
    "${objects[@]:1}" | python3 scripts/ci/sonar-lcov.py "$repo" "$source" "$report"
