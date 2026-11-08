# Developer onboarding

Build and UI work does not require access to production publishing credentials or the owner's computers. Start with one local platform, use fictional cards and synthetic documents, and add remote targets only when the change needs them.

## Repository and architecture

Read [AGENTS.md](../AGENTS.md), [PLAN.md](../PLAN.md), [architecture](09-architecture.md) and the relevant platform README. The public product is **eSemnBun**; `MoldSign` remains in internal modules, protocol and storage identifiers. Don't rename those identifiers as a cosmetic cleanup.

| Code | Toolchain / role |
| --- | --- |
| `swift/MoldSignKit` | SwiftPM shared Apple/Linux core and CLI; C shims use CommonCrypto/PCSC on Apple, OpenSSL/pcsc-lite on Linux |
| `apple/` | Xcode app targets for macOS and iOS/iPadOS, shared SwiftUI UI, helper and share extension |
| `android/` | Gradle wrapper, Kotlin core, USB CCID transport and Compose app |
| `windows/` | .NET SDK selected by `global.json`, C# core/CLI, WinUI desktop app, insertion helper and installer |
| `linux/` | Swift + GTK4/libadwaita GNOME app |
| `spec/` | Shared cryptographic vectors, CLI contract and browser-origin allow-list |
| `website/` | Site, generated release-download data and desktop update feeds |

Read version requirements from `Package.swift`, Xcode project/configurations, Gradle files, `windows/global.json` and CI workflows. Use pinned toolchains rather than upgrading all SDKs during onboarding. Run `bundle install` for Ruby/fastlane tasks; use the Gradle wrapper and `npm ci` for the website.

The vendor localhost TLS identity is not in public source. Ask an authorized maintainer for the approved private runtime resource when testing the HTTPS browser bridge or producing app packages. Missing identity does not mean signing logic is broken. Do not publish the file, private card traces, credentials or user documents. The public CA certificates and golden vectors are different from that private runtime resource.

## Choose your machines and access

You may use native Windows/Linux, your own VMs, remote hosts or CI. The owner's MacBook Air/QEMU arrangement is an optional tested profile, not a requirement. Do not copy its IP addresses, users, ports or sudo assumptions into shared scripts.

1. Copy [developer-environment.example.json](developer-environment.example.json) to `.local/developer-environment.json` and replace the example values. The file is ignored; no passwords, PINs, tokens or private keys belong there.
2. Specify how each host is reached: local shell, SSH alias, jump host/forwarded port, or console-only. Put private SSH connection settings in your own `~/.ssh/config`; refer to aliases in the inventory. If SSH is unavailable, use your authorized hypervisor/RDP session or CI instead.
3. Record the guest OS, CPU architecture, repository path and toolchain. A Windows ARM64 guest running the x64 app under emulation is different from native x64 coverage.
4. Record interactive desktop access separately from shell access. Windows GUI launched from SSH may land in a noninteractive session. Linux UI needs the actual graphical session/DBus environment; don't assume `DISPLAY=:0` or a UID of 1000.
5. For iPhone/iPad targets, use `xcrun simctl list devices available`; for Android, use `adb devices -l` and your SDK's AVD inventory. Select explicit device IDs for install, launch, files and screenshots.
6. Assign the USB reader only when real-card coverage is necessary. Hypervisor passthrough can remove it from the host. Confirm ownership before testing and restore it afterward. No physical card is needed for most core/UI work.

A minimal SSH setup can look like this (replace all examples):

```sshconfig
Host esemnbun-linux
    HostName your-linux-host
    User your-linux-user
    IdentityFile ~/.ssh/your-development-key

Host esemnbun-windows
    HostName your-windows-host
    User your-windows-user
    # ProxyJump your-jump-host   # only if your topology requires it
```

Test read-only connectivity first. Sync source at a known commit, excluding build caches, secrets and private documents; preserve guest changes. Do not rebuild or reset existing VMs just to reproduce the owner's topology. The [VM skill](../.agents/skills/esemnbun-test-vms/SKILL.md) supplies owner-specific commands and recipes when that profile is actually in use.

## First build

Run commands from the repository root unless a subshell changes directory:

