#!/usr/bin/env bash
# Package the macOS menu-bar app (DMG) and the `moldsign` CLI (tar.gz) into dist/macos/.  (MAC-15, CLI-04)
#
# Signing (all optional):
#   MACOS_SIGN_IDENTITY  "Developer ID Application: …"   default "-" (ad-hoc: runs on this Mac only)
#   MACOS_TEAM_ID        team for the identity
#   NOTARY_PROFILE       `xcrun notarytool store-credentials` profile → notarize + staple the DMG
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/macos"
DD="$ROOT/dist/.derived-macos"
IDENTITY="${MACOS_SIGN_IDENTITY:--}"
VERSION="$(xcodebuild -project "$ROOT/apple/MoldSign.xcodeproj" -scheme MoldSign-macOS -showBuildSettings 2>/dev/null | awk '/ MARKETING_VERSION =/{print $3; exit}')"
rm -rf "$OUT" && mkdir -p "$OUT"

sign_args=(CODE_SIGN_IDENTITY="$IDENTITY" CODE_SIGN_STYLE=Manual)
[[ -n "${MACOS_TEAM_ID:-}" ]] && sign_args+=(DEVELOPMENT_TEAM="$MACOS_TEAM_ID") || sign_args+=(DEVELOPMENT_TEAM=)
[[ "$IDENTITY" != "-" ]] && sign_args+=(OTHER_CODE_SIGN_FLAGS=--timestamp)

echo "▸ Archiving MoldSign-macOS (identity: $IDENTITY)"
xcodebuild -project "$ROOT/apple/MoldSign.xcodeproj" -scheme MoldSign-macOS -configuration Release \
  -derivedDataPath "$DD" -archivePath "$OUT/MoldSign.xcarchive" "${sign_args[@]}" archive -quiet

APP="$OUT/MoldSign.xcarchive/Products/Applications/MoldSign.app"
codesign --verify --deep --strict "$APP"

echo "▸ Building DMG"
STAGE="$OUT/dmg-stage"
mkdir -p "$STAGE" && cp -R "$APP" "$STAGE/" && ln -s /Applications "$STAGE/Applications"
hdiutil create -quiet -volname "MoldSign $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$OUT/MoldSign-$VERSION.dmg"
rm -rf "$STAGE"
[[ "$IDENTITY" != "-" ]] && codesign --sign "$IDENTITY" --timestamp "$OUT/MoldSign-$VERSION.dmg"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "▸ Notarizing"
  xcrun notarytool submit "$OUT/MoldSign-$VERSION.dmg" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$OUT/MoldSign-$VERSION.dmg"
fi

echo "▸ Building the moldsign CLI (release)"
(cd "$ROOT/swift/MoldSignKit" && swift build -c release --product moldsign --arch arm64 --arch x86_64 >/dev/null)
CLI="$(cd "$ROOT/swift/MoldSignKit" && swift build -c release --product moldsign --arch arm64 --arch x86_64 --show-bin-path)/moldsign"
codesign --force --options runtime --sign "$IDENTITY" ${MACOS_SIGN_IDENTITY:+--timestamp} "$CLI"
tar -C "$(dirname "$CLI")" -czf "$OUT/moldsign-$VERSION-macos-universal.tar.gz" moldsign

rm -rf "$DD"
echo "✔ $(ls "$OUT")"
