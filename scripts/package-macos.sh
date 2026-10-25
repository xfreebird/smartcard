#!/usr/bin/env bash
# Package the macOS menu-bar app (DMG) and the `esemnbun` CLI (tar.gz) into dist/macos/.  (MAC-15, CLI-04)
#
# Signing (all optional):
#   MACOS_SIGN_IDENTITY  "Developer ID Application" (or the full name)   default "-" (ad-hoc: runs on this Mac only)
#   MACOS_TEAM_ID        team for the identity
# Notarization (with a real identity), either:
#   NOTARY_PROFILE       `xcrun notarytool store-credentials` profile, or
#   ASC_KEY_ID + ASC_ISSUER_ID + ASC_KEY_PATH (file) | ASC_KEY_P8 (content): App Store Connect API key (CI)
# → the DMG is notarized and stapled, the CLI is notarized (a bare binary can't be stapled; Gatekeeper looks it up).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/macos"
DD="$ROOT/dist/.derived-macos"
IDENTITY="${MACOS_SIGN_IDENTITY:--}"
VERSION="$(xcodebuild -project "$ROOT/apple/eSemnBun.xcodeproj" -scheme eSemnBun-macOS -showBuildSettings 2>/dev/null | awk '/ MARKETING_VERSION =/{print $3; exit}')"
rm -rf "$OUT" && mkdir -p "$OUT"

notary=()
if [[ "$IDENTITY" != "-" && -n "${NOTARY_PROFILE:-}" ]]; then
  notary=(--keychain-profile "$NOTARY_PROFILE")
elif [[ "$IDENTITY" != "-" && -n "${ASC_KEY_ID:-}" && ( -n "${ASC_KEY_PATH:-}" || -n "${ASC_KEY_P8:-}" ) ]]; then
  KEY_FILE="${ASC_KEY_PATH:-}"
  if [[ -z "$KEY_FILE" ]]; then
    KEY_FILE="$(mktemp -d)/AuthKey_$ASC_KEY_ID.p8"
    printf '%s\n' "$ASC_KEY_P8" > "$KEY_FILE"
    trap 'rm -rf "$(dirname "$KEY_FILE")"' EXIT
  fi
  notary=(--key "$KEY_FILE" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID")
fi

# codesign with a secure timestamp: Apple's timestamp server occasionally doesn't answer, so retry
sign_ts() {
  local attempt
  for attempt in 1 2 3; do
    codesign "$@" && return 0
    echo "  timestamp server didn't answer (attempt $attempt), retrying" >&2
    sleep 5
  done
  return 1
}

# notarize <file>: submit, wait, fail unless Apple accepts it (prints the log on rejection)
notarize() {
  local result id status
  result="$(xcrun notarytool submit "$1" "${notary[@]}" --wait --timeout 45m --output-format json)"
  id="$(/usr/bin/plutil -extract id raw - <<<"$result")"
  status="$(/usr/bin/plutil -extract status raw - <<<"$result")"
  echo "  $(basename "$1"): $status ($id)"
  if [[ "$status" != "Accepted" ]]; then
    xcrun notarytool log "$id" "${notary[@]}" || true
    exit 1
  fi
}

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
[[ "$IDENTITY" != "-" ]] && sign_ts --sign "$IDENTITY" --timestamp "$OUT/eSemnBun-$VERSION.dmg"

if (( ${#notary[@]} )); then
  echo "▸ Notarizing the DMG"
  notarize "$OUT/eSemnBun-$VERSION.dmg"
  xcrun stapler staple -q "$OUT/eSemnBun-$VERSION.dmg"
fi

echo "▸ Building the esemnbun CLI (release)"
(cd "$ROOT/swift/MoldSignKit" && swift build -c release --product esemnbun --arch arm64 --arch x86_64 >/dev/null)
CLI="$(cd "$ROOT/swift/MoldSignKit" && swift build -c release --product esemnbun --arch arm64 --arch x86_64 --show-bin-path)/esemnbun"
sign_ts --force --options runtime --identifier md.esemnbun.cli --sign "$IDENTITY" ${MACOS_SIGN_IDENTITY:+--timestamp} "$CLI"
if (( ${#notary[@]} )); then
  echo "▸ Notarizing the CLI"
  (cd "$(dirname "$CLI")" && /usr/bin/ditto -c -k esemnbun "$OUT/esemnbun-notarize.zip")
  notarize "$OUT/esemnbun-notarize.zip"
  rm -f "$OUT/esemnbun-notarize.zip"
fi
tar -C "$(dirname "$CLI")" -czf "$OUT/esemnbun-$VERSION-macos-universal.tar.gz" esemnbun

rm -rf "$DD"
echo "✔ $(ls "$OUT")"
