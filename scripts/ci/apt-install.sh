#!/usr/bin/env bash
# Install Ubuntu packages in CI containers. Acquire::Retries repeats a dropped download, but an archive caught
# mid-sync serves indexes whose hashes no longer match, and apt-get then exits 100 for the whole job. Repeating
# the update and install after a pause lets the mirror settle.
set -euo pipefail
(( $# > 0 )) || { echo "usage: $0 package..." >&2; exit 2; }
for attempt in 1 2 3; do
    if apt-get -o Acquire::Retries=3 update --error-on=any &&
       apt-get -o Acquire::Retries=3 install -y --no-install-recommends "$@"; then
        exit 0
    fi
    [[ "$attempt" != 3 ]] || exit 100
    echo "apt-get failed; retrying in $((30 * attempt)) s ($attempt/3)."
    sleep "$((30 * attempt))"
done
