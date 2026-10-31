# Android corrections — 31 October 2026

Application source now groups application coordination/ports, presentation state, platform infrastructure
and Compose UI. Core Kotlin source groups card, crypto, formats, network, bridge and application policy;
Gradle's Android-free core boundary is retained. App package names match their application/presentation/infrastructure folders. Core library package names and manifest entry points stay stable.

`DocumentAccess` owns document grants/metadata/reads/cache imports/export copies and is injectable into
MainViewModel. `ReaderGateway` owns discovery/state/permissions/transport access and is injectable into
AppContainer alongside the SigningService factory. Concrete USB and SAF dependencies live in infrastructure.
The ViewModel keeps presentation state and coordinates existing frozen-batch signing/verification policy.

Artwork now uses a circular head and shallow shoulder dome, with no extended torso; the portrait frame remains
3:5. The chip has defined contact channels. PIN entry is centered with responsive-width cells 56dp tall,
capped at 44dp wide so eight cells fit compact phones. Tablet PIN content is bounded 640dp. Local authorization
copy correctly reads “Signature requested by you” rather than “You requests a signature”.

Validation:

- Debug APK, unsigned Release APK, Release AAB and lint passed after all code/resource changes.
- Core JUnit:117 tests, zero failures/errors, one opt-in test skipped.
- USB JUnit:21 tests, zero failures/errors.
- Release APK and AAB ELF/library audits pass for armeabi-v7a, arm64-v8a, x86 and x86_64.
- ARM64 emulator launches through the normal AndroidViewModel factory after constructor injection changes.
- 24 current-source light/dark captures: cards, no reader, batch and blank PIN on phone, portrait tablet and
  landscape tablet. PIN captures refreshed after the final copy correction. Ready-frame manifests accompany
  every image. Output: Desktop/esemnbun-screenshots/android/2026-10-31.

The PIN scenario uses a timed fictional consent request and never invokes signing or accesses a vault/card.
No PIN was typed. Android x86-64 runtime remains a separate execution gate; package ABI verification is not
reported as x86-64 runtime execution. The repository's manual runtime workflow is available for that gate.

The later tablet desktop-layout amendment replaces the earlier side-by-side workspace. See
[tablet validation](android-tablet-desktop-layout-2026-10-31.md) for current 32 tablet captures and builds.
