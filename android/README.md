# MoldSign for Android

Gradle project for the Android port (PLAN.md **F-12**, then the **AND-\*** items). It follows the
contracts in [`docs/09-architecture.md`](../docs/09-architecture.md) (layers, `ApduTransport`,
`CosmoXCard` flow, error taxonomy, PinVault, bridge origin policy) and the screen spec in
[`docs/10-design-system.md`](../docs/10-design-system.md) §4.5. The Swift `MoldSignKit` is the reference;
this is a line-by-line port gated by [`spec/vectors/card-crypto.json`](../spec/vectors/card-crypto.json).

## Modules

| Module | Kind | Package | Contents |
|---|---|---|---|
| `:core` | Kotlin/JVM library, no Android deps | `md.moldsign.core` | `Hex`, `Aes` (javax.crypto ECB/CBC, NoPadding), `Cmac` (RFC 4493), `Iso9797`, `Sha`, `DigestInfo`, `SecureChannel`, `CosmoXCard`, `ApduTransport`, `CardError`, `BridgeOriginPolicy`, `BridgeServer` (loopback HTTP/1.1), `SigningService` / `CardSigningService`, models, and stubs for `PadesSigner`, `XadesSigner`, `TrustServices`, `Validator` |
| `:transport-usb` | Android library | `md.moldsign.transport.usb` | `Ccid` (pure framing + class-descriptor parser), `CcidTransport : ApduTransport` over USB bulk endpoints, `UsbReaderMonitor` (attach/detach, permission, slot polling → `StateFlow<ReaderState>`), `res/xml/device_filter.xml` |
| `:app` | Compose + Material 3 app | `md.moldsign.app` | Theme from the design tokens, bottom navigation (Semnează · Verifică · Browser · Card), StatusCard, FileRow + FormatChip, PIN bottom sheet, ConnectionGuide, `BridgeService` (foreground `connectedDevice`), `PinVault` (Keystore AES-GCM + BiometricPrompt), ro/en strings |

The bridge allow-list is not copied: `:core` packages `../spec/bridge/allowed-origins.properties` into its jar
(`md/moldsign/core/allowed-origins.properties`, loaded by `BridgeOriginPolicy.bundled()`).

## Build and test

Requirements: Android SDK at the path in `local.properties` (`sdk.dir=…`, gitignored, create it per machine)
and a JDK 17 installed. `gradle/gradle-daemon-jvm.properties` asks Gradle for a JDK 17 daemon, so
`./gradlew` also works when the default `java` is newer (Gradle 8.13 cannot run on JDK 25/26). If Gradle cannot
find one, set `JAVA_HOME` to a JDK 17.

```bash
cd android
./gradlew :core:test                    # vectors, card simulator, origin policy, HTTP server (JVM)
./gradlew :transport-usb:testDebugUnitTest  # CCID framing + descriptor parsing (JVM)
./gradlew :app:assembleDebug            # app/build/outputs/apk/debug/app-debug.apk
./gradlew :app:lintDebug
```

Toolchain: Gradle 8.13, AGP 8.10.1, Kotlin 2.1.0 (Compose compiler plugin 2.1.0), Compose BOM 2026.03.01
(Material 3 1.4.0), minSdk 26, compile/target SDK 36. Versions are in `gradle/libs.versions.toml`.

## What the tests cover

`spec/vectors/card-crypto.json` (all byte-for-byte): constants, KDF, EXTERNAL AUTHENTICATE ciphertext + CMAC,
response decode (CMAC + challenge), session keys, the IV for `ssc_initial`, **every** `sm.wrap` case from a
fresh channel, `sm.unwrap`, all three NIST CMAC cases (including the empty message), ISO 9797 padding, DigestInfo.

