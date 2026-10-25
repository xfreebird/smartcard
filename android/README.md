# eSemnBun for Android

The public name is **eSemnBun** (docs/10 §0.2b, UX-12): launcher label, home title, bridge notification, About, and
the packaged files `eSemnBun-<version>.apk` / `.aab` (`scripts/package-android.sh`; without a release key they keep a
`-debugsigned` / `-unsigned` suffix). The codename stays in code: applicationId and packages `md.moldsign.*`, module
names, `Theme.MoldSign`, DataStore / Keystore aliases. "MoldSign" also stays where it means the vendor (the STISC
suite, the bridge protocol).

Gradle project for the Android port (PLAN.md **F-12**, then the **AND-\*** items). It follows the
contracts in [`docs/09-architecture.md`](../docs/09-architecture.md) (layers, `ApduTransport`,
`CosmoXCard` flow, error taxonomy, PinVault, bridge origin policy) and the screen spec in
[`docs/10-design-system.md`](../docs/10-design-system.md) §4.5. The Swift `MoldSignKit` is the reference;
this is a line-by-line port gated by [`spec/vectors/card-crypto.json`](../spec/vectors/card-crypto.json).

## Modules

| Module | Kind | Package | Contents |
|---|---|---|---|
| `:core` | Kotlin/JVM library, no Android deps | `md.moldsign.core` | `Hex`, `Aes` (javax.crypto ECB/CBC, NoPadding), `Cmac` (RFC 4493), `Iso9797`, `Sha`, `DigestInfo`, `SecureChannel`, `CosmoXCard` (incl. the identity guard), `ApduTransport`, `CardError` (incl. `CardChanged`), `BridgeOriginPolicy`, `BridgeServer` (loopback HTTP/1.1), `SigningService` / `CardSigningService` (per-reader sessions), `Wallet.kt` (`ReaderSlot`, `CardGenerations`, `WalletState`, `StatusLight`), models, and stubs for `PadesSigner`, `XadesSigner`, `TrustServices`, `Validator` |
| `:transport-usb` | Android library | `md.moldsign.transport.usb` | `Ccid` (pure framing + class-descriptor parser), `CcidTransport : ApduTransport` over USB bulk endpoints, `UsbReaderMonitor` (every attached reader: attach/detach, permission, slot polling, card generations → `StateFlow<List<ReaderSlot>>`; sessions routed by reader id), `res/xml/device_filter.xml` |
| `:app` | Compose + Material 3 app | `md.moldsign.app` | Design v2 (docs/10 §0): theme from the design tokens (dynamic color, brand fallback), edge-to-edge `Scaffold` with `TopAppBar` + status light chip + `NavigationBar` (Semnează · Verifică · Browser · Card), card wallet, document list + FormatChip, `ExtendedFloatingActionButton`, PIN `ModalBottomSheet`, ConnectionGuide, `BridgeService` (foreground `connectedDevice`, notification = status light), `PinVault` (Keystore AES-GCM + BiometricPrompt), ro/en strings, debug-only demo mode |

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

## Design v2/v3: card wallet and status light (UX-01, UX-02, UX-05, UX-09…UX-12)

* **Several readers, several cards** (docs/09 §3.1b). `UsbReaderMonitor` keeps one slot per attached CCID reader
  (USB device path = reader id; identical readers get a " #2" suffix). `CardGenerations` gives each inserted card a
  generation that changes when a card is present after it was absent or the reader is (re)attached with a card.
  `AppContainer` reconciles its `WalletState` with every snapshot (same rules as the Apple `AppModel.apply`): an
  unchanged generation keeps the certificate; a new card or generation is read once, PIN-less; "Recitește cardul"
  forgets and re-reads all of them. A late read for a replaced card is dropped (generation check).
* **Signing uses the selected card.** `SigningService` calls take `reader` (routes the CCID session) and
  `expectedCertificateSha1`. **Identity guard**: the session reads EF 0001 and compares SHA-1 before the PIN sheet
  opens and before VERIFY (`CosmoXCard.checkIdentity` / `prepareForSigning`); a different card throws
  `CardError.CardChanged`, the app re-reads the wallet and says "Cardul din cititor s-a schimbat…". Several
  documents share one PIN entry (`BatchConsent`); a wrong PIN still stops at the first one.
