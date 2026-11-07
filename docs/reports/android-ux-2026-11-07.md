# Android responsive UI review — 2026-11-07

Android Sign now uses independent identity and document columns in wide, short windows, including phone landscape. Portrait keeps the stacked layout. Navigation switches to a scrolling rail in phone landscape, and the document pane owns its signing action. Compact bottom navigation uses localized “Files” and “Sign” labels while destination titles retain their full names. On windows narrower than 400 dp, the status action becomes a 48 dp button with a status dot and full accessible status description, preventing the app title wrapping between the other toolbar actions.

Changes are in `MoldSignRoot.kt`, `screens/Screens.kt`, and `components/StatusLight.kt`. Localized labels were coordinated through the catalog. No card transport/signing logic was changed for this UI work.

## Build and evidence

- Base commit: `d0f4f131499e7e23bad8e75be6ead77c0b07fd9b`, plus current working-tree changes.
- Main Mac: Debug APK `android/app/build/outputs/apk/debug/app-debug.apk`; `:app:assembleDebug` passed. Main Mac fallback was necessary because read-only discovery on the Air found no Android SDK or repository at the standard paths.
- Full `:core:test`: 121 tests, no failures/errors, one opt-in live TSA test skipped. Includes all 12 bridge route tests.
- `:app:testDebugUnitTest --tests md.moldsign.app.pin.PinRecordBindingTest`: one AES-GCM certificate-binding regression passed, no failures.
- Emulator `emulator-5560`, AVD `esb-stamp-review`, API 36. All commands explicitly selected that serial. No physical reader or PIN used.
- Fictional cards/documents only, Romanian UI. Demo capture hides the debug banner so its added height does not distort production layout. Per-image JSON records APK SHA-256, dimensions, theme and scenario.
- Local evidence: `/tmp/esemnbun-ux-2026-11-07/android/`. Final matrix uses 320×568 and 412×915 dp phones and 600×960 and 800×1280 dp tablet viewports, in both orientations. Small phone is captured in both themes, other profiles in dark mode. These are resized emulator viewports, not four distinct hardware devices.

## Findings and limits

The initial 320 dp capture exposed a wrapped application title and the original orphan-letter Documents navigation label. Both were addressed. The first single-line navigation pass exposed truncation of “Semnează”; the shorter localized navigation label addresses that without reducing the normal font size. Landscape keeps card identity beside files; on the shortest phone, actions and lower navigation entries require scrolling.

This is a focused layout review. It does not prove real-card signing, USB transport, drag-and-drop, external browser integration, full accessibility navigation, enlarged system fonts, foldables, or every screen/state/language/theme combination. No live PKI tests were enabled. Initial capture artifacts may include old build frames; final matrix files overwrite the matching Sign screenshots and include final APK hashes.

## Interaction follow-up

At 568×320 dp, two real emulator swipes in the document pane revealed the complete signing button, while the identity stayed in place. A separate rail swipe revealed Browser and Card; tapping Card opened its destination. Evidence: `phone-small-landscape-dark-sign-action.png`, `phone-small-landscape-dark-rail-scrolled.png`, and `phone-small-landscape-dark-card-via-rail.png`. The action was not invoked; no PIN was entered.

A Russian 320 dp sample exposed that even the shorter Verify label exceeded the default Material label slot. Bottom labels now use the available item width minus 4 dp, centered, retaining normal font size. The final Russian capture confirms Подпись, Проверка, Файлы, Браузер and Карта are all readable in full (`phone-small-portrait-dark-ru-sign.png`). Romanian was recaptured afterward. This is not a complete Russian UI audit.

Matrix APK SHA-256: `cc6f653e0463d9dcb76b840bc95a494dcaa2f7bdc5076ef473abdd40141c9049`. All ten matrix Sign JSON records match this APK. The subsequent navigation-only width/Verify-label refinement was rebuilt successfully and recaptured at 320 dp in Russian and Romanian; final APK SHA-256: `d8aed9ce2763b5d8df200073b0d163695fca90e80429fc9276536c6b7ffbfa00`. Final successful build log: `/tmp/esemnbun-android-final-build.log`. Security test XML: `android/app/build/test-results/testDebugUnitTest/TEST-md.moldsign.app.pin.PinRecordBindingTest.xml`.