`CosmoXCardTest` drives `authenticate()`, `readCertificate()`, `verifyPin()` and `sign()` against a simulated
card that keeps its own SSC and checks every command MAC. It also checks GET RESPONSE chaining, Le=00, and the
mapping 63Cx → `WrongPin`, 6983 → `PinBlocked`, 6985 → `CardStateStuck`, 6988 → `SmOutOfSync`.
`BridgeOriginPolicyTest` / `BridgeServerTest` cover the allow-list, the CORS + `Access-Control-Allow-Private-Network`
preflight, 403 without CORS headers, and a real-socket round trip.

## Real vs stub

| Area | Status |
|---|---|
| Crypto, secure messaging, card flow (`CosmoXCard`) | **Real**: port of `Card.swift` / `SecureChannel.swift`, vector-tested; never run against a physical card from Android yet |
| `CardSigningService.certificate()` / `signDigestInfo()` | **Real**: process-wide card lock, progress steps, consent callback |
| CCID transport + reader monitor | **Real code, unverified on hardware** (AND-02, AND-03) |
| `BridgeOriginPolicy` + `BridgeServer` (HTTP 18480, OPTIONS/CORS/PNA, `GET /certificates` → empty list) | **Real**; signing routes return 501 (AND-04) |
| `BridgeService` foreground service + ongoing notification with **Oprește** | **Skeleton** (AND-04/05/08) |
| `PinVault` | **Implemented, not wired into the flow** (AND-06) |
| PAdES, XAdES, TSA/OCSP/CRL, validator | **Stubs** that throw `NotImplementedError` (AND-01) |
| SAF save of `<name>-semnat.<ext>`, share target | TODO (AND-07) |
| NFC `IsoDep` | not started (AND-09) |

The TODO markers in the code: `TODO(AND-01)` formats/trust/validator · `TODO(AND-02)` interrupt-endpoint
NotifySlotChange instead of polling, T=1 TPDU readers, verify the power-cycle reset · `TODO(AND-03)` the bit4id
VID/PID · `TODO(AND-04)` TLS 18443, signing routes, certificate list, FGS prerequisite · `TODO(AND-05)` background
consent notification · `TODO(AND-06)` PinVault wiring, paste blocking · `TODO(AND-07)` SAF output ·
`TODO(AND-08)` Chrome Local Network Access · `TODO(AND-10)` R8/signing.

## Where the port differs from the Swift reference (on purpose)

1. **CMAC of an empty message** follows RFC 4493. `cpcsc.c` writes `M_last[16]` out of bounds for it. The card
   protocol never MACs an empty message, so card-facing output is identical.
2. **`readBinary` unpads once.** `Card.swift` calls `iso9797Unpad` again on data `SecureChannel.unwrap` has already
   unpadded, which truncates any 128-byte certificate chunk ending in `00` or `80`. The port appends the unwrapped
   data as is, so output is the same whenever the reference is correct. The simulator test has such chunks.
   **Fix the Swift side too** (then the two agree in every case).
3. **63Cx maps to `WrongPin` only on VERIFY.** Elsewhere it stays an `UnexpectedStatus`, so an EXTERNAL
   AUTHENTICATE 63Cx can never delete a stored PIN.

Kept faithful even though they look odd: `authenticate()` ignores the SW of the plain SELECT MF (Swift re-checks the
AID's SW there), the SELECT EF 0001 SW is unchecked, and a response without tag `8E` is not MAC-checked.

## On-device checklist (not yet done)

- miniLector EVO over USB-C OTG: enumerates, `device_filter.xml` launches the app, permission dialog, `GetSlotStatus`.
- `dwFeatures` reports short-APDU exchange (else the transport refuses the reader).
- Insert card → automatic PIN-less certificate read (one attempt per insertion, never retried) → holder name.
- `BridgeService` starts on API 34+ (FGS `connectedDevice` prerequisite), Chrome reaches `http://127.0.0.1:18480/certificates` from msign.gov.md.
- Never test with the real PIN in automated runs; a wrong PIN burns the retry counter (R-07).
