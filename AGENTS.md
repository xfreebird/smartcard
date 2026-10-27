# Smartcard / eSemnBun (codename MoldSign) — Project Knowledge Base

This repo reverse-engineered and re-implemented the STISC **MoldSign** signing stack
(Moldovan national eID: IDEMIA CosmoX ID-A card on a bit4id miniLector POCKET EVO reader)
and is growing it into native apps for **macOS, iOS, Android, Windows** plus a CLI on
**macOS, Linux, Windows**. Everything below documents how the system works, how every
artifact was obtained, and how to re-derive them if the vendor app changes.

**Naming:** the product is **eSemnBun** (this casing) on every platform; the CLI command is `esemnbun`; store IDs are
`md.esemnbun.ios` / `md.esemnbun.mac` / `md.esemnbun.cli` (Apple, team H86U5Z8HYB) and `md.esemnbun.app` (Android).
`MoldSign` stays the codename in code (modules, namespaces, Kotlin package, Linux/Windows IDs, storage paths, keychain
names, `MSIGN_PIN`) and the name of the *vendor* suite and its bridge protocol (docs/10 §0.2b, D-07).

**Signing/release:** fastlane match (`fastlane/`, storage `github.com/xfreebird/fastlanecerts`), `.github/workflows/release.yml`,
secrets only in GitHub Actions secrets and the owner's offline copy: docs/11 "Signing secrets". `gh` on the dev Mac
defaults to an employer GitHub Enterprise host: always pass `GH_HOST=github.com`.

> **Living plan: [`PLAN.md`](PLAN.md)**: phases, task IDs (`F-…`, `MAC-…`, `IOS-…`, `AND-…`, `WIN-…`,
> `CLI-…`, `LNX-…`, `SEC-…`), decisions, risks, progress log. Update it in the same change as the work.
> Code references tasks as `TODO(ID)`.

> **Deep documentation: [](docs/README.md)** — card protocol, PAdES, XAdES,
> server replica, offline validation, infrastructure, and the full re-derivation runbook.

## Layout

```
PLAN.md                      Living development plan (update as you go)
spec/                        Cross-platform contracts every port must honour
  vectors/card-crypto.json   Golden bytes: KDF, ext-auth, session keys, SM wrap/unwrap, CMAC, padding
  bridge/allowed-origins.properties   Vendor origin allow-list for the browser bridge
  cli.md                     `esemnbun` CLI contract (commands, PIN rules, exit codes)
swift/MoldSignKit/           SwiftPM package — THE CORE (moved from MoldSignMac/, history kept), used by
                             the Apple apps AND the Linux CLI/GNOME app
  Sources/MoldSignKit/
    Card/                    CosmoXCard (IAS/ECC), SecureChannel, AES/CMAC, CardTransport (PC/SC, TKSmartCard)
    Formats/                 PAdES (Signing.swift), XAdES, Validation, RSAVerifier, ChainCerts, TimestampRequest
    Network/TrustServices    TSA/OCSP/CRL over plain HTTP (NWConnection on Apple, POSIX on Linux)
    Bridge/                  MoldSign Server replica (Server.swift) + BridgeOriginPolicy
    Services/SigningService  App facade: one card op at a time, progress steps, output naming
    Support/                 MSLog, BuildInfo, POSIXSocket (Linux listener/client)
  Sources/CPCSC/             C shims: PC/SC (PCSC.framework | pcsc-lite) + AES/CMAC (CommonCrypto | OpenSSL)
                             + OpenSSL SHA/RSA/TLS for Linux. Real platform headers live only in cpcsc.c
  Sources/moldsign/          CLI (spec/cli.md), macOS + Linux; SwiftPM product `esemnbun`
  Tests/MoldSignKitTests/    Vectors, real-signature RSA, PDF/XAdES structure, bridge, live PKI (opt-in), and
                             Support/SimulatedCosmoXCard: full IAS/ECC card (mutual auth, SM, PIN counter, real RSA with a
                             test key). Use it for any card-flow or bridge change instead of the real card
  Resources/                 Info.plist (ATS), localhost.p12 (see "Sensitive"), test.pdf
apple/
  eSemnBun.xcodeproj         Xcode project (source of truth): eSemnBun-macOS (menu-bar app), eSemnBun-iOS,
                             esemnbun-cli; synchronized folders → new files join automatically
  Apps/Shared/               SwiftUI design system (CardSelector = ID-card face + switcher), AppModel, screens,
                             ReaderMonitor (CTK), PinVault (Keychain)
  Apps/macOS/  Apps/iOS/     Platform shells (menu bar + auth panel / tabs + in-app browser)
linux/                       GNOME app (GTK4 + libadwaita via the C API from Swift), data/, flatpak/ — linux/README.md
android/                     Gradle: core (Kotlin port), transport-usb (CCID), app (Compose) — android/README.md
windows/                     .NET: MoldSign.Core (C# port), MoldSign.Cli, MoldSign.App (WinUI 3) — windows/README.md
scripts/                     package-{macos,ios,android,linux}.sh, package-windows.ps1, test-portable-macos.sh
                             → dist/ (git-ignored)
docs/                        01–08 RE + protocol docs, 09 architecture, 10 design system, 11 build & release
re/                          Reverse-engineering workspace — see docs/08-re-inventory.md
```

