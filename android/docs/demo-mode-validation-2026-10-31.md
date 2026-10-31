# Android persistent demo mode validation — 31 October 2026

The settings gear is available on every screen. Enabling demo mode requires confirmation of its
fictional-data/invalid-signature disclaimer, then restarts the Activity in a new task with fresh
lifecycle-owned view models. Disabling restores the hardware-backed composition. The preference
survives a cold launch; switching is unavailable during work or a pending consent request.

Demo mode initializes the mock reader before creating any USB adapter. It uses fictional display
certificates with no DER/private key, rejects every physical APDU transport request, and never asks
for or loads a PIN. Bridge startup and saved-PIN deletion are disabled. Real picked/shared input is
ignored; only the two built-in PDF fixtures are used. Demo history has a separate preferences namespace.

Every selected fixture creates its own new `DEMO-<fixture>-NOT-SIGNED.pdf`, inserted into Downloads
without overwriting prior output or input. Each has its own Activity/Open/Share/Save-as entry. These
are static sample pages, never signed. The PDF carries `DEMO - NOT A VALID SIGNATURE` and
`DEMO ONLY - UNSIGNED` watermarks. `pdftotext` confirmed the text and `pdfsig` confirmed no signatures.
A persistent banner remains on every app screen. The final result Snackbar offers Open and explicitly
states that no real signature was created.

## Checks

Final batch passed:

```sh
./android/gradlew -p android :app:assembleDebug :app:assembleRelease :app:lintDebug :app:testDebugUnitTest --no-daemon
```

Log: `/tmp/esemnbun-android-demo-snackbar-verified-build.log` (35 seconds).
Two focused mock-safety tests passed; lint reports zero errors. Both APKs pass the four-ABI ELF audit
(ARMv7, ARM64, x86, x86_64).

| Artifact | SHA-256 |
| --- | --- |
| Debug APK | `3d0f460a2492e833b30eb4fd4db109b93c6e8fa0c31b2ccaf022cad377e17938` |
| Unsigned Release APK | `1cde82335bef3f02c7cc102f16927b342a9d636b9ac01e74ab00ab8840472240` |

## Native checks and evidence

The dedicated emulator `emulator-5580` exercised native settings taps, disclaimer confirmation,
mode-switch restart, cold-launch persistence, the simulated two-document batch, separate sample
output rows, Android's native Share chooser, and disabling demo mode back to the normal no-reader UI.
Debug and actual non-debuggable Release both passed. The Release APK was signed locally with the
existing Android debug test key solely for emulator installation; no production signing or publishing
was performed. Its installed SHA-256 is `cd07cb1b5f30c7164d117c7f1d8b46bd0a5d2f6bdaac225f98d0052327ce896e`.

- Debug evidence: `/Users/nghimbovschi/Desktop/esemnbun-screenshots/android/2026-10-31/demo-mode/`
- Final Release evidence: the `release/` subfolder at that path.
- Each has eight screenshots plus native UI XML and `validation.json`. Release's manifest records
  `debuggable: false` and the installed APK hash. The final Release result screenshot includes the
  corrected persistent Snackbar/Open action; the earlier Debug result capture preceded that UI fix.
- Exported sample PDF is retained in `release/DEMO-contract-NOT-SIGNED.pdf`.
- Runtime logs: `/tmp/esemnbun-android-demo-batch-native.log` and
  `/tmp/esemnbun-android-demo-release-native.log`.
- Reusable script: `android/scripts/test-demo-mode.py`; pass `--allow-release` for an explicitly installed
  local Release validation APK. It accepts only emulators, and expects the English 1080×2400 mock profile.

This emulator omits the rendered floating action from its UIAutomator hierarchy. The script activates
it with an actual native touch at the screenshot-verified position, and checks the resulting separate
sample outputs and native Share UI; it does not invoke signing programmatically.

No physical card, real PIN or actual user document was used. The emulator is stopped and its demo
preference was restored to off after validation. Unrelated existing source changes were preserved.
