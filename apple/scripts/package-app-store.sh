#!/bin/bash
# Archive and export the sandboxed macOS candidate locally. Does not upload.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
out=${MAC_APP_STORE_OUTPUT:-"$root/dist/macos-app-store"}
team=${APPLE_TEAM_ID:-H86U5Z8HYB}
mkdir -p "$out"
archive="$out/eSemnBun.xcarchive"
# An explicit override file takes precedence over the base xcconfig consistently.
overrides=$(mktemp -t esemnbun-app-store)
trap 'rm -f "$overrides"' EXIT
python3 - "$overrides" "$root/apple/Configuration/AppStore.xcconfig" "$team" "${MAC_APP_STORE_PROFILE:-}" <<'PYTHON'
import pathlib,re,sys
output,base,team,profile=sys.argv[1:]
if not re.fullmatch(r'[A-Z0-9]{10}',team):
    raise SystemExit('APPLE_TEAM_ID must be a ten-character team identifier')
if any(character in profile for character in '\r\n'):
    raise SystemExit('MAC_APP_STORE_PROFILE must be a single profile name')
settings=[f'#include "{base}"',f'DEVELOPMENT_TEAM = {team}','CODE_SIGN_STYLE = Manual']
if profile: settings.append(f'PROVISIONING_PROFILE_SPECIFIER = {profile}')
pathlib.Path(output).write_text('\n'.join(settings)+'\n')
PYTHON
xcodebuild -project "$root/apple/eSemnBun.xcodeproj" -scheme eSemnBun-macOS \
    -configuration Release -destination 'generic/platform=macOS' \
    -xcconfig "$overrides" \
    -archivePath "$archive" archive
python3 - "$out/ExportOptions.plist" "$team" "${MAC_APP_STORE_PROFILE:-}" <<'PYTHON'
import plistlib,sys
options={'method':'app-store-connect','destination':'export','teamID':sys.argv[2],
         'signingStyle':'manual' if sys.argv[3] else 'automatic'}
if sys.argv[3]:
    options['provisioningProfiles']={'md.esemnbun.mac':sys.argv[3]}
    options['signingCertificate']='Apple Distribution'
with open(sys.argv[1], 'wb') as f: plistlib.dump(options,f)
PYTHON
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$out" \
    -exportOptionsPlist "$out/ExportOptions.plist"
echo "Local App Store candidate exported to $out. Validate signed sandbox behavior before uploading."
