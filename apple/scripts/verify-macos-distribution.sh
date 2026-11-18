#!/usr/bin/env bash
# Assert distribution boundaries on a signed app bundle before packaging.
set -euo pipefail
variant=${1:?Usage: verify-macos-distribution.sh store|desktop /path/eSemnBun.app}
app=${2:?Supply an application bundle}
case "$variant" in store|desktop) ;; *) echo 'Unknown distribution' >&2; exit 2;; esac
codesign --verify --deep --strict "$app"
entitlements=$(mktemp -t esemnbun-entitlements)
trap 'rm -f "$entitlements"' EXIT
codesign -d --entitlements :- "$app" > "$entitlements" 2>/dev/null
python3 - "$variant" "$app" "$entitlements" <<'PYTHON'
import pathlib,plistlib,subprocess,sys
variant,app,entitlements=sys.argv[1:]
app=pathlib.Path(app)
values=plistlib.loads(pathlib.Path(entitlements).read_bytes())
store=variant=='store'
info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
assert info.get('ITSAppUsesNonExemptEncryption') is False, 'Missing owner-declared exempt-encryption default'
assert bool(values.get('com.apple.security.app-sandbox')) == store, 'Wrong sandbox entitlement for distribution'
assert (app/'Contents/Resources/localhost.p12').exists(), 'Missing loopback TLS identity'
agent_dir = app/'Contents/Library/LaunchAgents'
desktop_label = 'md.esemnbun.reader-watcher'
store_label = 'md.esemnbun.mac.reader-watcher'
label = store_label if store else desktop_label
agent = plistlib.loads((agent_dir/f'{label}.plist').read_bytes())
assert not (agent_dir/f'{desktop_label if store else store_label}.plist').exists(), 'Stale reader agent'
assert agent['Label'] == label and agent['BundleProgram'] == 'Contents/Helpers/esemnbun-reader-watcher'
helper = app/agent['BundleProgram']
helper_values = plistlib.loads(subprocess.check_output(['codesign', '-d', '--entitlements', ':-', str(helper)]))
assert helper_values.get('com.apple.security.smartcard'), 'Reader watcher requires smart-card access'
assert bool(helper_values.get('com.apple.security.app-sandbox')) == store, 'Wrong reader watcher sandbox'
if store:
    suite = info['ReaderWatcherPreferencesSuite']
    assert suite in values['com.apple.security.application-groups'] and suite in helper_values['com.apple.security.application-groups']
    assert values.get('com.apple.security.files.user-selected.read-write') and values.get('com.apple.security.files.bookmarks.app-scope')
    assert values.get('com.apple.security.network.server'), 'Store loopback bridge requires server entitlement'
print(f'{variant} distribution boundaries verified')
PYTHON
