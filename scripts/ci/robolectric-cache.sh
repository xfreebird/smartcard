#!/usr/bin/env bash
# Robolectric's Android framework jar (151 MB) is the largest Android test dependency. Maven Central answers bursts
# of large downloads from shared CI addresses with HTTP 429, and Gradle neither honours Retry-After nor waits long
# enough between its own attempts. This puts the jar and its POM into Gradle's file cache with curl's backoff; Gradle
# then reuses the locally available file whose checksum matches and fetches only that checksum. Each file must match
# the SHA-256 that dependency verification already pins.
#   robolectric-cache.sh outputs   print version= and path= for actions/cache
#   robolectric-cache.sh seed      download what the Gradle cache does not hold yet
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
version=$(sed -nE 's/^robolectricAndroidAll = "([^"]+)"$/\1/p' "$repo_root/android/gradle/libs.versions.toml")
if [[ ! "$version" =~ ^[0-9A-Za-z.-]+$ ]]; then
    echo "robolectricAndroidAll is missing from android/gradle/libs.versions.toml" >&2
    exit 1
fi
cache="${GRADLE_USER_HOME:-$HOME/.gradle}/caches/modules-2/files-2.1/org.robolectric/android-all-instrumented/$version"

case "${1:-}" in
    outputs) printf 'version=%s\npath=%s\n' "$version" "$cache"; exit 0 ;;
    seed) ;;
    *) echo "usage: $0 outputs|seed" >&2; exit 2 ;;
esac

metadata="$repo_root/android/gradle/verification-metadata.xml"
base="${ROBOLECTRIC_REPOSITORY:-https://repo.maven.apache.org/maven2}/org/robolectric/android-all-instrumented/$version"
work=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/robolectric.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
for name in "android-all-instrumented-$version.pom" "android-all-instrumented-$version.jar"; do
    if compgen -G "$cache/*/$name" > /dev/null; then
        echo "Already cached: $name"
        continue
    fi
    expected=$(awk -v artifact="name=\"$name\"" 'index($0, artifact) { found = 1 }
        found && match($0, /sha256 value="[0-9a-f]+"/) { print substr($0, RSTART + 14, RLENGTH - 15); exit }' "$metadata")
    if [[ ${#expected} != 64 ]]; then
        echo "verification-metadata.xml pins no SHA-256 for $name" >&2
        exit 1
    fi
    # Without --retry-delay curl backs off exponentially and honours Retry-After on 429 and 503.
    curl --fail --silent --show-error --location --connect-timeout 20 --speed-limit 65536 --speed-time 60 \
        --retry 8 --retry-connrefused --retry-max-time 900 --output "$work/$name" "$base/$name"
    actual=$(shasum -a 256 "$work/$name" | cut -d ' ' -f 1)
    if [[ "$actual" != "$expected" ]]; then
        echo "SHA-256 of downloaded $name is $actual, verification-metadata.xml pins $expected" >&2
        exit 1
    fi
    # Gradle names each cached file's directory after the file's SHA-1.
    sha1=$(shasum -a 1 "$work/$name" | cut -d ' ' -f 1)
    mkdir -p "$cache/$sha1"
    mv "$work/$name" "$cache/$sha1/$name"
    echo "Cached $name"
done
