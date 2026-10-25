# 11 — Build, Test, Package, Sign

Per-platform commands, what each package script produces, and how signing is wired. Outputs go to
`dist/` (git-ignored). Signing material is **never** in the repo: scripts read it from the environment.
Plan items: MAC-15, IOS-10, AND-10, WIN-08, CLI-04, LNX-07, LNX-13.

| Platform | Build / test | Package | Output (`dist/…`) | Signing inputs |
|---|---|---|---|---|
| Swift core + CLI (macOS) | `cd swift/MoldSignKit && swift test` (`MSIGN_NETWORK_TESTS=1` for live PKI) | part of `scripts/package-macos.sh` | `macos/esemnbun-<ver>-macos-universal.tar.gz` | `MACOS_SIGN_IDENTITY` |
| Swift core, Linux code paths (on macOS) | `scripts/test-portable-macos.sh` (OpenSSL + POSIX sockets; needs `brew install openssl@3`) | — | — | — |
| macOS app | `xcodebuild -project apple/eSemnBun.xcodeproj -scheme eSemnBun-macOS build` | `bundle exec fastlane mac_signing` then `scripts/package-macos.sh` | `macos/eSemnBun-<ver>.dmg` (notarized + stapled), `eSemnBun.xcarchive` | `MACOS_SIGN_IDENTITY` (`Developer ID Application`), `MACOS_TEAM_ID`, notarization: `ASC_KEY_ID` + `ASC_ISSUER_ID` + `ASC_KEY_PATH`/`ASC_KEY_P8`, or `NOTARY_PROFILE` |
| iOS app | `xcodebuild … -scheme eSemnBun-iOS -destination 'generic/platform=iOS Simulator' build` | `bundle exec fastlane ios_ipa` (match App Store profile); unsigned: `scripts/package-ios.sh` | `ios/eSemnBun-<ver>.ipa` (App Store signed), `eSemnBun-iOS.xcarchive` | `ASC_*`, `MATCH_PASSWORD`, `BUILD_NUMBER` (fastlane/SIGNING.md) |
| Android | `cd android && ./gradlew :core:test :transport-usb:testDebugUnitTest :app:assembleDebug` | `scripts/package-android.sh` | `android/eSemnBun-<ver>*.apk`, `*.aab` | `ANDROID_KEYSTORE`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` |
| Windows (core + CLI) | `cd windows && dotnet test MoldSign.Portable.slnf` (works on macOS/Linux) | part of `windows/scripts/package-windows.ps1` **on Windows** (Native AOT) | `bin\esemnbun.exe` inside the installers | Authenticode (WIN-08) |
| Windows app + installers | Visual Studio / `dotnet build src/MoldSign.App` **on Windows** | `windows/scripts/package-windows.ps1` (CI job `windows`; `-SelfSignForTesting` for local MSIX installs) | `eSemnBun-<ver>-x64.msi` (WiX v5, per machine, `Program Files\eSemnBun`, `bin\` on PATH, optional start at sign-in), `eSemnBun-<ver>-x64.msix` (startup task), `winget/<ver>/eSemnBun.eSemnBun*.yaml`, `SHA256SUMS.txt` | certificate thumbprint or Azure Trusted Signing via env vars; unsigned otherwise (an unsigned MSIX won't install) |
| Linux CLI + GNOME app | see `linux/README.md` (Swift 6 toolchain + `libadwaita-1-dev libsecret-1-dev libpcsclite-dev libssl-dev`) | `scripts/package-linux.sh` (skips formats whose tools are missing; CI job `linux`) | `esemnbun_<ver>-1_<arch>.deb` + `esemnbun-cli_…deb`, `esemnbun-<ver>-1.<arch>.rpm` + `esemnbun-cli-…rpm`, `eSemnBun-<ver>.flatpak`, `esemnbun-<ver>-linux-<arch>.tar.gz` | Flathub / GPG for repos |

## Release workflow (`.github/workflows/release.yml`)

Tag `v*` (e.g. `git tag v0.2.0 && git push origin v0.2.0`) → one job per platform, then a GitHub Release with every
file and a `SHA256SUMS.txt`. "Run workflow" on the Actions tab builds the same artifacts without a release.

| Job | Runner | Produces | Signed with |
|---|---|---|---|
| `macos` | macos-26 | `eSemnBun-<ver>.dmg`, `esemnbun-<ver>-macos-universal.tar.gz` | Developer ID Application (match), notarized with the API key; DMG stapled |
| `ios` | macos-26 | `eSemnBun-<ver>.ipa` | Apple Distribution + `match AppStore md.esemnbun.ios` |
| `android` | ubuntu-24.04 | `eSemnBun-<ver>.apk`, `.aab` | upload key (`ANDROID_KEYSTORE_BASE64`) |
| `linux` | `swift:6.2-noble` container | CLI tarball, `.deb` × 2, `.rpm` × 2 | unsigned (repository signing later) |
| `flatpak` | ubuntu-24.04 | `eSemnBun-<ver>.flatpak` | unsigned bundle |
| `windows` | windows-latest | `.msi`, `.msix`, winget manifests | optional (Azure Trusted Signing / thumbprint); unsigned by default |

## Signing secrets

| Where | What |
|---|---|
| GitHub → Settings → Secrets → Actions | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `APPLE_TEAM_ID`, `MATCH_PASSWORD`, `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` |
| `github.com/xfreebird/fastlanecerts` (match storage, public, encrypted) | Apple Distribution + Apple Development certificates and profiles for `md.esemnbun.ios`; Developer ID Application once imported |
| The owner's offline copy (outside git; README inside it) | every value above, the `.p8`, the Android upload keystore, the exported Apple identities, the Developer ID key + CSR |

Apple team `H86U5Z8HYB` (personal account), bundle IDs `md.esemnbun.ios` / `md.esemnbun.mac` (CLI identifier
`md.esemnbun.cli`), Android application ID `md.esemnbun.app`. Linux and Windows identifiers keep the codename.
Losing the Android upload key is recoverable through Play App Signing (key reset); losing `MATCH_PASSWORD` means
re-creating the Apple certificates (`fastlane nuke_all` + `certs`).

## macOS signing + notarization recipe (local)

```bash
bundle exec fastlane mac_signing                    # Developer ID identity from match into the keychain
export MACOS_SIGN_IDENTITY="Developer ID Application" MACOS_TEAM_ID=H86U5Z8HYB
export ASC_KEY_ID=… ASC_ISSUER_ID=… ASC_KEY_PATH=…/AuthKey_….p8     # or NOTARY_PROFILE=<notarytool profile>
scripts/package-macos.sh                            # signs, notarizes (DMG + CLI), staples the DMG
spctl -a -vv -t install dist/macos/eSemnBun-*.dmg   # → "accepted, source=Notarized Developer ID"
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
