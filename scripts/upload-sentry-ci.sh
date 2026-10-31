#!/usr/bin/env bash
set -euo pipefail
platform="${1:?Usage: upload-sentry-ci.sh <apple|linux|windows> <symbols-directory>}"
symbols="${2:?Supply the dedicated symbol/archive directory}"
if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]]; then
  echo '::warning::SENTRY_AUTH_TOKEN is unset; Sentry debug-symbol upload was skipped. Native production stack traces are not fully verified.'
  exit 0
fi
repo="$(cd "$(dirname "$0")/.." && pwd)"
tool_directory="$repo/.build/sentry-cli"
"$repo/scripts/install-sentry-cli.sh" "$tool_directory"
export PATH="$tool_directory:$PATH" SENTRY_URL=https://de.sentry.io
case "$platform" in
  apple) "$repo/apple/scripts/upload-sentry-symbols.sh" "$symbols" ;;
  linux) "$repo/linux/scripts/upload-sentry-symbols.sh" "$symbols" ;;
  windows) pwsh -NoProfile -File "$repo/windows/scripts/upload-sentry-symbols.ps1" -SymbolsPath "$symbols" ;;
  *) echo 'Unknown platform.' >&2; exit 2 ;;
esac
