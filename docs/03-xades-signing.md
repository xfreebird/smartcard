# 03 — XAdES Signing (BES / T / C, middleware-faithful)

Implemented in `MoldSignMac/MoldSignMac/XAdES.swift` (`XAdESSigner`). Verified byte-structurally
identical to golden middleware outputs (all tag sequences equal) and JDK-XMLDSig valid.

## Container document

A signed *signature file* is a standalone XML document whose root is `<ds:Signature>`:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Id="Signature-<uuid>">
  <ds:SignedInfo Id="SignedInfo-<uuid>">...</ds:SignedInfo>
  <ds:SignatureValue Id="SignatureValue-<uuid>">b64</ds:SignatureValue>
  <ds:KeyInfo Id="KeyInfo-<uuid>"><ds:X509Data><ds:X509Certificate>b64signer</ds:X509Certificate></ds:X509Data></ds:KeyInfo>
  <ds:Object><xades:QualifyingProperties xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" Target="#Signature-<uuid>">...</xades:QualifyingProperties></ds:Object>
  <!-- enveloping only: more ds:Object FileObject entries -->
</ds:Signature>
```

`xmlns:xades` is declared on QualifyingProperties, NOT on the root (vendor quirk that
matters for c14n of the SignedProperties subset).

## SignedInfo

- Detached: CanonicalizationMethod `http://www.w3.org/TR/2001/REC-xml-c14n-20010315`;
  Enveloping: same URI + `#WithComments` (vendor uses this nonstandard shape — replicate).
- SignatureMethod `http://www.w3.org/2001/04/xmldsig-more#rsa-sha256`.
- Reference 1: `URI="#SignedProperties-<u>"`, `Type="http://uri.etsi.org/01903#SignedProperties"`,
  `Id="SignedProperties-Reference-<u>"`, digest = SHA-256 over c14n(SignedProperties).
- Reference 2+ (per file):
  - detached: `URI="file:/<basename>"` digest over raw bytes, `Id="SignedFile-Reference-<u>-<basename>"`
  - enveloping: `URI="#FileObject-<u>"` digest over c14n of the FileObject element.

## SignedProperties skeleton

```xml
<xades:SignedProperties Id="SignedProperties-<u>">
 <xades:SignedSignatureProperties>
  <xades:SigningTime>YYYY-MM-DDTHH:MM:SS+03:00</xades:SigningTime>
  <xades:SigningCertificate><xades:Cert><xades:CertDigest>
    <ds:DigestMethod Algorithm="...sha256"></ds:DigestMethod><ds:DigestValue>sha256(cert)</ds:DigestValue>
  </xades:CertDigest><xades:IssuerSerial>
    <ds:X509IssuerName>2.5.4.97=NTRMD-1003600096694,CN=MDQSign,O=IP ...\C8\9B...,C=MD</ds:X509IssuerName>
    <ds:X509SerialNumber>decimal-of-big-endian-serial</ds:X509SerialNumber>
  </xades:IssuerSerial></xades:Cert></xades:SigningCertificate>
 </xades:SignedSignatureProperties>
 <xades:SignedDataObjectProperties Id="SignedDataObjectProperties-<u>">
  <xades:DataObjectFormat ObjectReference="SignedFile-Reference-<u>-</FULL/PATH>">
   <xades:Description>/FULL/PATH</xades:Description>
   <xades:MimeType>text/plain | application/octet-stream</xades:MimeType>
  </xades:DataObjectFormat>
 </xades:SignedDataObjectProperties>
</xades:SignedProperties>
```

Quirks to replicate blindly:
- **Basename-vs-full-path mismatch**: SignedInfo Reference Id uses basename, DataObjectFormat
  ObjectReference + Description use the full path (they never match — the vendor ships it so).
- **MimeType**: `text/plain` only for `*.txt`, else `application/octet-stream`.
- **X509IssuerName** (RFC2253-reversed): non-ASCII emitted as `\XX` per UTF-8 byte
  (e.g. `Chi\C8\99in\C4\83u`); orgId spelled `2.5.4.97=` numerically in SigningCertificate
  but `organizationIdentifier=` textually in CompleteCertificateRefs (lazy name registration
  in the vendor code). SerialNumber decimal from big-endian INTEGER bytes.

