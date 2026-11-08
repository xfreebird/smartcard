#!/usr/bin/env bash
# OS 27 system Open/Search schemas must be included in shipping Apple artifacts.
set -euo pipefail
version=$(xcrun --sdk macosx --show-sdk-version)
if [[ ! "$version" =~ ^([0-9]+)\. ]] || (( 10#${BASH_REMATCH[1]} < 27 )); then
  echo 'error: Siri system schemas require Xcode 27 or newer. Select it with DEVELOPER_DIR.' >&2
  exit 1
fi
echo "Verified macOS SDK $version for Siri system schemas."
