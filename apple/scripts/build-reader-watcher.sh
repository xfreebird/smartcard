#!/bin/bash
set -euo pipefail
helper_dir="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers"
agent_dir="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Library/LaunchAgents"
# Remove stale direct-distribution outputs when reusing a build folder for the App Store configuration.
case " ${SWIFT_ACTIVE_COMPILATION_CONDITIONS:-} " in
  *" APP_STORE "*)
    rm -f "$helper_dir/esemnbun-reader-watcher" "$agent_dir/md.esemnbun.reader-watcher.plist"
    exit 0 ;;
esac
mkdir -p "$helper_dir" "$agent_dir"
parts=()
swift_inputs=("$SRCROOT/Helpers/ReaderWatcher/main.swift" "$SRCROOT/Helpers/ReaderWatcher/InsertionPolicy.swift")
if [[ "$CONFIGURATION" == Debug ]]; then swift_inputs+=(-D DEBUG); fi
for watcher_arch in $ARCHS; do
  part="$TEMP_DIR/esemnbun-reader-watcher-$watcher_arch"
  xcrun swiftc "${swift_inputs[@]}" -O -sdk "$SDKROOT" \
    -target "$watcher_arch-apple-macos14.0" -o "$part"
  parts+=("$part")
done
xcrun lipo -create "${parts[@]}" -output "$helper_dir/esemnbun-reader-watcher"
cp "$SRCROOT/Helpers/ReaderWatcher/md.esemnbun.reader-watcher.plist" "$agent_dir/"
if [[ "${CODE_SIGNING_ALLOWED:-NO}" == YES ]]; then
  codesign --force --options runtime --entitlements "$SRCROOT/Helpers/ReaderWatcher/ReaderWatcher.entitlements" --sign "${EXPANDED_CODE_SIGN_IDENTITY:--}" "$helper_dir/esemnbun-reader-watcher"
fi
