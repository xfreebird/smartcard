# eSemnBun (codename MoldSign) — Documentation

Native re-implementation (macOS, iOS, Android, Windows, Linux/GNOME; CLI on macOS, Linux, Windows) of the Moldovan STISC MoldSign signing stack:
eID smart-card driver, PAdES/XAdES signing (single + counter-signatures with timestamps),
offline validation, and a drop-in replica of the MoldSign Server used by msign.gov.md.

**New developers:** [Developer onboarding](13-developer-onboarding.md) covers local toolchains, configurable VM access, UI evidence and publishing boundaries. Copy [the environment example](developer-environment.example.json) to the ignored `.local/` directory for your own machine inventory.

**Start here:** `../AGENTS.md` (project map, sensitivity rules) and **`../PLAN.md`** (living development plan: phases, task IDs, decisions, progress log).

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
| [09-architecture.md](09-architecture.md) | Cross-platform architecture: layers, per-language module map, CardTransport / CosmoXCard / PinVault / Bridge / ReaderMonitor contracts, testing strategy, why no shared core |
| [10-design-system.md](10-design-system.md) | Design tokens, components, every screen (macOS menu bar, windows, sheets, iOS, Android, Windows), copy ro→en, accessibility |
| [11-build-and-release.md](11-build-and-release.md) | Per-platform build/test/package commands, `scripts/package-*.sh`, signing inputs (env only), what's been packaged, notarization recipe |
| [14-github-actions.md](14-github-actions.md) | Workflow selection, CI routing, artifact reuse, store boundaries, recovery and secret storage inventory |
| [13-developer-onboarding.md](13-developer-onboarding.md) | Developer setup, host/device inventory, builds, UI validation, signing and release access |
| [privacy-policy.txt](privacy-policy.txt) | Public privacy policy for the store listings (App Store, Google Play, Microsoft Store): what stays on the device, what goes to the Moldovan trust services |
| [../spec/](../spec) | Cross-platform contracts: `vectors/card-crypto.json` (golden bytes every port must pass), `bridge/allowed-origins.properties`, `cli.md` |

## Quick start

```bash
cd swift/MoldSignKit && swift build && swift test              # core + CLI (MSIGN_NETWORK_TESTS=1 adds live TSA/CRL/OCSP)
.build/debug/esemnbun sign ~/Downloads/doc.pdf                 # → doc-semnat.pdf (PIN prompt, or MSIGN_PIN)
.build/debug/esemnbun verify ~/Downloads/doc-semnat.pdf        # validate offline
.build/debug/esemnbun server                                   # browser bridge on 127.0.0.1:18480 / :18443
open ../../apple/eSemnBun.xcodeproj                            # macOS menu-bar app, iOS app, CLI targets
cd ../../android && ./gradlew :core:test :app:assembleDebug    # Android
cd ../windows && dotnet test MoldSign.Portable.slnf            # Windows core + CLI tests (see windows/README.md)
```

Browser flow: https://msign.gov.md/#/ → Sign with MoldSign — talks to our bridge instead
of the Java suite (quit the vendor suite first — they share ports 18480/18443).

## Module map

`swift/MoldSignKit/Sources/MoldSignKit/`: `Card/` (CosmoXCard IAS/ECC driver, SecureChannel, AES/CMAC, CardTransport: PC/SC +
CryptoTokenKit) · `Formats/` (PAdES + CMS, XAdES, Validator, ChainCerts, RFC3161 request) · `Network/TrustServices`
(TSA/OCSP/CRL over plain HTTP) · `Bridge/` (MoldSign Server protocol + origin policy) · `Services/SigningService`
(app facade, card lock) · `Support/Log`. `CPCSC` = PC/SC + CommonCrypto C shims. `moldsign` = CLI source (product `esemnbun`).
Apps: `apple/Apps/{Shared,macOS,iOS}` (Xcode project `apple/eSemnBun.xcodeproj`) · `linux/` (GNOME) · `android/` · `windows/`.
