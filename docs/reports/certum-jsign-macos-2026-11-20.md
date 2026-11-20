# Certum Windows signing from macOS — 20 November 2026

## Result

Jsign running natively on the owner's Apple Silicon Mac signed copies of the eSemnBun 0.2.14 Windows MSI and Native AOT CLI executable through Certum SimplySign Desktop. Both files passed independent osslsigncode verification on macOS and Microsoft SignTool verification on Windows, with verified RFC 3161 timestamps and the intended publisher. Windows reported `Status: Valid`, zero warnings and zero errors for each file.

The initial validation used local artifacts and did not publish them. The owner subsequently authorized publication; that follow-up is recorded below. The public 0.2.14 MSI had previously been signed and published using Windows SignTool. No application rebuild or release-workflow change was needed for either signing path.

## Inputs and outputs

The MSI input was the preserved original 0.2.14 installer, SHA-256 `e7c4337f1212ca1ac74efb6867aa0fc77e5575db1c843aea4a045b67eb70a99b`. Jsign replaced its self-signed installer signature on a copy. The Windows CLI input came from the published `esemnbun-cli-0.2.14-windows-x64.zip`, SHA-256 `cccf0a2e35636be9405e66adddd22b385db2ccc2acc93d5b60cd67f8089c73af`; its original executable was unsigned. Downloaded archive hashes matched the GitHub release asset digests.

| Local output | SHA-256 | macOS verifier | Windows verifier |
| --- | --- | --- | --- |
| `eSemnBun-0.2.14-x64-jsign.msi` | `66ead49bd2e73379698df8c4c33827e5142c71751961284939631b6c90742707` | Signature, timestamp, chain and CRL checks passed | SignTool `/pa /all /v /tw` passed; Authenticode Valid |
| `esemnbun-jsign.exe` | `0f5d4a6d9d52638edd72f2f8f2a82b4588d16a199e08891ce9ed009d23751d92` | Signature, timestamp, chain and CRL checks passed | SignTool `/pa /all /v /tw` passed; Authenticode Valid |

Output files and detailed verifier logs are in ignored `.local/certum-signing/jsign-macos/`. The Windows transfer hashes matched these local output hashes.

## Tested setup

- SimplySign Desktop 2.10.24 / proCertum SmartSign 9.4.5.0 from Certum's official macOS DMG. `pkgutil --check-signature` verified the Asseco Data Systems SA Developer ID Installer identity (`3A63AEGXJ7`), trusted timestamp and Apple notarization.
- The installed app and `/usr/local/lib/libSimplySignPKCS.dylib` are universal arm64/x86_64 binaries. An Intel-only description in older package-manager metadata did not describe this downloaded package. No Rosetta was required for this test.
- Homebrew Jsign 7.6, OpenJDK 21.0.13.1, OpenSC 0.27.1 and osslsigncode 2.16. Jsign's Java process ran on the Mac; Windows was used only for independent verification of these test signatures.
- The owner connected SimplySign Desktop using the phone-generated one-time code. The PKCS#11 token advertised no login requirement and PIN min/max `0/0`; Java accepted the pinless token with an empty store password.
- SunPKCS11 used `slotListIndex = 0`; the first token's numeric slot ID was `0x1`. Keytool exposed a PrivateKeyEntry under the public certificate serial alias. The exported public certificate matched the intended certificate before signing.

The signer was `Open Source Developer Nicolae Ghimbovschi`, issued by `Certum Code Signing 2021 CA`, with SHA-1 thumbprint `A888E140E811BE3E3B4007129FE38CF69F858454` and certificate SHA-256 fingerprint `8D08A4CC3503AF961C09A7FCB642C50D4582E6323E026583E0016151737D6CBD`. Both outputs used SHA-256 Authenticode signatures and RFC 3161 tokens from `http://time.certum.pl`. The timestamp authority was `Certum Timestamp 2026`.

## Reusable details

The tested procedure is in [the new signing skill](../../.agents/skills/esemnbun-certum-sign/SKILL.md). It is linked from the existing build/release skills and the repository's skill index.

