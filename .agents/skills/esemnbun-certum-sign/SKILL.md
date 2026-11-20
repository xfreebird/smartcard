---
name: esemnbun-certum-sign
description: Sign and verify Windows MSI installers and CLI/MCP executables from macOS using Certum SimplySign Desktop and Jsign. Use for manual release signing; publishing and native macOS Developer ID signing use the release and build skills.
---

# Certum signing for Windows files on macOS

This path was verified on Apple Silicon with SimplySign Desktop 2.10.24, its universal PKCS#11 library, OpenJDK 21, Jsign 7.6 and osslsigncode 2.16. See [the validation report](../../../docs/reports/certum-jsign-macos-2026-11-20.md) for the tested artifacts and limits. Discover current installed versions and certificate identity rather than treating these versions or an old certificate alias as permanent.

## Scope and artifact order

- Windows MCP runs through `esemnbun.exe mcp`; signing `esemnbun.exe` covers CLI and MCP modes. The macOS `esemnbun` and `esemnbun-mcp` executables use Apple Developer ID plus notarization through [build/sign](../esemnbun-build-sign/SKILL.md).
- Sign Windows EXE/DLL payloads before packaging, then sign the final MSI. Signing an existing MSI changes the installer signature; it does not add separate signatures to its embedded executables.
- Work on copies of the exact requested artifacts, recording source release/commit and SHA-256. Native compilation is unnecessary for a signature-only operation. Keep the source and already published installer intact during testing.
- A signing test does not authorize publication. For an authorized replacement use [release/stores](../esemnbun-release-stores/SKILL.md). Preserve the release filename, regenerate checksums and affected package-manager hashes, refresh the website's mirrored download, and verify the downloaded bytes. Store MSIX identity/signing is a separate operation.

For a released Windows CLI ZIP, preserve its entry names and LICENSE and replace only the intended executable. The existing `cli-packages.yml` rebuilds the Scoop definition, embedded Chocolatey package and package-repository download copy, then refreshes release checksums. It selects the latest stable release: confirm that this is the intended tag before dispatching. After completion, verify the signed executable hash inside the release ZIP, Chocolatey package and repository archive. The website workflow mirrors these derived assets; its successful deployment is separate from the initial release upload.

## Install and connect

1. Obtain SimplySign Desktop from [Certum's official download page](https://support.certum.eu/en/software/procertum-smartsign/). Verify the package with `pkgutil --check-signature` before installing; the tested installer was signed/notarized as Asseco Data Systems SA (`3A63AEGXJ7`). Complete its license and administrator steps with the owner when required.
2. Install/discover `jsign`, `osslsigncode`, `opensc` and Homebrew's `ca-certificates`. Jsign's Homebrew package supplied OpenJDK 21. Inspect the actual PKCS#11 library with `file`: the tested `/usr/local/lib/libSimplySignPKCS.dylib` supports arm64 and x86_64. Match the Java architecture to the installed library; older package/cask descriptions may describe Intel-only versions.
3. Connect the Mac menu-bar SimplySign application using the owner's SimplySign account and fresh phone-generated one-time code. Do not capture activation QR codes, OTP seeds, access tokens, application configuration or authentication logs in reports or skills. The PKCS#11 library relays to the running, connected desktop app; it cannot replace that login.

```sh
pkcs11-tool --module /usr/local/lib/libSimplySignPKCS.dylib --list-slots
```

`No slots` means the desktop connection is missing or not ready. Resolve that connection rather than probing the user's physical signing card. The tested Code Signing cloud token advertised no login requirement and PIN min/max `0/0`. The empty store password below applies to that pinless token; do not guess PINs or automatically retry an authentication error.

## Bind the certificate and sign a copy

Keep this public provider configuration under ignored `.local/`:

```text
name = SimplySign
library = /usr/local/lib/libSimplySignPKCS.dylib
slotListIndex = 0
```

`slotListIndex` selects the token's position in the list, not its numeric slot ID. The tested first token had slot ID `0x1`. With multiple tokens select the intended token and confirm the certificate before signing.

Resolve `SIGNING_JAVA_HOME` to the compatible JDK (tested: `$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home`), `JSIGN_JAR` to the installed `jsign-*.jar` under `$(brew --prefix jsign)/libexec`, and `PKCS11_CFG` to the configuration file. Use that same JDK's keytool to list aliases:

```sh
"$SIGNING_JAVA_HOME/bin/keytool" -list -storetype PKCS11 -keystore NONE \
  -providerClass sun.security.pkcs11.SunPKCS11 -providerArg "$PKCS11_CFG" \
  -storepass ''
```

The tested alias was the certificate serial number. Export the selected public certificate with keytool `-exportcert` and the same provider arguments, then compare its subject, validity and fingerprint to the intended issued certificate. Set `SIGNING_ALIAS` only after that comparison. Never select a certificate merely because it is the first entry.

Copy the source to a new `SIGNED_COPY`, then sign that copy:

```sh
"$SIGNING_JAVA_HOME/bin/java" -Djava.net.useSystemProxies=false \
  -jar "$JSIGN_JAR" --storetype PKCS11 --keystore "$PKCS11_CFG" \
  --storepass '' --alias "$SIGNING_ALIAS" --replace --alg SHA256 \
  --tsaurl http://time.certum.pl --tsmode RFC3161 --name eSemnBun \
  "$SIGNED_COPY"
```

`--replace` avoids retaining a previous self-signed signature on the copy. Direct Java invocation avoids Homebrew's Jsign launcher's system-proxy default; it does not alter macOS proxy settings. Stop and inspect a signing failure instead of blindly repeating the command. No private key or exportable signing PFX is obtained from SimplySign.

## Verify before packaging or publication

Jsign 7.6 has no `verify` command; the website's verification examples are labelled as an 8.0 preview. Use an independent verifier:

```sh
SIGNING_CA_FILE="$(brew --prefix)/etc/ca-certificates/cert.pem"
osslsigncode verify -CAfile "$SIGNING_CA_FILE" -TSA-CAfile "$SIGNING_CA_FILE" \
  -in "$SIGNED_COPY"
shasum -a 256 "$SIGNED_COPY"
```

Require success for file integrity, signature, timestamp and chain verification. On the tested Mac, osslsigncode's default `/etc/ssl/cert.pem` lacked Certum Trusted Network CA 2; Homebrew's maintained CA bundle validated the issuer and both signatures. Use a maintained trust store rather than disabling verification or trusting the leaf certificate.

For Windows acceptance, copy the exact signed output to Windows and run:

```powershell
signtool verify /pa /all /v /tw "C:\path\signed-file.msi"
Get-AuthenticodeSignature "C:\path\signed-file.msi"
```

Use the same commands for EXE files. Require zero warnings/errors, a verified timestamp, the intended Certum publisher and `Status: Valid`. Compare transfer hashes. Use [environment discovery](../esemnbun-dev-environment/SKILL.md) before selecting a Windows host; a VM is useful for verification but is not required for the Mac signing operation.

Signing does not establish SmartScreen reputation or installer runtime correctness. State which files, hashes and verifiers passed, and whether any release assets were published.
