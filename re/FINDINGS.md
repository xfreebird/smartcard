# MoldSign RE — Findings & iOS Port Plan

Goal: iOS app that signs documents with the Moldovan eID card via the bit4id
miniLector POCKET EVO reader connected to the iPhone.

## System architecture (verified)

```
MoldSign Desktop (Java UI)  ──HTTP 127.0.0.1:18480/18443──▶  MoldSign Server (Java, Jersey/Grizzly)
                                                                    │  iaikPkcs11Wrapper (JNI)
                                                                    ▼
                                                          native_lib/libbit4xpki.dylib  (Bit4id srl, universal middleware v1.4.11.1200)
                                                                    │  PCSC.framework (SCardTransmit)
                                                                    ▼
                                                          pcscd/usbsmartcardreaderd (built-in CCID)
                                                                    ▼
                                                          bit4id miniLector POCKET EVO (VID 0x25DD, PID 0x3111, standard CCID)
                                                                    ▼
                                                          Moldovan eID card
```

- `MoldSignData/Server/PKCS11.properties`: `driver_lib=libcastle.1.0.0.dylib|libbit4xpki.dylib|libeToken.dylib`
- The user's card binds to provider `libbit4xpki.dylib` (server logs)
- Card server API (decompiled): `POST /sign/data` (SignDataInputModel{data(base64), signFormat=PAdES|XAdES, certificate, pin,...})
  → async worker → `GET /sign/data/PKCS11/{sessionId}/{type}`; Origin allow-list in `allowedSites.jar`

## The card (verified live via PKCS#11 probe)

- IDEMIA **Cosmo X "ID-A"**, applet label **ASP_51180B0A2B597D33**, serial 51180B0A2B597D33
- ATR: `3BDF96008131FE4580738421E0574D44415F415350810F78` (historical bytes contain ASCII `MDA_ASP`)
- Issued 2025-05-29 by IDEMIA for STISC
- IAS/ECC-style applet suite:
  - IAS/ECC AID: `A0000007 77030C60000000FE0000050000` (SELECT ok)
  - **Generic ADF**: `E828BD080F D25047656E65726963 00` ("veneric"), FID ADF1
  - **eSIGN ADF**: `E828BD080F A0000000 0167 455349474E` ("ESIGN"), FID ADF2
  - EF D003 = card serial (tag 5A), EF D004 = 16-byte ASCII "32972F83F5A65DC9" (key id?)
  - **EF 7001 = PIN overview**: PIN, PUK, **PIN QSCD** (qualified signing PIN), PIN ENC records
- PKCS#11 v2.20, PIN 6..8 chars, login required
- Mechanisms: CKM_RSA_PKCS(0x1), CKM_RSA_X_509(0x3), CKM_SHA1_RSA_PKCS(0x6),
  **CKM_SHA256_RSA_PKCS(0x40)**, CKM_SHA384/512_RSA_PKCS, ECDSA family (0x1040..), AES(0x1080..),
  digests SHA-1(0x220)/SHA256(0x250)/SHA384(0x260)/SHA512(0x270)

## Card protocol observed (enumeration, NO PIN, from p11_probe + interposer)

1. Plain SELECT IAS/ECC AID → 9000
2. SELECT MF / EF D003 (serial) / Generic ADF / EF 5032 (cardholder data: label, issuer, date)
3. SELECT eSIGN ADF (plain FCI returned, security attrs "47DADADADA" = SM required)
4. SELECT EF 7001 → READ BINARY (PIN/PUK/QSCD/ENC retry state, references)
5. SELECT GP ISD (`A000000151000000`-ish), GET DATA DF64
6. **IAS/ECC secure messaging establishment**:
   - `00 22 C1 A4 09 8004 FF40108C 83 01 04` (MSE SET, key ref 04)
   - `00 84 00 00 10` GET CHALLENGE → 16B nonce
   - `00 82 00 00 60 <96B>` **EXTERNAL AUTHENTICATE** — data = 16-byte constant
     (`492D28A5F7722BE4222BA37B4D53FE83`) + 80 bytes varying per session;
     card replies 96B; then **all APDUs are SM-wrapped** (CLA 0C, tag 87 enc, 8E MAC)
   - The 16B constant is NOT stored raw in the dylib (embedded Lua modules are
     encrypted/compressed) → must be captured/understood from live traces
7. SM-wrapped SELECTs + `0C CB 3F FF` GET DATA (IAS/ECC data objects) for PKCS#15 info

## Signing flow (decompiled Java, STISC jars)

- `DartModule.sign(token, keyId, dataToSign)` (used by "sign simple data"):
  `C_Login` → `C_DigestInit(CKM_SHA256)` → `C_Digest(data)` → find RSA key by CKA_ID →
  `C_SignInit(CKM_SHA256_RSA_PKCS)` → `C_Sign(hash)`
