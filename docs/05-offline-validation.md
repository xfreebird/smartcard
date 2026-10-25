# 05 — Offline Validation (`esemnbun verify`)

`swift/MoldSignKit/Sources/MoldSignKit/Formats/Validation.swift` (`Validator`). Everything runs offline in ms —
no SecTrust (it hangs fetching missing intermediates), no revocation calls.

## PAdES: `Validator.validatePDF`

1. **Locate signatures** — regex `/ByteRange\s*\[\s*(\d+) (\d+) (\d+) (\d+)\s*\]` over the
   file; names resolved within a ±6000-char window looking for `/T(...Signature...)`
   (note iText's space: `/T (Signature1)`).
2. **Contents pairing must be object-scoped**: find `/Contents\s*<hex>` only between the
   ByteRange's own `N 0 obj` … `endobj`. The Java app writes `/Contents <hex>` (space!) —
   a plain `/Contents<` search skips it and pairs with the NEXT signature's CMS
   ("content modified!" false negative that we chased).
3. **Chain of trust per signature** — rebuild content over the two ByteRange spans and
   compare with CMS signedAttrs `messageDigest` (contentIntact).
4. **RSA verify**: extract signedAttrs `[0]` region from SignerInfo; hash it as a SET
   (`0x31 + len + content — the IMPLICIT tag swapped back); verify card signature with
   `SecKeyVerifySignature(key, .rsaSignatureDigestPKCS1v15SHA256, attrsHash, sig)`.
5. **Chain, manually** (this replaces SecTrust on purpose):
   - `leaf.issuer == MDQSign.subject`, `MDQSign.issuer == mdtrustca.subject` (raw DER Name equality);
   - `SecKeyVerifySignature(caKey, .rsaSignatureMessagePKCS1v15SHA256, leafTBS, leafSig)`;
   - same for CA against embedded `ChainCerts.mdTrustCA` DER.
   SecTrust tried to fetch the missing intermediates for Econom Natalia's older chain and
   hung for minutes; the manual ladder is instant and deterministic — embed the exact
   intermediates you trust.
6. **Timestamp**: unsignedAttr OID `…16.2.14` present? first `GeneralizedTime(0x18)` after
   `id-smime-ct-TSTInfo` in the TST token = TST genTime → report level `PAdES-B-T` vs `-B-B`.

## XAdES: `Validator.validateXAdES`

1. SignedInfo/substring extraction, then per Reference:
   - `#SignedProperties-<u>`: c14n subset (inject inherited `xmlns:ds` + `xmlns:xades`,
     prefix-sorted; expand `<e/>` to `<e></e>` quote-aware) → sha256 vs DigestValue.
   - `file:/name`: sha256 of the supplied file bytes (CLI resolves relative to cwd or
     `docsDir`; server resolves basename-mapped `signedFiles`).
   - digestValue MUST be searched against the FULL URI string; helpers that strip the
     `file:/`/`#`-prefix before lookup break silently (real bug).
2. RSA: c14n(SignedInfo) (inject `xmlns:ds` only) → `SecKeyVerifySignature(…SHA256, c14nHash, sig)`.
3. Manual chain + level detection (`SignatureTimeStamp` → `-T`, `CompleteCertificateRefs` → `-C`).

## Report shape

`Signature1: VALID — Ghimbovschi Nicolae, PAdES-B-T, signed 261024211300Z, tst …,
chain trusted[, content modified!][, bad signature!]` — the CLI exits non-zero if any
signature fails content or crypto (chain-trust state is reported but not fatal).

## Gotchas encoded

- `String(decoding: data, as: UTF8.self)` on the PDF (latin-1-safe for regexing) — byte
  offsets: always round-trip through NSString/utf16 consistently.
- NSRegularExpression over an entire 400KB doc with materialized match arrays was the
  local hang — scope every regex to object regions / windows.
- DER zero-padding after a CMS (the `/Contents` hex padding) — strip via first-TLV total
  length before walking.