## CLI cheat sheet

```bash
cd swift/MoldSignKit
swift build && swift test                                # MSIGN_NETWORK_TESTS=1 → live TSA/CRL/OCSP too
../../scripts/test-portable-macos.sh                     # same tests through the Linux code paths (OpenSSL, POSIX)
.build/debug/esemnbun readers                            # PC/SC readers + card presence
.build/debug/esemnbun cert --out leaf.der                # signing certificate, no PIN
.build/debug/esemnbun sign <in.pdf> [<out.pdf>]          # PAdES-T (default <name>-semnat.pdf)
.build/debug/esemnbun <in.pdf> <out.pdf>                 # legacy form, same as `sign`
.build/debug/esemnbun xades <XAdES-BES|XAdES-T|XAdES-C> <in> <out.xml> [--enveloping]
.build/debug/esemnbun verify <signed.pdf>                # PAdES validate (exit 2 = invalid)
.build/debug/esemnbun verify <sig.xml> <docs_dir>        # XAdES validate
.build/debug/esemnbun sign-hex <digestinfo_hex>          # raw card signature
.build/debug/esemnbun cms-for-hash <sha256_hex>          # detached CMS for external digest
.build/debug/esemnbun server [port [https_port]]         # MoldSign Server replica (vendor suite must be quit)
# PIN: --pin-stdin → MSIGN_PIN → no-echo prompt. Never on the command line, never in code.
xcodebuild -project apple/eSemnBun.xcodeproj -scheme eSemnBun-macOS build   # or open in Xcode
MSIGN_DEMO_CARDS=2|none [MSIGN_DEMO_SELECTED=1 MSIGN_DEMO_DARK=1] <Debug app binary>  # fictional cards, no PC/SC
```

Java probes (in `/tmp/pk7/`): `Probe.java` = iText 9 + BouncyCastle `readSignatureData`
(exact stack the MSign backend uses), `Probe3.java` = JDK XMLDSig validation.
Run with `java -cp "/Applications/STISC/MoldSign/lib/*" Probe.java file.pdf`.

---

## 1. Card protocol (CosmoX ID-A, IAS/ECC)

* Reader: "bit4id miniLector POCKET EVO"; ATR `3B DF 96 00 81 31 FE 45 80 73 84 21 E0 57 4D 44 41 5F 41 53 50 81 0F 78`.
* Always `SCardReconnect(SCARD_RESET_CARD)` on connect — kills stale SM state from crashed sessions.
  (The current code does **not** do this by default; `PCSCTransport.reset()` exists. Verify on device: MAC-12.)
* Mutual auth: IAS/ECC → session keys (AES-256). SM wrap: AES-256-CBC,
  `IV = AES-ECB(Kenc, SSC+1)`, CMAC-8; **always append `Le=00`** even for case-3 APDUs;
  SSC advances for SW-only responses too. Data-slice `startIndex` bugs are the #1 crash source
  — wrap every `dropFirst`/`subdata` in `Data(...)`, and build SSC from `[UInt8]`.
* Flow: SELECT MF → SELECT Generic ADF `E828BD080FD25047656E65726963` (14 bytes, **P2=04**)
  → VERIFY PIN **ref 0x03** → SELECT MF → SELECT ADF again → MSE SET `80 01 02 84 01 81`
  → INTERNAL AUTHENTICATE with DigestInfo(SHA-256) → 512B RSA-4096 signature.
* Signing cert: EF `0001` under Generic ADF, 128-byte READ BINARY chunks, 1799 bytes full X.509
  (outer SEQUENCE incl. signature — the earlier 1263B TBS-only bug).
* **Card-state traps**: `SW=6988` (SM out of sync — re-check SSC/Le logic), `SW=6985`
  (stuck state / counter — physically re-insert the card; do NOT keep blindly probing auth —
  the retry counter was already burned once this way).