```bash
(cd swift/MoldSignKit && swift build && swift test)
(cd android && ./gradlew :core:test :app:assembleDebug)
(cd windows && dotnet test MoldSign.Portable.slnf)
xcodebuild -project apple/eSemnBun.xcodeproj -scheme eSemnBun-iOS \
  -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Choose the command for your host; these are not all expected to work on every OS. SwiftPM Apple tests need the Apple toolchain; the portable C# solution does not build the WinUI app. For Linux GTK dependencies/build and Windows native app/installer commands, use [Linux README](../linux/README.md), [Windows README](../windows/README.md) and [build/sign skill](../.agents/skills/esemnbun-build-sign/SKILL.md). The package scripts document their arguments at the top of each file.

For local macOS execution, compile with the target's signing configuration and smart-card entitlement. Confirm the executable being launched comes from that build, not a stale `/Applications` copy. Keep Store sandbox entitlements distinct from Developer ID entitlements. Simulator signing does not validate device provisioning or macOS smart-card access.

Tests should match the change: cryptographic vectors for port changes, simulated-card flows for signing/session changes, native builds for UI changes. `scripts/test-portable-macos.sh` exercises the Linux-like OpenSSL/POSIX code paths but not GTK UI. Network tests opt in; do not treat a skipped network test as a live PKI pass.

## UI, screenshots and documents

Read the [UI validation skill](../.agents/skills/esemnbun-ui-validation/SKILL.md). Demo scenarios are Debug-only and use fictional identities; capture scripts reject incompatible binaries. Use a dedicated test simulator/emulator and isolated preferences. The root `scripts/capture-screenshots.sh` routes to platform implementations; inspect their usage and select your target explicitly.

Validate phone and tablet layouts, light/dark themes and the relevant language. Inspect images after capture. Screenshot appearance does not prove signing, a connected physical reader, inter-app drag/drop or a reveal-in-file-manager action. Exercise those interactions separately and record what remains untested.

Use synthetic sample PDFs/XML. For iOS, locate the chosen app's data container with `simctl get_app_container UDID md.esemnbun.ios data` and place files in its Documents folder. For Android, push to the chosen device's Downloads folder. Then confirm actual file-picker/Files visibility. Do not copy a contributor's entire Downloads folder without an explicit request.

The iOS/iPadOS browser bridge serves only while the app is active; browser connectivity is also affected by foreground/split-view state. The opt-in simulator bridge preview is a read-only development fixture, not real-card access. macOS and the vendor app can compete for the same localhost bridge ports. Chrome local-network permission, system proxies, TLS identity and keychain prompts can all affect portal discovery independently of card signing.

## Signing and release access

Most contributors need only development signing or simulator builds. Maintainers provide narrowly scoped access when a task requires distribution. Secrets live in GitHub Actions and an authorized offline backup, never the repository or environment inventory.

| Distribution | Inputs / distinction |
| --- | --- |
| Apple | Match storage access, `MATCH_PASSWORD`, App Store Connect API key; Developer ID DMG notarization is separate from App Store/TestFlight profiles and PKG |
| Android | Existing `ANDROID_KEYSTORE_*`, alias/key password; Play service-account permission is separate from APK signing |
| Windows | MSI signing certificate/password; Store submission uses the four `MSSTORE_*` credentials, linked Entra application and Partner Center role |
| Huawei | AppGallery service-account JSON; upload/draft/review are separate operations |

See [signing inputs](11-build-and-release.md), [automation guide](../distribution/BUILD-AUTOMATION.md) and [release skill](../.agents/skills/esemnbun-release-stores/SKILL.md). Before dispatch, inspect workflow defaults and side effects. A release workflow may publish public files and submit selected stores; a TestFlight upload does not submit App Review. A Play artifact-only upload must preserve tracks and active review. Never cancel Huawei's active review just to create a new draft.

Pass explicit monotonically increasing build numbers after checking existing uploads. The workflow run counter can be lower than a previously overridden store build. Marketing-version changes are separate from build increments. Prefer the existing API/fastlane path; explain any browser fallback caused by permission or capability gaps.

On the owner's setup, publish only from the authorized main Mac with `GH_HOST=github.com` and the requested commit identity. Other contributors use their own authorized identities/hosts; do not reuse the owner's identity by default. Confirm the remote and account, especially on machines with an employer GitHub Enterprise session.

After publishing, verify the release assets/checksums, Apple processing state, store review state and Pages deployment independently. Website generation uses actual GitHub release metadata; refresh checked-in data when asset sizes/URLs change. A replacement DMG under the same version has the same URL but new bytes and may not trigger a version-only update notification.

## Completing a change

Update `PLAN.md` with the implementation and relevant remaining validation. Report commit/build, tested targets, actual observations and limitations. Keep detailed evidence under `docs/reports/` or a local ignored directory; sanitize identity details and filenames. Follow the repository's commit/review conventions; don't add tool attribution.

The repo skills are discoverable in `.agents/skills/`. Start with environment discovery, then build/sign, UI validation or release/submission as the task requires. Existing operational scripts are preferred over copied one-off commands. Historical reports explain what happened at the time; current code and store state decide what to do now.

For CI selection, exact-artifact publishing, review deferrals and distribution credential storage, read [GitHub Actions and publishing operations](14-github-actions.md). Use the CI automation skill when editing workflows; use the release skill for authorized delivery.
