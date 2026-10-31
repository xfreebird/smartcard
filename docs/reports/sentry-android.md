# Android excluded from Sentry — 31 October 2026

Per the user's amendment, Sentry is restricted to desktop applications. All Android Sentry additions
have been removed: SDK and Gradle plugin dependencies, version-catalog aliases, application startup
instrumentation, manifest metadata, monitoring adapter and privacy tests, mock verification hook and
verification script. Existing Android UI, localization, architecture and mock-scenario changes remain.
No Sentry upload configuration remains in Android, and no further telemetry was sent after the amendment.

Validation passed after a clean application build:

```sh
./android/gradlew -p android :app:clean :app:assembleDebug :app:assembleRelease :app:lintDebug --no-daemon
```

Debug and unsigned Release APKs built successfully; lint reports zero errors. Neither APK contains
Sentry asset/native-library entries, `Lio/sentry/` DEX classes, or the removed verification marker.
Both retain the four supported ABIs (ARMv7, ARM64, x86, x86_64), with only the existing graphics-path
and DataStore native libraries. The Release runtime dependency report contains no Sentry dependency.

Evidence:

- `/tmp/esemnbun-android-no-sentry-build.log` — successful clean build and lint.
- `/tmp/esemnbun-android-no-sentry-dependencies.log` — dependency audit.
- `/tmp/esemnbun-android-no-sentry-apk-audit.json` — artifact hashes and SDK/hook absence checks.

| Final artifact | SHA-256 |
| --- | --- |
| Debug APK | `c07233f0a97ff976d2a24c3458b41a4a11ada12c14bcd3bcefeb8483e24963fa` |
| Unsigned Release APK | `c669b098dc25cd790015abb43eaec3413bc9d6c4fb8e822c2e492a4e3783f18e` |

Earlier Android onboarding produced one hardware-free verification issue,
`ESEMNBUN-ANDROID-1`, before the desktop-only amendment. That historical Sentry data and the newly
created Android project were not deleted; Android no longer initializes or packages Sentry.
The dedicated mock emulator was stopped before the amendment and remains stopped.
