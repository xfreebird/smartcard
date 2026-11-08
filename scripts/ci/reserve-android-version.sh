#!/usr/bin/env bash
# Shared counter; callers serialize with android-play-version-code.
set -euo pipefail
git fetch --force --tags origin
minimum_version_code=1793624666
last_reserved_code="$(git tag -l 'android-play-vc-*' | sed -n 's/^android-play-vc-//p' | sort -n | tail -1)"
if [[ -n "$last_reserved_code" && "$last_reserved_code" -gt "$minimum_version_code" ]]; then
  next_build_number=$((last_reserved_code + 1))
else
  next_build_number=$((minimum_version_code + 1))
fi
build_number="${BUILD_NUMBER_INPUT:-$next_build_number}"
[[ "$build_number" =~ ^[1-9][0-9]*$ ]] || { echo '::error::Invalid build number'; exit 1; }
[[ ${#build_number} -le 10 ]] && (( build_number <= 2100000000 )) || { echo '::error::Build number exceeds Android versionCode limit'; exit 1; }
if (( build_number < next_build_number )); then
  if [[ -n "$BUILD_NUMBER_INPUT" && "$(git rev-parse "refs/tags/android-play-vc-$build_number^{}" 2>/dev/null || true)" == "$GITHUB_SHA" ]]; then
    echo "Reusing version code $build_number reserved for this source commit"
  else
    echo '::error::Build number belongs to another source commit or is below the next Play version code'
    exit 1
  fi
else
  # Reserve an existing commit through the refs API; pushing a new annotated tag
  # can require workflows permission when main advanced after checkout.
  gh api --method POST "repos/$GITHUB_REPOSITORY/git/refs" \
    -f "ref=refs/tags/android-play-vc-$build_number" -f "sha=$GITHUB_SHA" >/dev/null
fi
echo "BUILD_NUMBER=$build_number" >> "$GITHUB_ENV"
