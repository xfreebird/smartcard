#!/usr/bin/env bash
# Pinned official CLI binary, verified against the release's published asset digest.
set -euo pipefail
destination="${1:?Usage: install-sentry-cli.sh <installation-directory>}"
case "$(uname -s):$(uname -m)" in
  Darwin:*) asset=Darwin-universal; checksum=2d1b118fa46960ba5e8e0cca9a6e197366905776a0ddc5a89c7d05a3908b77db ;;
  Linux:aarch64|Linux:arm64) asset=Linux-aarch64; checksum=b6e49fca868a36d20da2ada1832a0ce2f9ac7012c128207518b09d6b6c991f4d ;;
  Linux:x86_64) asset=Linux-x86_64; checksum=c958865f9d4000183509ea21b1f04925d5390de6d8d87386b9e69f2b305070c3 ;;
  MINGW*:x86_64|MSYS*:x86_64) asset=Windows-x86_64.exe; checksum=50009f23c49d6e9ff7624204c7035855303b49c5e326708ee783c1fdf783ac83 ;;
  *) echo 'Unsupported Sentry CLI host.' >&2; exit 2 ;;
esac
mkdir -p "$destination"
binary="$destination/sentry-cli"
[[ "$asset" != *.exe ]] || binary="$binary.exe"
curl -fsSL "https://github.com/getsentry/sentry-cli/releases/download/3.8.2/sentry-cli-$asset" -o "$binary"
if command -v sha256sum >/dev/null; then
  echo "$checksum  $binary" | sha256sum -c -
else
  echo "$checksum  $binary" | shasum -a 256 -c -
fi
chmod +x "$binary"
