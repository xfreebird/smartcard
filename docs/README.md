# MoldSignMac — Documentation

Native macOS re-implementation of the Moldovan STISC MoldSign signing stack:
eID smart-card driver, PAdES/XAdES signing (single + counter-signatures with timestamps),
offline validation, and a drop-in replica of the MoldSign Server used by msign.gov.md.

**Start here:** `../AGENTS.md` — project map, sensitivity rules, sensitivity list, iOS TODO.

| Doc | Contents |
|---|---|
| [01-card-protocol.md](01-card-protocol.md) | IAS/ECC mutual auth, SM channel rules, P2=04/Le=00/SSC traps, status-word playbook, Slicing crashes, recapture tools |
| [02-pades-signing.md](02-pades-signing.md) | iText-faithful incremental updates, fixed-width ByteRange, counter-signing via existing AcroForm, CMS with signingCertificateV2+chain+MDQTSA, the BouncyCastle rejection bug, byte-template method |
| [03-xades-signing.md](03-xades-signing.md) | XAdES-BES/T/C byte-exact structures incl. vendor quirks (id/basename mismatch, duplicated OCSPRef, DN spellings, #WithComments), CRL/OCSP fetching, golden extraction, XMLDSig harness |
| [04-server-replica.md](04-server-replica.md) | localhost.cts.md TLS + 18480/18443, auth/CORS rules, async session protocol (absolute Location + 303), every DTO, Jersey list parsing traps, PIN UX, frontend wiring of the portal |
| [05-offline-validation.md](05-offline-validation.md) | verify internals: object-scoped /Contents pairing, `/T (` name window, c14n rules (expand + inherited ns), manual chain ladder (why not SecTrust), report shape |
| [06-infrastructure.md](06-infrastructure.md) | CA chain, TSA/OCSP/CRL URLs, vendor suite layout, TLS p12 extraction, sensitivity table |
| [07-re-derivation-runbook.md](07-re-derivation-runbook.md) | How to re-extract EVERYTHING after a vendor update: pcsc_trace capture, memory-scan for keys, CFR decompile list, golden generation, validation harness builds, trap log |
| [08-re-inventory.md](08-re-inventory.md) | File-by-file guide to the re/ artifacts: captures, key vectors, card dumps, reference CMS, decompiled jars, RE tooling |

## Quick start

```bash
cd MoldSignMac && swift build && swift test
.build/debug/MoldSignMac ~/Downloads/doc.pdf /tmp/doc-signed.pdf       # sign (prompts PIN)
.build/debug/MoldSignMac verify /tmp/doc-signed.pdf                    # validate offline
MSIGN_PIN=… .build/debug/MoldSignMac server                            # browser replacement
```

Browser flow: https://msign.gov.md/#/ → Sign with MoldSign — talks to our replica instead
of the Java suite (restart the vendor server to switch back — they share ports).

## Module map

`Card.swift` IAS/ECC driver · `SecureChannel.swift` SM wrap/unwrap · `CPCSC` PC/SC+AES C shims ·
`Signing.swift` PAdES+CMS+TSA · `XAdES.swift` XAdES + DN/CRL/OCSP helpers ·
`Validation.swift` offline validator · `Server.swift` protocol replica · `ChainCerts.swift`
public CA material · `TimestampRequest.swift` RFC3161 DER · `main.swift` all CLI modes
