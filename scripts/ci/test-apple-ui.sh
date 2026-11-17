#!/bin/bash
# CI-only preparation; platform suites also remain directly runnable on developer machines.
set -euo pipefail
platform=${1:?ios|macos}
app=${2:?Debug app required}
out=${3:?Fresh output directory required}
repo=$(cd "$(dirname "$0")/../.." && pwd)
[[ ! -e "$out" ]] || { echo 'Use a fresh output directory.' >&2; exit 2; }
case "$platform" in
    macos)
        # Hosted images preauthorize XCTest. Do not prompt or change the host's security settings.
        if ! /usr/bin/automationmodetool | grep -q 'DOES NOT REQUIRE'; then
            echo 'The runner must preauthorize XCTest Automation Mode; no UI tests were run.' >&2
            exit 1
        fi
        entitlements=$(mktemp)
        trap 'rm -f "$entitlements"' EXIT
        cat > "$entitlements" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>com.apple.security.smartcard</key><true/>
<key>com.apple.security.get-task-allow</key><true/>
</dict></plist>
PLIST
        codesign --force --deep --sign - --entitlements "$entitlements" "$app"
        codesign --verify --deep --strict "$app"
        bash "$repo/apple/scripts/run-mock-ui-tests.sh" macos "$app" mac "$out"
        ;;
    ios)
        mkdir -p "$out"
        xcrun simctl list devices available -j > "$out/devices.json"
        xcrun simctl list runtimes -j > "$out/runtimes.json"
        sdk_version=$(xcrun --sdk iphonesimulator --show-sdk-version)
        python3 "$repo/scripts/ci/select_apple_ui_targets.py" "$out/devices.json" "$out/runtimes.json" "$sdk_version" > "$out/targets.tsv"
        cat "$out/targets.tsv"
        # Separate devices, app containers, test hosts and evidence; one billed runner/job.
        exec python3 "$repo/scripts/ci/run-ios-ui-devices.py" "$app" "$out/targets.tsv" "$out"
        ;;
    *) echo 'Unsupported platform.' >&2; exit 2 ;;
esac
