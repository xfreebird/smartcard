# Android Play optimization validation — 2026-11-21

Validated the working-tree Android changes over commit `43d8e780` using local JDK 17.0.14,
Gradle 8.13, AGP 8.10.1 and the configured Android SDK. Marketing version is 0.2.14;
`BUILD_NUMBER` was unset, so these local validation artifacts use versionCode 2.

## Tests

| Task | Passed | Skipped | Failed |
| --- | ---: | ---: | ---: |
| `:core:test` | 165 | 1 | 0 |
| `:transport-usb:testDebugUnitTest` | 21 | 0 | 0 |
| `:app:testDebugUnitTest` | 18 | 0 | 0 |
| `:app:testReleaseUnitTest` | 18 | 0 | 0 |
| Total | 222 | 1 | 0 |

The skipped test is the opt-in `PadesCmsSignerTest.liveTimestampAuthorityAnswers`.
Bridge allow-list loading and the HTTPS listener test passed. Release unit tests run on the JVM;
they do not execute the optimized DEX on an Android device.

## Builds

`:app:assembleDebug`, `:app:assembleRelease` and `:app:bundleRelease` passed.
Release ran `:app:minifyReleaseWithR8` and resource optimization successfully.

| Output, relative to repository root | Bytes | Uncompressed DEX bytes |
| --- | ---: | ---: |
| `android/app/build/outputs/apk/debug/app-debug.apk` | 23,817,324 | 67,728,580 |
| `android/app/build/outputs/apk/release/app-release-unsigned.apk` | 3,233,728 | 3,705,188 |
| `android/app/build/outputs/bundle/release/app-release.aab` | 6,057,149 | 3,705,188 |

Release APK and AAB are unsigned local outputs, not store-ready packages. Debug uses normal
development signing. No upload key, store build-number reservation or publishing workflow was used.

The AAB contains `BUNDLE-METADATA/com.android.tools/r8.json` and the embedded ProGuard mapping.
All three optimization flags are enabled. Taking the complements of its `no*Percentage` statistics
indicates these local scores:

| Metric | Percentage |
| --- | ---: |
| Obfuscation | 96.66% |
| Optimization | 95.59% |
| Shrinking | 96.43% |

These exceed the 25% thresholds in the supplied Play warning. The optimized DEX is also below
10 MB. Google documents the metadata and size criteria in [DEX code optimization](https://developer.android.com/google/play/vitals/code-optimization).
These are local artifact observations; Play has not analyzed a new uploaded build in this task.

Verified the allow-list, vendor TLS identity, public CA certificates and PDF stamp metrics remain
present in both APKs and the AAB. `scripts/check-android-abis.py` passed on both APKs for ARM32,
ARM64, x86 and x86-64. This confirms packaging, not runtime behavior on those architectures.

Release APK SHA-256: `aa794e36f18689f95bc169ec63a7a1ed567e5a16af677eb12479df9835540dd5`.
Release AAB SHA-256: `d0aaaba9c3311e11bb0c39390563cd42a8a18b325885511fa9d25e36d921d4de`.

## Lint

Both `:app:lintDebug` and `:app:lintRelease` passed after fixing three existing blockers:

- Put `windowLightNavigationBar` in an API 27 launch-theme override while preserving shared
  launch styling and the Android 12+ splash theme.
- Read the PDF stamp locale through `LocalConfiguration`; update the stamp language without
  resetting its placement when the locale changes.
- Resolve the saved-document failure string through `stringResource`, with `rememberUpdatedState`
  for the asynchronous inspection callback.

Debug reports 176 warnings and one hint; Release reports 177 warnings and one hint, with no errors.
Reports are in `android/app/build/reports/lint-results-{debug,release}.html`.
`git diff --check` passed.

## Evidence and remaining acceptance

Ignored local logs, the machine-readable summary, R8 metadata and the exact mapping copy are in
`.local/validation/android-play-2026-11-21/`. `gradle.log` records the initial lint failure;
`gradle-final.log` records the successful final batch. Core/USB tests were reused as up-to-date in
the final batch after passing in the initial batch; app tests reran after the lint fixes.

No emulator UI tests, physical device/card flows, live TSA test, optimized Release installation,
store signing or Play upload were performed. Edge-to-edge still needs runtime checks on Android
14/15/16 across navigation modes, cutouts, rotation and keyboard presentation. Saved-PIN/biometrics,
reader/NFC signing, browser authentication, stamps, protection, sharing and widgets need optimized
Release runtime acceptance before rollout.

## Authorized GitHub delivery and closed alpha submission

The owner subsequently requested commit/push, passing Android Actions and a new closed alpha
publication. Source commit [`116720dd`](https://github.com/xfreebird/smartcard/commit/116720dd9de687091ad91c9b87effc24c5d595dd)
was pushed to `main` as `xfreebird <xfreebird@gmail.com>`. Unrelated working-tree files were excluded.

| Operation | Result |
| --- | --- |
| [CI 44900747793](https://github.com/xfreebird/smartcard/actions/runs/44900747793) | Passed Android build/unit tests, 34 native mock UI journeys, required protection/persistence/saved-identity/browser-authentication phases, localization and `CI result` |
| [Signed Android build 44900784500](https://github.com/xfreebird/smartcard/actions/runs/44900784500) | Passed; APK/AAB for 0.2.14 (1793624701), exact source commit above; build-only with Play upload disabled |
| [Play publish 44901343721](https://github.com/xfreebird/smartcard/actions/runs/44901343721) | Passed; result `submitted`, operation `closed_testing`, selected track `alpha` |

Before building, both the live uploaded-bundle maximum and repository reserved maximum were
1793624700. The supported builder reserved 1793624701. Verified package `md.esemnbun.app`,
versionName 0.2.14, versionCode 1793624701, APK upload-certificate fingerprint
`0bd6c7ce1a0e57b3f959917d6c166c433184a3101cad5ddd5333b82bce9324cf` and the AAB signature.
The signed AAB retains its embedded mapping and R8 metadata, all required classpath resources and
3,704,984 bytes of uncompressed DEX. Its metadata indicates the same optimization percentages
reported above.

- Signed APK SHA-256: `cc368c6feea9673726aad4386c9767df4e0238721c9b0331f92778ce7506d832`.
- Signed AAB SHA-256: `0a8ce85706de0d56235c592d7825aaaa60ada06bceda90feb15a307fc3d031b1`.

The publisher reused the exact signed Actions artifact, supplied change-specific EN/RO/RU notes,
validated the returned bundle code/hash and independently verified the committed track state.
A second read from the main Mac confirmed alpha's 1793624701 code/hash and that production,
internal and beta matched their pre-submission state. No tester lists, store listings, screenshots,
other platforms or GitHub release assets were changed.

After submission, [Play Console alpha](https://play.google.com/console/u/1/developers/8344963402071617946/app/4973211912255144827/tracks/4698313398880262778)
showed **Release 0.2.14 (1793624701) in review**. The previous 1793624700 remained **Available to
selected testers**. API track status `completed` does not establish approval or new-build tester
availability. Those remain pending Google review. This delivery section supersedes the local-only
publication status above; optimized Release hardware/UI acceptance remains unverified.

Ignored evidence also includes `github-ci.log`, `signed-1793624701/identity.json`, the signed
APK/AAB and exact embedded mapping, `publish-result/play-result.json`, and independent
`play-before.json` / `play-after.json` snapshots under the local validation directory.
