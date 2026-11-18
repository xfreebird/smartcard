#!/bin/bash
set -euo pipefail
helper_dir="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers"
agent_dir="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Library/LaunchAgents"
mkdir -p "$helper_dir" "$agent_dir"
parts=()
swift_inputs=("$SRCROOT/Helpers/ReaderWatcher/main.swift" "$SRCROOT/Helpers/ReaderWatcher/InsertionPolicy.swift")
entitlements="$SRCROOT/Helpers/ReaderWatcher/ReaderWatcher.entitlements"
label="md.esemnbun.reader-watcher"
other_label="md.esemnbun.mac.reader-watcher"
sign_options=(--options runtime)
if [[ " ${SWIFT_ACTIVE_COMPILATION_CONDITIONS:-} " == *" APP_STORE "* ]]; then
  other_label="$label"
  label="md.esemnbun.mac.reader-watcher"
  sign_options+=(--identifier "$label")
  # launchd starts this executable independently. Give it its own sandbox identity.
  info="$SRCROOT/Helpers/ReaderWatcher/StoreInfo.plist"
  swift_inputs+=(-D APP_STORE -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker "$info")
  entitlements="$TEMP_DIR/ReaderWatcher-Store.entitlements"
  cp "$SRCROOT/Helpers/ReaderWatcher/ReaderWatcher.entitlements" "$entitlements"
  /usr/libexec/PlistBuddy -c 'Add :com.apple.security.app-sandbox bool true' "$entitlements"
  /usr/libexec/PlistBuddy -c 'Add :com.apple.security.application-groups array' "$entitlements"
  /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string ${DEVELOPMENT_TEAM}.md.esemnbun.reader-watcher" "$entitlements"
fi
if [[ "$CONFIGURATION" == Debug ]]; then swift_inputs+=(-D DEBUG); fi
for watcher_arch in $ARCHS; do
  part="$TEMP_DIR/esemnbun-reader-watcher-$watcher_arch"
  xcrun swiftc "${swift_inputs[@]}" -O -sdk "$SDKROOT" \
    -target "$watcher_arch-apple-macos14.0" -o "$part"
  parts+=("$part")
done
xcrun lipo -create "${parts[@]}" -output "$helper_dir/esemnbun-reader-watcher"
rm -f "$agent_dir/$other_label.plist"
cp "$SRCROOT/Helpers/ReaderWatcher/md.esemnbun.reader-watcher.plist" "$agent_dir/$label.plist"
/usr/libexec/PlistBuddy -c "Set :Label $label" "$agent_dir/$label.plist"
if [[ "${CODE_SIGNING_ALLOWED:-NO}" == YES ]]; then
  codesign --force "${sign_options[@]}" --entitlements "$entitlements" --sign "${EXPANDED_CODE_SIGN_IDENTITY:--}" "$helper_dir/esemnbun-reader-watcher"
fi
