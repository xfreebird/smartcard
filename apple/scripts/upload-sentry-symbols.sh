#!/bin/bash
# Upload only compiled debug symbols; source code is deliberately excluded.
set -euo pipefail
if [[ $# -ne 1 || ! -d "$1" ]]; then
    echo "Usage: $0 <dSYM directory or xcarchive>" >&2
    exit 2
fi
: "${SENTRY_AUTH_TOKEN:?Set a Sentry CI auth token through the secret store}"
export SENTRY_ORG="${SENTRY_ORG:-personal-kee}"
export SENTRY_PROJECT="${SENTRY_PROJECT:-apple}"
command -v sentry-cli >/dev/null || { echo 'Install sentry-cli before uploading symbols.' >&2; exit 2; }
sentry-cli debug-files upload --org "$SENTRY_ORG" --project "$SENTRY_PROJECT" "$1"
