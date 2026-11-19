# Card public-key compatibility across platforms — 19 November 2026

The working patch provides the same explicit public-key compatibility policy on every native app and desktop CLI. Default RSA certificate mode still requires X.509 keyEncipherment. Compatibility treats the exported public certificate as an RSA key container; senders importing it and recipients decrypting its files select the option explicitly. The encrypted file never enables that policy automatically.

## Platform coverage

| Surface | Explicit selection | Public certificate export and file operations | Validation status |
| --- | --- | --- | --- |
| iPhone/iPad and macOS | Card public key compatibility in shared Protect files form | Public card read/export, imported recipient encryption, card decryption | Prior physical iPhone read/export and production-core decryption passed; full main-app file journey, iPad and macOS pending |
| Android | Same option in Protect files | Same operations through Kotlin core and native document access | Source/resources and regression sources updated; build/runtime pending |
| Windows native | Same option in Protect files | Same operations through C# core and native file pickers | Source/resources and regression sources updated; build/runtime pending |
| Linux GNOME | Same option in Protect files | Same operations through shared Swift core and native file pickers | Source/resources updated; native build/runtime pending |
| macOS/Linux CLI | `--card-public-key` | `encryption-certs` listing/export and certificate/card encrypt/decrypt | Source updated; new executable and command execution pending |
| Windows CLI | `--card-public-key` | Same command contract | Source and hardware-free command regression sources updated; build/execution pending |

Certificate export requires neither a document nor a PIN. It writes exact public X.509 DER through each platform's existing save mechanism. Export includes no private key. Native forms clear recipient selection and entered secrets when the policy changes, so a previously selected identity cannot silently cross modes. Asynchronous card reads reject a changed reader or known certificate while tolerating transient reader-monitor hydration. The card core independently re-discovers the actual selected identity before PIN verification.

## Core behavior and regression coverage

- Swift, Kotlin and C# retain the explicit policy in the discovered card identity and pass it through certificate import, encryption and decryption. RSA algorithm/modulus bounds apply in both policies. Default-purpose rejection has no automatic compatibility fallback.
- Discovery still requires an unambiguous PKCS#15 key/certificate/PIN association, decipher usage, matching RSA modulus and supported numeric PIN reference/length/encoding. ASCII-numeric and UTF-8 PIN metadata support numeric input only. Fresh discovery must match the selected certificate and key before VERIFY; there is no automatic authentication or PIN retry.
- All three secure-response decoders require authenticated status and MAC. An outer non-success status must agree with the authenticated status. Final EOF chunks survive authentication and strict unpadding; duplicate/missing/malformed status or MAC, invalid padding and conflicting status fail. Windows mutual-authentication prerequisites now check response status and exact serial/seed/challenge lengths; the serial read requests 18 bytes and skips two without assuming their value.
- CLI policy is explicit for listing, exact-fingerprint export and file operations. It is rejected for password operations and removal. Invalid fingerprints fail before card access; secret values remain outside command arguments. Existing exclusive output creation and original preservation remain in use.
- The shared fictional `spec/vectors/encryption/test-signing-only.der` has critical Non Repudiation and no keyEncipherment, with an intentionally public fixture key. Swift/Kotlin/C# regression sources require strict rejection, explicit compatibility round-trip and wrong-recipient rejection before private callbacks. Card simulators cover policy, numeric UTF-8 metadata, changed capability and single PIN/decipher admission. Windows adds authenticated short/boundary EOF and malformed secure-response coverage plus CLI flag/offline encryption/output-preservation coverage.

The physical evidence is limited to the tested iPhone 13 Pro, bit4id reader and owner's card. Earlier controlled probes restored a random 16-byte challenge and an independently OpenSSL-encrypted 4096-byte file exactly, each with one VERIFY and one decipher. The main iPhone app exported the exact 1799-byte public certificate through Files. See [the investigation report](ios-encryption-certificate-2026-11-19.md) for evidence, privacy handling and limits. No additional physical-card/PIN operation was performed for this parity change.

## Checks and remaining acceptance

Passed source checks: complete EN/RO/RU localization generation/drift check for all four resource targets, Swift frontend syntax parsing of edited handwritten Swift files and `git diff --check`. The fictional certificate was inspected with OpenSSL. Syntax parsing does not establish type correctness or a native build.

Per the owner's standing rule, new native builds and automated suites were not run. Suggested owner verification from the repository root:

```sh
(cd swift/MoldSignKit && swift test)
scripts/test-portable-macos.sh
(cd android && ./gradlew :core:test :app:assembleDebug)
(cd windows && dotnet test MoldSign.Portable.slnf)
# On the configured Linux host:
(cd linux && swift build && swift test)
```

Also build the Apple iOS/macOS schemes and Windows WinUI app on their native hosts using the documented development signing flow. On each native surface, verify default rejection and explicit compatibility with the fictional fixture, independent public export without document/PIN, cancellation and mode-change clearing, then encrypted-file save with original preservation. Exercise card decryption only with an approved supported card and explicit PIN authorization; stop at the first error. Recheck Windows signing flows because its secure-response validation is shared with signing. Portable core tests do not establish native picker/reader behavior.

No commit, push, release, store submission or new installation was performed for the parity change. Previously installed iPhone builds remain the hardware evidence and do not validate subsequent source changes on other platforms.
