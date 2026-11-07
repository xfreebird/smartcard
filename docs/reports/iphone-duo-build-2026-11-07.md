# iPhone Duo SDK delivery gate — 2026-11-07

The iOS packaging paths now require iOS 27.1 or later SDKs before signing setup, credential reads or artifact cleanup. This prevents a successful SDK 26 compatibility build from silently being delivered as a native iPhone Duo build. It does not raise the app's minimum supported iOS deployment version.

Apple states that SDK 26 builds use compatibility layouts, SDK 27 builds fill most of the inner display, and SDK 27.1+ builds use the full display and native vertical toolbars/tab bars. This is a build-SDK requirement, not something that can be established by running an older-SDK binary on a new simulator. [Apple: Prepare for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/).

## Implemented

- `apple/scripts/require-ios-sdk.sh`: metadata-only check of both `iphoneos` and `iphonesimulator`, minimum 27.1, clear failure for older/unreadable SDK versions. Honors existing `DEVELOPER_DIR` or selected Xcode; never changes global `xcode-select`.
- `scripts/package-ios.sh`: invokes the gate before removing `dist/ios`, creating output directories, or archiving.
- `fastlane/Fastfile` `ios_release`: invokes the gate before `setup_ci`, API-key loading and match. Signing identifiers, export profiles and upload behavior remain unchanged.
- `.github/workflows/release.yml`: only the iOS job uses `xcode-27` and `/Applications/Xcode_27.1.app/Contents/Developer`, with explicit preflight before Ruby/signing preparation.
- `.github/workflows/apple-testflight.yml`: matrix chooses `xcode-27` for iOS and preserves `macos-26` for macOS. Only the requested iOS branch persists the selected `DEVELOPER_DIR` after its preflight succeeds.
- `.github/workflows/ci.yml`: dedicated unsigned Release simulator build for iOS/share extension on that SDK, replacing the iOS step in the old combined Apple job. Existing macOS app/Store/CLI commands and runner remain unchanged.

The runner label was verified against GitHub's official available-images table: `xcode-27` is the arm64 label. Its image inventory lists Xcode 27.1 at `/Applications/Xcode_27.1.app`, SDKs `iphoneos27.1` and `iphonesimulator27.1`, and an iPhone Duo simulator. The image is advertised as public preview, so hosted runner availability still requires an actual CI run; no runner dispatch was performed. [Runner registry](https://github.com/actions/runner-images), [Xcode 27 image inventory](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md).

## Checks performed

- `bash -n` passed for preflight and packaging scripts.
- `ruby -c fastlane/Fastfile` passed.
- Ruby YAML parsing passed for all three edited workflows; this checks YAML syntax, not GitHub's complete expression/action schema. `actionlint` was unavailable.
- `git diff --check` passed.
- Local `/Applications/Xcode-26.6.0.app/Contents/Developer` was rejected with exit 1 and selected device SDK 26.5 in the error. This is the SDK actually returned by that local toolchain, despite the Xcode application version/name.
- Local `/Applications/Xcode-27.1-rc.app/Contents/Developer` passed with device and simulator SDK 27.1. Metadata reads emitted sandbox FSEvents warnings but returned the expected versions and exit status.

No archive, match, credential mutation, upload, push or hosted workflow dispatch was performed in these checks. Simulator UI/build validation is recorded separately by the iOS review. Local RC SDK acceptance does not establish that a particular RC archive is accepted by App Store Connect.

Local use, without changing the machine's default Xcode:

```sh
DEVELOPER_DIR=/Applications/Xcode-27.1-rc.app/Contents/Developer \
  bash apple/scripts/require-ios-sdk.sh
```

For an authorized release, pass the same environment to the packaging script or `bundle exec fastlane ios_release`. The CI paths intentionally pin the documented stable 27.1 application path rather than selecting an RC by accident. If GitHub later removes that path, preflight fails clearly instead of silently falling back to an older SDK.

A subsequent local unsigned Release simulator build of the final iOS source passed with SDK 27.1, matching the CI build configuration. Log: `/tmp/esemnbun-duo-2026-11-07/release-build27.log`. The bundle retains minimum OS 17.0 and single-scene configuration. Hosted runner execution, device signing and upload remain untested.
