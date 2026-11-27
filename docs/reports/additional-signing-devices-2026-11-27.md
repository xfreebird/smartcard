# Additional signing devices: vendor inspection and support plan

Date: 2026-11-27. Source inspected: the installed vendor suite `/Applications/STISC/MoldSign` (version 2.4.12,
from the server log), its jars decompiled under `re/decompiled/`, and its bundled `native_lib/`. No card or token
operation was performed for this report. Nothing here is validated on hardware.

## Summary

eSemnBun supports one device family: the 2025 Moldovan eID (IDEMIA CosmoX ID-A). We talk to it directly with our own
IAS/ECC APDU driver. The vendor app works differently. It hosts PKCS#11, loads several vendor modules, and signs with
any certificate whose private key sits on a token those modules expose. On Windows it can also sign through the
Windows certificate store. That is how it supports the STISC **USB tokens**: Feitian ePass2003, SafeNet/Thales
eToken and IDPrime, and in its Windows build ACS ACOS5. These tokens are the main device type we lack.

Chosen path (owner, 2026-11-27; PLAN.md D-16): our own user-space driver per token family over the transports we
already use for the eID, on all five platforms, behind an experimental switch that is off by default. Vendor
middleware (PKCS#11, Windows CNG, macOS CryptoTokenKit identities) is not used. The first step is done: the switch on
every app and CLI, and recognition of the tokens by ATR (§5). Signing with a token needs the core work (TOK-03…05)
and, per family, a real token and one APDU capture (TOK-06…08).

## 1. What the vendor supports

### 1.1 Architecture: a generic PKCS#11 host

- `MoldSignData/Server/PKCS11.properties` lists the modules to load:
  `driver_lib=libcastle.1.0.0.dylib|libbit4xpki.dylib|libeToken.dylib`. On this Mac `use_mscsp=false`, and the
  `defaultDriverPath` and proxy settings are empty.
- `CardReaderManager` creates one `CardSelector` per module. `CardSelector` calls IAIK `Module.getInstance(path)`
  then `C_Initialize`. A 1-second monitor thread polls `C_GetSlotList(tokenPresent=true)` on every module.
- Each slot becomes a `CardReader` with id `<module>-<slotID>`. This is the `providerId` the portal sees, for
  example `libbit4xpki.dylib-0`. Each reader gets its own IAIK JCA provider bound to `SLOT_ID`.
- `TokenSes.refreshCertificates` runs `C_FindObjects` over all objects and pairs keys with certificates by
  `CKA_ID`. `CardObjectManipulation` exports every certificate that has a matching key.
- In Settings ("Drivers"), the user can add **any** PKCS#11 library with a file chooser, remove it, or refresh the
  list. The filter is `.dll` on Windows and `.so` on Linux, with no filter on macOS. The choice is saved back to
  `driver_lib`.
- Windows only: the "MSCSP" checkbox registers `MSCSPSecurityProvider`, which uses
  `KeyStore.getInstance("Windows-MY", "SunMSCAPI")`. It lists every certificate in the user's Windows store and
  signs with its key, which covers any token whose minidriver or CSP is installed. Its PDF signing falls back to
  **SHA-1** for this provider (`SignPDFWorker`: `if ("SunMSCAPI"...) digestAlgorithm = "SHA-1"`).
- The startup log (`log/err_MoldSign_Server.log`) shows all three macOS modules loading and initializing:
  `Loading driver` / `init driver` for libcastle, libbit4xpki and libeToken.

### 1.2 Bundled modules (macOS install)

| File | Identified as | Devices | Loads on current macOS? | In `driver_lib`? |
|---|---|---|---|---|
| `libbit4xpki.dylib` | bit4id Universal Middleware 1.4.11.1200 (x86_64 + arm64) | Smart cards. Enabled drivers in this build (`ALW-ENBL`): `idacosmox` (**our eID**), `nxpias`, `nxpcdlite`, `cryptoid`, `bit4id_me` (bit4id tokens), `incardts`, `incardtsfull`, `oberthur`, `p11wrap` | yes | yes |
| `libcastle.1.0.0.dylib` | Feitian "Castle" PKCS#11 (strings: `Feitian Technologies Co., Ltd.`, `EnterSafe ePass2003`, `Castle_ePass2003_pcsc_mutex_`) | **Feitian ePass2003** USB token | yes | yes |
| `libeToken.dylib` | SafeNet Authentication Client PKCS#11 (Thales) | **SafeNet eToken** and **IDPrime** (strings list IDPrime MD 3810/830/840/… and `IDPrime Java Applet`) | yes | yes |
| `libIDPrimeTokenEngine.dylib`, `libIDPrimePIVTokenEngine.dylib` | SAC token engines that libeToken loads | IDPrime and IDPrime PIV | The PIV engine needs `libSACLog.dylib`, which is not bundled | through libeToken |
| `libacos5pkcs11.dylib` | ACS ACOS5 PKCS#11 | ACS ACOS5 tokens (`ACOS5_32`, `ACOS5_64` classes) | **no**: i386/x86_64 only, links `/usr/lib/libssl.0.9.8.dylib`, which is absent | no |
| `libcrypto.3.dylib` | OpenSSL 3 | dependency of libeToken | yes | n/a |

The decompiled code also names Windows files: `bit4xpki.dll` (`DartBoss`, certificate issuance and renewal) and
`acospkcs11.dll` (excluded from `getAllModules`). So the Windows build ships the ACS module. On macOS the vendor
suite cannot use ACOS5 tokens unless the user installs ACS's own middleware and adds its module manually.

### 1.3 Algorithms

- `IaikPkcs11SecurityProvider.calculateSignatureFromHash` handles **RSA** (`RawRSA/PKCS1` over a DigestInfo, which
  is `CKM_RSA_PKCS`), **ECDSA** (`RawECDSA` over the hash) and DSA.
- PAdES goes through iText `PrivateKeySignature(key, "SHA-256", provider)`, which accepts RSA or EC keys. The TSA is
  always MDQTSA (`http://tsp.pki.gov.md/moldsign2/`). OCSP uses `OcspClientBouncyCastle`, which reads the URL from
  the certificate's AIA.
- XAdES delegates `Signature.SHA256withRSA` / `SHA1withRSA`, so in practice it is RSA only.
- STISC requires RSA of at least 2048 bits for 2-year certificates and 4096 bits for 5-year ones (source 1 below).
  Tokens may therefore hold RSA-2048, while our code assumes RSA-4096 sizes in places.

### 1.4 Trusted issuers (`trusted.jks` in `PKCS11CardReader-2.0.jar`, 19 public certificates)

| Hierarchy | CAs | Notes |
|---|---|---|
| mdtrustca (2025–2045) | MDQSign, MDeID, MobileQSign, MDQTSA, MDQOCSP | MDQSign is our eID issuer; MobileQSign is the mobile signature |
| mdtrustrootca (2020–2040) | MoldSign QCA 3A, MoldSign AdvCA 3A, MoldSign Mobile eID 3A, TSA 3A, OCSP 3A | STISC token certificates (CAs valid to 2030) |
| RootCA SIS 2 (2015–2035) | MoldSign QCA 1, AdvCA 1, Mobile eID 3, Fiscservinform QCA, Registru Qualified CA | Most of these intermediates expired between 2025-10 and 2026-05 |
| eMoldova (CTS, 2012–2028) | self-signed | legacy |

Our `ChainCerts` embeds only MDQSign and mdtrustca. `PAdESSigner.buildCMS`, `XAdESSigner` (`chainDER:
[ChainCerts.mdQSign]` in `SigningService`, `Bridge/Server.swift` ×2) and `Validator` chain checks all hard-code
that chain.

## 2. What STISC issues (public sources)

- **ePass2003** (Feitian): certificates valid for 1 or 2 years only (source 1).
- **ACOS5T2** (ACS): the only device named for **5-year** certificates, which need RSA-4096. The device costs 190 lei
  (source 1, December 2021).
- **WatchData** and **SafeNet** tokens: issued 2017–2018 by Fiscservinform. They are limited to 2-year certificates
  (source 1), so any certificate on them has expired. The vendor's macOS build bundles no WatchData module.
- **SafeNet eToken Fusion CC** (Thales) and ePass2003 appear in recent MTender procurement documents, according to
  search-result excerpts. The documents themselves were not opened (source 4), so confirm before relying on this.
- **MPass** describes the current STISC device as "a cryptographic USB-based device" without naming a model
  (source 2).
- **Mobile signature** (SIM-based, MobileQSign) is not a local device. The desktop suite does not handle it.

## 3. Gaps in eSemnBun

| Area | Today | Needed for tokens |
|---|---|---|
| Device access | Own IAS/ECC driver (`CosmoXCard`) over PC/SC, CTK `TKSmartCard`, Android USB CCID, NFC | PKCS#11 / CNG / CTK key handles, or a native driver per token family |
| Signer seam | `SigningService.withCard` passes a `CosmoXCard`; formats receive `signBlock: (DigestInfo) -> signature` | A `SigningCredential` abstraction: certificate, key algorithm, `sign(digest, algorithm)`, PIN or login policy |
| Algorithms | `sha256WithRSA` hard-coded in `buildCMS`; `RSAVerifier` only | RSA-2048/3072/4096 and ECDSA P-256/P-384 in CMS, XAdES and the validator |
| Chain and revocation | MDQSign → mdtrustca embedded; XAdES-C CRL/OCSP URLs are MDQSign-specific | Issuer-agnostic chain building (AKI→SKI) from a bundled public CA set plus AIA fetch; CRL and OCSP URLs taken from the certificate |
| Bridge | `/certificates` lists eID cards | Also token certificates, routed by certificate to their provider |
| UI | ID-card face, PIN rules for the eID | "USB token" presentation, PIN length and retry state from the token, detection of unsupported tokens |

The token SELECT is safe today. `CosmoXCard.authenticate()` selects the IAS AID first and stops on a non-9000
status, so a foreign token in a reader fails before any EXTERNAL AUTHENTICATE. It just appears as an unreadable card.

## 4. Approaches

**A. Use the user's middleware (desktop: macOS, Linux, Windows, CLI).** This is what the vendor does. It covers every
token whose maker ships a PKCS#11 module or Windows minidriver, with no APDU-level work and no per-family RE.

- PKCS#11 host in the core: `dlopen` a configurable module list, like the vendor's `driver_lib`. Pair keys and
  certificates by `CKA_ID`, sign with `CKM_RSA_PKCS` over our DigestInfo (this keeps SHA-1 working for the portal's
  XAdES) or `CKM_ECDSA` over the hash. Default modules:
  - OpenSC (`/Library/OpenSC/lib/opensc-pkcs11.so`, `opensc-pkcs11.so` on Linux), which has `epass2003` and
    `idprime` drivers.
  - `p11-kit-proxy.so` on Linux.
  - SafeNet SAC (`libeTPkcs11.dylib`), Feitian and ACS modules where installed.
- Windows: certificates in `CurrentUser\My` with a hardware-backed key, signed through CNG
  (`RSA.SignHash(..., Pkcs1)`). SafeNet SAC, Feitian and ACS install minidrivers. This equals the vendor's MSCSP mode,
  but stays on SHA-256 rather than its SHA-1 fallback.
- macOS: CryptoTokenKit identities (`SecItemCopyMatching` with the token access group,
  `SecKeyCreateSignature(.rsaSignatureDigestPKCS1v15SHA256)`). This is the only route for the **Mac App Store**
  build, which cannot load third-party dylibs. It needs middleware that installs a CTK token extension; OpenSC does.
  The Desktop build can host PKCS#11 too, but needs `com.apple.security.cs.disable-library-validation`.

**B. Native drivers (iOS, Android, and desktop without middleware).** We would implement each token's APDU protocol
over our existing transports, as we did for CosmoX. This is high effort per family and requires physical tokens:

- ePass2003: proprietary secure messaging.
- IDPrime 940 / eToken 5110 CC and Fusion: no SM, but proprietary container mapping.
- ACOS5-64 v3 (ACOS5T2).

OpenSC's drivers (LGPL-2.1) are the best public protocol reference. This repository is MIT, so derive a written
protocol spec and implement from it rather than copying code.

**Recommendation:** A first (P1/P2 tasks below), B as a spike once tokens are bought. The core work (seam,
algorithms, chain) is shared by both and comes first.

### 4.1 User space only (no vendor middleware)

**What the OS already provides.** The macOS CCID driver
(`/usr/libexec/SmartCardServices/drivers/ifd-ccid.bundle`, libccid 1.5.1, the same list Linux pcsc-lite uses)
recognizes every relevant token as a standard reader, with no install:

| Token | USB ID in the OS list |
|---|---|
| Feitian ePass2003 / ePass2003Auto | `096E:0807`, `096E:080A` |
| ACS CryptoMate (T2), the ACOS5T2 | `072F:B106` (also CryptoMate64 `072F:90DB`, CryptoMate EVO `072F:B112`) |
| SafeNet eToken 5100/5110 | `0529:0620` |
| SafeNet eToken 5110+ FIPS, 5300, Fusion | `08E6:34CF`, `08E6:34CC`, `08E6:34D2` |
| Watchdata USB Key | `163C:0407`, `163C:0417`, `163C:0418` |

- Windows binds class-compliant CCID devices to its inbox driver.
- iOS/iPadOS exposes them through `TKSmartCard`.
- Android uses our own CCID driver (`android/transport-usb`).

So **the transport is free on every platform**, and our `CardTransport` implementations already cover it.

**What the OS does not provide** is the signing protocol of these tokens:

- macOS ships only Apple's PIV token extension (`com.apple.CryptoTokenKit.pivtoken`; `pluginkit -m -p
  com.apple.ctk-tokens` also lists PlatformSSO, AccessKey and `ctkcardtoken`). None of the STISC tokens is a PIV
  token by default, so nothing appears in the keychain without middleware.
- Windows ships PIV/GIDS minidrivers only. Vendor minidrivers *may* arrive automatically through Windows Update
  smart-card Plug and Play. If one does for a given token, a CNG certificate-store route would work with no
  install (not pursued, D-16). This is unverified and must be tested per token.
- Linux distributions often ship OpenSC registered with p11-kit, which supports ePass2003 and IDPrime. Check in the
  Fedora 44 VM whether it is there by default.

**Consequence.** The only route that works everywhere with only what the OS provides is the one we already use for
the eID: our own user-space driver per token family over `CardTransport`. PAdES, XAdES, TSA, the bridge, the PIN vault
and the UI are reused once TOK-03 to TOK-05 are done. Feasibility by family:

| Family | Protocol | Unknowns | Value now |
|---|---|---|---|
| ePass2003 | ISO-style APDUs inside proprietary secure messaging whose static keys are public in OpenSC; PIN check is a challenge-response, not a plain VERIFY (per OpenSC's driver) | File layout as personalized by STISC with Feitian's middleware | **High**: issued today, cheap |
| IDPrime (eToken 5110 CC, Fusion CC) | Plain ISO 7816 (VERIFY, MSE SET, PSO CDS); certificates in the minidriver file layout (container map, zlib-compressed certificate files) | Whether the CC variants require a protected PIN path; older non-CC eToken 5110 units run a different applet | Medium: current STISC issuance unconfirmed |
| ACOS5-64 v3 (ACOS5T2) | ACS publishes the reference manual; plain APDUs unless the issuer enabled SM | STISC personalization (SM, file layout), RSA-4096 timing | High (5-year certificates), but least known |

**Platform reach by route.**

| Route | macOS | Linux | Windows | Android | iOS/iPadOS |
|---|---|---|---|---|---|
| Vendor middleware (PKCS#11, CNG, CTK) | yes | yes | yes | no middleware exists | no middleware exists |
| Own user-space driver | yes (PC/SC, CTK) | yes (pcsc-lite) | yes (WinSCard) | yes: `device_filter.xml` already matches any CCID interface (class 11), and `CcidTransport` picks it | yes: `ReaderMonitor`/`AppModel` list every `TKSmartCardSlotManager` slot with a valid card |

Mobile caveats:

- These tokens are USB only, with no NFC, so they need a USB-C port or an OTG/camera adapter for USB-A models.
- Phone USB power and Lightning adapters are the same constraints as R-08.
- A token on iOS is proven only by analogy with the bit4id reader.

Per D-01, each driver is written three times: Swift (macOS, iOS, Linux), Kotlin (Android) and C# (Windows). Shared
vectors in `spec/vectors/` keep the three in line.

Each family needs a token and one APDU capture of the vendor module signing (`re/pcsc_trace.c` with `libcastle` or
`libeToken`, as in docs/07), followed by a simulator before any real-token PIN.

## 5. Plan (PLAN.md phase "TOK", own drivers per D-16)

| ID | Pri | Work | Testable without hardware |
|---|---|---|---|
| TOK-01 ✓ | P1 | Experimental switch, off by default, in every app's settings and in both CLIs (`--experimental-tokens`, `MSIGN_EXPERIMENTAL_TOKENS=1`); off keeps today's behavior | yes |
| TOK-02 ✓ | P1 | Recognition by ATR before any APDU, from `spec/tokens/token-families.json`: the ATR tables inside the vendor's `libcastle` (ePass2003), `libeToken` (eToken Java, IDPrime) and `libIDPrimeTokenEngine` (IDPrime) modules, with masks and file offsets. A recognized token is named, with "signing is not available yet" | yes (vectors); real ATRs unconfirmed |
| TOK-03 | P1 | `SigningCredential` seam in the three cores: `CosmoXCredential` adapts today's card path; `SigningService`, the bridge and the CLI sign through it; identity guard (certificate SHA-1) before every PIN | yes (SimulatedCosmoXCard) |
| TOK-04 | P1 | Algorithm-agile formats: CMS SignerInfo algorithm from the key; ECDSA DER `Ecdsa-Sig-Value` from raw `r‖s`; XAdES `rsa-sha1/rsa-sha256/ecdsa-sha256`; EC verification in `Validator`; RSA-2048 sizes | yes (generated keys) |
| TOK-05 | P1 | Issuer-agnostic trust: bundle the vendor's public CA set, build chains by AKI/SKI with AIA `caIssuers` fallback, take CRL/OCSP URLs from the certificate for XAdES-C, generalize `Validator` | yes (fixtures; live PKI opt-in) |
| TOK-06 | P1 | Buy an ePass2003 (later an eToken 5110 and an ACOS5T2); record its ATR and one APDU trace of the vendor module signing with `re/pcsc_trace.c`; confirm or correct the spec table | no |
| TOK-07 | P1 | ePass2003 protocol spec in `docs/` from the capture and public documents, vectors in `spec/vectors/`; no LGPL code copied | from the capture |
| TOK-08 | P1 | ePass2003 driver: Swift against a simulator first, then Kotlin and C# against the shared vectors; one PIN attempt, never retried | simulator yes; acceptance no |
| TOK-09 | P2 | SafeNet eToken / IDPrime driver (TOK-06…08 for that family) | as above |
| TOK-10 | P2 | Token UI and bridge: token face in the card list, PIN rules from the token, `/certificates` and routing for token certificates, user guide | partly |
| TOK-11 | P3 | ACOS5-64 v3: the vendor module has no ATR table, so recognition and the driver both need a token | no |
| TOK-12 | P3 | Earlier eID generations: bit4xpki also enables `nxpias` and `oberthur`. Find out whether older Moldovan eIDs carry signing certificates, then capture the ATR and a trace if one is available | no |

Acceptance for each device family: a portal-accepted PAdES-T, iText `Probe.java` and `openssl cms -verify` passing,
XAdES-T through `Probe3.java`, a tampered document rejected, and the PIN never retried automatically.

## 6. Risks

- **ATR tables vs tokens in the field.** The recognition patterns are the vendor modules' own tables, not ATRs read
  from tokens. If a real token answers with an ATR outside them, it is not recognized and behaves as today (the eID
  error). TOK-06 confirms them.
- **Middleware and the eID on the same reader.** Not applicable with own drivers (D-16). Users who also run the
  vendor suite can still collide with us on the eID's secure channel, as today.
- **PIN counters.** Tokens lock after a few failed logins, and some show only `COUNT_LOW`/`FINAL_TRY`. Keep the
  existing rule: one attempt, no automatic retry, stop and explain.
- **Hardware.** We own no token. Buying an ePass2003 and an ACOS5T2 from STISC, with real certificates, is needed
  for portal acceptance. Blank tokens with self-signed certificates are enough for protocol work.
- **Store policies.** Own drivers need no third-party library, so the Mac App Store, iOS and Android builds are not
  blocked.
- **Licensing.** OpenSC is LGPL. Loading its module at runtime is fine; copying its driver code into this MIT
  repository is not.
- **Decompiled sources vs installed version.** The `re/decompiled/` sources may predate the installed 2.4.12 jars.
  The driver list and loading behavior above are confirmed from the installed files and log. Re-decompile before
  relying on finer details (runbook docs/07 step 3).

## Sources

1. [Semnătura electronică pentru 5 ani – noi mecanisme de obținere (Monitorul Fiscal, 2021-12-21)](https://monitorul.fisc.md/en/electronic_services/semnatura-electronica-pentru-5-ani-noi-mecanisme-de-obtinere-a-semnaturii-electronice.html)
2. [Electronic signature on eToken device (MPass)](https://mpass.gov.md/info/moldsign?lang=en)
3. [STISC a actualizat softul MoldSign (Monitorul Fiscal, 2023-05-24)](https://monitorul.fisc.md/en/stisc-a-actualizat-softul-moldsign/)
4. MTender procurement documents (search excerpts only, not opened), for example
   [f0c71ece…](https://storage.mtender.gov.md/get/f0c71ece-84f8-4918-9a96-12037e739115-1737357862989)
5. [OpenSC: Feitian ePass2003](https://www.github.com/OpenSC/OpenSC/wiki/Feitian-ePass2003) and [OpenSC NEWS (IDPrime, 5110)](https://www.github.com/OpenSC/OpenSC/blob/master/NEWS)
