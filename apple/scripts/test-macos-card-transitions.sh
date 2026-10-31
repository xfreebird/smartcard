#!/bin/bash
# Run from a logged-in macOS GUI session against a Debug mock-enabled app.
# Exercises reader removal and reinsertion without a physical reader or PIN.
set -euo pipefail
app=${1:?Usage: test-macos-card-transitions.sh DEBUG_APP OUTPUT_DIR}
out=${2:?Output directory required}
binary="$app/Contents/MacOS/eSemnBun"
[[ -x "$binary" ]] || { echo 'Missing app executable' >&2; exit 1; }
if ! grep -aq MSIGN_DEMO_CARD_TRANSITIONS "$binary" &&
   ! { [[ -f "$app/Contents/MacOS/eSemnBun.debug.dylib" ]] && grep -aq MSIGN_DEMO_CARD_TRANSITIONS "$app/Contents/MacOS/eSemnBun.debug.dylib"; }; then
    echo 'A Debug app with the card-transition fixture is required.' >&2
    exit 1
fi
mkdir -p "$out"
log="$out/card-transitions.log"
[[ ! -e "$log" ]] || { echo 'Choose a new output directory.' >&2; exit 1; }
MSIGN_QA_NO_HARDWARE=1 MSIGN_DEMO_CARDS=3 MSIGN_DEMO_SELECTED=2 \
MSIGN_DEMO_CARD_TRANSITIONS=1 MSIGN_DEMO_PREFERENCES_SUITE="md.esemnbun.qa.transitions.$$" \
    "$binary" --show-main-window >"$log" 2>&1 &
pid=$!
trap 'kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' EXIT
for _ in $(seq 1 120); do
    kill -0 "$pid" 2>/dev/null || { cat "$log" >&2; echo 'App exited during card transitions.' >&2; exit 1; }
    [[ $(grep -c '^MSIGN_QA_CARD_COUNT=' "$log" || true) -ge 4 ]] && break
    sleep 0.25
done
actual=$(grep '^MSIGN_QA_CARD_COUNT=' "$log" | tr '\n' ' ')
[[ "$actual" == 'MSIGN_QA_CARD_COUNT=2 MSIGN_QA_CARD_COUNT=1 MSIGN_QA_CARD_COUNT=0 MSIGN_QA_CARD_COUNT=3 ' ]] || {
    cat "$log" >&2; echo 'Card transitions did not complete in order.' >&2; exit 1;
}
kill -0 "$pid" 2>/dev/null || { echo 'App exited after the transitions.' >&2; exit 1; }
echo "Card transitions completed with the app running; log: $log"
