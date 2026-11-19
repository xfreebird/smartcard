# iOS public certificate probe

Standalone development app `md.esemnbun.certificateprobe`, separate from eSemnBun and the NFC probe. Uses the connected USB/Lightning reader through CryptoTokenKit. Modes 1–3 read public data without a PIN. Separately initiated modes 4–5 perform one PIN verification and one synthetic decipher, each protected by its own persistent lock. No mode signs, manages PINs or writes to the card. Never uninstall the shipping app or the probe to bypass a lock.

1. Refresh readers, explicitly choose the reader holding the intended card, then run **1. Read public files** once. The only commands are direct Generic ADF SELECT, SELECT EF `7001`/`7002`/`7005`/`0001`, bounded READ BINARY and bounded GET RESPONSE. One READ/GET RESPONSE length correction is permitted; no transport retries. Missing files are reported; security-state/retry-counter errors stop immediately.
2. Collect the report before using **2. Check app encryption discovery**. This separately confirmed check uses the current production secure-channel setup and `encryptionIdentities()` parser. No PIN is sent. Do not repeat a failed authentication/security-state check without investigation.
3. Reports and public files are saved under Files → On My iPhone → Certificate Probe, using complete file protection. They may contain identity information; retrieve into ignored `.local/` only. Exact parsed X.509 certificates have an explicit Share action. Export alone does not establish card decryption support.

`project.yml` is authoritative. Generate with `xcodegen generate --spec probes/ios-certificate/project.yml`. Build the `CertificateProbe` scheme for the explicit attached device, using a development signing team. The app links the current local MoldSignKit package; no vendor TLS identity is bundled or needed.

Retrieve after the owner completes a scan:

```sh
xcrun devicectl device copy from --device '<DEVICE_UDID>' \
  --domain-type appDataContainer --domain-identifier md.esemnbun.certificateprobe \
  --source Documents --destination .local/certificate-investigation/<NEW_COLLECTION>
```

Do not infer a private decipher capability from an RSA signing certificate. Modes 4–5 were prepared only after directory/control-parameter review established the card's advertised decipher capability. Default production certificate-purpose checks remain separate from the explicitly selected card public-key compatibility policy.

## Build 2

The first public route stopped at direct Generic ADF selection (`6A86`). Production authentication succeeded, then encryption discovery reported `Card not responding`. Build 2 adds operation names, reply byte counts and outer status words, without payloads. Its second check first runs the normal exact-length signing-certificate reader as a control, then reads each of the three encryption directory files through a Debug-only fixed-file diagnostic API, saving the public bytes locally. Only after those reads does it run the production parser. A failed prerequisite stops the check. The control certificate is clearly named `signing-certificate.cer`; its RSA recipient validation result is reported separately.

## EOF findings and build 5

Build 2 isolated a protected final READ with outer `6282`. Build 3 authenticated that warning and obtained EF `7001`, then reached a protected outer `6B00` after an exact-block-length file. Build 4 handles both through mandatory MAC verification and matching authenticated/outer non-success statuses. It obtained `7001` (347 bytes), `7002` (2048) and `7005` (4000), then completed discovery with zero supported identities.

The directories list one RSA-4096 key and one certificate. The key advertises decipher/unwrap; the certificate's critical Key Usage contains only Non Repudiation. The PIN metadata uses UTF-8 encoding, while production encryption discovery accepts only its narrower ASCII-numeric profile. These observations are distinct from proof of a working decipher operation.

Build 5 adds **3. Read key access conditions (no PIN)**. It uses the vendor CosmoX `get_DOCP` GET DATA template, requesting only A0 public control parameters for the directory-listed key 1 (class 90) and PIN 3 (class 81), under Generic ADF. It does not request private-key/PIN values, verify a PIN, change a retry counter or send PSO DECIPHER. The transport filter now permits protected GET DATA for this fixed probe path. Store the results only in ignored local evidence.

Support regressions are in `Tests/`; the owner can run `swift test --package-path probes/ios-certificate`. Core regressions cover authenticated EOF chunks, block-boundary EOF, corrupted/missing MACs and status disagreement. Automated tests have not been run during this investigation.

## Controlled private operations

Mode 4 binds the current certificate, uniquely joins the key/PIN/certificate directories, checks actual key/PIN public control parameters, then wraps one random 16-byte value and performs one VERIFY/ref03 and one vendor-compatible RSA decipher. A matching result establishes only that primitive on the tested card. The lock is exclusively created before VERIFY and survives restarts/updates.

Mode 5 is a distinct, separately initiated file acceptance check. Keep the original capability lock. Place synthetic `original.bin`, independently OpenSSL-encrypted `sender.asymmetric.p7m` and the matching exact `recipient.cer` under `Documents/file-sharing-input`. It discovers the card with explicit `.cardPublicKey` policy, binds exact certificate DER, produces a native CMS envelope, and decrypts the OpenSSL envelope through the production card method. It saves `restored.bin` only after exact byte comparison. A separate exclusively created file-test lock precedes VERIFY; there are no automatic retries.

Both modes succeeded on the physical iPhone 13 Pro/card/bit4id reader on 19 November 2026. The file result matched all 4096 original bytes. Neither operation created a signature. These observations do not establish other card generations or universal certificate-purpose suitability.

The owner explicitly requested a PIN embedded in temporary device probe builds. Such a build may override Info.plist from a mode-0600 file under ignored `.local/`, containing `ProbeDiagnosticPIN`; the maintained source contains only the optional lookup, never the value. Never pass the value in build arguments or log it. After the authorized check, install a normal build, verify the app plist has no such key, remove private input files, and preserve both attempt locks and reports. Do not embed a PIN in the shipping app or commit it.
