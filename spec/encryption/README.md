# File protection: implementation and validation plan

## Scope

Provide discoverable **Protect files** tools in Documents on Apple, Android, Windows and Linux, plus desktop CLI commands. Support password encryption/decryption and certificate/card encryption/decryption compatible with MoldSign Desktop. Safe removal is a separate confirmed operation, never an automatic consequence of encryption.

## Compatibility evidence

Reference: installed MoldSign Desktop 2.0 workers (private reverse-engineering workspace; do not copy vendor code into distributed source).

- Password AES files: 16-byte salt, 16-byte IV, SHA-512 of ASCII key size (128/192/256), then AES-CBC/PKCS#7 ciphertext. Password derivation is Bouncy Castle PKCS#12 SHA-256, key diversifier 1, 65,537 iterations; this is **not PBKDF2**. Extension `.symmetric.p7m`.
- Older password CMS EncryptedData: PKCS#12 SHA-1/3DES, MD5/DES and SHA-1/40-bit RC2. Read-only legacy support; do not offer weak algorithms for new encryption.
- Certificate CMS EnvelopedData: AES-128-CBC, RSA PKCS#1 v1.5 key transport, recipient issuer/serial. Validate keyEncipherment and card key capability; signing-only keys must not receive decryption operations. Reads the vendor bare streaming BER representation and emits DER ContentInfo, accepted by the vendor IAIK CMS library; extension `.asymmetric.p7m`.
- Vendor overwrite modes advertise random/DoD/Gutmann passes. Their implementation is not an erasure guarantee. Never reproduce a false guarantee on flash, copy-on-write, snapshots or cloud/provider files.

## Delivery sequence and acceptance gates

1. Generate synthetic interoperability fixtures with the installed vendor libraries; test both directions independently, including Unicode passwords, empty files and block boundaries.
2. Add bounded parsers, password and CMS cryptography to all three native cores. Reject unknown identifiers, truncation, excessive sizes and invalid padding without exposing partial output.
3. Add recipient discovery and card unwrap through the existing serialized card service. Bind consent/PIN to the selected encryption certificate, stop on any PIN error, test APDUs with simulated cards before any physical-card use.
4. Add exclusive output creation and original preservation; passwords/PINs stay out of logs, history and command arguments. No automatic opening of decrypted content. Explain that legacy CBC compatibility cannot detect every modification or wrong password.
5. Add consistent pick → choose protection → confirm → save/share flows in Documents, adaptive layouts, progress/cancel, accessible labels, localized EN/RO/RU and clear errors.
6. Safe removal: explicit selection and confirmation, local regular files only for overwrite attempts, refuse symlinks/hardlinks/unsupported providers, never promise physical erasure. Offer ordinary provider deletion only when supported and label it accurately.
7. Run native core suites, vendor interoperability, simulator/emulator/desktop interactions; capture fictional-data screenshots of entry, form, result/error and removal confirmation in light/dark. Record exact evidence and remaining hardware limits.

## Implementation status (2026-11-09)

Implemented in Swift/C, Kotlin and C#: bounded password/CMS codecs, legacy password decryption, PKCS#15 encryption-key discovery, extended secure-message APDUs, serialized card unwrap with identity revalidation and no PIN retry. New encryption uses AES only. Android has a read-only RC2 implementation because the emulator has no RC2 JCA provider; it is checked against all eight RFC 2268 vectors and vendor files.

Documents exposes localized Protect files forms on Apple, Android, Windows and Linux. Desktop forms include a separately confirmed overwrite/removal action; mobile does not claim it can overwrite provider storage. CLI commands are documented in [the CLI contract](../cli.md#file-protection). Outputs are not added to signed-document history and do not cause the original to be removed.

Validation evidence and remaining gates are recorded in [the feature report](../../docs/reports/file-protection-2026-11-09.md). Physical-card decryption is not yet validated: software fixtures and simulated cards establish cryptographic/APDU behavior, not the capabilities of the owner's card. This feature has not been released.

### Native app algorithm selection (unreleased)

For a password-protected file, choose AES-128, AES-192 or AES-256. The default remains AES-256. Each choice uses the corresponding MoldSign password envelope marker, so recipients supply their password without selecting a key size. Existing legacy password envelopes retain their read support.

For a recipient, choose **RSA certificate** and import the recipient’s public X.509 encryption certificate. CMS uses RSA to wrap a fresh AES-128 key for each file. Decryption requires the corresponding private encryption key and, for a supported card, its reader and PIN. A signing-only eID cannot act as that recipient.
