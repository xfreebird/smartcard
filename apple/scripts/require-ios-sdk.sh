#!/usr/bin/env bash
# Metadata-only preflight: iOS 27.1+ SDK is needed for native iPhone Duo layouts.
# Honor DEVELOPER_DIR / xcode-select; never change the global Xcode selection.
set -euo pipefail

for sdk in iphoneos iphonesimulator; do
  if ! version=$(xcrun --sdk "$sdk" --show-sdk-version); then
    echo "error: Cannot read the $sdk SDK. Select Xcode with iOS 27.1+ using DEVELOPER_DIR." >&2
    exit 1
  fi
  if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+)(\.[0-9]+)?$ ]]; then
    echo "error: Unrecognized $sdk SDK version: $version" >&2
    exit 1
  fi
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  if (( 10#$major < 27 || (10#$major == 27 && 10#$minor < 1) )); then
    echo "error: iPhone Duo builds require iOS 27.1+ SDK; selected $sdk is $version." >&2
    echo "Set DEVELOPER_DIR to a suitable Xcode.app/Contents/Developer before building. Existing artifacts are untouched." >&2
    exit 1
  fi
  echo "Verified $sdk SDK $version (minimum 27.1 for iPhone Duo)."
done
