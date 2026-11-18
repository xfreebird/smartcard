#!/usr/bin/env bash
# Retry transient dependency downloads without hiding compilation or test failures.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root/android"
log=$(mktemp "${TMPDIR:-/tmp}/esemnbun-gradle.XXXXXX")
trap 'rm -- "$log"' EXIT
# Gradle sometimes reports only "plugin artifact ... not found", omitting the transport error.
# Check only the implementation modules configured in this repository, at their publishing origins.
retry_plugin_resolution() {
    local coordinate group artifact version origin url status curl_status=0
    coordinate=$(sed -nE "s/.*Plugin Repositories \(could not resolve plugin artifact '([^']+)'\).*/\1/p" "$log" | head -n 1)
    case "$coordinate" in
        org.jetbrains.kotlin:kotlin-gradle-plugin:*|org.jetbrains.kotlin:compose-compiler-gradle-plugin:*)
            origin=https://repo.maven.apache.org/maven2 ;;
        com.android.tools.build:gradle:*) origin=https://dl.google.com/dl/android/maven2 ;;
        *) return 1 ;;
    esac
    IFS=: read -r group artifact version <<< "$coordinate"
    [[ "$version" =~ ^[0-9][a-zA-Z0-9.-]*$ ]] || return 1
    url="$origin/$(tr '.' '/' <<< "$group")/$artifact/$version/$artifact-$version.pom"
    status=$(curl --silent --show-error --head --max-time 8 --output /dev/null --write-out '%{http_code}' "$url") || curl_status=$?
    echo "Plugin resolution probe for $coordinate: HTTP $status, curl exit $curl_status."
    case "$curl_status:$status" in
        0:200|0:429|0:5??|6:*|7:*|28:*|52:*|56:*) return 0 ;;
        *) return 1 ;;
    esac
}

for attempt in 1 2 3; do
    set +e
    ./gradlew "$@" 2>&1 | tee "$log"
    codes=("${PIPESTATUS[@]}")
    set -e
    [[ "${codes[1]}" == 0 ]] || exit "${codes[1]}"
    [[ "${codes[0]}" != 0 ]] || exit 0
    [[ "$attempt" != 3 ]] || exit "${codes[0]}"
    if grep -qiE 'There were failing tests|Compilation (error|failed)|^e: |status code[: ]+(401|403)([^0-9]|$)' "$log"; then
        exit "${codes[0]}"
    fi
    if grep -qE 'Could not (resolve all|download|GET|HEAD)|Downloading https?://' "$log" &&
       grep -qiE 'Read timed out|Connection timed out|Connection reset|Remote host terminated|Temporary failure in name resolution|status code[: ]+(429|5[0-9]{2})|50[234] (Bad Gateway|Service Unavailable|Gateway Timeout)' "$log"; then
        echo "Transient dependency transfer failure; retrying ($attempt/3)."
    elif [[ " $* " != *' --offline '* ]] && retry_plugin_resolution; then
        # Invalidate Gradle's cached negative metadata for this retry.
        [[ " $* " == *' --refresh-dependencies '* ]] || set -- "$@" --refresh-dependencies
        echo "Plugin repository resolution failed; retrying ($attempt/3)."
    else
        exit "${codes[0]}"
    fi
    sleep "$((5 * attempt))"
done
