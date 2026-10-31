#!/bin/bash
# Dispatch platform mock captures to existing native drivers.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
platform=${1:?Usage: capture-screenshots.sh macos|ios|android|linux|windows [platform arguments]}
shift
case "$platform" in
    macos|ios) exec "$root/apple/scripts/capture-screenshots.sh" "$platform" "$@" ;;
    android) exec "$root/android/scripts/capture-screenshots.sh" "$@" ;;
    linux) exec "$root/linux/scripts/capture-mocks-air.sh" "$@" ;;
    windows) exec pwsh -NoProfile -File "$root/windows/scripts/capture-scenarios.ps1" "$@" ;;
    *) echo "Unknown platform: $platform" >&2; exit 2 ;;
esac