- SimplySign must be running and connected. Before connection, the PKCS#11 module reported `No slots`. The cloud certificate is accessed through this module; an exportable private-key PFX is not involved.
- Direct Java invocation with `-Djava.net.useSystemProxies=false` avoids the Homebrew Jsign launcher's system-proxy default while leaving OS proxy settings intact.
- Jsign 7.6 signs files but does not implement the website's preview `verify` command. Independent verification used osslsigncode and Microsoft SignTool.
- The Mac's default `/etc/ssl/cert.pem` lacked the required Certum Trusted Network CA 2 root. Verification passed with Homebrew's maintained CA bundle at `/opt/homebrew/etc/ca-certificates/cert.pem`, supplied explicitly for signer and timestamp trust. No verification checks were disabled and no leaf certificate was installed as a trust anchor.
- Windows CLI and MCP share `esemnbun.exe`; `mcp` is a command mode. A separate MCP executable does not need signing on Windows.
- Signing an existing MSI covers its container. It does not add separate signatures to embedded EXE/DLL files. Future package builds should sign their payload binaries before creating the MSI, then sign the final installer and regenerate all affected archive/package hashes.

## macOS binary status and limits

The published `esemnbun-0.2.14-macos-universal.tar.gz` hash matched `933c814eb9e6c135157b3c55e8a2ac8a55b9861f31d481948446817de5828f2a`. Its `esemnbun` and `esemnbun-mcp` executables already had valid hardened-runtime, timestamped signatures from `Developer ID Application: Nicolae Ghimbovschi (H86U5Z8HYB)`. Both passed `codesign --verify --strict --check-notarization --verbose=2`. The app-oriented `spctl --assess --type execute` check described these raw tools as valid code but not apps; it was not used as the CLI notarization acceptance check.

Certum Authenticode signing addresses Windows files. Native macOS distribution continues to use Apple Developer ID and notarization through the existing packaging script.

No native builds, installer execution, CLI/MCP runtime journeys or SmartScreen reputation acceptance were tested. No OTP seeds, access tokens, signing PINs, private keys or authentication configuration were added to the skill or report. The new skill passed its structural validator; live signing and verification evidence is recorded above.

## Authorized publication follow-up

On the owner's subsequent request, the validated Jsign outputs replaced the matching v0.2.14 Windows release artifacts under their existing filenames:

- `eSemnBun-0.2.14-x64.msi`: SHA-256 `66ead49bd2e73379698df8c4c33827e5142c71751961284939631b6c90742707`.
- `esemnbun-cli-0.2.14-windows-x64.zip`: SHA-256 `d856228fdddedf2ef15b00e2f92c2ed4cd392453ae42ad888071e5969564cd78`. The ZIP preserves the original entry names and LICENSE bytes; its `esemnbun.exe` exactly matches the verified signed executable above.

The release checksum entries were updated. [CLI package repositories run 44731168619](https://github.com/xfreebird/smartcard/actions/runs/44731168619) passed both jobs and regenerated the Scoop definition, embedded Chocolatey package and repository download copy from the signed ZIP. Its checks passed for APT installation, RPM signatures, Chocolatey installation/uninstallation and CLI help. These checks do not establish real-card signing or MCP runtime acceptance. The website workflow separately refreshes the public mirrors.

Downloaded GitHub assets matched their published digests. Every entry in the regenerated `SHA256SUMS.txt` matched the corresponding release asset digest. The Scoop definition references the new CLI ZIP hash; the Chocolatey package embeds executable SHA-256 `0f5d4a6d9d52638edd72f2f8f2a82b4588d16a199e08891ce9ed009d23751d92`; the package-repository archive carries the exact new CLI ZIP and matching definition-bundle hash. All unrelated platform release assets retained their original asset IDs and digests.

Derived asset SHA-256 values:

| Asset | SHA-256 |
| --- | --- |
| `esemnbun-cli.0.2.14.nupkg` | `485c9c30c3f3e6bf4ed2ba0a4b8192edb5634ec4def38913c75a19d25ca635d5` |
| `esemnbun-package-definitions.zip` | `b8591a967d8a7915bde969b1bc89d6c033d1d894707b3a6e4195df11d196d0df` |
| `esemnbun-package-repositories.tar.gz` | `952af95b421e5f283b4613532a2e7f5eb2627b940072b040fce2adb02f86f898` |

The source changes add the signing skill, cross-links and manual-signing guidance, record this validation, and refresh the Windows download size and EN/RO/RU signing note. The desktop update-feed version remains 0.2.14; a signature-only replacement is not a new application version.

## Primary references

- [Certum macOS software download](https://support.certum.eu/en/software/procertum-smartsign/)
- [Jsign PKCS#11 and command documentation](https://ebourg.github.io/jsign/)
- [osslsigncode](https://github.com/mtrojnar/osslsigncode)
- [Apple Developer ID signing and notarization](https://developer.apple.com/developer-id/)