## XAdES-T additions

Inside `<xades:UnsignedProperties><xades:UnsignedSignatureProperties>`:

```xml
<xades:SignatureTimeStamp Id="SignatureTimeStamp-<u>">
 <ds:CanonicalizationMethod Algorithm="...c14n-20010315"></ds:CanonicalizationMethod>
 <xades:EncapsulatedTimeStamp Encoding="http://uri.etsi.org/01903/v1.2.2#DER">b64(token)</xades:EncapsulatedTimeStamp>
</xades:SignatureTimeStamp>
```

Token (RFC3161 from MDQTSA, see doc 02) is over `sha256(c14n(<ds:SignatureValue …>))` —
the SignatureValue *element* with `xmlns:ds` inherited injected and empty tags expanded.

## XAdES-C additions (after the timestamp)

```xml
<xades:CompleteCertificateRefs Id="CompleteCertificateRefs-<u>"><xades:CertRefs>
  <xades:Cert><xades:CertDigest>sha256(cert)</...><xades:IssuerSerial>parent DN (named orgId), serial dec</...></xades:Cert> ...per chain member (signer + MDQSign; NOT self-root)
</xades:CertRefs></xades:CompleteCertificateRefs>
<xades:CompleteRevocationRefs Id="CompleteRevocationRefs-<u>">
 <xades:CRLRefs>
  <xades:CRLRef><xades:DigestAlgAndValue>sha256(crl.der)</...>
   <xades:CRLIdentifier URI="http://pki.md/crl/mdqsign.crl">
    <xades:Issuer>CRL issuer DN reversed w/ named orgId</xades:Issuer>
    <xades:IssueTime>CRL thisUpdate ISO</xades:IssueTime><xades:Number>CRL number dec</xades:Number>
  </xades:CRLIdentifier></xades:CRLRef> ... (mdtrustca.crl likewise)
 </xades:CRLRefs>
 <xades:OCSPRefs>
  <xades:OCSPRef><xades:OCSPIdentifier URI="http://mdqsign.ocsp.pki.md">
    <xades:ResponderID><xades:ByName>CN=MDQOCSP,O=...,L=...,C=MD,organizationIdentifier=...</xades:ByName></xades:ResponderID>
    <xades:ProducedAt>OCSP producedAt ISO</xades:ProducedAt>
   </xades:OCSPIdentifier><xades:DigestAlgAndValue>sha256(response.der)</...></xades:OCSPRef>
  ×2 — IDENTICAL (vendor bug: loops the chain but always queries the signer's OCSP response)
 </xades:OCSPRefs>
</xades:CompleteRevocationRefs>
```

CRL/OCSP fetching: `curl` for CRLs; `openssl ocsp -issuer ca.pem -cert leaf.pem -url …
-respout rsp.der -noverify` for OCSP. Responder DN ordering in the response name is plain
reversed-by-RDN (CN,O,L,C,orgId) — verified against goldens.

## Inclusive C14N for digest inputs (applies everywhere)

For every locally-computed digest of an XML subset:
1. Take the emitted element text.
2. **Expand** every empty element `<e …/>` → `<e …></e>` quote-aware (attributes contain `/`
   in URIs — a regex that classes `[^>/]` breaks; use a tiny scanner).
3. **Inject inherited namespaces** at the ROOT of the subset, prefix-sorted
   (`xmlns:ds` before `xmlns:xades`).
4. LF endings only, no BOM, no pretty-print whitespace.

## Obtaining new goldens

Any vendor update that changes these structures is captured by running the vendor's Java
server and calling it (no GUI):

```
POST http://localhost:18480/sign/file          (headers: moldSign: DesktopSuiteClient)
<signFileInputModel>… <signFormat>XAdES-BES|XAdES-T|XAdES-C</signFormat>
  <type>Detached|Embedded</type> …
→ 201 + Location → poll until 200 → destinationFile has the golden document
```

## Offline acceptance harness

`/tmp/pk7/Probe3.java` — JDK XMLDSig `XMLSignature.validate` with a URI dereferencer
shimming `file:/` references; true across the board (refs + ours + middleware's).
