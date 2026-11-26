#!/bin/bash
# Run from a logged-in, otherwise idle macOS GUI session against a Debug app. No reader, card, PIN or
# background item is used: the bundled Debug helper reads fake snapshots and targets an isolated QA
# instance it did not launch.
# Checks that an insertion leaves an already showing main window alone (no activation, no reordering),
# that an explicit reopen still brings it forward, and that an insertion still presents a closed window.
set -euo pipefail
app=${1:?Usage: test-macos-insertion-window.sh DEBUG_APP OUTPUT_DIR}
out=${2:?Output directory required}
app=$(cd "$app" && pwd)
binary="$app/Contents/MacOS/eSemnBun"
helper="$app/Contents/Helpers/esemnbun-reader-watcher"
[[ -x "$binary" && -x "$helper" ]] || { echo 'Missing app or helper executable' >&2; exit 1; }
grep -aq MSIGN_QA_HELPER_RUNNING_APP "$helper" || { echo 'A Debug helper with the QA delivery hook is required.' >&2; exit 1; }
[[ ! -e "$out" ]] || { echo 'Choose a new output directory.' >&2; exit 1; }
mkdir -p "$out"
app_pid=''
helper_pid=''
suites=()

cleanup() {
    [[ -z "$helper_pid" ]] || { kill "$helper_pid" 2>/dev/null || true; wait "$helper_pid" 2>/dev/null || true; }
    [[ -z "$app_pid" ]] || { kill "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true; }
    for suite in "${suites[@]+"${suites[@]}"}"; do
        defaults delete "$suite" >/dev/null 2>&1 || true
        rm -f "$HOME/Library/Preferences/$suite.plist"
    done
}
trap cleanup EXIT

# Another build with the same bundle identifier may be running: compare processes, not identifiers.
front() {   # pid | bundleid of the frontmost application
    local info
    info=$(lsappinfo info "$(lsappinfo front)")
    case $1 in
        pid) grep -oE 'pid = [0-9]+' <<<"$info" | head -1 | awk '{print $3}' ;;
        bundleid) grep -oE 'bundleID="[^"]*"' <<<"$info" | head -1 | cut -d'"' -f2 ;;
    esac
}
wait_for() {   # description, timeout seconds, command...
    local what=$1 limit=$2
    shift 2
    for _ in $(seq 1 $((limit * 4))); do
        if "$@"; then return 0; fi
        sleep 0.25
    done
    echo "Timed out waiting for: $what" >&2
    return 1
}
finder_front() { [[ "$(front bundleid)" == com.apple.finder ]]; }
app_front() { [[ "$(front pid)" == "$app_pid" ]]; }
single_instance() { [[ $(pgrep -f "^$binary( |$)" | wc -l | tr -d ' ') == 1 ]]; }
log_has() { grep -q "$2" "$1"; }

launch() {   # scenario name, extra app arguments...
    local name=$1
    shift
    local suite="md.esemnbun.qa.insertion.$name.$$"
    suites+=("$suite")
    defaults write "$suite" bridgeEnabled -bool false
    defaults write "$suite" didCompleteOnboarding -bool true
    [[ $# -gt 0 ]] || defaults write "$suite" didPresentMainWindow -bool true
    MSIGN_QA_NO_HARDWARE=1 MSIGN_QA_READER_URL=1 MSIGN_DEMO_CARDS=2 MSIGN_DEMO_PREVIEW=0 \
    MSIGN_DEMO_PREFERENCES_SUITE="$suite" "$binary" "$@" >"$out/$name-app.log" 2>&1 &
    app_pid=$!
    current_suite=$suite
}

insert_reader() {   # scenario name
    local name=$1 snapshot="$out/$1-snapshot.json"
    printf '{}' > "$snapshot"
    # BundleProgram starts the executable with a relative argv[0] under launchd.
    (cd "$app" && MSIGN_DEMO_PREFERENCES_SUITE="$current_suite" MSIGN_QA_HELPER_RUNNING_APP=1 \
        exec -a Contents/Helpers/esemnbun-reader-watcher "$helper" --mock-snapshot "$snapshot") >"$out/$name-helper.log" 2>&1 &
    helper_pid=$!
    sleep 1.2   # The first sample is a silent baseline.
    printf '{"qa-reader": true}' > "$snapshot"
    wait_for 'helper delivery without activation' 10 log_has "$out/$name-helper.log" 'MOCK_WATCHER_DELIVERED activates=false'
    kill "$helper_pid" 2>/dev/null || true
    wait "$helper_pid" 2>/dev/null || true
    helper_pid=''
}

stop_app() {
    kill "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null || true
    app_pid=''
}

# 1. Main window showing behind another app: insertion only updates content.
launch showing --show-main-window
wait_for 'main window to come forward at launch' 20 app_front
open -a Finder
wait_for 'Finder to become frontmost' 10 finder_front
insert_reader showing
wait_for 'insertion policy decision' 10 log_has "$out/showing-app.log" 'MSIGN_QA_INSERTION_WINDOW=update-content'
sleep 1.5   # Cover the delayed second activation pass bringForward would perform.
finder_front || { echo "Insertion activated $(front bundleid) over Finder." >&2; exit 1; }
echo 'PASSED: insertion with a showing window kept Finder frontmost and did not present the window.'

# 2. Explicit reopen (Dock, Finder, open -a) still brings the same window forward.
open -a "$app"
wait_for 'explicit reopen to activate the app' 10 app_front
single_instance || { echo 'Reopen started another instance.' >&2; exit 1; }
echo 'PASSED: explicit reopen brought the window forward.'
stop_app

# 3. No main window: insertion presents it and activates the app as before.
launch closed
sleep 3   # Launch completes without a window.
open -a Finder
wait_for 'Finder to become frontmost' 10 finder_front
insert_reader closed
wait_for 'insertion policy decision' 10 log_has "$out/closed-app.log" 'MSIGN_QA_INSERTION_WINDOW=bring-forward'
wait_for 'insertion to present the window' 10 app_front
single_instance || { echo 'Insertion started another instance.' >&2; exit 1; }
echo 'PASSED: insertion without a showing window presented and activated it.'
stop_app
echo "Logs: $out"
