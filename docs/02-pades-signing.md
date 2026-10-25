# 02 — PAdES Signing (PDFs msign.gov.md accepts)

Implemented in `MoldSignMac/MoldSignMac/Signing.swift` (`PAdESSigner`). This file is the
distillation of ~2 weeks of portal rejections; every element below exists because some
validator proved it necessary.

## The PDF incremental update (vendor-faithful)

The document is never rewritten; an update is appended after the last `%%EOF`:

```
\n<SIG> 0 obj\n<</Type/Sig /Filter/Adobe.PPKLite /SubFilter/ETSI.CAdES.detached
  /ByteRange [0 %010d %010d %010d ] /Contents<37960 lowercase hex chars>
  /M(D:yyyyMMddHHmmss+03'00') /Reason(MoldSign Signature) /Location(Moldova)
  /ContactInfo() /Prop_Build<</App<</Name/>>>>>>\nendobj\n
<ACRO> 0 obj\n<</Fields[<FIELD> 0 R]/SigFlags 3>>\nendobj\n
<FIELD> 0 obj\n<</FT/Sig /T(Signature1) /Type/Annot /Subtype/Widget
  /Rect[0 0 0 0] /F 0 /P <firstpage> 0 R /V <SIG> 0 R>>\nendobj\n
<ROOT> 0 obj\n<latest catalog dict + /AcroForm <ACRO> 0 R
  + /Extensions<</ESIC<</BaseVersion/1.7/ExtensionLevel 2>>>>>> ... >>\nendobj\n
xref
0 1\n0000000000 65535 f \n
<SIG> 1\n%010d 00000 n \n ... (one subsection per object)
trailer\n<</Size N /Root <ROOT> 0 R /Prev <old startxref> /ID [<id1><id2>]>>\nstartxref\n%d\n%%EOF\n
```

Hard rules:
- `/ByteRange` numbers **zero-padded to 10 digits** — byte offsets never shift when values
  change between passes. Format `/ByteRange [0 a b c ]` (space before `]`).
- `/Contents` placeholder: 37,960 lowercase hex chars (18,980 B). Fit check before embed,
  zero-pad remainder. Lowercase — the vendor writes lowercase.
- Catalog must be the **latest existing version of the original object** (find the LAST
  `\n<num> 0 obj` occurrence), extended via *insert before the last `>>` only*
  (`replacingOccurrences` of every `>>` corrupts nested dicts — a real bug).
- `/ID [<><>]` reused verbatim from the old trailer.

## Counter-signing (chain of signatures)

When the latest Catalog already has `/AcroForm N 0 R`:
1. Don't create another AcroForm — **append ` <FIELD2> 0 R` to the existing
   AcroForm object's `/Fields[...]`** and emit it as a new version (ensure `/SigFlags 3`).
2. Field name: next free index — scan `/T\s*\(\s*Signature(\d+)` over the whole file
   (iText writes `/T (Signature1)` WITH A SPACE; duplicates shadow the older signature
   in iText's `getSignatureNames`).
3. Catalog stays untouched; ByteRange of the new signature spans the entire file
   (including the first update), its `/Contents` excluded.
4. Never modify any byte before the append offset — prior signatures stay intact.

Verified portal results: PDFs with 2 parties' valid signatures; 3-chain too.

## The CMS (CAdES) content

`ContentInfo → SignedData { version 1, digestAlgorithms {sha256},
encapContentInfo {id-data}, certificates [0] {signer, MDQSign, mdtrustca}, signerInfos }`.
SignerInfo:
- version 1, SID = IssuerAndSerialNumber (issuer + serial TLVs copied raw from the cert),
- digestAlgorithm sha256, signedAttrs `[0]`:
  - contentType=id-data,
  - signingTime (UTCTime `yyMMddHHmmssZ`),
  - messageDigest = SHA-256(ByteRange content),
  - **signingCertificateV2** OID `1.2.840.113549.1.9.16.2.47` value
    `SET{SEQ{SEQ{SEQ{OCTET STRING SHA-256(certDER)}}}}`.
- signatureAlgorithm sha256WithRSAEncryption,
- signature = card RSA-4096 raw PKCS#1-v1.5 over DigestInfo(SHA-256(SET(signedAttrs))),
- unsignedAttrs `[1]` = timeStampToken (OID `1.2.840.113549.1.9.16.2.14`).

### The bug that cost weeks — signingCertificate nesting

`BouncyCastle` parses `SigningCertificate ::= SEQUENCE { certs SEQUENCE OF ESSCertID }`.
Shipping the v1 OID (`...2.12`) with `SET{SEQ{hash}}` misses two SEQUENCE layers, and BC
throws `IllegalArgumentException: unknown object in getInstance: DEROctetString`, which
iText wraps as `PdfException: Unknown PdfException` in `readSignatureData`. The MSign
backend then reports "document contains no signatures" — structure was never the problem.
Detect it in minutes: `/tmp/pk7/Probe.java` against the STISC libs (iText 9 + BC 1.80).

## RFC3161 timestamp (MDQTSA)

- Endpoint `http://tsp.pki.gov.md/moldsign2/` (**HTTP only**; ATS must be excepted or use
  `/usr/bin/curl` — URLSession refuses cleartext without a signed bundle).
- Request: `TimeStampReq{version 1, messageImprint{sha256, sha256(signatureBytes)}, certReq TRUE}`
  POSTed as `application/timestamp-query`.
- Response: `TimeStampResponse{status, token}` — take the second element raw DER into the
  unsignedAttr. Policy OID `1.2.498.3.32.5`.
- A portal-validate signature MUST carry the timestamp (PAdES-B-T), or it shows INVALID.

## Verifying your own work offline

1. `/tmp/pk7/Probe.java <file.pdf>` — iText `SignatureUtil`: names, parse, integrity.
2. `openssl cms -verify -binary -inform DER -in cms.der -content <byterange-bytes> -noverify`
   (without `-binary` openssl CRLF-mangles the content and fails a correct signature —
   a classic false-negative).
3. `MoldSignMac verify <file>` — full offline: digest + RSA + manual chain.
4. Portal: https://msign.gov.md/#/ verify upload.

## Byte-template method (fastest way to a working file)

If the structure ever needs redoing against a new vendor output:
1. Sign a PDF with the working app; `dd` split at `len(unsigned)` — everything after is
   the template update.
2. Re-emit it byte-for-byte; replace only the `/Contents` hex (placeholder width unchanged),
   recompute ByteRange over the template (values match a same-length build exactly),
   sign the digest with the card, embed.
3. This method survived every validator on first try after months of structural guessing.
