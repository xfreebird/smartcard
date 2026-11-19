# File protection: implementation and validation plan

## Scope

Provide discoverable **Protect files** tools in Documents on Apple, Android, Windows and Linux, plus desktop CLI commands. Support password encryption/decryption and certificate/card encryption/decryption compatible with MoldSign Desktop. Safe removal is a separate confirmed operation, never an automatic consequence of encryption.

## Compatibility evidence

Reference: installed MoldSign Desktop 2.0 workers (private reverse-engineering workspace; do not copy vendor code into distributed source).

- Password AES files: 16-byte salt, 16-byte IV, SHA-512 of ASCII key size (128/192/256), then AES-CBC/PKCS#7 ciphertext. Password derivation is Bouncy Castle PKCS#12 SHA-256, key diversifier 1, 65,537 iterations; this is **not PBKDF2**. Extension `.symmetric.p7m`.
- Older password CMS EncryptedData: PKCS#12 SHA-1/3DES, MD5/DES and SHA-1/40-bit RC2. Read-only legacy support; do not offer weak algorithms for new encryption.
- Certificate CMS EnvelopedData: AES-128-CBC, RSA PKCS#1 v1.5 key transport, recipient issuer/serial. Default policy requires keyEncipherment; explicit public-key compatibility is described below. Every card path requires advertised decipher capability and exact recipient/key admission before PIN. Reads the vendor bare streaming BER representation and emits DER ContentInfo, accepted by the vendor IAIK CMS library; extension `.asymmetric.p7m`.
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

Original validation evidence and remaining gates are recorded in [the feature report](../../docs/reports/file-protection-2026-11-09.md). Those software fixtures and simulated cards establish cryptographic/APDU behavior. The November 19 physical-card acceptance and unreleased compatibility extension are described below.

### Native app algorithm selection (unreleased)

For a password-protected file, choose AES-128, AES-192 or AES-256. The default remains AES-256. Each choice uses the corresponding MoldSign password envelope marker, so recipients supply their password without selecting a key size. Existing legacy password envelopes retain their read support.

For a recipient, choose **RSA certificate** and import the recipient’s public X.509 encryption certificate. CMS uses RSA to wrap a fresh AES-128 key for each file. Decryption requires the corresponding private key and, for a supported card, its reader and PIN. The certificate's declared purpose and the card key's actual capabilities must be evaluated separately.

### Explicit card public-key compatibility (2026-11-19, unreleased)

Every native app (macOS, iPhone/iPad, Android, Windows and Linux) exposes an explicit **Card public key compatibility** option. The macOS/Linux Swift CLI and Windows CLI use `--card-public-key` for listing, export and certificate/card file operations. With this option, a certificate serves as the public RSA key container; this does not assert that its issuer approved encryption usage. The default certificate path continues to require `keyEncipherment`. Senders importing the certificate and recipients decrypting its files select the compatibility option explicitly. The CMS format and algorithms are identical in both modes.

Card discovery still requires a unique PKCS#15 key/certificate/PIN association, advertised decipher usage, matching modulus size, the supported PIN reference and supported numeric PIN encoding. ASCII-numeric and UTF-8 metadata are accepted for numeric input only. The discovered identity retains its policy; decryption checks the CMS recipient and re-discovers that exact identity before VERIFY. There is no automatic PIN retry. Export writes exact public DER, without PIN/private-key data or a document requirement.

Physical iPhone 13 Pro investigation established that the owner's RSA-4096 key advertises decipher/unwrap and permits PIN-authorized decipher, although its sole certificate has critical Non Repudiation usage. A single synthetic RSA wrap/unwrap matched all 16 bytes; a separate OpenSSL-encrypted 4096-byte file was restored exactly through the production card method. The actual iPhone app exported the exact public certificate through Files. Evidence and UI/runtime limits are in [the investigation report](../../docs/reports/ios-encryption-certificate-2026-11-19.md). This proves the tested card/reader, not every signing certificate or card generation.

Swift, Kotlin and C# provide the same explicit policy. Their discovered identities retain it for fresh pre-PIN revalidation. All three secure-response decoders require authenticated status and MAC, preserve final EOF chunks, and require any non-success outer status to agree with the authenticated status. Windows additionally checks each mutual-authentication prerequisite and requests the exact 18-byte serial input used by the other cores.

Cross-platform regressions share `test-signing-only.der`: strict mode rejects it, explicit compatibility encrypts/decrypts, and mismatched recipients fail before private-key callbacks. Card simulators cover discovery, numeric UTF-8 metadata, changed capability, EOF and single PIN admission. Source/UI parity and unrun native validation are recorded in [the parity report](../../docs/reports/card-public-key-platform-parity-2026-11-19.md). No build, store delivery or unperformed hardware validation is implied.
