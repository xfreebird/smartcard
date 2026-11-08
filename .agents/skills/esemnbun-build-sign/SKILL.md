---
name: esemnbun-build-sign
description: Build, test, package and verify signing for eSemnBun on Apple, Android, Windows and Linux, including local launches with correct entitlements.
---

# Build and sign eSemnBun

Read [developer onboarding](../../../docs/13-developer-onboarding.md) and the relevant platform section of [build and release](../../../docs/11-build-and-release.md). Scripts, project files and workflow inputs are authoritative; older prose may describe historical versions.

Before selecting a build/publish workflow, consult [the operation matrix and secret inventory](../../../docs/14-github-actions.md). An existing signed artifact may already satisfy the requested source; rebuilding just to submit a track consumes another code unnecessarily. Build success, upload, review and rollout must be reported separately.

## Before building

- Resolve the developer's actual machine/VM access from the environment skill. Do not assume the owner's SSH addresses, user names, OS architecture or installed SDK paths.
- Identify the exact commit, configuration, architecture, marketing version and integer build number. Use project-pinned SDKs and the workflow's supported runner/tool versions.
- Batch checks for the change. Portable core tests do not prove the native UI works. Use simulated cards for card-flow changes; a real-card test needs the owner's PIN for that session and stops on a PIN error.
- Obtain the vendor localhost TLS bundle through an authorized private handoff. Its absence is a setup error; never commit it or generate an unrelated replacement and claim portal compatibility.

## Apple

Use `apple/eSemnBun.xcodeproj`, schemes `eSemnBun-iOS`, `eSemnBun-macOS`, and `eSemnBun-macOS-AppStore`. Synchronized source folders include new resources automatically; verify target membership/exceptions when adding files. iOS launch screens are system launch resources; validate with `ibtool` and a cold launch, on phone and tablet.

Use `fastlane/Fastfile`, `fastlane/SIGNING.md`, `fastlane/Matchfile` and `apple/Configuration/` for signing. Match downloads are read-only during normal builds. Do not nuke or regenerate all profiles just to fix one missing profile. Store and Developer ID distributions have different signing/entitlement requirements.

A runnable macOS build must retain the correct smart-card entitlement; merely compiling or ad-hoc signing without entitlements is insufficient. Inspect `codesign -d --entitlements :- APP` and run `apple/scripts/verify-macos-distribution.sh` with the distribution mode its usage requires. Verify the nested reader helper too. Preserve hardened runtime and notarize/staple Developer ID releases; do not apply Developer ID packaging rules to the sandboxed Store build.

The localhost PKCS#12 import must stay in memory: persisting it in the login keychain can cause hidden prompts and block bridge handshakes after rebuilding. PKI HTTP requests deliberately bypass URLSession HSTS/proxy behavior; retain that path.

## Android

Use the Gradle wrapper under `android/`, its pinned JDK/SDK requirements, `:core:test` and `:app:assembleDebug` for development. Release APK/AAB signing uses environment inputs in `scripts/package-android.sh`; never substitute a debug key. Keep the existing application ID and signing key. Check versionCode against uploaded bundles, not only active tracks.

## Windows

Use `windows/global.json`, `Directory.Build.props`, and `windows/scripts/package-windows.ps1`. Portable tests can run elsewhere; WinUI/XAML compilation and installer/runtime validation require Windows. Respect x64/ARM64 and toolchain support for Native AOT. `windows/MoldSign.Portable.slnf` does not cover the app's UI.

MSI is the public installer; MSIX is the Store input. Native AOT CLI lives in `bin/` because `esemnbun.exe` and `eSemnBun.exe` collide on case-insensitive filesystems. Standalone MSI signing currently uses a self-signed certificate, not public CA trust; do not describe it as universally trusted. Store signing is separate.

Before size optimization, inventory compressed and unpacked package entries. The 0.2.2 baseline includes a second .NET runtime in the watcher and unused Windows App SDK AI payload. These are measured candidates, not implemented savings. Native AOT/trimming requires fixing reflection-based JSON and checking WinUI/COM/bridge behavior; do not delete DLLs based only on their names.

## Linux

Read `linux/README.md` for GTK/libadwaita, PC/SC, OpenSSL and Secret Service requirements. Build in the intended guest/distribution and use `scripts/package-linux.sh`; don't assume a Mac portable build proves GTK integration. `scripts/test-portable-macos.sh` exercises OpenSSL/POSIX paths, not the Linux desktop UI. Live PKI tests are opt-in.

Report artifact paths, commit/configuration, checks actually run, and unverified hardware/UI cases. Launching a previous installed app does not validate a new build.
