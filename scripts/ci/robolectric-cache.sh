#!/usr/bin/env bash
# Robolectric's Android framework jar (151 MB) is the largest Android test dependency. Maven Central answers CI's
# shared addresses with HTTP 429, for the download and even for Gradle's request about a copy it already has. CI
# therefore keeps the jar and its POM in a local Maven folder, restored from the Actions cache, and Gradle reads
# them only from there (ROBOLECTRIC_LOCAL_REPOSITORY in android/settings.gradle.kts). On a cache miss this fills
# the folder with curl's backoff, from Google's Maven Central mirror first. Every file must match the SHA-256
# that dependency verification pins, wherever it came from.
#   robolectric-cache.sh outputs   print version= and path= for actions/cache and Gradle
#   robolectric-cache.sh seed      download what the folder does not hold yet, then check both files
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
version=$(sed -nE 's/^robolectricAndroidAll = "([^"]+)"$/\1/p' "$repo_root/android/gradle/libs.versions.toml")
if [[ ! "$version" =~ ^[0-9A-Za-z.-]+$ ]]; then
    echo "robolectricAndroidAll is missing from android/gradle/libs.versions.toml" >&2
    exit 1
fi
repository="${ROBOLECTRIC_LOCAL_REPOSITORY:-$HOME/.cache/robolectric-repository}"
module_path="org/robolectric/android-all-instrumented/$version"

case "${1:-}" in
    outputs) printf 'version=%s\npath=%s\n' "$version" "$repository"; exit 0 ;;
    seed) ;;
    *) echo "usage: $0 outputs|seed" >&2; exit 2 ;;
esac

metadata="$repo_root/android/gradle/verification-metadata.xml"
read -r -a mirrors <<< "${ROBOLECTRIC_MIRRORS:-https://maven-central.storage-download.googleapis.com/maven2 https://repo.maven.apache.org/maven2}"
work=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/robolectric.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$repository/$module_path"

pinned() {
    awk -v artifact="name=\"$1\"" 'index($0, artifact) { found = 1 }
        found && match($0, /sha256 value="[0-9a-f]+"/) { print substr($0, RSTART + 14, RLENGTH - 15); exit }' "$metadata"
}
sha256() { shasum -a 256 "$1" | cut -d ' ' -f 1; }

for name in "android-all-instrumented-$version.pom" "android-all-instrumented-$version.jar"; do
    expected=$(pinned "$name")
    if [[ ${#expected} != 64 ]]; then
        echo "verification-metadata.xml pins no SHA-256 for $name" >&2
        exit 1
    fi
    target="$repository/$module_path/$name"
    if [[ -f "$target" && "$(sha256 "$target")" == "$expected" ]]; then
        echo "Already present: $name"
        continue
    fi
    rm -f -- "$target"
    for mirror in "${mirrors[@]}"; do
        # Without --retry-delay curl backs off exponentially and honours Retry-After on 429 and 503.
        if curl --fail --silent --show-error --location --connect-timeout 20 --speed-limit 65536 --speed-time 60 \
                --retry 6 --retry-connrefused --retry-max-time 600 --output "$work/$name" "$mirror/$module_path/$name"; then
            actual=$(sha256 "$work/$name")
            if [[ "$actual" == "$expected" ]]; then
                mv "$work/$name" "$target"
                echo "Downloaded $name from $mirror"
                break
            fi
            echo "SHA-256 of $name from $mirror is $actual, verification-metadata.xml pins $expected" >&2
        fi
        echo "Could not take $name from $mirror; trying the next source." >&2
    done
    if [[ ! -f "$target" ]]; then
        echo "No source provided $name with the pinned SHA-256" >&2
        exit 1
    fi
done
