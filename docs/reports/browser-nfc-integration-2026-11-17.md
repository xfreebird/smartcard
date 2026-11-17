# Embedded browser NFC authentication

Implemented for iOS and Android on 17 November 2026. Real-portal authentication acceptance is pending the owner's card test. Ordinary NFC document signing was already released in 0.2.12; this change adds the browser path.

## User flow

1. Open the app's embedded browser. Choose **NFC** or **Card reader** with the authentication-method selector. In NFC mode, the card menu selects a known card or reads a new one.
2. For a new identity, choose **Read NFC card** and present it once. This reads only the public signing certificate; it does not authenticate or send a PIN. The browser refreshes the visible URL with a GET after identity selection, without replaying a form POST.
3. The bridge lists the actual certificate while the card is absent. A generic placeholder certificate is not used: the protocol sends `certificateBase64` to the portal and uses that selected identity when signing the challenge.
4. Request authentication on the portal. The existing native consent/PIN flow runs first. NFC opens only after approval/PIN, and the same selected card must be presented.
5. Public certificate DER is compared before secure-channel authentication and PIN verification. One session produces the signature; NFC is released before timestamp/network completion. The existing 201/absolute-Location/long-poll protocol delivers the response to the webpage.

The browser has an explicit saved **NFC / Card reader** choice, independent of the Sign workspace. NFC mode lists only the selected NFC identity, even with a reader connected; Reader mode lists only connected reader identities. Missing NFC identity never falls back to a reader. On iOS the same preference is available in Settings → Browser. Android exposes the same controls on its Browser landing page and inside the embedded browser, applying the preference to external browsers too.

A newly scanned certificate stays in app memory. Existing saved-PIN certificate metadata can seed the selection after restart; this change does not persist an additional identity database or any PIN. On iOS, leaving the embedded browser withdraws its NFC identity and cancels active NFC work. On Android, the bridge continues advertising the selected public NFC identity to external browsers. Signing posts the existing consent notification; the owner opens the app, confirms the PIN and taps the card in the foreground, then returns to the waiting external browser. Android does not attempt background RF. A retained identity can be selected again when the browser is reopened.

## Implementation

- Swift `MoldSignServer` adds public identity and on-demand transport hooks. Listing does not open RF. The host opens a session after authorization; the core compares public DER before authentication, preserves the existing certificate check before VERIFY, and releases the transport once it receives the signature. Transport failure/cancellation never falls back to a reader. The transport choice is frozen before consent and retained through batch PIN reuse; withdrawing the selected NFC identity fails the request. NFC requires a native PIN even if the webpage supplies a PIN field.
- iOS `NFCBrowserCoordinator` owns the native session and browser identity. AppModel connects it to the bridge, its common PIN vault and known identities. A worker-to-main-actor adapter keeps Core NFC callbacks off the blocked bridge worker.
- Kotlin `SigningBridgeRoutes` adds an optional scoped signing-service hook. Android `NfcBrowserCoordinator` collects native consent/PIN before reader mode, checks exact DER and supplies a dedicated `CardSigningService` using the existing NFC connection and card-signature cleanup callback.
- Both implementations preserve origin checks and response ownership. Native cancellation, backgrounding, connection loss, card mismatch and PIN failure stop that request without automatic authentication/PIN retry. Existing batch PIN reuse remains origin/card scoped; each signature still opens a fresh NFC session.
- Browser method/readiness copy is provided in Romanian, English and Russian. Demo identities cannot enter these hardware paths.

## Verification and handoff

- iOS Debug 0.2.12 build 4 passed on Xcode 27.1 for the iPhone 13 Pro; the bundle passed strict recursive signature verification. Android isolated NFC Test APK compilation passed. Localization export checks and whitespace checks passed. Exact local logs are under ignored `.local/nfc-browser-20261117/`.
- Added Swift simulated-card bridge cases for listing without RF, on-demand XAdES authentication with signature validation, cancellation without reader fallback, swapped-card rejection before PIN and a single wrong-PIN attempt.
- Added Kotlin bridge cases for lazy session-service routing and cancellation without fallback. Existing contactless core tests cover exact certificate binding and one-attempt PIN behavior.
- Automated tests have not been run in this task, following the owner's standing instruction that the owner runs tests. Native builds are part of the requested device launch. No real-card commands have been sent by development tools.
- Pending: owner-run regression suites, iPhone 13 Pro and Android MPass authentication, portal PDF/XAdES signing, saved-PIN reuse, initial scan versus known identity, cancellation/backgrounding and physical Reader/NFC switching. A compiled app is not proof of portal acceptance.

Suggested focused suites:

```sh
swift test --package-path swift/MoldSignKit --filter BridgeEndToEndTests
cd android
./gradlew :core:test --tests md.moldsign.core.SigningBridgeRoutesTest --tests md.moldsign.core.ContactlessSigningTest
```

Do not intentionally submit an incorrect PIN to a real card. Enter the real PIN only on the phone. If a scan fails, report the error and collect the existing metadata-only NFC diagnostics before choosing the next manual attempt.

## Authentication-method follow-up

The owner confirmed the initial iPhone embedded-browser NFC authentication works. Added a saved, exclusive NFC/reader choice and Android external-browser routing. Mode changes refresh the embedded page using GET. The Android notification reflects NFC readiness. These follow-up UI/persistence/external-browser cases still require physical acceptance; automated regression suites remain unrun by instruction.

Follow-up build verification: iOS Debug 0.2.12 build 6 and the Android NFC Test APK compiled successfully. The iOS bundle passed strict recursive signature verification; RO/EN/RU localization exports match their catalog. Added a Swift bridge regression ensuring NFC-only mode neither lists nor uses connected readers. Automated tests were not run.

## Compact controls and error presentation

Browser authentication options moved to a left toolbar button and a modal on both mobile platforms. iOS Settings opens the same modal; its row shows the short localized NFC/Reader value instead of a long inline picker. The iOS connection strip is replaced by a small toolbar status dot with an accessible state label and full text inside the modal. Card selection, NFC scanning and Android external-browser instructions live inside the options modal.

Web loading failures now use a friendly localized notice and navigation cancellation is silent. Native NFC sheets, identity-read errors and mobile bridge signing responses use presentation messages instead of exception descriptions; unknown app errors no longer expose exception strings. Added core regression cases ensuring a technical failure is replaced by the host's friendly response. These tests are prepared but not run, per standing instructions.

Compact-UI verification: iOS Debug build 7 and the Android NFC Test APK compiled; localization export and whitespace checks passed. The browser refreshes its displayed identities once when returning from Settings after a method/card change. Native layout, modal dismissal and physical error presentation remain for owner acceptance.

Device delivery: the final iOS Debug build 7 (including refresh-on-return from Settings) passed compilation and signature checks, then installed and launched on the reconnected iPhone 13 Pro. The Android NFC Test APK (`md.esemnbun.app.nfctest`) installed and launched on the connected Android phone after USB installation was allowed. The production Android app and its data were preserved. Final modal layout, method persistence and error presentation still require owner acceptance.
