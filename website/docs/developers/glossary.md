---
title: Glossary
description: Plain-language definitions for the card, cryptographic, UI and release terms used throughout the developer handbook.
---

| Term | Meaning here |
| --- | --- |
| ADF / AID | Application Dedicated File / Application Identifier: a card application and the bytes used to select it |
| APDU | Application Protocol Data Unit: one logical command to the card or its response |
| ASN.1 / DER | A data-description language and its deterministic binary encoding, used for certificates and signature structures |
| ATR | Answer to Reset: card communication parameters returned after power/reset, not the holder's identity |
| CCID | USB smart-card reader class protocol; wraps data exchanged between host and reader |
| Certificate | A signed statement connecting an identity and public key, with issuer and validity information |
| CLI | Command-line interface, invoked from a terminal or another process |
| CMAC | A keyed message-authentication code based on a block cipher; detects modification by someone without the key |
| CMS | Cryptographic Message Syntax: the signed-data container embedded in PDF signatures |
| Consent | A person's approval of a specific operation; distinct from having access to a PIN |
| CRL / OCSP | A published certificate revocation list / an online certificate status protocol |
| Digest | A fixed-length hash of bytes; changing the bytes changes the digest with overwhelming probability |
| DigestInfo | ASN.1 structure naming the digest algorithm and containing the digest for the RSA signing operation |
| EF / MF | Elementary File / Master File in the card's filesystem hierarchy |
| Entitlement | A signed Apple application capability declaration, such as smart-card access |
| Golden vector | Known inputs and exact expected outputs shared across implementations |
| IAS/ECC | The electronic identity/signature card application profile used here; the name does not mean the signing key is an elliptic-curve key |
| IFSC / IFSD | Maximum T=1 information-field size accepted by the card / interface device side |
| Lc / Le | APDU command-data length / expected response-data length |
| LRC | Longitudinal redundancy check: a transmission checksum, not cryptographic authentication |
| MCP | Model Context Protocol: a local stdio tool interface in this project |
| PAdES / XAdES | Advanced electronic signature profiles for PDF / XML |
| PC/SC | Operating-system API/service model for accessing smart-card readers |
| PIN / QSCD | Personal identification number / qualified signature creation device; this project's signing PIN is often labelled PIN QSCD |
| PKI | Public Key Infrastructure: certificates, issuers and services used to establish and assess trust |
| Secure messaging / SSC | Protected APDU exchange / its send sequence counter |
| T=1 / TPDU | A block protocol between reader and card / transport protocol data unit handled by that layer |
| TSA / RFC 3161 | Timestamp authority / the timestamp request-token protocol used by timestamped signatures |
| WTX | Waiting-time extension: a T=1 control exchange requesting more processing time |
| Marketing version / build number | Human-facing release version / increasing upload identifier; they serve different purposes |
| TestFlight / App Review | Apple's beta distribution / production store review; an upload to one is not submission to the other |

See [the card sequence](card-protocol.md) for a worked explanation and [the architecture](architecture.md) for where each concept belongs.
