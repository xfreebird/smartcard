#!/usr/bin/env bash
# Build release APK + AAB into dist/android/ as eSemnBun-<version>.apk / .aab  (AND-10, UX-12)
# (public name eSemnBun; the codename / applicationId md.moldsign.app stays in the code).
#
# Signing (optional, all four together) — the upload key never goes into the repo:
#   ANDROID_KEYSTORE  ANDROID_KEYSTORE_PASSWORD  ANDROID_KEY_ALIAS  ANDROID_KEY_PASSWORD
# Without them the APK is signed with the local debug keystore (sideload testing only) and the AAB is unsigned;
# those two keep a -debugsigned / -unsigned suffix so they are never mistaken for release artifacts.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/android"
python3 "$ROOT/scripts/ci/android_build_policy.py" --verify-wrapper
rm -rf "$OUT" && mkdir -p "$OUT"
cd "$ROOT/android"
VER="$(sed -n 's/^ *versionName *= *"\(.*\)".*/\1/p' app/build.gradle.kts | head -1)"
NAME="eSemnBun-${VER:?versionName not found in app/build.gradle.kts}"

echo "▸ Gradle release build"
"$ROOT/scripts/gradle-ci.sh" --quiet :app:assembleRelease :app:bundleRelease

APK_IN="$(ls app/build/outputs/apk/release/*.apk | head -1)"
AAB_IN="$(ls app/build/outputs/bundle/release/*.aab | head -1)"
# Fail before signing if the actual AAB lacks the selected AGP/R8 optimization.
python3 "$ROOT/scripts/ci/android_build_policy.py" --aab "$AAB_IN"
BT="$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/* | sort -V | tail -1)"

if [[ -n "${ANDROID_KEYSTORE:-}" ]]; then
  KS=(--ks "$ANDROID_KEYSTORE" --ks-pass "env:ANDROID_KEYSTORE_PASSWORD" --ks-key-alias "$ANDROID_KEY_ALIAS" --key-pass "env:ANDROID_KEY_PASSWORD")
  "$BT/zipalign" -f -p 4 "$APK_IN" "$OUT/$NAME-aligned.apk"
  "$BT/apksigner" sign "${KS[@]}" --out "$OUT/$NAME.apk" "$OUT/$NAME-aligned.apk"
  rm "$OUT/$NAME-aligned.apk"
  jarsigner -keystore "$ANDROID_KEYSTORE" -storepass:env ANDROID_KEYSTORE_PASSWORD -keypass:env ANDROID_KEY_PASSWORD \
    -signedjar "$OUT/$NAME.aab" "$AAB_IN" "$ANDROID_KEY_ALIAS" >/dev/null
else
  echo "▸ No release key: signing the APK with the debug keystore (testing only)"
  "$BT/zipalign" -f -p 4 "$APK_IN" "$OUT/$NAME-aligned.apk"
  "$BT/apksigner" sign --ks "$HOME/.android/debug.keystore" --ks-pass pass:android --ks-key-alias androiddebugkey \
    --key-pass pass:android --out "$OUT/$NAME-debugsigned.apk" "$OUT/$NAME-aligned.apk"
  rm "$OUT/$NAME-aligned.apk"
  cp "$AAB_IN" "$OUT/$NAME-unsigned.aab"
fi
# Retain retracing/build evidence with the exact signed AAB. Only APK/AAB files
# are public Release assets; optimization evidence remains in Actions artifacts.
mkdir -p "$OUT/optimization"
cp app/build/outputs/mapping/release/mapping.txt "$OUT/optimization/"
cp app/build/outputs/mapping/release/configuration.txt "$OUT/optimization/"
FINAL_AAB=("$OUT"/*.aab)
python3 "$ROOT/scripts/ci/android_build_policy.py" --aab "${FINAL_AAB[0]}" --report "$OUT/optimization/build-policy.json"
"$BT/apksigner" verify --print-certs "$OUT"/*.apk | head -3
echo "✔ $(ls "$OUT")"
