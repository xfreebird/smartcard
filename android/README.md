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
| `:core` | Kotlin/JVM library, no Android deps | `md.moldsign.core` | `Hex`, `Aes` (javax.crypto ECB/CBC, NoPadding), `Cmac` (RFC 4493), `Iso9797`, `Sha`, `DigestInfo`, `SecureChannel`, `CosmoXCard` (incl. the identity guard), `ApduTransport`, `CardError` (incl. `CardChanged`), `BridgeOriginPolicy`, `BridgeServer` (loopback HTTP/1.1), `SigningService` / `CardSigningService` (per-reader sessions), `Wallet.kt` (`ReaderSlot`, `CardGenerations`, `WalletState`, `StatusLight`), models, the format signers (`PadesCmsSigner`, `XadesDocumentSigner`), `MdTrustServices` (TSA / CRL / OCSP over HTTP, one retry for the gateways' idle 502s), `OfflineValidator` + `Verdict`, and the browser bridge (`BridgeTls`, `SigningBridgeRoutes`) |
| `:transport-usb` | Android library | `md.moldsign.transport.usb` | `Ccid` (pure framing + class-descriptor parser), `CcidTransport : ApduTransport` over USB bulk endpoints, `UsbReaderMonitor` (every attached reader: attach/detach, permission, slot polling, card generations → `StateFlow<List<ReaderSlot>>`; sessions routed by reader id), `res/xml/device_filter.xml` |
| `:app` | Compose + Material 3 app | `md.moldsign.app` | Design v2 (docs/10 §0): theme from the design tokens (dynamic color, brand fallback), edge-to-edge `Scaffold` with `TopAppBar` + status light chip + `NavigationBar` (Semnează · Verifică · Browser · Card), card wallet, document list + FormatChip, `ExtendedFloatingActionButton`, keyboard-aware PIN dialog, ConnectionGuide, `BridgeService` (foreground `connectedDevice`, notification = status light), `PinVault` (Keystore AES-GCM + BiometricPrompt), ro/en/ru keyed resources, debug-only demo mode |

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

### Optimized releases and edge-to-edge

Release builds enable R8 shrinking, optimization and obfuscation using
`proguard-android-optimize.txt`, plus resource shrinking. Debug stays unminified. AndroidX/Compose
consumer rules cover their dynamic entry points; avoid package-wide keep rules that defeat optimization.
The bridge allow-list and TLS identity use absolute classpath paths to survive class/package renaming.

Build the optimized artifacts with `./gradlew :app:assembleRelease :app:bundleRelease :app:lintRelease`.
Keep `app/build/outputs/mapping/release/mapping.txt` with the exact build for crash retracing.
For distribution use `../scripts/package-android.sh` and the existing upload key. Before rollout,
exercise startup, saved PIN/biometrics, reader/NFC signing, browser authentication, PDF stamps,
file protection, document sharing and the widget in the optimized Release APK. Debug checks alone
do not prove R8 compatibility. Inspect the uploaded AAB's DEX percentages in Play Console; the source
configuration alone does not establish that the minimum scores have been met.

`MainActivity` already calls `enableEdgeToEdge()` and uses `adjustResize`. The root Material 3
Scaffold explicitly uses safe-drawing insets and applies/consumes its content padding once, shared
by the rail and destinations. Check Android 14, 15 and 16 with gesture and three-button navigation,
portrait/landscape, a display cutout, keyboard input and phone/tablet layouts before rollout.

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
  the chip), a **neutral** shield outline (never the coat of arms), the gold chip at the right-center, a grey portrait frame with
  a silhouette, fields Numele/Surname, Prenumele/Given name(s), Valabil până la/Valid until (`dd MM yyyy`, certificate
  notAfter) and Emitent/Issuer, and a status strip (green "Pregătit pentru semnare", amber "Se citește cardul…" with
  placeholder bars, red problem text; reader caption on large sizes). Surname / given names come from the
  certificate's SN / GN (`CertificateSummary.nameParts`), else the CN split at the first space (first word = surname).
  No photo, no document number, no MRZ, no IDNP. Fixed colors in light and dark, hairline border and shadow.
