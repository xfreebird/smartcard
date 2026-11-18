---
title: Build and run
description: Set up an authorized checkout and compile the Swift, Android, Windows and Linux applications with their native toolchains.
---

Choose the platform you intend to change. You do not need every SDK or a physical card to contribute. Core tests and Debug fixtures cover much of the project without personal identity data.

## Prepare your checkout

Obtain repository access, clone your authorized remote and read `AGENTS.md`, `docs/13-developer-onboarding.md` and the relevant platform README. Keep machine-specific paths in ignored local configuration. The template `docs/developer-environment.example.json` can be copied to `.local/developer-environment.json`; record host aliases, SDKs and device IDs, never credentials.

The browser bridge's vendor TLS identity is an external setup input. Obtain it through an authorized maintainer handoff when needed. A random replacement certificate does not establish compatibility with `localhost.cts.md`. Do not publish the bundle or its password.

| Target | Toolchain / source of truth |
| --- | --- |
| Swift core | Swift tools version in `swift/MoldSignKit/Package.swift`; Apple toolchain on macOS, supported Swift Linux toolchain on Linux |
| Apple apps | Xcode project `apple/eSemnBun.xcodeproj`; `apple/scripts/require-siri-sdk.sh` checks the SDK requirement used by workflows |
| Android | JDK 17, Android SDK, checked-in Gradle wrapper; versions in `android/gradle/libs.versions.toml` |
| Windows | Windows for WinUI; .NET SDK selected by `windows/global.json`, Windows SDK / C++ tools per `windows/README.md` |
| Linux desktop | Swift, GTK4/libadwaita, Poppler, libsecret, pcsc-lite and OpenSSL development packages |
| Website | Node 22 as used by Website CI, npm lockfile and Python 3.12+ for generation scripts |

Build-tool versions and app minimum OS versions are different. Check the target's **Release** deployment settings and packaged metadata before changing supported-OS claims. A Swift package's minimum alone does not determine the shipped app's minimum.

## Swift core and CLI — macOS or Linux

```sh
cd swift/MoldSignKit
swift build --product esemnbun
.build/debug/esemnbun --help
```

On Linux, install pcsc-lite and OpenSSL development headers first. `MOLDSIGN_PORTABLE` selects the Linux-compatible backend automatically. On Apple, the core uses platform crypto/PCSC through the C shim.

Once you deliberately want to inspect attached hardware, `esemnbun readers` enumerates it and `esemnbun cert --out leaf.der` reads a public certificate. Certificate reading performs a card session even though it does not verify the PIN. Keep personal certificate output private. See [testing](testing.md) for the hardware-free path.

## macOS native application

From the repository root:

```sh
bash apple/scripts/require-siri-sdk.sh
xcodebuild -project apple/eSemnBun.xcodeproj \
  -scheme eSemnBun-macOS -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath dist/dev-macos build
open dist/dev-macos/Build/Products/Debug/eSemnBun.app
```

Use your authorized development signing setup. Keep the smart-card entitlement and the nested helper's entitlements; an ad-hoc launch without them may compile yet fail reader discovery. Close an older running copy before checking your new app, and verify the launched path. The sandboxed `eSemnBun-macOS-AppStore` scheme is a separate distribution configuration.

The Mac App Store app uses CryptoTokenKit to detect compatible USB readers and cards. Its local bridge supports both the built-in Browser and compatible external browsers while the app runs. The Store sandbox restricts filesystem-path requests and output locations; it does not make the bridge exclusive to the built-in Browser. The separate reader-insertion helper that relaunches a fully quit app and the local-automation approval broker belong to the standalone edition.

For fictional card UI, launch the Debug binary directly with its demo environment:

```sh
MSIGN_DEMO_CARDS=2 \
  dist/dev-macos/Build/Products/Debug/eSemnBun.app/Contents/MacOS/eSemnBun
```

Use a dedicated test profile for preferences and history. Demo UI is not proof of real-card access.

## iPhone and iPad simulator

