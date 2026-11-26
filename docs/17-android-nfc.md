# Android NFC signing

Android NFC signing is included in 0.2.12. On 2026-11-16 the owner signed a
PDF on an Android 14 phone (model 22126RN91Y) using the same Moldovan eID previously tested
on iPhone. The resulting RSA-4096 CMS passed independent OpenSSL verification; changing
the signed content failed verification. The timestamp token's signature and its binding
to the card signature also passed. See [the evidence report](reports/android-nfc-signing-2026-11-16.md).

This establishes the tested card/device PAdES-T path. Certificate-chain trust, revocation,
other card generations/devices and XAdES over real NFC are separate acceptance checks.

See the [Android NFC sequence diagram](https://esemnbun.md/img/developers/nfc-android-sequence.svg) in the Developer Handbook.

## User flow

Sign starts with one **Choose a document** action. Import reveals a review screen with
**Continue**, followed by the same PIN dialog and NFC session. The chosen method and identity
remain available in compact rows. **How it works** presents the three detailed steps in a
bottom sheet. Settings has separate dialogs for connected cards and remembered identities.

Sign defaults to **NFC** on capable phones with a blue card illustration. Selecting
Reader shows live connection/insertion guidance, USB permission when needed, or the connected
identity cards inline. Multiple cards retain the swipe carousel and a selection hint; the
connection guide opens from How it works. The Continue hint reflects missing reader/card
setup. The app uses the shared brand palette by default instead of
wallpaper-derived colors, with neutral light/dark surfaces. New copy supports RO/EN/RU.

1. Use **NFC**, or choose **Card reader** in Sign. Both choices remain available with a USB reader connected.
2. The compact card chooser selects an already known card or **Another card**. A reader card and its NFC
   counterpart use the same signing-certificate identity. Another card clears that selection.
3. Select the document(s), tap Continue and use the common PIN dialog. A selected saved card
   offers biometric PIN retrieval; an unknown card requires manual PIN entry.
4. Hold the card at the phone's NFC antenna until the NFC window closes. The public
   certificate, authentication, protected PIN verification and signature use one connection.
   The app releases the card before timestamp/network work and shows the saved document afterwards.

Each document in a batch gets one NFC presentation. The batch PIN remains in memory only,
is bound to the first identified card, and is cleared at completion or failure. Any NFC,
authentication, PIN, document or storage error stops the NFC batch. Retry requires a new
explicit user action. Loss of the VERIFY response does **not** establish whether the card
processed the PIN; never infer remaining attempts from a transport error.

## Architecture and card safeguards

- `NfcSigningController` uses foreground Android reader mode with NFC-A/NFC-B, skips NDEF
  checks and suppresses the early system tag sound. ISO-DEP connect/transceive run off the
  main thread. Waiting for a card is bounded to 60 seconds; each transceive to 8 seconds.
  Every session end (card signature, failure, cancel, timeout) closes the connection. Late callbacks
  cannot replace the accepted tag or reactivate a cancelled session. No reconnect/authentication loop exists.
- Reader mode is owned by `NfcReaderModeGate`, not by a session. Turning reader mode off while the eID is
  still at the antenna hands the card back to Android's dispatcher, which finds no app for an ISO-DEP card
  without NDEF and shows "No supported app for this NFC tag". After a session that saw a card, reader mode
  therefore stays on and absorbs (never connects to) further discoveries until the activity pauses. On
  pause the last tag is passed to `NfcAdapter.ignore` with a 1 s debounce before reader mode is released, so
  a card that keeps its UID is not dispatched while it stays in range. A session that never saw a card
  releases reader mode at once. The next document of a batch reuses the enabled reader mode and asks the
  platform to present the held card again; it still opens its own connection. While reader mode is held,
  other NFC uses (for example tap-to-pay) wait until eSemnBun leaves the foreground.
- `ContactlessCertificateReader` selects IAS, Generic ADF and EF0001 without authentication.
  Reads are exact, at most 128 bytes each, with a 4096-byte certificate limit and bounded
  GET RESPONSE chaining. The selected certificate must match **exact DER** before authentication.
- `NfcSignDocuments` passes the same connection into `CardSigningService`. That service
  reads the certificate again and checks its fingerprint before VERIFY. The preauthorized
  consent also compares DER before releasing a PIN copy. No USB fallback is attempted.
- The Kotlin card driver now checks every authentication prerequisite, reads D003 as exactly
  18 bytes then skips two without assuming their values, and reads D004/challenge as exactly
  16 bytes. Each session uses fresh terminal randomness/key material. Mutual authentication
  verifies both MAC and challenge/terminal binding.
- Secure responses require a well-formed status object and MAC; authentication precedes
  decryption. Bare successful statuses, duplicate/missing fields and bad padding are rejected.
  Bare errors consume an SSC step and stop the app operation. Response chaining is bounded.
- Signing reselects MF and Generic ADF after VERIFY, matching the proven physical-card path.
  Core tests exercise the public read and signature on the same simulated connection,
  swapped cards, one-attempt PIN failure, fresh randomness, setup failures and malformed responses.

Android APIs: [NfcAdapter reader mode](https://developer.android.com/reference/android/nfc/NfcAdapter#enableReaderMode(android.app.Activity,%20android.nfc.NfcAdapter.ReaderCallback,%20int,%20android.os.Bundle))
and [IsoDep](https://developer.android.com/reference/android/nfc/tech/IsoDep).

## Shared PIN and identity management

`PinVault` retains its existing certificate SHA-1 account and authenticated encrypted record
format. No transport prefix or new PIN namespace is introduced. The common dialog offers
manual entry, optional saving and explicit biometric retrieval. Saving occurs only after
a successful document result and requires biometric confirmation. A wrong PIN clears the
stale local credential and identity. Cancellation or failure clears pending plaintext copies.

`SavedCardIdentities` stores public certificate metadata only after the corresponding PIN
is saved. Explicit NFC identification and choosing a reader card for NFC can also remember
a certificate in memory during the session. **Settings → Saved cards and PINs** lists both
kinds, including disconnected cards and older records without a saved PIN. **Forget card**
clears the stored identity, optional PIN and active NFC/browser choices for that certificate.
An inserted card remains available through its USB reader. Routine reader polling does
not restore the forgotten entry. Restored metadata is parsed and fingerprint-checked.
The next signing session still checks the live certificate.

Physical saved-PIN save/reuse, restart persistence, deletion across methods and switching
between two real cards still need a dedicated acceptance run.

## Builds and diagnostics

Normal builds keep `md.esemnbun.app`. A Play install cannot be upgraded using the local debug
key. The opt-in `-PnfcTestInstall=true` Debug variant uses `md.esemnbun.app.nfctest`, labelled
**eSemnBun NFC Test**, and has its own app/PIN storage. It preserves the Play app and its data.

```sh
cd android
./gradlew :core:test :app:testDebugUnitTest
./gradlew :app:assembleDebug :app:assembleDebugAndroidTest -PnfcTestInstall=true
adb -s DEVICE_SERIAL install -r app/build/outputs/apk/debug/app-debug.apk
# Optional UI helper; requires the phone to permit test-package installation.
adb -s DEVICE_SERIAL install -r -t app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb -s DEVICE_SERIAL shell am instrument -w -e suite nfc-preparation \
  md.esemnbun.app.nfctest.test/md.moldsign.app.FileProtectionInstrumentation
```

`NfcPreparationIntegration` is restricted to the separate Debug install. It checks both
orientations and PIN cancellation without submitting a PIN or sending an APDU. It did not
run on the owner's phone because installing the test helper was blocked. The normal app
installed and its first real NFC signature succeeded.

The separate Debug install can prepare a synthetic PDF without starting a scan or providing a PIN:

```sh
adb -s DEVICE_SERIAL shell am start -n md.esemnbun.app.nfctest/md.moldsign.app.MainActivity \
  --ez nfc_test_prepare true
android/scripts/collect-nfc-diagnostics.sh DEVICE_SERIAL
```

Debug reports are capped at 20 files under `cache/nfc-diagnostics`. They contain stages,
relative durations, command instruction numbers, response sizes/status words and error
classes. They exclude command/response payloads, PINs, keys, tag identifiers, certificates,
cardholder details and document names/content. Release builds do not persist these reports.
The collector uses `run-as`, copies only that directory into a fresh ignored `.local/`
destination, and hashes each file. Signed PDFs, extracted CMS/certificates and device
screenshots also stay private under `.local/`.

## Follow-up acceptance

- Saved PIN: save after success, reuse with biometrics, restart, then delete; exercise both NFC and USB.
- Two cards: select card A, present B and verify rejection before PIN; explicitly choose Another card for B.
- USB connected: sign by NFC while a different card remains in the reader.
- Cancel/background/rotation: waiting and in-progress scan; confirm closure and no automatic retry.
- Keep the card on the phone after a signature, a failure and a cancel: no "No supported app for this NFC
  tag" message while eSemnBun is in front; then leave the app with the card still there. A card with a
  random UID may still be dispatched once by the system after the app has left the foreground.
- XAdES and multi-document NFC batches, other Android devices and other card generations.
- Certificate trust/revocation and external portal validation remain distinct from cryptographic integrity.

## Embedded browser authentication

The embedded browser can advertise a remembered NFC certificate while the card is absent. For a new card, choose **NFC → Read NFC card** once; this reads public metadata without a PIN. The portal then requests authentication normally, and the app collects the PIN before opening a fresh, certificate-bound NFC session. The saved **NFC / Card reader** selector controls which identities are listed, both in the embedded browser and external browsers. External NFC requests use the eSemnBun notification to collect the PIN and scan in the foreground; return to the browser afterwards. See [implementation and acceptance](reports/browser-nfc-integration-2026-11-17.md).