* **Card face, v3** (`ui/components/IdCardFace.kt`, docs/10 §0.2b UX-09): a stylized illustration of the Moldovan
  identity card drawn in one `drawWithCache` pass (Canvas + `TextMeasurer`, every size a fraction of the card width):
  pastel paper gradient, 12 guilloche sine waves (hue rotated ±20° by the first certificate SHA-1 byte) and a rosette,
  bilingual "REPUBLICA MOLDOVA / REPUBLIC OF MOLDOVA" and "CARTE DE IDENTITATE / IDENTITY CARD" (scaled to fit left of
  the chip), a **neutral** shield outline (never the coat of arms), the gold chip top-right, a grey portrait frame with
  a silhouette, fields Numele/Surname, Prenumele/Given name(s), Valabil până la/Valid until (`dd MM yyyy`, certificate
  notAfter) and Emitent/Issuer, and a status strip (green "Pregătit pentru semnare", amber "Se citește cardul…" with
  placeholder bars, red problem text; reader caption on large sizes). Surname / given names come from the
  certificate's SN / GN (`CertificateSummary.nameParts`), else the CN split at the first space (first word = surname).
  No photo, no document number, no MRZ, no IDNP. Fixed colors in light and dark, hairline border and shadow.
* **Card + selector = one component** (`ui/components/CardWallet.kt`, UX-10 revised): nothing outside the card (no
  dots, picker, menu or carousel). Collapsed it shows only the selected card. With > 1 card a round disclosure button
  sits inside the card at (0.935 W, 0.50 H), diameter 0.085 W (85 % white + hairline, 48 dp touch target), chevron
  pointing right; field values stop at 0.88 W. Tapping it expands the component in place into a `Column` of every
  card, same size, 11 dp apart, in reader order (each card is an `AnimatedVisibility`, 250 ms; Compose follows
  "Remove animations"); the chevron turns down and the selected card keeps the accent ring while its status strip reads
  "✓ Folosit pentru semnare" in brand blue `#2350D8` (a check instead of the dot; no separate badge; a selected card
  still reading or in error keeps that line). Tap a card → it becomes the signing card and the list collapses; the disclosure, the selected card,
  Back or Escape collapse without change. Long press: "Recitește cardul" + "Semnează cu {holder}" for the other cards.
  ←/→ on the collapsed card switch cards. TalkBack: the collapsed card is one element "{holder}, card de identitate,
  valabil până la …, {i} din {n}" with "Cardul următor" / "Cardul anterior" / "Recitește cardul"; the disclosure is
  "Alege cardul ({n} carduri)" with expand/collapse actions and state; expanded cards are buttons "Semnează cu
  {holder}", the selected one marked "selectat". Same component on Semnează, Card and Browser; a tap on the collapsed
  card opens the Card screen from Semnează / Browser. Empty states stay cards: connector illustration (no reader),
  USB access, dashed "Introdu cardul", red reader error.
* **Documents and formats.** Empty: the large "Alege documentele" tile; with documents, the list and a smaller
  "Adaugă documente" tile under it. Every row has a format chip: a PDF offers PAdES-T (default), XAdES-BES, XAdES-T
  and XAdES-C (a detached `.xml` over the PDF bytes); other files offer XAdES only. Each option shows the file it will
  produce (`SignFormat.outputName`: `<name>-semnat.pdf|xml`). The chosen format goes to the core unchanged
  (`SigningService.sign(input, format, …)`; PAdES on a non-PDF is refused before the card is touched).
* **Sign FAB.** The ExtendedFAB "Semnează" is shown only with documents and a ready, idle selected card; otherwise the
  Semnează screen says why under the list (no accent button that cannot work).
* **Activitate** (5th destination, `ActivityLog` + core `ActivityHistory`): signed / verified documents (shown only
  while the file is still reachable: persisted read permission + the document still answers a query, re-checked on
  start and whenever the screen resumes) and browser requests (always kept), newest first, max 100. "Golește lista"
  asks for confirmation. Pickers take a persistable read permission so entries survive restarts.
  TODO(AND-07): point entries at the saved `<name>-semnat.<ext>`; TODO(AND-04): log bridge requests.