- PDF signing (`SignPDFWorker`): IAIKPkcs11 JCA provider + LoginManager(PKCS11PinProvider);
  `getPrivateKey(label)` → iText `Brand.stamp(...)` (SHA-256, PAdES, CAdES-detached) →
  `Brand.stampLtv(...)` (DSS update: certs + OCSP)
- Card management (`DartModule.generate/putCertificate/delete`): on-card keygen
  RSA-2048 / EC P-256, label "Moldova", cert upload via C_CreateObject
- STISC online services (`cargo/iso/Kayak`, `DartApi`): certificate renewal/issue API

## CAPTURED LIVE SIGNING SEQUENCE (re/apdu_capture.log — crown jewel)

Full sequence of a real PAdES signing (PIN masked in trace, never logged):

1. SELECT IAS/ECC AID `A000000077030C60000000FE0000050000` → 9000
2. SELECT MF, EF D003 (serial), then per operation:
   - `00 22 C1 A4 09 80 04 FF40108C 83 01 04` — MSE SET (SM-establishment key, ref 04)
   - `00 84 00 00 10` GET CHALLENGE → 16B nonce
   - `00 82 00 00 60 <96B>` EXTERNAL AUTHENTICATE:
     16-byte constant `492D28A5F7722BE4222BA37B4D53FE83` + 80 varying bytes
     → card replies 96B; SM session keys derived (IAS/ECC chip authentication)
   - every following APDU: CLA 0C, data TLV 87 (AES-enc), MAC TLV 8E
3. **PIN VERIFY** (SM): `0C 20 00 03 Lc…` → **PIN reference 0x03** (PIN QSCD), PIN 6–8 chars
4. Sign (SM-wrapped):
   - `0C 22 41 A4` MSE SET — INTERNAL-AUTHENTICATE template (encrypted 17B:
     algorithm = raw RSA + private-key reference)
   - `0C 88 00 00` **INTERNAL AUTHENTICATE** with encrypted **DigestInfo(SHA-256)**
     (51B plaintext → 64B AES ciphertext) → response = **512-byte RSA-4096 signature**
     (T=0 chaining via GET RESPONSE)
   - an IA attempted without login state in the eSIGN context returns `6982`
     (middleware then re-verifies PIN and retries)
5. Certificates read via SM `0C B0` READ BINARY (~29 reads, ≤256B chunks)

**Net signing primitive**: `sig = RSA_private( DigestInfo_SHA256( data ) )`
via MSE+INTERNAL AUTHENTICATE, gated by VERIFY(PIN ref 03) in the eSIGN ADF context.

## FULL PROTOCOL — extracted from bit4xpki's embedded Lua (memory forensics)

The card drivers inside `libbit4xpki.dylib` are Lua scripts, decrypted at runtime
in process memory. Extracted via lldb attach (unsigned JRE copy) + memory region
dump → `re/lua_extracted/` (127 runs; `token-cosmox-ida.lua` + CosmoXIASSmartCard
module = runs 12-17). Key findings:

**Mutual authentication (SM establishment):**
```lua
Kenc = SHA256( RANDOM_SEED[16] || SERIAL[16] || MK || 00000002 )
Kmac = SHA256( RANDOM_SEED[16] || SERIAL[16] || MK || 00000003 )
-- RANDOM_SEED = EF D004 content (16 ASCII bytes "32972F83F5A65DC9")
-- SERIAL      = EF D003 (5A) content (16 ASCII bytes "51180B0A2B597D33")
-- MK (idacosmox token) = hex 539423A6AF9F3228AFE8ABCFB8D298ADB6EBDD942A184EEE50E2A3D6CD22547F

payload(96) = AES-CBC(Kenc, RND_IFD||SN_IFD||RND_ICC||SN_ICC||K_IFD)   -- 80B, no pad
           || AES-CMAC(Kmac, ciphertext)                                -- 16B
-- RND_IFD = 199F0388C3ACEC2D84C6CE4CE785CB7B   (static)
-- SN_IFD  = 4A95FED1DB606A62                   (static)
-- K_IFD   = 445969C4020CEDD4A8C4BFCE4B9820D2BE8CDD972F983B813038A512905BBF08 (static 32B)
-- RND_ICC = GET CHALLENGE nonce; SN_ICC = last 8 bytes of serial

response(96) = AES-CBC(Kenc, RND_ICC||SN_ICC||RND_IFD||SN_IFD||K_ICC) || CMAC(Kmac, ·)
sessENC = SHA256((K_ICC xor K_IFD) || 00000001)
sessMAC = SHA256((K_ICC xor K_IFD) || 00000002)
SSC     = RND_ICC[-8] || RND_IFD[-8]  (incremented per SM APDU)
```

