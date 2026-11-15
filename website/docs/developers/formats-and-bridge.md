---
title: Formats, trust services and integrations
description: How card signatures become PAdES or XAdES documents and how websites, CLI commands and MCP clients reach the signing services.
---

A card returns signature bytes, not a signed file. Format code packages those bytes with certificates, digests and optional timestamp/revocation evidence so another application can verify the result.

## PDF / PAdES

The PDF signer appends an incremental update. Earlier PDF bytes remain in place; new objects introduce a signature dictionary, signature field and updated document references. A reserved hexadecimal `/Contents` region holds CMS, the cryptographic signature container.

`/ByteRange` describes the portions covered by the signature, excluding the reserved signature contents. Fixed-width offsets prevent the layout from shifting while the actual signature is inserted. Counter-signing adds another field/update while retaining existing signatures and form fields.

The signing chain is:

```text
PDF covered bytes
    → document digest
    → CMS signed attributes (including that digest and a certificate digest)
    → DigestInfo of the signed attributes
    → RSA operation on the card
    → CMS, certificates and optional timestamp
    → reserved PDF Contents
```

CMS attributes include content type, signing time, message digest and `signingCertificateV2`. ASN.1 nesting matters: the right bytes inside the wrong SET/SEQUENCE structure are still an invalid message. Certificate identity is encoded using issuer and serial number.

For timestamped output, an RFC 3161 request covers the **signature bytes' digest**, not simply the original PDF's digest. The timestamp token becomes an unsigned CMS attribute. A visible name/date stamp is a separate PDF appearance and cannot establish cryptographic validity.

Source: Swift `Formats/Signing.swift`, Kotlin format code under `android/core`, and Windows `Signing/`. Prefer the format-specific tests and independent parsers when changing PDF offsets or CMS encoding.

## XML / XAdES

XML signatures sign canonicalized XML rather than the arbitrary whitespace serialization of a document. SignedInfo contains references to the signed data and signed properties. Every reference digest and canonicalization algorithm must agree with the declared XML.

| Variant | Included evidence |
| --- | --- |
| XAdES-BES | Basic XML signature and signed properties |
| XAdES-T | BES plus a signature timestamp |
| XAdES-C | Timestamped signature plus certificate/revocation references |

A **detached** signature refers to external original bytes. An **enveloping** signature contains the payload in a `ds:Object`. To verify detached output, the verifier needs the original document; a missing original is different from a digest mismatch.

Compatibility details include inclusive canonicalization, expanding empty elements, inherited namespaces, issuer-name escaping and the vendor's reference naming. Do not “clean up” serialization without checking vectors and an independent XML signature implementation. Browser requests can ask for SHA-1 for a vendor-compatible XML flow; do not silently apply that choice to PDF or to all application signing.

## Network and trust

Timestamp authorities (TSA), certificate revocation lists (CRL) and online certificate status responders (OCSP) provide different evidence. The legacy endpoints used by this profile include plain HTTP. The Swift client uses a controlled transport because normal URL-loading behavior can upgrade HTTP through HSTS or apply a system proxy that breaks compatibility. Linux uses POSIX/OpenSSL paths; Kotlin and C# have their own network implementations.

Preserve the URL's encoded path, including a required trailing slash. A network request returning bytes is not sufficient: the signer/validator must parse and evaluate the relevant cryptographic object. This transport choice does not mean every download in the application should use plain HTTP.

Verification reports must distinguish document integrity, mathematical signature validity, certificate trust, timestamp evidence and revocation information. Do not translate an unavailable check into “valid”. Read the particular validator's implemented checks before claiming full online revocation or long-term validation. Automated offline tests do not prove a live PKI endpoint is reachable today.

## Browser bridge

The website does not read the USB device directly. A local bridge translates compatible MoldSign requests into application signing operations. The default listeners are loopback HTTP `127.0.0.1:18480` and HTTPS `localhost.cts.md:18443`. The HTTPS identity is provisioned separately through the project's authorized setup process.

```text
Portal                 Local bridge                 Native app / core
  | GET certificates        |                              |
  |------------------------>| read public identities       |
  |<------------------------|                              |
  | POST signing request    |                              |
  |------------------------>| queue work ----------------->|
  |<-- 201 + Location ------|                      consent + PIN
  | GET absolute Location   |                      card operation
  |------------------------>| wait                         |
  |                         |<---------- result -----------|
  |<------ 200 result ------|                              |
```

The result GET is a **long poll**, held until work completes. The POST's `Location` must be absolute; otherwise a portal can resolve it against its own server. A chain of redirects is not a substitute for waiting.

Origin policy comes from `spec/bridge/allowed-origins.properties`. A browser Origin must pass the allow-list. The native-client header is a separate compatibility path and must not override a disallowed browser Origin. Reject unapproved origins without permissive CORS headers. Native-only filesystem operations must not become browser access to arbitrary local paths.

Batch PIN sessions are bounded, in-memory and scoped to the request identity/origin rules. They do not justify saving a plaintext PIN or sharing authorization across websites. User consent is still an application responsibility.

If discovery fails, examine the bridge listener, conflicting vendor process, TLS provisioning, browser local-network permission, system proxy and app lifecycle separately. On iOS/iPadOS, foreground/background restrictions matter. A supported URL alone does not prove the app can serve it while suspended.

## CLI and MCP

The CLI exposes explicit commands such as `readers`, `cert`, `sign`, `xades` and `verify`; its contract is `spec/cli.md`. PIN input uses secure interactive input or an explicitly selected stdin/provider path. Never put a PIN in command-line arguments.

The local MCP server uses **stdio**, not a public web endpoint. Its tools expose discovery, verification and a prepared signing flow through the same local application capabilities. A preparation step is not permission to execute a signature. Follow the existing [MCP integration guide](../integrations/mcp-agents.md) and `spec/mcp.md` for exact tool schemas and authorization rules.

The website's `llms.txt`, Markdown exports and `discovery.json` help clients read documentation; they are not the MCP server and cannot sign documents. [The agent reference](agents.md) maps development tasks to source and checks.
