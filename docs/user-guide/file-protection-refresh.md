# File-protection documentation refresh

This checklist covers the 10 November 2026 password-only native-app revision. It is an internal capture runbook, not public how-to text.

## Required captures

Capture native English, Romanian and Russian interfaces for Mac, iPhone, iPad, Android phone, Android tablet, Windows and Linux. Use the updated Debug builds with isolated capture preferences and no demo banner. Keep the prior screenshot files until replacements have been inspected; do not present their old method selector as the current interface.

For each form capture:

1. The navigation/header menu entry, with Encrypt and Decrypt visible where the platform exposes them directly.
2. Password encryption with source filename and distinct Password / Confirm password inputs.
3. Password decryption with the encrypted filename and one password input.
4. Successful completion, with Done/Close rather than Cancel. Apple and Android automatically save the app-managed result; desktop Windows/Linux apps save through their native destination picker.
5. Saved documents containing an encrypted and a decrypted result, with the appropriate operation label. Ciphertext must not open automatic signature verification.
6. Desktop removal form only on Mac, Windows and Linux.

The retained CLI certificate examples describe compatibility commands; they explicitly state that the Moldovan ID card lacks the required encryption key. Native app guides must not link the old certificate/card screenshots.

## Capture inputs

Apple's repository runner accepts the following settings. Replace paths and device IDs with the current verified Debug artifacts and simulator inventory:

```sh
MSIGN_CAPTURE_THEMES=light MSIGN_CAPTURE_LANGUAGE=ro \
MSIGN_CAPTURE_TAB=documents \
MSIGN_CAPTURE_SCENARIOS='protect-password protect-decrypt' \
bash apple/scripts/capture-screenshots.sh ios "$IOS_DEBUG_APP" "$CAPTURE_DIR/iphone/ro" "$IPHONE_UDID"

MSIGN_CAPTURE_THEMES=light MSIGN_CAPTURE_LANGUAGE=ro \
MSIGN_CAPTURE_TAB=activity \
MSIGN_CAPTURE_SCENARIOS='protect-password protect-decrypt protect-remove' \
bash apple/scripts/capture-screenshots.sh macos "$MAC_DEBUG_APP" "$CAPTURE_DIR/macos/ro"
```

Repeat for `en`, `ro`, `ru`, and a separately rendered iPad. The current task's Apple artifacts are under `/tmp/protection-ios-derived` and `/tmp/protection-macos-derived`; capture destination is `.local/protection-0310/{macos,iphone,ipad}/{en,ro,ru}`. Verify these paths before reuse.

Android capture launches use `--es demo documents --es demo_page activity --ez store_capture true --es capture_dialog protect-password` (or `protect-decrypt`). Set each native locale with `adb -s "$ANDROID_SERIAL" shell cmd locale set-app-locales md.esemnbun.app --locales ro`. Wait for the Debug readiness marker before capturing. Use the actual display ID returned by the target emulator; never assume a display ID from an older run. Restore display overrides and theme after phone/tablet captures. The repository's `scripts/docs/capture-android-guide.py` contains locale and dimensions provenance handling.

Linux capture uses `MSIGN_DEMO_CARDS=1 MSIGN_SCREENSHOT_CAPTURE=1 MSIGN_DEMO_PAGE=activity MSIGN_CAPTURE_DIALOG=protect-password MSIGN_DEMO_DARK=0 MSIGN_DEMO_LANGUAGE=ro`, launched in the guest's graphical user session. Windows uses the same scenario/page flags and isolated `MSIGN_TEST_PREFERENCES` with `Language=en-US|ro-RO|ru-RU`. Use the capture tooling in the VM/UI-validation skills for native screenshots. Verify the executable path and hash rather than capturing an older foreground installation.

## Import and annotate

Store approved images at `website/static/img/guide/<asset-platform>/<locale>/`. Asset platform names are `macos`, `iphone`, `ipad`, `android-phone`, `android-tablet`, `windows`, `linux`.

Use `GuideScreenshot` with a numbered accessible step list. Coordinates are target heights/side hints; the component packs all badges and pointer lines into reserved gutters outside the application image. Do not burn numbers into PNGs. Inspect the rendered normal and enlarged panels: no annotation pixel may cover text, fields, icons or controls. Add separate panels for menu, completion and Documents states; do not point at controls that are absent from a form screenshot.

Update `file-protection-evidence.json` after importing actual images. Record native locale, source artifact identity, scenario, capture date, dimensions and SHA-256 per asset. Keep fixture captures distinct from a real password round trip. Do not claim physical-card testing.

## Regenerate and validate

```sh
python3 scripts/docs/organize-user-guides.py
python3 scripts/docs/organize-user-guides.py --check
python3 scripts/docs/validate-user-guides.py
cd website
node --test tests/guideNavigation.test.mjs tests/guideCallouts.test.mjs
```

Build all website locales and inspect representative narrow/desktop views before publication. Update panel-count assertions and the README when new menu/completion panels are added.