* **Status light** (`StatusLight` in core, `StatusLightChip` in the top app bar): green = card ready, amber = reader
  only / reading / USB access, blue = signing (pulses), red = error, none = idle; chip text + full accessibility label.
* **Tray = bridge notification, two states** (`WalletState.tray()`, UX-11): green accent + "Card conectat · {holder}"
  while any card is inserted and not in error (reading, ready or signing); gray + "Niciun card conectat" (or the
  error's one-liner) otherwise. Strings for a Quick Settings tile are ready (`qs_tile_label`, `tray_*`).

### Demo mode (debug builds only)

`src/debug/kotlin/md/moldsign/app/DemoMode.kt` injects fake readers and cards (fictional holders, made-up SHA-1s); `src/release` compiles a no-op, so
neither the fake data nor the intent extra exist in release builds.

```bash
./gradlew :app:installDebug
adb shell am start -n md.moldsign.app/.MainActivity --es demo cards   # 2 ready cards
# other scenarios: one · reading · error · empty · permission · noreader
# every scenario also seeds a fictional activity list (files in the app cache, one missing → pruned)
```

The demo stops following the USB monitor until the process restarts; "Recitește cardul" re-reads the fake cards.

## What the tests cover

`spec/vectors/card-crypto.json` (all byte-for-byte): constants, KDF, EXTERNAL AUTHENTICATE ciphertext + CMAC,
response decode (CMAC + challenge), session keys, the IV for `ssc_initial`, **every** `sm.wrap` case from a
fresh channel, `sm.unwrap`, all three NIST CMAC cases (including the empty message), ISO 9797 padding, DigestInfo.

`CosmoXCardTest` drives `authenticate()`, `readCertificate()`, `verifyPin()` and `sign()` against a simulated
card that keeps its own SSC and checks every command MAC. It also checks GET RESPONSE chaining, Le=00, and the
mapping 63Cx → `WrongPin`, 6983 → `PinBlocked`, 6985 → `CardStateStuck`, 6988 → `SmOutOfSync`.
`IdentityGuardTest` serves two different (public, CA) certificates from the simulator as "card A" and "card B": a
swapped card fails with `CardChanged` before VERIFY (no `SM:20` in the APDU log, retry counter untouched, consent never
asked); the matching card signs; sessions go to the requested reader. `WalletStateTest` covers generations, one read
per insertion, late reads for replaced cards, selection fallback, re-read and the status light.
`BridgeOriginPolicyTest` / `BridgeServerTest` cover the allow-list, the CORS + `Access-Control-Allow-Private-Network`
preflight, 403 without CORS headers, and a real-socket round trip.

## Real vs stub

| Area | Status |
|---|---|
| Crypto, secure messaging, card flow (`CosmoXCard`) | **Real**: port of `Card.swift` / `SecureChannel.swift`, vector-tested; never run against a physical card from Android yet |
| `CardSigningService.certificate()` / `signDigestInfo()` | **Real**: process-wide card lock, progress steps, consent callback |
| CCID transport + reader monitor (several readers, card generations) | **Real code, unverified on hardware** (AND-02, AND-03) |
| Card wallet, status light, identity guard, per-reader signing | **Real**; wallet/light/guard logic unit-tested in `:core`, UI checked on the emulator with the demo mode |
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
`TODO(AND-08)` Chrome Local Network Access · `TODO(AND-10)` R8/signing · `TODO(UX-01)` Quick Settings tile.

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
- Two readers on a USB-C hub: both cards in the wallet, the selected one signs; swap a card while the PIN sheet is
  open → `CardChanged`, no PIN sent; remove + re-insert within the 1 s poll is not detected (TODO(AND-02) interrupt endpoint).
- `BridgeService` starts on API 34+ (FGS `connectedDevice` prerequisite), Chrome reaches `http://127.0.0.1:18480/certificates` from msign.gov.md.
- Never test with the real PIN in automated runs; a wrong PIN burns the retry counter (R-07).