## 2. PAdES signing (the PDF that msign.gov.md accepts)

The winning recipe (proved on the live portal):

1. **Structure**: incremental update appended after last `%%EOF`, iText/MoldSign style:
   SigDict (`/Type/Sig /Filter/Adobe.PPKLite /SubFilter/ETSI.CAdES.detached`, `/ByteRange`,
   `/Contents` hex, `/M`, `/Reason(MoldSign Signature)`, `/Location(Moldova)`, `/ContactInfo()`,
   `/Prop_Build<</App<</Name/>>>>`), AcroForm (`/Fields`, `/SigFlags 3`), sig field+widget
   (`/FT/Sig /T(SignatureN) /Subtype/Widget /V`), **updated original Catalog object**
   (latest version, + `/AcroForm` + `/Extensions<</ESIC<</BaseVersion/1.7/ExtensionLevel 2>>>>`),
   xref subsections + trailer with `/Prev`. `/ByteRange` numbers zero-padded to 10 digits so
   offsets never shift; `/Contents` placeholder 37,960 lowercase hex chars (18,980 B).
2. **Counter-signing**: reuse the existing AcroForm object (append new field ref to `/Fields`,
   emit new version of it); field name = next free `SignatureN` (scan `/T\s*\(\s*Signature(\d+)` —
   note iText writes `/T (Signature1)` WITH A SPACE); never page over `/Annots`.
3. **CMS**: signedAttrs = contentType + signingTime(UTCTime) + messageDigest +
   **signingCertificateV2** OID `1.2.840.113549.1.9.16.2.47`, value
   `SET{SEQ{SEQ{SEQ{OCTET STRING sha256(cert)}}}}`. v1 (`2.12`) + missing nesting makes
   BouncyCastle throw `unknown object in getInstance: DEROctetString` — this was THE portal
   "no signature" bug for weeks.
   SID = IssuerAndSerialNumber raw-TLV copied from cert. Certificates `[0]` = signer + MDQSign +
   mdtrustca. unsignedAttrs `[1]` = timeStampToken.
4. **Timestamp**: RFC3161 over `sha256(signature)` to `http://tsp.pki.gov.md/moldsign2/`
   (HTTP only — ATS exception or curl; `Content-Type: application/timestamp-query`, `certReq TRUE`),
   token embedded as unsignedAttr `1.2.840.113549.1.9.16.2.14`. Fresh token required per signature.
5. **Verification of PDF work**: `/tmp/pk7/Probe.java` (iText `getSignatureNames` +
   `readSignatureData` + `verifySignatureIntegrityAndAuthenticity`) and
   `openssl cms -verify -binary -content <byterange-content> -noverify`.