```sh
xcrun simctl list devices available
xcodebuild -project apple/eSemnBun.xcodeproj \
  -scheme eSemnBun-iOS -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath dist/dev-ios CODE_SIGNING_ALLOWED=NO build
```

Choose an available simulator UUID, boot it if necessary, then install and launch:

```sh
# Replace SIMULATOR_UUID with the selected test device's UUID.
xcrun simctl bootstatus SIMULATOR_UUID -b
xcrun simctl install SIMULATOR_UUID \
  dist/dev-ios/Build/Products/Debug-iphonesimulator/eSemnBun.app
xcrun simctl launch SIMULATOR_UUID md.esemnbun.ios
```

Use the [UI automation runner](testing.md) for deterministic fictional cards and isolated fixtures. A simulator build covers interface flow. Test USB adapters and CryptoTokenKit on a supported physical device with a reader. NFC testing requires a supported physical iPhone and a profile for `md.esemnbun.ios` with the NFC Tag Reading (`TAG`) entitlement. The app declares its ISO 7816 application identifiers in Info.plist and localizes `NFCReaderUsageDescription`. Keep the existing App Groups when refreshing signing profiles.

## Android

Create ignored `android/local.properties` with your SDK path (`sdk.dir=...`). Use JDK 17 or the configured Gradle daemon toolchain. From the repository root:

```sh
cd android
./gradlew :app:assembleDebug
adb devices -l
```

Choose an emulator/device serial explicitly:

```sh
adb -s EMULATOR_SERIAL install -r app/build/outputs/apk/debug/app-debug.apk
adb -s EMULATOR_SERIAL shell am start \
  -n md.esemnbun.app/md.moldsign.app.MainActivity --es demo cards
```

The installed application ID is `md.esemnbun.app`; the Kotlin activity namespace retains `md.moldsign.app`. The demo extra is Debug-only. USB signing requires a physical USB host device, a supported reader and USB permission. NFC signing requires a physical device that supports ISO-DEP. NFC is optional in the app manifest so devices without it can use a reader. For isolated hardware testing, build `:app:assembleDebug` with `-PnfcTestInstall=true`. It installs as `md.esemnbun.app.nfctest` and uses separate app and PIN storage.

## Windows

Portable core tests/CLI compilation can run on other hosts, but WinUI, installer and real WinSCard validation require Windows. In PowerShell on Windows:

```powershell
Set-Location windows
dotnet build MoldSign.slnx -c Debug -p:Platform=x64
dotnet run --project src/MoldSign.App -p:Platform=x64
```

Use the architecture supported by the project/toolchain and record it. Running an x64 app under Windows ARM64 emulation is different from native ARM64 coverage. Distribution packaging is described in [releasing](releasing.md).

For the portable CLI entry point:

```sh
cd windows
dotnet run --project src/MoldSign.Cli -- --help
```

A non-Windows host can run portable logic but cannot exercise the WinSCard adapter. The GUI and CLI must remain in separate output locations because `eSemnBun.exe` and `esemnbun.exe` collide on case-insensitive filesystems.

## Linux desktop

Install Swift separately using the toolchain appropriate for your distribution. For native libraries on Ubuntu/Debian:

```sh
sudo apt install libpoppler-glib-dev libadwaita-1-dev libsecret-1-dev \
  libpcsclite-dev libssl-dev pkg-config pcscd libccid
```

Then, from the repository root:

```sh
cd linux
swift build
MSIGN_DEMO_CARDS=2 .build/debug/esemnbun-gnome
```

Run inside a graphical desktop session with its session bus. For real hardware, ensure `pcscd` is available and the session has access. SSH shell access alone does not establish graphical or smart-card permission. `linux/README.md` contains Fedora package equivalents and packaging instructions.

GTK can also be built on macOS for layout development, but it does not reproduce Linux Secret Service, portals, desktop integration or distribution libraries. A VM used for hardware validation must own the passed-through reader; restore its previous owner after the session.

## Next steps

Run the checks relevant to your change using [Testing and automation](testing.md). Keep development builds distinct from signed release artifacts, and report the executable path, configuration, source revision and actual target used.