**Signing primitive (`pso_internal_auth`):**
```lua
MSE SET: 00 22 41 A4 [80 <algo>] [84 01 <kid>]   -- algo CSA_RSAPKCSv2_1_SHA256/384/512
INTERNAL AUTHENTICATE: 00 88 00 00 <DigestInfo>  -- card does raw RSA (P15 sig)
-- DigestInfo OID prefix stripped & algo inferred; or raw hash (32/48/64B)
```

**File layout (idacosmox):** AODF=EF7001, PrivKD=EF7002, secretKD=EF7003,
PubKD=EF7004, CDF=EF7005, dataDF=EF7006, PIN_POLICY=FFF0, PIN_POLICY_HISTORY=FFF1.
VERIFY: `00 20 00 <bso> <pin>` (bso = PIN ref 0x03 for us); pin padding cfg-driven.

**WARNING — retry counter:** EXTERNAL AUTH with wrong data returns 63Cn (started
at 15; decrements per failure, 6985 = structural reject without decrement).
Successful sessions restore it. Do NOT probe with wrong payloads.
(`re/sm_probe_DO_NOT_RUN` is retained for reference only.)

**✅ FULLY VERIFIED END-TO-END (ground truth from middleware debug log):**
- Debug log unlock: create `/usr/local/4log/mw/` and set `USE_CLEARTEXT_LOG=12345678`
  (magic value!). Log: `/usr/local/4log/mw/libbit4xpki.dylib.<date>.pid_%08X.log.bin`.
- The SM keys use the **CosmoXIASSmartCard class default MK** (from
  `CosmoXIASSmartCard.new()`), NOT the token MK:
  `MK = C1765FCA5C11B6E9F827EB1230FA74C3140619976CE92B66199801CFDB125F1E`
  (the token-level `MK = 539423A6…22547F` is only used for the cert-cache
  encryption via `add_info()`: `_mk = SHA256(CSN||MK)`)
- **Kenc/Kmac verified byte-exact** (targets logged by the middleware):
  `Kenc = 1BDE993470F87C880481AAA0B4D9BDFEB01DF43194464CEFB49E7E329F2E3DA6`
  `Kmac = 85CBC3EEDDFA3259F0C3609124CB110863A89DAC73293C228384AC6A156F57C1`
- **Payload construction verified byte-exact**:
  `payload = AES-256-CBC(Kenc, IV=0, nopad, RND_IFD||SN_IFD||RND_ICC||SN_ICC||K_IFD) || AES-256-CMAC(Kmac, ct)`
- **sessENC/sessMAC verified byte-exact** (plain SHA-256):
  `sessENC = SHA256((K_ICC xor K_IFD)||00000001) = 7C0749D4…CDCEDE` ✓
- Card's response = AES-256-CBC(Kenc, RND_ICC||SN_ICC||RND_IFD||SN_IFD||K_ICC) || CMAC(Kmac, ct)
  (decoded in middleware log as `dec1`, structure confirmed)
- The middleware's md.sha256 is plain SHA-256; SM crypto is AES-256-CBC/CMAC.
- NOTE: after finishing debugging, consider removing `/usr/local/4log/mw` (it
  collects logs on every server start; encrypted with a hardcoded scheme, but
  still sensitive material accumulating).

## PAdES signature profile (from real sample in log/signData_*_dst.tmp)

- /Filter /Adobe.PPKLite, /SubFilter **/ETSI.CAdES.detached**, SHA-256, RSASSA-PKCS1-v1_5
- CMS: version 1, detached, cert chain [user, MDQSign, mdtrustca]
- signedAttrs: contentType, signingTime, messageDigest(SHA-256), **signingCertificate v1** (ESSCertID, SHA-1)
- unsignedAttrs: **id-aa-timeStampToken** — RFC3161 from **MDQTSA**, policy `1.2.498.3.32.5`,
  TSA URL (XAdES worker): `http://tsp.pki.gov.md/moldsign2/…`, tst SignedData digest = SHA-1
- LTV: separate DSS/VRI incremental update (certs + OCSP), then doc timestamp would follow for -LTA
- Revocation: OCSP `http://mdqsign.ocsp.pki.md` (user cert), `http://mdtrustca.ocsp.pki.md` (CA)
- Policy OID on user cert: `1.2.498.3.32.1.1`; chain org: STISC (`NTRMD-1003600096694`)

## iOS transport (research)

