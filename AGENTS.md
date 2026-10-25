# Smartcard / MoldSignMac — Project Knowledge Base

This repo reverse-engineered and re-implemented the STISC **MoldSign** signing stack
(Moldovan national eID: IDEMIA CosmoX ID-A card on a bit4id miniLector POCKET EVO reader)
as a native macOS app. Everything below documents how the system works, how every
artifact was obtained, and how to re-derive them if the vendor app changes.

> **Deep documentation: [](docs/README.md)** — card protocol, PAdES, XAdES,
> server replica, offline validation, infrastructure, and the full re-derivation runbook.

## Layout

```
MoldSignMac/                 SwiftPM package — the whole product
  MoldSignMac/
    Card.swift               IAS/ECC card driver (connect, mutual auth, VERIFY, sign, cert read)
    SecureChannel.swift      AES-256-CBC/CMAC secure messaging, SSC tracking
    Crypto.swift             AES/SHA wrappers, Data hex helpers
    CPCSC/                   C target: PC/SC + AES-CBC/ECB/CMAC via CommonCrypto
    Signing.swift            PAdES: detached CMS builder + iText-style PDF incremental update, TSA
    ChainCerts.swift         MDQSign CA + mdtrustca root, base64 DER (public certs)
    XAdES.swift              XAdES-BES/T/C builder (detached + enveloping), DN/ASN.1 helpers,
                             CRL/OCSP fetching via curl/openssl
    Validation.swift         Offline validator: ByteRange/CMS/RSA, manual chain, XAdES c14n checks
    Server.swift             MoldSign Server protocol replica (NWListener, HttpServer class)
    TimestampRequest.swift   RFC3161 request DER builder
    main.swift               CLI modes (see cheat sheet)
  MoldSignMacTests/          Unit + structural tests (golden crypto vectors, PDF/XAdES probes)
  Resources/Info.plist       ATS exception for tsp.pki.gov.md (HTTP-only TSA)
  Resources/localhost.p12    localhost.cts.md TLS identity (see "Sensitive" section)
re/                          Reverse-engineering workspace — see docs/08-re-inventory.md
  FINDINGS.md                Running notes from the RE phase
  decompiled/<jar>/          CFR-decompiled vendor jars (ground truth for protocol)
  pcsc_trace.c, apdu_capture.log, run_capture.sh   PC/SC interposer + captured sessions
  sig1.der                   Reference CMS captured from middleware
  tools (memscan, dump_regions, sm_probe[DO_NOT_RUN])
```

## CLI cheat sheet

```bash
cd MoldSignMac
swift build && swift test
.build/debug/MoldSignMac <in.pdf> <out-signed.pdf>      # PAdES sign (prompts for PIN QSCD)
.build/debug/MoldSignMac sign-hex <digestinfo_hex>      # raw card signature
.build/debug/MoldSignMac cms-for-hash <sha256_hex>      # detached CMS for external digest
.build/debug/MoldSignMac xades <XAdES-BES|XAdES-T|XAdES-C> <in> <out.xml>
.build/debug/MoldSignMac verify <signed.pdf>            # PAdES validate
.build/debug/MoldSignMac verify <sig.xml> <docs_dir>    # XAdES validate
MSIGN_PIN=... .build/debug/MoldSignMac server           # MoldSign Server replica
```

Java probes (in `/tmp/pk7/`): `Probe.java` = iText 9 + BouncyCastle `readSignatureData`
(exact stack the MSign backend uses), `Probe3.java` = JDK XMLDSig validation.
Run with `java -cp "/Applications/STISC/MoldSign/lib/*" Probe.java file.pdf`.

---

## 1. Card protocol (CosmoX ID-A, IAS/ECC)

* Reader: "bit4id miniLector POCKET EVO"; ATR `3B DF 96 00 81 31 FE 45 80 73 84 21 E0 57 4D 44 41 5F 41 53 50 81 0F 78`.
* Always `SCardReconnect(SCARD_RESET_CARD)` on connect — kills stale SM state from crashed sessions.
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
async `Location` polling until non-303. Fields/paths/models are in
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
  Poll → `303 See Other` (+ absolute `Location`) until ready, then `200`.
* Model field names (JSON or Jersey-XML): `data, contentType, algorithm, signFormat,
  signatureType, certificate{...base64...}, pin` → `{"base64File": "..."}`;
  `/sign/pdf` → `{"path": "..."}`; verify → `<valid>true|false</valid>`.
* Jersey serializes lists as repeated tags (`<filesToSign><filesToSign>x</...>`) — parse leaf pairs only.
* CMS/PIN: posts may omit `pin` → vendor pops a GUI dialog; replica shows an osascript
  password prompt (fallbacks: JSON pin → `MSIGN_PIN` env → dialog → tty).

Our replica (`Server.swift`) serves `http://127.0.0.1:18480` and `https://localhost.cts.md:18443`
with the vendor's cert chain, full CORS filter (`Access-Control-Allow-Origin: <echo origin>`,
`Origin, x-requested-with, content-type, accept, error, Location` allow+expose headers,
`OPTIONS` handlers).

## 5. Sensitive vs not

**Sensitive — never commit/publish:**
* **PIN QSCD of the user's card.** Lives only in terminal env/unit-test runs (`MSIGN_PIN`),
  never in the repo. New contributors must not learn it from code.
* **If the session is suddenly failing with SW=6985**: the PIN retry counter may be
  nearly exhausted — warning worth treating as sensitive for the user's physical card safety.

**Vendor-shipped (required to function; not user secrets; still keep off public repos):**
* `Resources/localhost.p12` — localhost.cts.md TLS identity (publicly-issued Certum DV cert +
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
5. **Re-validate ours**: `swift test` + Probe.java (PAdES) + Probe3.java (XAdES) + portal upload.

## 7. TODO — iOS port

* Replace `CPCSC` (PC/SC) with **CryptoTokenKit**: `TKSmartCardSlotManager` /
  `TKSmartCard` transmit; keep `Card.swift`/`SecureChannel.swift` — they take APDUs the same.
* AES-CBC/CMAC: CryptoKit `AES` doesn't expose CMAC directly — implement on top of `AES` block
  cipher (CMAC = CBC-MAC with subkey doubling, already proven in the C code), or use
  `CCCrypt` (available on iOS).
* TSA/OCSP/CRL via `URLSession` (needs HTTPS or ATS exceptions — MDQTSA is HTTP-only, so an
  `Info.plist` domain exception for `tsp.pki.gov.md` is required on device too).
* `openssl ocsp` call in XAdES-C → replace with a Security-framework-free OCSP client
  (build OCSPRequest DER manually over signer/issuer certIDs and POST to the responder).
* UI: document picker → PIN prompt → PAdES/XAdES sign → share sheet. Validation screens can
  reuse `Validation.swift` as-is (SecKeyVerifySignature works on iOS).
```