**How to re-derive the structure if the vendor app changes**: sign a fresh PDF with the vendor
app, diff it against its unsigned source (`first diff at len(unsigned)` = update start); every
object/xref/trailer is then byte-readable. Reuse it as a byte template with only `/Contents`
replaced (offsets can't move if placeholder widths are kept).

## 3. XAdES (BES / T / C), middleware-faithful

Golden references: POST `/sign/file` to a running Java server with header
`moldSign: DesktopSuiteClient` (or any Origin in its allow-list) — XML `SignFileInputModel`,
async `Location` long-poll. Fields/paths/models are in
`re/decompiled/TransferObjects-2.0` and `ClientCardServer-2.0/.../Signature.java`.

Format facts (all load-bearing):
* IDs: `Signature|SignedInfo|SignatureValue|KeyInfo|SignedProperties|... -<UUID>`; SignedInfo
  references `#SignedProperties-<u>` (Type `http://uri.etsi.org/01903#SignedProperties`).
* Detached file ref: `URI="file:/<basename>"`, digest over raw bytes; **Id uses basename but
  DataObjectFormat `ObjectReference` uses the FULL PATH** (vendor quirk — replicate).
* Enveloping: `<ds:Object Encoding="UTF-8" Id="FileObject-<u>"><b64></ds:Object>`,
  SignedInfo C14N = `...REC-xml-c14n-20010315#WithComments`, digest over c14n of that element.
* `SigningTime` ISO-8601 with TZ offset. X509IssuerName = RFC2253 reversed DER with
  per-UTF-8-byte escapes (`\C8\9B`); in `SigningCertificate` orgId is numeric `2.5.4.97=`,
  in `CompleteCertificateRefs` it's `organizationIdentifier=` (middleware registers names lazily).
* C14N inclusive: expand ALL empty elements (`<ds:DigestMethod .../>` → `...></ds:DigestMethod>`)
  and inject inherited namespaces on the digested subset (`xmlns:ds`, `xmlns:xades`, prefix-sorted).
* `-T`: SignatureTimeStamp, digest over c14n of the SignatureValue element, MDQTSA as in PAdES.
* `-C`: CompleteCertificateRefs (signer + issuers, digest + IssuerSerial), CompleteRevocationRefs:
  CRLs (`http://pki.md/crl/mdqsign.crl`, `.../mdtrustca.crl` — digest, issuer, thisUpdate, number)
  + **two identical OCSPRefs** (vendor bug: loops chain but always queries the signer;
  `http://mdqsign.ocsp.pki.md` via `openssl ocsp`; ResponderID ByName = reversed DN).

**Validation**: `/tmp/pk7/Probe3.java` (JDK XMLDSig) — resolves `file:/` via custom dereferencer.
Offline validator (our `Validation.swift`) reuses the same c14n tricks — remember: inject
inherited namespaces, expand empties, and prefix-strip URIs only for lookup, not comparison.

## 4. MoldSign Server protocol replica

Browser facts (msign.gov.md frontend):
* Server prefix comes from `GET /api/direct/GetInstrumentConfig` →
  `https://localhost.cts.md:18443` (resolves to 127.0.0.1).
* Auth: any `Origin` from the vendor's allow-list, **or header `moldSign: DesktopSuiteClient`**.
* Async signing: `POST` → `201 Created` + **`Location` with ABSOLUTE URL**
  (relative paths get resolved against the portal by axios — this was a real bug).
  The result `GET` is a **long-poll** (vendor `Future.get()`): held until the signature exists, then `200`
  (`400` + `error` header on failure). **Never 303-loop**: the portal issues one GET and browsers cap redirects at 20.
* Several cards: `/certificates` lists every inserted card; signing goes to the reader holding the chosen
  certificate; **the card's certificate is compared before every VERIFY** (`CosmoXCard.prepareForSigning`), so a
  swapped card never receives another card's PIN. Display names are decoded (`X509Name`), never `\XX` escapes.
* Portal batches: `use_pin_session=<first id>` on later POSTs, `keep_pin_session=1` on the first poll → one consent
  + PIN per batch (same origin, memory only, 5 min TTL). XAdES honours the request's `algorithm` (portal: SHA-1
  for Xml/Text; vendor-faithful); `signatureType:"Embedded"` = enveloping. PAdES stays SHA-256 (portal-accepted).
* Model field names (JSON or Jersey-XML): `data, contentType, algorithm, signFormat,
  signatureType, certificate{...base64...}, pin` → `{"base64File": "..."}`;
  `/sign/pdf` → `{"path": "..."}`; verify → `<valid>true|false</valid>`.
* Jersey serializes lists as repeated tags (`<filesToSign><filesToSign>x</...>`) — parse leaf pairs only.
* CMS/PIN: posts may omit `pin` → vendor pops a GUI dialog; replica shows an osascript
  password prompt (fallbacks: JSON pin → `MSIGN_PIN` env → dialog → tty).

Our replica (`Bridge/Server.swift`) serves `http://127.0.0.1:18480` and `https://localhost.cts.md:18443`
(bound to 127.0.0.1 only) with the vendor's cert chain. CORS echoes the origin **only for origins on
the vendor allow-list** (`BridgeOriginPolicy`, `spec/bridge/allowed-origins.properties`). Everyone else
gets 403 without CORS headers. Preflights add `Access-Control-Allow-Private-Network: true`. Apps plug in
`authorize` (consent + PIN). Details: docs/04 "Hardening and embedding".

## 5. Sensitive vs not