- iOS 16+ (iPhone) / iPadOS 16.1+ has **built-in CCID reader support**; our reader is CCID
- `TKSmartCardSlotManager` is available on iOS with `com.apple.security.smartcard` entitlement;
  third-party apps ship a **CryptoTokenKit Token Extension (appex)** that acts as the card "driver"
  (proven feasible by Twocanoes Smart Card Utility with third-party CCID readers)
- The Moldovan card is NOT PIV → built-in PIV token doesn't apply; we implement our own appex
  with raw APDU access via `TKSmartCardSlot`/`TKSmartCard.transmit`
- Requires: iPhone with USB-C (15 Pro or newer; user has USB-A reader + USB-C adapter)
- Open question: does the eID chip have a contactless interface (→ CoreNFC path, no reader)?

## Capture kit (built & validated)

- `re/pcsc_trace.dylib` — DYLD_INSERT interposer (SCard* via __interpose tuples + dlsym wrapping),
  universal arm64/x86_64, masks PIN data (INS 0x20/0x24/0x2C/0xDA/0xDB)
- `re/p11_probe` — PKCS#11 enumeration probe (no PIN) — validated; produced the card facts above
- `re/jre_trace/` — copy of the bundled JRE with signatures removed (DYLD_INSERT survives)
- `re/run_capture.sh` — runs the MoldSign Server with the interposer (after quitting the real apps)
- TODO capture: one real signing → VERIFY PIN reference, key selection, sign APDU sequence

## Next steps

1. Live capture of a real signing (needs card + user PIN entered in the STISC app)
2. Decode the SM establishment + VERIFY + sign sequence; map to CEN/TS 15480 (IAS/ECC)
3. Scaffold iOS app: CTK token extension (card driver) + host app (PAdES signing, TSA, OCSP, LTV)
4. Optional: card management (keygen/cert issuance) later

## macOS App Status (MoldSignMac)

### Working (verified against the real card):
- ✅ PC/SC reader connection + card reset on connect
- ✅ Mutual auth: Kenc/Kmac derivation, MSE, GET CHALLENGE, EXTERNAL AUTHENTICATE
- ✅ Secure messaging: AES-256-CBC encryption, AES-256-CMAC, SSC tracking (incl. short responses)
- ✅ SELECT IAS AID, SELECT MF, SELECT Generic ADF (P2=04, 14-byte AID)
- ✅ SELECT EF 0001, READ BINARY (cert file read from card: 1263 bytes)
- ✅ VERIFY PIN (SW=9000 — card accepts the PIN!)
- ✅ MSE SET (algo=02, kid=81) + INTERNAL AUTHENTICATE → RSA-4096 signature
- ✅ **RSA signature verified mathematically correct** (openssl pkeyutl -verifyrecover)

### Remaining Issue:
- ❌ CMS/PAdES embedding: hand-rolled DER encoder produces a structure that
  openssl cms -verify rejects (ASN.1 encoding error in SignerInfo area).
  The signature itself is valid; the CMS wrapper needs proper encoding.

### Fix needed:
Replace hand-rolled CMS builder with one of:
1. Shell out to `openssl cms -sign` (pass cert + pre-computed signature via -nosmimeutil)
2. Use a proper CMS library (Swift ASN.1 kit, or Python cryptography lib)
3. Fix the DER encoder to match the reference CMS in re/sig1.der byte-for-byte

The reference CMS (from the middleware) has this SignerInfo structure:
```
SignerInfo ::= SEQUENCE {
  version INTEGER 1,
  sid [0] IMPLICIT IssuerAndSerialNumber  -- NOT just SKI!
  digestAlgorithm SEQUENCE { sha256, NULL }
  signedAttrs [0] IMPLICIT SET OF {
    contentType = id-data
    signingTime = UTCTime
    messageDigest = SHA-256(ByteRange content)
    signingCertificate-v1 = ESSCertID(SHA-1(cert))
  }
  signatureAlgorithm SEQUENCE { sha256WithRSAEncryption, NULL }
  signature OCTET STRING (512 bytes)
}
```
Key difference: the reference uses IssuerAndSerialNumber for SID, not SubjectKeyIdentifier.

### Debug History (all bugs found & fixed):
1. Data.dropFirst() slice startIndex → wrapped in Data()
2. SSC construction from suffix slices → converted via [UInt8]
3. Generic ADF AID had extra trailing 00 → corrected to 14 bytes
4. SELECT Generic ADF P2=00 → P2=04
5. Case 2 APDUs (READ BINARY) treated as case 3 → added body.count==1 check
6. SSC not advancing for SW-only responses → increment on short responses too
7. Missing Le=00 in SM APDUs → always append (matches Lua)
8. Stale SM state → SCardReconnect with SCARD_RESET_CARD on connect
9. Cert from card rejected by openssl x509 (but ASN.1 parses OK) — likely
   a non-critical DER quirk; the middleware uses it successfully
