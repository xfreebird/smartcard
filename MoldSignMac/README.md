# MoldSignMac — Moldovan eID Card PDF Signer

Signs a PDF with the qualified electronic signature (QES) stored on the Moldovan
eID card (IDEMIA CosmoX ID-A), using the bit4id miniLector reader.

## Build & Test

```bash
swift build          # Build the CLI tool
swift test           # Run crypto tests (6 tests, all verified against card captures)
```

## Usage

1. Insert card in reader, connect reader to Mac
2. Run: `.build/debug/MoldSignMac <input.pdf> <output.pdf>`
3. Enter PIN QSCD when prompted
4. Upload the signed PDF to https://msign.gov.md/#/ to verify

## Architecture

```
├── Package.swift          — SwiftPM manifest
├── CPCSC/                 — C wrappers for PCSC + CommonCrypto (AES-256-CBC/CMAC)
│   ├── cpcsc.h            — API + PCSC type declarations (bypasses Swift-incompatible modulemap)
│   └── cpcsc.c            — SCard* + AES + CMAC implementations
├── MoldSignMac/
│   ├── main.swift         — CLI entry point
│   ├── Crypto.swift       — AES-256 class (ECB/CBC/CMAC via C), SHA-256/SHA-1, ISO 9797-2 padding
│   ├── SecureChannel.swift— IAS/ECC SM wrap/unwrap (SSC, TLV 87/97/8E)
│   ├── Card.swift         — CosmoX ID-A driver: connect, mutual auth, VERIFY, sign, read cert
│   └── Signing.swift      — PAdES: CMS SignedData, PDF incremental update
├── MoldSignMacTests/
│   └── CryptoTests.swift  — 6 golden-vector tests (all verified against card captures)
└── Resources/
    └── test.pdf           — bundled test PDF
```

## Verified Crypto Test Vectors

| Test | What it verifies | Status |
|------|-----------------|--------|
| Kenc derivation | SHA256(seed+serial+MK+00000002) | ✅ |
| Kmac derivation | SHA256(seed+serial+MK+00000003) | ✅ |
| Ext auth payload | AES-256-CBC encrypt 80 bytes + CMAC 16 bytes | ✅ |
| Response decode | CMAC verify + CBC decrypt → RND_ICC | ✅ |
| Session keys | SHA256(K_ICC⊕K_IFD + counter) | ✅ |
| ISO padding | 0x80 + zeros to block boundary | ✅ |

## Protocol Reference

See `../re/FINDINGS.md` for the complete reverse-engineered protocol spec
with all constants, test vectors, and construction details.
