# 11 — Build, Test, Package, Sign

Per-platform commands, what each package script produces, and how signing is wired. Outputs go to
`dist/` (git-ignored). Signing material is **never** in the repo: scripts read it from the environment.
Plan items: MAC-15, IOS-10, AND-10, WIN-08, CLI-04, LNX-07, LNX-13.

| Platform | Build / test | Package | Output (`dist/…`) | Signing inputs |
|---|---|---|---|---|
| Swift core + CLI (macOS) | `cd swift/MoldSignKit && swift test` (`MSIGN_NETWORK_TESTS=1` for live PKI) | part of `scripts/package-macos.sh` | `macos/moldsign-<ver>-macos-universal.tar.gz` | `MACOS_SIGN_IDENTITY` |
| Swift core, Linux code paths (on macOS) | `scripts/test-portable-macos.sh` (OpenSSL + POSIX sockets; needs `brew install openssl@3`) | — | — | — |
| macOS app | `xcodebuild -project apple/MoldSign.xcodeproj -scheme MoldSign-macOS build` | `scripts/package-macos.sh` | `macos/MoldSign-<ver>.dmg`, `MoldSign.xcarchive` | `MACOS_SIGN_IDENTITY` (Developer ID Application), `MACOS_TEAM_ID`, `NOTARY_PROFILE` (`xcrun notarytool store-credentials`) |
| iOS app | `xcodebuild … -scheme MoldSign-iOS -destination 'generic/platform=iOS Simulator' build` | `scripts/package-ios.sh` | `ios/MoldSign-iOS.xcarchive` + `MoldSign-unsigned.ipa`, or a signed IPA | `IOS_TEAM_ID`, `IOS_EXPORT_METHOD` (`development` · `release-testing` · `app-store-connect`) |
| Android | `cd android && ./gradlew :core:test :transport-usb:testDebugUnitTest :app:assembleDebug` | `scripts/package-android.sh` | `android/moldsign-release*.apk`, `*.aab` | `ANDROID_KEYSTORE`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` |
| Windows (core + CLI) | `cd windows && dotnet test MoldSign.Portable.slnf` (works on macOS/Linux) | `dotnet publish src/MoldSign.Cli -c Release -r win-x64 -p:PublishAot=true` **on Windows** | `moldsign.exe` | Authenticode (WIN-08) |
| Windows app | Visual Studio / `dotnet build src/MoldSign.App` **on Windows** | MSIX (WIN-08) | — | — |
| Linux CLI + GNOME app | see `linux/README.md` (Swift 6 toolchain + `libadwaita-1-dev libsecret-1-dev libpcsclite-dev libssl-dev`) | Flatpak `linux/flatpak/md.moldsign.MoldSign.yml`; static-stdlib tarball (LNX-07) | — | Flathub / GPG for repos |

## What has been packaged so far (2026-10-25)

| Artifact | Signed with | Runs where |
|---|---|---|
| `MoldSign-0.1.0.dmg` (universal) | ad-hoc (`-`) | this Mac. Other Macs: Gatekeeper blocks it until Developer ID signing + notarization |
| `moldsign-0.1.0-macos-universal.tar.gz` | ad-hoc, hardened runtime | this Mac; elsewhere after `xattr -d com.apple.quarantine` |
| `MoldSign-unsigned.ipa` + `.xcarchive` | none | nowhere until re-signed (`IOS_TEAM_ID`) |
| `moldsign-release-debugsigned.apk` | Android **debug** key | any device with sideloading; not for the Play Store |
| `moldsign-release-unsigned.aab` | none | Play upload after signing with the upload key |

### Why no real signing yet

The Mac has Apple signing identities, but they belong to an **employer team**. Signing a personal
project with them is a decision for the owner, not for a build script. The scripts take a
team/identity/keystore from the environment, so release signing is one variable away once the
project has its own Apple Developer account and Android upload key (D-05, AND-10).

## macOS signing + notarization recipe

```bash
export MACOS_SIGN_IDENTITY="Developer ID Application: <Name> (<TEAMID>)"
export MACOS_TEAM_ID=<TEAMID>
xcrun notarytool store-credentials moldsign-notary --apple-id <id> --team-id <TEAMID>   # once
NOTARY_PROFILE=moldsign-notary scripts/package-macos.sh
spctl -a -vv -t install dist/macos/MoldSign-*.dmg        # → "accepted, source=Notarized Developer ID"
```

The app needs the hardened runtime (on) and the `com.apple.security.smartcard` entitlement (set in
`apple/Apps/macOS/MoldSign.entitlements`). Sandbox stays off until D-04 is decided.

## Notes

* **iOS export methods** need matching provisioning; `-allowProvisioningUpdates` lets Xcode create
  development/ad-hoc profiles for a team the logged-in Apple ID belongs to.
* **Android release** currently ships without R8 shrinking (14 MB APK). Enabling `isMinifyEnabled`
  needs keep rules for the Compose/Keystore code paths (AND-10).
* **Windows Native AOT** cannot cross-compile: build `win-x64` / `win-arm64` on Windows (or CI). A
  non-AOT single-file exe can be produced anywhere with `--self-contained -p:PublishSingleFile=true`.
* **Linux**: build on Linux (or CI in the `swift:6.x` image). On macOS, `scripts/test-portable-macos.sh`
  exercises the Linux code paths: OpenSSL AES/CMAC/SHA/RSA, POSIX HTTP client, POSIX + OpenSSL TLS bridge.
