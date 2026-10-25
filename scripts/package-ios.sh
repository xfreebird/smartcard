#!/usr/bin/env bash
# Archive the iOS app and export an IPA into dist/ios/.  (IOS-10)
#
# Signing (optional):
#   IOS_TEAM_ID        Apple team → signed export with Xcode-managed signing (automatic provisioning)
#   IOS_EXPORT_METHOD  development | release-testing (ad hoc) | app-store-connect   (default: development)
# Without IOS_TEAM_ID the archive is unsigned and the IPA is for later re-signing only (not installable).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/ios"
DD="$ROOT/dist/.derived-ios"
rm -rf "$OUT" && mkdir -p "$OUT"

if [[ -n "${IOS_TEAM_ID:-}" ]]; then
  echo "▸ Archiving MoldSign-iOS (team $IOS_TEAM_ID)"
  xcodebuild -project "$ROOT/apple/MoldSign.xcodeproj" -scheme MoldSign-iOS -configuration Release \
    -destination 'generic/platform=iOS' -derivedDataPath "$DD" -archivePath "$OUT/MoldSign-iOS.xcarchive" \
    DEVELOPMENT_TEAM="$IOS_TEAM_ID" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates archive -quiet
  cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>${IOS_EXPORT_METHOD:-development}</string>
  <key>teamID</key><string>$IOS_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict></plist>
PLIST
  xcodebuild -exportArchive -archivePath "$OUT/MoldSign-iOS.xcarchive" -exportPath "$OUT" \
    -exportOptionsPlist "$OUT/ExportOptions.plist" -allowProvisioningUpdates -quiet
else
  echo "▸ Archiving MoldSign-iOS (unsigned)"
  xcodebuild -project "$ROOT/apple/MoldSign.xcodeproj" -scheme MoldSign-iOS -configuration Release \
    -destination 'generic/platform=iOS' -derivedDataPath "$DD" -archivePath "$OUT/MoldSign-iOS.xcarchive" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO archive -quiet
  STAGE="$OUT/ipa-stage/Payload"
  mkdir -p "$STAGE"
  cp -R "$OUT/MoldSign-iOS.xcarchive/Products/Applications/MoldSign.app" "$STAGE/"
  (cd "$OUT/ipa-stage" && zip -qry "$OUT/MoldSign-unsigned.ipa" Payload)
  rm -rf "$OUT/ipa-stage"
fi

rm -rf "$DD"
echo "✔ $(ls "$OUT")"