* **Horizontal wallet carousel (ADJ-02)**: a native Compose pager keeps the selected card centered, shows adjacent-card peeks and commits selection when a swipe settles. Keyboard and TalkBack selection actions use the same reader identity. A numbered position label replaces the old vertical disclosure list. Empty states remain native connection cards. The card uses a golden-ratio landscape aspect and the avatar frame uses3:5 width:height; the chip is vertically centered on the right and text reserves its space.

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
  Browser signatures add a "Semnat · PAdES-T" / "Eșuat" entry named after the site.
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
preflight, 403 without CORS headers, and a real-socket round trip. `SigningBridgeRoutesTest` covers the portal flow
(certificate list, `201` + absolute `Location` + empty body, the long-poll, PIN sessions per origin and card, XAdES
with the requested digest) and `BridgeTlsTest` the HTTPS listener with the vendor identity.
`XadesDocumentSignerTest` validates BES / T / C / enveloping output with the JDK's XML-DSig engine (an independent
canonicalizer); `OfflineValidatorTest` signs with a software key and a test CA / root, then checks valid, tampered,
re-timestamped, counter-signed and detached-without-document cases; `MdTrustServicesTest` runs the PKI client against a
local server (OCSP request, the one retry, unusable answers).

## Real vs stub

| Area | Status |
|---|---|
| Crypto, secure messaging, card flow (`CosmoXCard`) | **Real**: port of `Card.swift` / `SecureChannel.swift`, vector-tested; never run against a physical card from Android yet |
| `CardSigningService.certificate()` / `signDigestInfo()` | **Real**: process-wide card lock, progress steps, consent callback |
| CCID transport + reader monitor (several readers, card generations) | **Real code, unverified on hardware** (AND-02, AND-03) |
| Card wallet, status light, identity guard, per-reader signing | **Real**; wallet/light/guard logic unit-tested in `:core`, UI checked on the emulator with the demo mode |
| `BridgeOriginPolicy` + `BridgeServer` (HTTP 18480 + HTTPS 18443 with the vendor `localhost.cts.md` identity, OPTIONS/CORS/PNA) | **Real**, verified on a phone with curl (valid public chain) |
| `SigningBridgeRoutes`: `GET /certificates`, async `POST /sign/data` + long-poll, PIN sessions | **Real for PAdES-T** (signed with the real card from a simulated portal request, Swift validator + iText: valid); XAdES content answers an error until ported; `/sign/pdf`, `/sign/file`, verify routes answer 501 (file paths of the desktop suite) |
| `BridgeService` foreground service, ongoing notification with **Oprește**, consent heads-up notification | **Real** (AND-04/05); signed from msign.gov.md in Chrome on a phone 2026-10-25; the Local Network Access prompt still to document (AND-08) |
| `PinVault` | Wired into local reader/NFC signing: biometric retrieval, save after success, common certificate account and disconnected-card deletion (AND-06). |
| PAdES-T (`PadesCmsSigner`), MDQTSA client (`MdTrustServices.timestamp`), CRL GET, chain certs (`ChainCerts`) | **Real** (AND-01): cross-checked with `openssl cms -verify`, the Swift validator and iText 9 + BouncyCastle (the portal's stack); **signed with the real card and PIN on a phone 2026-10-25** (Swift validator: valid, chain trusted; iText `verify()=true`) |
| XAdES BES/T/C (`XadesDocumentSigner`: detached or enveloping, SHA-256 or the portal's SHA-1), native OCSP request, CRL / OCSP metadata for XAdES-C | **Real** (AND-01): signatures validated by the JDK's XML-DSig engine, `Probe3` and the Swift validator; the OCSP request is byte-identical to `openssl ocsp`; live OCSP / CRL / MDQTSA answers parse (CRL number checked against openssl). A failing CRL / OCSP / TSA fails the signature (the Swift signer silently drops the reference). **Not yet signed with the real card on a phone** |
| `OfflineValidator`: PAdES (ByteRange, CMS, RSA, chain, time-stamp imprint) and XAdES (references, SignedInfo, chain, time-stamp imprint) | **Real** (AND-01), same verdicts as the Swift validator on card-signed PDFs; the Verify screen shows the verdict, the signature cards and an inline picker for a detached signature's document. It does not check revocation or the time-stamp token's own signature |
| Save of `<name>-semnat.<ext>` (`SignedFileStore`) | **Downloads/eSemnBun** via MediaStore (Android 10+; app Documents folder below); Activity rows offer Open / Share / Save as… (system save dialog); the app is a share target for PDFs and other files (AND-07, checked on a phone) |
| NFC `IsoDep` | Single-session signing implemented; physical Android PAdES-T signature and timestamp integrity verified on 2026-11-16 (AND-09). See [Android NFC](../docs/17-android-nfc.md). |

The TODO markers in the code: `TODO(AND-02)` interrupt-endpoint
NotifySlotChange instead of polling, PPS to a faster Fi/Di, verify the power-cycle reset · `TODO(AND-03)` the bit4id
VID/PID · `TODO(AND-04)` start/stop with the reader, FGS prerequisite · `TODO(AND-06)` saved-PIN hardware acceptance, paste blocking ·
`TODO(AND-08)` Chrome Local Network Access · `TODO(AND-10)` optimized Release runtime/Play validation · `TODO(UX-01)` Quick Settings tile.

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

## On-device checklist

- miniLector EVO over USB-C OTG: enumerates, permission dialog, `GetSlotStatus`: **done 2026-10-25** (Xiaomi
  22126RN91Y, Android 14, `adb` over Wi-Fi because the reader takes the only USB port). Still open: `device_filter.xml`
  launching the app on attach.
- The miniLector POCKET EVO is a **TPDU-level** CCID reader (`dwFeatures` 0x000100B6: auto ATR configuration, auto
  activation, no automatic parameter negotiation 0x40, 3 V only), not short-APDU as assumed. `CcidTransport` drives it with
  the host T=1 block layer (`T1`) after `PC_to_RDR_SetParameters` (protocol 1, LRC, BWI/CWI/IFSC from the ATR,
  default Fi/Di) and an IFSD negotiation to 254, the same as libccid. **Without SetParameters the reader stays in a
  T=0 default**: header-only commands "work", S/R blocks get an empty reply and every T=1 I-block gets `bError 0xFB`.
  Character-level readers are still refused.
- Insert card → automatic PIN-less certificate read → holder name: **done 2026-10-25** (mutual authentication and the
  1799-byte certificate over T=1, "Card ready"). Not yet: PIN + signature (WTX, long responses), PPS to a faster Fi/Di
  (now 9600 bps, so a certificate read takes a few seconds).
- Two readers on a USB-C hub: both cards in the wallet, the selected one signs; swap a card while the PIN sheet is
  open → `CardChanged`, no PIN sent; remove + re-insert within the 1 s poll is not detected (TODO(AND-02) interrupt endpoint).
- `BridgeService` starts on API 34+ (FGS `connectedDevice` prerequisite). Test without Chrome: `adb forward tcp:28443 tcp:18443` (the Mac app may hold 18443/18480), then `curl --resolve localhost.cts.md:28443:127.0.0.1 -H 'Origin: https://msign.gov.md' https://localhost.cts.md:28443/certificates`; a `POST /sign/data` shows the heads-up notification, tapping it opens the PIN sheet.
- Chrome on the phone: msign.gov.md → sign; `localhost.cts.md` resolves to 127.0.0.1, Chrome may ask for the Local Network Access permission (AND-08), the request shows as a heads-up notification.
- XAdES on the phone: Sign tab → pick a text or XML file → XAdES-T (or -BES / -C) → PIN; the `<name>-semnat.xml` lands in Downloads/eSemnBun. Check it on the Mac with `esemnbun verify <sig.xml> <folder with the original file>` or on the phone's Verify tab (a detached signature asks for its document). XAdES-C needs the network (CRL + OCSP + MDQTSA); the OCSP gateway can take 13 s on the first request after an idle spell.
- Verify tab: pick a signed PDF or XAdES → verdict and signature cards appear at once; flip a byte of the PDF → "Invalid signature".
- Never test with the real PIN in automated runs; a wrong PIN burns the retry counter (R-07).

## Tablets, architectures and batch signing (ADJ-13 / ADJ-14)

The activity supports rotation and resizable windows. Expanded windows use a native Material3 navigation rail
and split signing workspace; compact windows keep phone navigation. Card selection remains centered and bounded
in width, with explicit gutters. The layout responds to available window width rather than device model.

The universal APK includes ARM32 (`armeabi-v7a`), ARM64 (`arm64-v8a`), x86 and x86-64 native dependency slices.
Play App Bundles split these by ABI. `python3 scripts/check-android-abis.py <apk-or-aab>` checks matching library
sets and actual ELF headers. Core signing/USB transport code is Kotlin/JVM and is shared across these targets.
Packaging verification is separate from device runtime evidence. The manual `Android x86-64 runtime smoke`
workflow exercises phone/tablet mock scenarios on an x86-64 emulator; local validation uses ARM64.

A frozen document batch displays its complete file/format list in one PIN sheet. `BatchConsent` keeps an
in-memory PIN copy scoped to that certificate/requester and approved filenames; each card operation gets its own
copy. Closing/cancellation/scope changes end the session; the batch stops at the first signing error. Another
batch asks again. Simulated tests never use real card PINs.

Mock capture defaults now include `documents` (one selected fictional PDF) and `batch` (three fictional PDF/text
inputs), alongside the seven wallet states. Every image has a JSON readiness sidecar. `MSIGN_CAPTURE_SCENARIOS`,
`MSIGN_CAPTURE_PAGES` and `MSIGN_CAPTURE_THEMES` can restrict a run. Readiness waits for a rendered requested page
and completed document loading. Warm intent transitions exercise card-list membership changes without restarting
the process; pager state is rebuilt when reader membership changes to prevent stale lazy-layout indices.

For tablet validation on a dedicated emulator, set `adb shell wm size 2560x1600` and `adb shell wm density 240`
capture, then use `wm size 1600x2560` for portrait. Restore with `wm size reset`
and `wm density reset`. Use `adb -s SERIAL` when more than one emulator is connected.

## Source responsibilities (31 October 2026)

`:app` keeps the Android composition entry points at its root, feature coordination and ports in
`application/`, UI state in `presentation/`, adapters in `infrastructure/`, and Compose code in `ui/`.
`DocumentAccess` isolates SAF permissions, metadata, reads and export copies from MainViewModel.
`ReaderGateway` isolates USB monitoring and transports from application orchestration; AppContainer accepts
reader and signing factories. Debug fixtures and release no-op entry points remain separate source sets.
`:core` groups application, card, crypto, formats, network and bridge implementations without Android imports.
The app packages match these responsibility folders. Core public package names remain stable for library API compatibility; manifest entry points remain at the app root.

Tablet amendment (31 October): expanded windows follow the desktop vertical signing hierarchy, with a
centered card above documents/picker and a compact signing button below. All destinations use a bounded
680dp reading column; native navigation remains a rail. Portrait and landscape share this hierarchy.

## User-controlled demo mode

Open the settings gear on any screen, enable **Demo mode**, and confirm its disclaimer.
The preference survives cold launches in both Debug and Release. Switching at idle stops the old
reader/bridge, disposes its application scope, and starts a fresh Activity/task with the selected
composition. Switching is disabled while signing or a consent request is pending.

Demo mode initializes a hardware-free reader and signing adapter before any USB adapter is created.
It shows fictional cards and two sample PDFs; picked/shared real documents are ignored. It never
opens a physical transport, uses a PIN or vault entry, or starts the browser bridge. A banner stays
visible on every screen. Demo history uses its own preferences, separate from real activity.

The simulated batch produces one new **DEMO-…-NOT-SIGNED.pdf** per selected sample. These are fixed
fixture pages carrying **DEMO - NOT A VALID SIGNATURE** and **DEMO ONLY - UNSIGNED** watermarks,
with no cryptographic signature. Their names/URIs are separately available in Activity for Open,
Share and Save as. The store inserts new files rather than overwriting inputs or previous outputs.

Hardware-free verification:

```sh
./gradlew :app:assembleDebug :app:assembleRelease :app:lintDebug :app:testDebugUnitTest --no-daemon
python3 scripts/test-demo-mode.py emulator-5580 /absolute/screenshot/output
```

The native interaction script uses an English 1080×2400 mock phone emulator. It exercises the actual
settings, confirmation, cold-launch persistence, preview batch, system share chooser and exit from
demo. The rendered floating action is omitted from this emulator's UIAutomator hierarchy, so its
activation uses a native touch at the screenshot-verified position. For an explicitly installed,
locally signed Release validation APK, pass `--allow-release`. No physical device is accepted.
