#!/usr/bin/env bash
# Retry transient dependency downloads without hiding compilation or test failures.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root/android"
log=$(mktemp "${TMPDIR:-/tmp}/esemnbun-gradle.XXXXXX")
trap 'rm -- "$log"' EXIT
for attempt in 1 2 3; do
    set +e
    ./gradlew "$@" 2>&1 | tee "$log"
    codes=("${PIPESTATUS[@]}")
    set -e
    [[ "${codes[1]}" == 0 ]] || exit "${codes[1]}"
    [[ "${codes[0]}" != 0 ]] || exit 0
    # Retry only a dependency-resolution failure paired with a transport/HTTP error.
    if grep -q 'There were failing tests' "$log" ||
       ! grep -qE 'Could not (resolve all|download|GET|HEAD)|Downloading https?://' "$log" ||
       ! grep -qiE 'Read timed out|Connection timed out|Connection reset|Remote host terminated|Temporary failure in name resolution|status code[: ]+(429|5[0-9]{2})|50[234] (Bad Gateway|Service Unavailable|Gateway Timeout)' "$log"; then
        exit "${codes[0]}"
    fi
    [[ "$attempt" != 3 ]] || exit "${codes[0]}"
    echo "Dependency download failed temporarily; retrying ($attempt/3)."
    sleep "$((5 * attempt))"
done
