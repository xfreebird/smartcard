#!/usr/bin/env bash
# Build release APK + AAB into dist/android/.  (AND-10)
#
# Signing (optional, all four together) — the upload key never goes into the repo:
#   ANDROID_KEYSTORE  ANDROID_KEYSTORE_PASSWORD  ANDROID_KEY_ALIAS  ANDROID_KEY_PASSWORD
# Without them the APK is signed with the local debug keystore (sideload testing only) and the AAB is unsigned.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/android"
rm -rf "$OUT" && mkdir -p "$OUT"
cd "$ROOT/android"

echo "▸ Gradle release build"
./gradlew --quiet :app:assembleRelease :app:bundleRelease

APK_IN="$(ls app/build/outputs/apk/release/*.apk | head -1)"
AAB_IN="$(ls app/build/outputs/bundle/release/*.aab | head -1)"
BT="$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/* | sort -V | tail -1)"

if [[ -n "${ANDROID_KEYSTORE:-}" ]]; then
  KS=(--ks "$ANDROID_KEYSTORE" --ks-pass "env:ANDROID_KEYSTORE_PASSWORD" --ks-key-alias "$ANDROID_KEY_ALIAS" --key-pass "env:ANDROID_KEY_PASSWORD")
  "$BT/zipalign" -f -p 4 "$APK_IN" "$OUT/moldsign-release-aligned.apk"
  "$BT/apksigner" sign "${KS[@]}" --out "$OUT/moldsign-release.apk" "$OUT/moldsign-release-aligned.apk"
  rm "$OUT/moldsign-release-aligned.apk"
  jarsigner -keystore "$ANDROID_KEYSTORE" -storepass:env ANDROID_KEYSTORE_PASSWORD -keypass:env ANDROID_KEY_PASSWORD \
    -signedjar "$OUT/moldsign-release.aab" "$AAB_IN" "$ANDROID_KEY_ALIAS" >/dev/null
else
  echo "▸ No release key: signing the APK with the debug keystore (testing only)"
  "$BT/zipalign" -f -p 4 "$APK_IN" "$OUT/moldsign-release-aligned.apk"
  "$BT/apksigner" sign --ks "$HOME/.android/debug.keystore" --ks-pass pass:android --ks-key-alias androiddebugkey \
    --key-pass pass:android --out "$OUT/moldsign-release-debugsigned.apk" "$OUT/moldsign-release-aligned.apk"
  rm "$OUT/moldsign-release-aligned.apk"
  cp "$AAB_IN" "$OUT/moldsign-release-unsigned.aab"
fi
"$BT/apksigner" verify --print-certs "$OUT"/*.apk | head -3
echo "✔ $(ls "$OUT")"
