# 09 — Cross-Platform Architecture

How the reverse-engineered core (docs 01–05) becomes four native apps. The plan and status
live in [`../PLAN.md`](../PLAN.md); this document is the **contract** every port follows.

## 1. Layers

```
┌──────────────────────────────────────────────────────────────────────────┐
│ UI          SwiftUI (macOS menu bar + window, iOS) · Compose · WinUI 3   │
├──────────────────────────────────────────────────────────────────────────┤
│ App services  SigningService · ReaderMonitor · PinVault · BridgeHost ·   │
│               ActivityLog            (platform code, same responsibilities)│
├──────────────────────────────────────────────────────────────────────────┤
│ Core          CosmoXCard · SecureChannel · Crypto(AES/CMAC/ISO9797) ·     │
│               PAdES · XAdES · TrustServices(TSA/OCSP/CRL) · Validator ·   │
│               BridgeProtocol (routes, DTOs, origin policy)                │
├──────────────────────────────────────────────────────────────────────────┤
│ CardTransport PC/SC (macOS) · TKSmartCard (iOS/macOS) · USB-CCID         │
│               (Android) · WinSCard (Windows) · NFC (research)            │
└──────────────────────────────────────────────────────────────────────────┘
```

Rules:

* **Core has no UI, no platform credential store, no process spawning.** Network goes through
  `TrustServices`, a **minimal plain-HTTP/1.1 client** (Swift: `NWConnection`; Kotlin: `Socket`;
  C#: `TcpClient` or `HttpClient` without HSTS). Do **not** use URLSession for the PKI endpoints: it
  HSTS-upgrades `http://tsp.pki.gov.md` to https, where the TSA drops the connection. Bypass the system proxy, as `curl` did (X-08).
* **Core is synchronous** today (it mirrors the proven Swift code). Callers run it off the UI
  thread. Async APIs are X-04.
* **One card operation at a time.** `SigningService` owns a process-wide lock. UI and bridge
  requests queue behind it, because two interleaved secure-messaging sessions desync the SSC (`6988`).
* **Swift is the reference.** Kotlin and C# ports are line-by-line translations first and
  idiomatic second. Any behavior change lands in Swift first, then gets a vector in
  `spec/vectors/`, then gets ported.

## 2. Module map per language

| Concern | Swift (`swift/MoldSignKit/Sources/MoldSignKit`) | Kotlin (`android/core`) | C# (`windows/src/MoldSign.Core`) |
|---|---|---|---|
| Transport | `CardTransport`, `PCSCTransport`, `TKSmartCardTransport` | `ApduTransport`; `android/transport-usb`: `CcidTransport` | `ICardTransport`, `WinSCardTransport` |
| Card driver | `CosmoXCard` | `CosmoXCard` | `CosmoXCard` |
| Secure messaging | `SecureChannel` | `SecureChannel` | `SecureChannel` |
| Primitives | `AES` (+ `CPCSC` C shim) | `Aes` (javax.crypto) + `Cmac` | `AesPrimitives` (System.Security.Cryptography) + `Cmac` |
| PAdES | `PAdESSigner` | `PadesSigner` (AND-01) | `PadesSigner` (WIN-01) |
| XAdES | `XAdESSigner` | `XadesSigner` (AND-01) | `XadesSigner` (WIN-01) |
| TSA/OCSP/CRL | `TrustServices` | `TrustServices` | `TrustServices` |
| Validation | `Validator` | `Validator` | `Validator` |
| Bridge | `MoldSignServer` + `BridgeOriginPolicy` | `BridgeServer` | `BridgeServer` (Kestrel) |
| Facade | `SigningService` | `SigningService` | `SigningService` |
| CLI | `esemnbun` (macOS **and Linux**, spec/cli.md) | — | `MoldSign.Cli` (Windows only) |
| Apps | `apple/eSemnBun.xcodeproj` → `Apps/{Shared,macOS,iOS}`; `linux/` GNOME (GTK4/libadwaita C API) | `android/app` | `windows/src/MoldSign.App` |
| Linux backends | `MOLDSIGN_PORTABLE`: OpenSSL (AES/CMAC/SHA/RSA/TLS), POSIX sockets, pcsc-lite | — | — |

## 3. Contracts

### 3.1 CardTransport

Raw APDU in → raw response **including SW1 SW2** out. No GET RESPONSE handling, because `CosmoXCard`
loops on `61xx` itself.

```swift
public protocol CardTransport: AnyObject {
    var readerName: String { get }
    func transmit(_ apdu: Data) throws -> Data
    func disconnect()
}
```
```kotlin
interface ApduTransport : java.io.Closeable {
    val readerName: String
    fun transmit(apdu: ByteArray): ByteArray
}
```
```csharp
public interface ICardTransport : IDisposable {
    string ReaderName { get; }
    byte[] Transmit(byte[] apdu);
}
```

Platform notes:

* **PC/SC (macOS, Windows):** share mode SHARED, protocols T0|T1, transmit with T=1 PCI.
  `SCardReconnect(SCARD_RESET_CARD)` on connect is documented as required (docs/01). It needs
  on-device verification before it becomes the default (MAC-12).
* **CryptoTokenKit (iOS, macOS alt):** `TKSmartCardSlotManager.default` → `slot(named:)` →
  `makeSmartCard()` → `beginSession` → `transmit(_:reply:)` (returns data + SW). On macOS the
  app needs the `com.apple.security.smartcard` entitlement, or `default` is nil. On iOS it is always
  available; USB CCID readers work via USB-C and the Lightning camera adapters (IOS-01).
* **Android USB CCID:** claim the CCID interface (class `0x0B`), bulk OUT/IN + interrupt IN.
  `PC_to_RDR_IccPowerOn` (0x62) → ATR; `PC_to_RDR_XfrBlock` (0x6F) per APDU (short APDUs,
  T=1 handled by the reader at APDU level for the miniLector); `RDR_to_PC_NotifySlotChange`
  (0x50) on the interrupt endpoint for card insert/remove. Sequence numbers wrap at 255.
* **NFC (research R-03):** iOS 26 `TKSmartCardSlotManager.createNFCSlot(message:)` with
  `com.apple.developer.nfc.readersession.iso7816.select-identifiers` = the IAS AID +
  Generic ADF; Android `IsoDep`. Only viable if the card exposes IAS/ECC contactless.

### 3.1b Several cards, card changes (all ports)

* **Several eID cards can be connected at once** (one per reader). Every card operation names its reader;
  `listCards()` = every reader holding a card + its PIN-less certificate; `reader(forCertificateSHA1:)` routes a
  signature to the card that holds a given certificate. The bridge's `/certificates` lists **all** cards.
* **Identity guard before VERIFY (mandatory).** Read the card's certificate first and compare its SHA-1 with
  the card the PIN / consent / selection is for. Mismatch → `cardChanged`, **before** the PIN goes out. A stored
  PIN looked up for a displayed card must never reach a different (swapped) card, because it would burn a retry
  there. Order: SELECT MF → ADF → read EF 0001 → compare → SELECT ADF → VERIFY → MSE → INTERNAL AUTHENTICATE.
* **Card-change detection.** Each inserted card gets a generation per reader. Apple: slot-state KVO plus the
  `TKSmartCard.valid` flag of the inserted card (drops on removal even when the state changes coalesce).
  Linux/Windows PC/SC: the event counter in the upper 16 bits of `dwEventState` plus presence transitions.
  A new generation drops the cached certificate and re-reads it.
* **Names for display** are decoded DirectoryStrings (UTF8/BMP/Teletex…): "Mîndru", never `M\C3\AEndru`. The
  `\XX` escapes are only for the XAdES `X509IssuerName` (vendor byte-exactness).

### 3.2 CosmoXCard (identical flow in every port)

```
authenticate():   SELECT IAS AID → SELECT MF → read D003 (serial) → read D004 (seed)
                  → Kenc/Kmac = SHA256(seed‖serial‖MK‖0000000{2,3})
                  → MSE SET 0022C1A4… → GET CHALLENGE → EXTERNAL AUTH (96 B)
                  → verify CMAC, decrypt → K_ICC → sessENC/sessMAC, SSC
selectMF()        SM
selectGenericADF() SM, P2=04, Le=00
readCertificate() SELECT MF → ADF → EF 0001, READ BINARY 128-byte chunks, full X.509 (outer SEQ)
verifyPIN(pin)    SM VERIFY ref 03; 63Cx → wrongPin(remaining x); 6983 → pinBlocked
sign(digestInfo)  SM MSE SET 41A4 800102840181 → INTERNAL AUTHENTICATE → 512-byte RSA-4096
```

The golden bytes are in `spec/vectors/card-crypto.json`. Every port's unit tests load that file
(relative path from the repo root) and must pass all cases.

### 3.3 Error taxonomy (UI copy keys in parentheses)

| Case | Trigger | UI behavior |
|---|---|---|
| `noReader` | no PC/SC reader, no slot, no USB device | "Conectează cititorul" (`error.noReader`) |
| `noCard` | reader empty / connect fails | "Introdu cardul" (`error.noCard`) |
| `wrongPin(remaining)` | `63Cx` | delete stored PIN, show remaining, **never auto-retry** |
| `pinBlocked` | `6983` | stop, explain PUK/unblock at CEV |
| `cardStateStuck` | `6985` | "Scoate și reintrodu cardul". Do not retry auth |
| `smOutOfSync` | `6988` / MAC failure | drop session, reconnect once |
| `network(service)` | TSA/OCSP/CRL failure | retry button; PAdES-B fallback is **not** offered (portal requires T) |
| `format(message)` | PDF/XML parse errors | show file name + message |
| `cancelled` | user dismissed PIN/consent | silent |

### 3.4 SigningService (app-facing facade)

```
readerState: stream<ReaderState>      // noReader | empty(reader) | card(reader, holder?) | busy | error
certificate(): CertificateSummary     // CN, issuer, validity, serial, sha1 — no PIN
signPDF(input, output, consent) → SignResult
signXAdES(files, format BES|T|C, type detached|enveloping, output, consent) → SignResult
verify(file, detachedDocs?) → [Report]
progress: stream<Step>                // connecting, authenticating, readingCertificate,
                                      // verifyingPin, signing, timestamping, revocation, writing, done
```

`consent` is a callback that returns either a PIN or *cancelled*. It is the single place where
the platform shows UI (PIN sheet, biometric prompt for the stored PIN, or the bridge consent sheet).

### 3.5 PinVault

* Keyed by **card certificate SHA-1** (a different card never receives another card's PIN).
* `save(pin, certId)`, `load(certId, reason) → pin?` (biometric/passcode gated), `delete(certId)`.
* Delete on `wrongPin`. Never persisted unencrypted; never logged.

| Platform | Storage | Gate |
|---|---|---|
| macOS | Keychain generic password, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | `LAContext.evaluatePolicy(.deviceOwnerAuthentication)` before every read; `SecAccessControl(.userPresence)` when the data-protection keychain is available (signed builds) |
| iOS | Keychain + `SecAccessControl(.userPresence)` | `LAContext` (Face ID / Touch ID, passcode fallback) |
| Android | AES-GCM key in Android Keystore (`setUserAuthenticationRequired(true)`), ciphertext in DataStore | `BiometricPrompt` with `CryptoObject` |
| Windows | `PasswordVault` (Credential Locker) | `UserConsentVerifier.RequestVerificationAsync` before read |

### 3.6 Bridge (MoldSign Server protocol)

Protocol details: [04-server-replica.md](04-server-replica.md). Additions every platform must implement:

1. **Origin policy (SEC-01)** from `spec/bridge/allowed-origins.properties`. Read *all* values;
   the file has a duplicate `gov` key, and Java keeps only the last one, but `*.gov.md` covers it anyway.
   Convert each value to a regex the way the vendor does (`.` → `\.`, `?` → `.?`, `*` → `.*`) and require a
   full match of the `Origin` header. Accept `moldSign: DesktopSuiteClient` **only when `Origin`
   is absent**. Anything else gets `403` and no CORS headers.
2. **Consent (SEC-02)** before any operation that touches the private key. `GET /certificates`
   is allowed without consent (it only reads the public certificate).
3. **Loopback only (SEC-03):** bind `127.0.0.1`; cap request bodies (64 MB); one signing at a time.
4. **Private Network Access:** answer preflights with `Access-Control-Allow-Private-Network: true`.
5. TLS identity: `localhost.cts.md` p12, loaded from the installed vendor suite when present,
   else from the app bundle (D-03).
6. **Result polls are long-polls.** Hold `GET …/PKCS11/{session}/…` until the session finishes, then `200`
   with the result, or `400` + header `error: <message>`. Never answer "not ready" with 303: the portal sends
   exactly one GET per document, and browsers stop after 20 redirects. That bug shipped in macOS 0.1.0.
7. Honour `signatureType`: `Embedded` = enveloping XAdES (the portal's Xml/Text contents), `Detached` = detached.

Per-platform hosting:

| Platform | Listener | Lifetime |
|---|---|---|
| macOS | `NWListener` 18480 (http) + 18443 (TLS) | menu-bar agent lifetime |
| iOS | `NWListener` | only while foreground (in-app browser, Split View), R-01 |
| Android | `ServerSocket` / `SSLServerSocket` (PKCS12 `KeyManagerFactory`) | foreground service `connectedDevice` while the reader is attached or the bridge toggle is on |
| Windows | Kestrel (`ListenLocalhost`, `UseHttps(pfx)`) | tray app lifetime |

### 3.7 ReaderMonitor

| Platform | Mechanism |
|---|---|
| macOS / iOS | KVO on `TKSmartCardSlotManager.default.slotNames`; per slot KVO on `state` (`.empty`, `.probing`, `.validCard`, `.muteCard`, `.missing`) |
| Android | `UsbManager.ACTION_USB_DEVICE_ATTACHED/DETACHED` broadcasts + CCID `NotifySlotChange` / `GetSlotStatus` polling |
| Windows | `DeviceWatcher` on `SmartCardReader.GetDeviceSelector(SmartCardReaderKind.Any)`; `SmartCardReader.CardAdded/CardRemoved` |

On `card present` the monitor triggers a PIN-less `certificate()` read so the UI can greet the
holder by name. That read runs the full mutual auth (it needs SM), so it also goes through the card lock.

## 4. Testing strategy

| Level | What | Where |
|---|---|---|
| Vectors | `spec/vectors/*.json`: KDF, external auth, session keys, SM wrap/unwrap, CMAC, padding, DigestInfo | all three test suites |
| Structural | PDF incremental-update shape, counter-signing, XAdES c14n | Swift today (`apple/Tests`), ported with the formats |
| Network (opt-in) | live TSA token, CRL, OCSP against public MD PKI | `MSIGN_NETWORK_TESTS=1` |
| Interop | iText/BouncyCastle `Probe.java`, JDK XMLDSig `Probe3.java`, portal upload | manual (docs/05, 07) |
| On-device | card sign with a test PIN entered by a human, never stored in the repo | manual checklist per release |

## 5. Why not one shared core?

Considered and rejected for now (D-01):

* **Swift everywhere** (Swift SDK for Android, Swift on Windows): keeps one core, but the Android
  side would need JNI glue and the toolchains are young. Debugging smart-card I/O across FFI is painful.
  (Swift *is* used on Linux, for the CLI only, where it is native and the core ports with modest
  `#if` work: LNX-01…05.)
* **Rust core with UniFFI:** one core and good bindings, but it means rewriting the proven
  Swift code and throwing away the reference implementation.
* **Kotlin Multiplatform:** good for Android and iOS, awkward for a native Windows tray app.

The core is ~3.5k lines. Translating it twice, with byte-exact vectors as the gate, costs less than
an FFI layer and keeps every app 100% native. Revisit if the formats grow (ASiC, encryption).
