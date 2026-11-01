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
import pathlib,plistlib,sys
variant,app,entitlements=sys.argv[1:]
app=pathlib.Path(app)
values=plistlib.loads(pathlib.Path(entitlements).read_bytes())
store=variant=='store'
assert bool(values.get('com.apple.security.app-sandbox')) == store, 'Wrong sandbox entitlement for distribution'
assert (app/'Contents/Resources/localhost.p12').exists(), 'Missing loopback TLS identity'
for resource in ('Contents/Helpers/esemnbun-reader-watcher','Contents/Library/LaunchAgents/md.esemnbun.reader-watcher.plist'):
    assert (app/resource).exists() != store, f'Wrong distribution payload: {resource}'
if store:
    assert values.get('com.apple.security.network.server'), 'Store loopback bridge requires server entitlement'
print(f'{variant} distribution boundaries verified')
PYTHON
