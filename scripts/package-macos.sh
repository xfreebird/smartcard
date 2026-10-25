#!/usr/bin/env bash
# Package the macOS menu-bar app (DMG) and the `esemnbun` CLI (tar.gz) into dist/macos/.  (MAC-15, CLI-04)
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
VERSION="$(xcodebuild -project "$ROOT/apple/eSemnBun.xcodeproj" -scheme eSemnBun-macOS -showBuildSettings 2>/dev/null | awk '/ MARKETING_VERSION =/{print $3; exit}')"
rm -rf "$OUT" && mkdir -p "$OUT"

sign_args=(CODE_SIGN_IDENTITY="$IDENTITY" CODE_SIGN_STYLE=Manual)
[[ -n "${MACOS_TEAM_ID:-}" ]] && sign_args+=(DEVELOPMENT_TEAM="$MACOS_TEAM_ID") || sign_args+=(DEVELOPMENT_TEAM=)
[[ "$IDENTITY" != "-" ]] && sign_args+=(OTHER_CODE_SIGN_FLAGS=--timestamp)

echo "▸ Archiving eSemnBun-macOS (identity: $IDENTITY)"
xcodebuild -project "$ROOT/apple/eSemnBun.xcodeproj" -scheme eSemnBun-macOS -configuration Release \
  -derivedDataPath "$DD" -archivePath "$OUT/eSemnBun.xcarchive" "${sign_args[@]}" archive -quiet

APP="$OUT/eSemnBun.xcarchive/Products/Applications/eSemnBun.app"
codesign --verify --deep --strict "$APP"

echo "▸ Building DMG"
STAGE="$OUT/dmg-stage"
mkdir -p "$STAGE" && cp -R "$APP" "$STAGE/" && ln -s /Applications "$STAGE/Applications"
hdiutil create -quiet -volname "eSemnBun $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$OUT/eSemnBun-$VERSION.dmg"
rm -rf "$STAGE"
[[ "$IDENTITY" != "-" ]] && codesign --sign "$IDENTITY" --timestamp "$OUT/eSemnBun-$VERSION.dmg"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "▸ Notarizing"
  xcrun notarytool submit "$OUT/eSemnBun-$VERSION.dmg" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$OUT/eSemnBun-$VERSION.dmg"
fi

echo "▸ Building the esemnbun CLI (release)"
(cd "$ROOT/swift/MoldSignKit" && swift build -c release --product esemnbun --arch arm64 --arch x86_64 >/dev/null)
CLI="$(cd "$ROOT/swift/MoldSignKit" && swift build -c release --product esemnbun --arch arm64 --arch x86_64 --show-bin-path)/esemnbun"
codesign --force --options runtime --sign "$IDENTITY" ${MACOS_SIGN_IDENTITY:+--timestamp} "$CLI"
tar -C "$(dirname "$CLI")" -czf "$OUT/esemnbun-$VERSION-macos-universal.tar.gz" esemnbun

rm -rf "$DD"
echo "✔ $(ls "$OUT")"
