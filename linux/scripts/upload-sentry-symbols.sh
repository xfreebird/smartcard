#!/usr/bin/env bash
# Upload compiled ELF/DWARF files only. No sources, documents, logs or signing identities.
set -euo pipefail
directory="${1:?Usage: upload-sentry-symbols.sh <dedicated-symbol-directory>}"
: "${SENTRY_AUTH_TOKEN:?Configure SENTRY_AUTH_TOKEN in the CI secret store}"
[[ -d "$directory" ]] || exit 2
sentry-cli --url https://de.sentry.io debug-files upload --org personal-kee --project esemnbun-linux "$directory"
