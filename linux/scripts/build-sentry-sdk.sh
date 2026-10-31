#!/usr/bin/env bash
# Pinned native SDK, in-process crash reporting: sanitized JSON only, no raw memory dumps.
set -euo pipefail
repo="$(cd "$(dirname "$0")/../.." && pwd)"
work="$repo/linux/.build/sentry-native"
prefix="$work/install"
[[ -f "$prefix/lib/libsentry.so" && -f "$prefix/inproc-backend" ]] && exit 0
mkdir -p "$work"
curl -fsSL https://github.com/getsentry/sentry-native/archive/refs/tags/0.17.5.tar.gz -o "$work/source.tar.gz"
echo "7a537f5717684bd54a4d15a61d20f0e04de4f3aa73556687c7dd255a19b5874d  $work/source.tar.gz" | sha256sum -c -
tar -xzf "$work/source.tar.gz" -C "$work"
cmake -S "$work/sentry-native-0.17.5" -B "$work/build" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_LIBDIR=lib \
  -DSENTRY_BACKEND=inproc -DSENTRY_TRANSPORT=curl -DSENTRY_BUILD_SHARED_LIBS=ON \
  -DSENTRY_BUILD_TESTS=OFF -DSENTRY_BUILD_EXAMPLES=OFF
cmake --build "$work/build" --parallel 2
cmake --install "$work/build" --prefix "$prefix"

touch "$prefix/inproc-backend"
