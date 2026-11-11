#!/bin/bash
# Explicit per-host batches; no publishing or real-card access. Invoke only when ready to run tests.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
platform=${1:?Usage: run-integration-tests.sh apple|linux|android|windows-portable OUTPUT}
out=${2:?Fresh output directory required}
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory.' >&2; exit 2; }
mkdir -p "$out"
out=$(cd "$out" && pwd)
export MSIGN_NETWORK_TESTS=0
run_swift_contracts() {
    swift build --package-path "$repo/swift/MoldSignKit" --product esemnbun 2>&1 | tee "$out/cli-build.log"
    swift build --package-path "$repo/swift/MoldSignKit" --product esemnbun-mcp 2>&1 | tee "$out/mcp-build.log"
    local binaries
    binaries=$(swift build --package-path "$repo/swift/MoldSignKit" --show-bin-path)
    python3 "$repo/scripts/test-cli-json.py" "$binaries/esemnbun" --results "$out/cli.json"
    python3 "$repo/scripts/test-mcp-process.py" "$binaries/esemnbun-mcp" 2>&1 | tee "$out/mcp-process.log"
}
case "$platform" in
    apple)
        swift test --package-path "$repo/swift/MoldSignKit" 2>&1 | tee "$out/core.log"
        swift test --package-path "$repo/apple" 2>&1 | tee "$out/app.log"
        run_swift_contracts
        ;;
    linux)
        swift test --package-path "$repo/swift/MoldSignKit" 2>&1 | tee "$out/core.log"
        swift test --package-path "$repo/linux" 2>&1 | tee "$out/app.log"
        run_swift_contracts
        ;;
    android)
        (cd "$repo/android" && ./gradlew :core:test :transport-usb:testDebugUnitTest :app:testDebugUnitTest :app:assembleDebug :app:assembleDebugAndroidTest) 2>&1 | tee "$out/android.log"
        ;;
    windows-portable)
        (cd "$repo/windows" && dotnet test tests/MoldSign.Core.Tests --logger "trx;LogFileName=integration.trx" --results-directory "$out") 2>&1 | tee "$out/windows.log"
        ;;
    *) echo 'Unsupported platform' >&2; exit 2 ;;
esac
