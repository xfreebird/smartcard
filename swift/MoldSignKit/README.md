# MoldSignKit: the Moldovan eID signing core (Swift)

The reverse-engineered core that signs with the Moldovan eID card (IDEMIA CosmoX ID-A, IAS/ECC)
through a bit4id miniLector, as a Swift package used by the macOS and iOS apps and the `moldsign` CLI.
It is the **reference implementation**: the Kotlin (`android/core`) and C# (`windows/src/MoldSign.Core`)
ports must match it byte-for-byte (`spec/vectors/card-crypto.json`).

## Build and test

```bash
swift build                              # MoldSignKit + CPCSC + moldsign CLI
swift test                               # 27 tests: vectors, card simulator, PDF/XAdES structure, bridge policy
MSIGN_NETWORK_TESTS=1 swift test         # + live MDQTSA token, CRL and OCSP (native vs openssl) against pki.md
```

The apps live in `../../apple/MoldSign.xcodeproj` (targets `MoldSign-macOS`, `MoldSign-iOS`, `moldsign-cli`), which links
this package as a local dependency.

## CLI

See `../../spec/cli.md`. Quick tour:

```bash
.build/debug/moldsign readers
.build/debug/moldsign cert --out leaf.der
.build/debug/moldsign sign contract.pdf           # → contract-semnat.pdf (PIN: --pin-stdin, MSIGN_PIN or prompt)
.build/debug/moldsign verify contract-semnat.pdf
.build/debug/moldsign server                      # browser bridge (quit the vendor suite first)
```

## Layout

```
Package.swift
Sources/
  CPCSC/                 C shims: PC/SC (macOS only) + AES-256 ECB/CBC/CMAC via CommonCrypto
  MoldSignKit/
    Card/                CosmoXCard, SecureChannel, Crypto (AES/CMAC/ISO 9797), Transport (PCSCTransport, TKSmartCardTransport)
    Formats/             PAdESSigner (Signing.swift), XAdESSigner, Validator, ChainCerts, TimestampRequest
    Network/             TrustServices: TSA / OCSP / CRL over a minimal plain-HTTP client (not URLSession: HSTS)
    Bridge/              MoldSignServer (MoldSign Server protocol) + BridgeOriginPolicy
    Services/            SigningService: app facade, one card operation at a time, progress steps, output naming
    Support/             MSLog: CLI verbose output; apps set `MSLog.sink = nil`
  moldsign/main.swift    CLI
Tests/MoldSignKitTests/  + Fixtures/ (public PKI artifacts only: MDQTSA token, MD CRLs, an OCSP response, a tiny PDF)
Resources/               Info.plist (ATS exceptions, embedded into the CLI), localhost.p12 (vendor TLS identity), test.pdf
```

Protocol and format details: `../../docs/01…05`. Architecture: `../../docs/09-architecture.md`.