**Sensitive — never commit/publish:**
* **PIN QSCD of the user's card.** Lives only in terminal env/unit-test runs (`MSIGN_PIN`),
  never in the repo. New contributors must not learn it from code. (It *was* hard-coded in the first
  commit's `main.swift`; removed in F-03 and purged from history before the first push, SEC-06. Never reintroduce it.)
* **If the session is suddenly failing with SW=6985**: the PIN retry counter may be
  nearly exhausted — warning worth treating as sensitive for the user's physical card safety.

**Vendor-shipped (required to function; not user secrets; still keep off public repos):**
* Shipped inside the macOS, Windows, Linux and Android apps (D-03): without it the bridge has no HTTPS and the
  portal lists no identities. The vendor suite itself only has `sslKeyStore2.jks` (real JKS), never a `.p12`.
* `swift/MoldSignKit/Resources/localhost.p12` — localhost.cts.md TLS identity (publicly-issued Certum DV cert +
  its private key + chain, shipped inside every MoldSign Desktop install). Re-extract:
  `keytool -importkeystore -srckeystore /Applications/STISC/MoldSign/MoldSignData/Server/sslKeyStore2.jks
  -destkeystore localhost.p12 -deststoretype PKCS12` (password is the one compiled into the
  vendor binary — see `re/decompiled/ClientCardServer-2.0/.../ApiServer.java`,
  `setKeyStorePass(...)`).
* Chain certs (`ChainCerts.swift`): MDQSign CA + mdtrustca root — public, from any signed doc.
* MDQTSA/OCSP/CRL URLs: public infrastructure.

**Debugging scaffolding with semi-sensitive protocol internals:** `re/pcsc_trace*`,
`apdu_capture.log` (contains full SM APDU traces incl. PIN-verify structure — the PIN itself is
SM-encrypted there, but treat files as private).

## 6. How to redo everything if the vendor app changes

1. **Protocol recapture**: build `re/pcsc_trace.c` (DYLD interposer over
   `SCardEstablishContext/Transmit`), run the vendor app signing once → `apdu_capture.log`.
   Re-derive: AADF AIDs, PIN ref, MSE template, Le/SM rules, cert file id from the raw trace.
2. **Key recapture**: if the IAS master key/derivation changes, repeat the middleware memory
   scan (`re/memscan.c`, `re/dump_regions.py`) right after a middleware signing session and
   re-derive Kenc/Kmac/session keys against the trace (unit tests in CryptoTests.swift are
   the vector checklist).
3. **Jars**: decompile updated jars with CFR (`java -jar cfr.jar <jar> --outputdir re/decompiled/<x>`);
   diff `SignatureInstance.java`, `SignXAdESWorker.java`, `Signature.java` (service routes),
   `ApiServer.java` (keystore pass, ports).
4. **PDF/XAdES reference regeneration**: run vendors' Java server, use `/certificates`,
   `/sign/file`, `/sign/data` (documented headers/auth above) to make new golden outputs for
   each format; also sign one PDF via their GUI for the PAdES template.
5. **Re-validate ours**: `swift test` (in `swift/MoldSignKit`) + Probe.java (PAdES) + Probe3.java (XAdES) + portal upload.
   If protocol bytes change, regenerate `spec/vectors/card-crypto.json` from Swift and re-run the Kotlin/C# suites.

## 7. Cross-platform work

Moved to [`PLAN.md`](PLAN.md) (phases, IDs, decisions) and [`docs/09-architecture.md`](docs/09-architecture.md)
(contracts). Gotchas found while building it:

* **URLSession can't reach the TSA**: HSTS rewrites `http://tsp.pki.gov.md` to https, where the TSA
  drops the connection (-1005). ATS exceptions don't help. `TrustServices` uses a minimal HTTP/1.1 client over `NWConnection`.
* `NWConnection` honours the **system HTTP proxy** (e.g. a leftover Charles proxy → 503s). PKI calls set
  `preferNoProxies`, which matches the old `curl` behavior.
* `URL.path` drops the trailing slash: `/moldsign2` → TSA answers 301. Use `URLComponents.percentEncodedPath`.
* Regexes like `(\d+) 0 obj` are **quadratic** over the 37,960-zero `/Contents` placeholder (counter-signing
  took 43 s). Always anchor with `(?<!\d)`.
* `readBinary` used to strip ISO-9797 padding twice: chunks ending in `00`/`80` were truncated (fixed; simulator test).
* The C CMAC wrote `M_last[16]` for empty messages (fixed; NIST vector in `spec/vectors`).
* Xcode targets must not differ only by case (`MoldSign` vs `moldsign` collided on APFS): targets are `eSemnBun-macOS`,
  `eSemnBun-iOS`, `esemnbun-cli`. Products `eSemnBun.app` and `esemnbun` coexist; on Windows (case-insensitive) the CLI
  lives in its own folder, see windows/README.md.
* macOS PC/SC uses **32-bit** `DWORD`/handles (`PCSC.framework/Headers/wintypes.h`), Linux pcsc-lite uses
  `unsigned long` (64-bit). Never redeclare PC/SC types: `cpcsc.c` includes the real header; Swift sees
  only fixed-width wrappers. (The first shim used 64-bit DWORD on macOS and worked only by little-endian luck.)
* `MOLDSIGN_PORTABLE` (automatic on Linux) selects OpenSSL + POSIX sockets. `scripts/test-portable-macos.sh` runs
  the whole suite that way on macOS, so most Linux bugs show up without a Linux box.
