---
title: macOS CLI
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# macOS — command-line guide

Reach a specific goal using the numbered terminal examples below. Commands stay in English. The illustrated panels are instructional examples, not screenshots of a real card signing. Only the capability and unsigned-fixture verification results were captured from a local executable; no real PIN, card or credential provider was used.

You need a supported electronic ID and its correct signing PIN, a compatible USB reader and any required adapter for card operations. NFC is not supported. Verification needs no reader or PIN. Keep your original documents. The private signing key stays on the card.

## 1. Install and discover what your executable supports

Open [Downloads](/downloads/) and choose your platform. CLI archives contain terminal and MCP tools; the desktop application is a separate installation. Use the package-manager instructions there for the current version and signing-key fingerprint. Then locate the command and inspect capabilities before automating.

<GuideScreenshot src="/img/guide/macos-cli/en/install.svg" alt="1. Install and discover what your executable supports" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Install through the selected platform channel."}, {"x": 3, "y": 83.2, "text": "Run capability discovery before using card commands."}]} />

```sh
brew install xfreebird/utils/esemnbun-cli
command -v esemnbun
esemnbun capabilities --json
```

<GuideScreenshot src="/img/guide/macos-cli/en/capability.svg" alt="command-line guide" caption="Captured local read-only capability output." steps={[{"x": 3, "y": 5.1, "text": "Run capability discovery before using card commands."}]} />

```sh
esemnbun capabilities --json
```

The captured local build reports MCP unavailable from its ordinary CLI capability envelope; the separate installed esemnbun-mcp helper has its own discovery. Always inspect your installed binaries.

## 2. Find the reader and check the certificate

Connect the USB reader and insert your card. List readers, then inspect the signing certificate without entering a PIN. With several cards, use the exact reader name and check the holder before every signing request. These commands below are examples; a reader was not accessed to create this guide.

<GuideScreenshot src="/img/guide/macos-cli/en/reader.svg" alt="2. Find the reader and check the certificate" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "List connected readers and card presence."}, {"x": 3, "y": 53.5, "text": "Read the intended certificate; replace the reader name."}, {"x": 3, "y": 83.2, "text": "Calculate SHA-256 of the exported certificate. Use these 64 hexadecimal digits for unattended signing, not the SHA-1 shown by cert."}]} />

```sh
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
shasum -a 256 leaf.der
```

## 3. Sign PDF or create an XML signature

PDF signing embeds a PAdES-T signature and timestamp. Omitting the output path creates a separate `-semnat.pdf` file; existing outputs are not overwritten. XAdES defaults to detached XML and SHA-256: retain the unchanged original with the XML. Choose BES without timestamp, T with timestamp, or C with certificate/revocation references. Use `--enveloping` only when the recipient wants the original inside XML. Timestamped formats need network access; C also obtains status references.

<GuideScreenshot src="/img/guide/macos-cli/en/sign.svg" alt="3. Sign PDF or create an XML signature" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Start PDF signing and respond to the no-echo PIN prompt."}, {"x": 3, "y": 53.5, "text": "Create the XML level your recipient requires."}, {"x": 3, "y": 83.2, "text": "Use enveloping only when needed; keep originals for detached XML."}]} />

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf
esemnbun xades XAdES-T Declaration.txt Declaration.xml
esemnbun xades XAdES-BES Declaration.txt Embedded.xml --enveloping
```

Enter the PIN only through the no-echo prompt or an existing secret-input caller with `--pin-stdin`. Input precedence is stdin, `MSIGN_PIN`, then prompt. Never put a PIN in command arguments, screenshots, scripts or logs. An incorrect PIN needs a deliberate stop and review; never retry automatically.

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf --pin-stdin
```

## 4. Verify and interpret the result

Choose the signed PDF or XML. For detached XML, provide the directory containing its unchanged originals. Verification is offline: integrity, signature and embedded trust results do not establish current revocation status. `ok:true` means execution succeeded, not that the signature is valid. No recognized signature is not a successful signed-document verification.

<GuideScreenshot src="/img/guide/macos-cli/en/verify.svg" alt="4. Verify and interpret the result" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Verify a PDF or XML using the original-document directory."}, {"x": 3, "y": 83.2, "text": "Use JSON for automation and inspect status, not only ok."}]} />

```sh
esemnbun verify Contract-semnat.pdf
esemnbun verify Declaration.xml /home/me/Originals
esemnbun verify --json Contract-semnat.pdf
```

<GuideScreenshot src="/img/guide/macos-cli/en/unsigned.svg" alt="command-line guide" caption="Captured local read-only output; this is an unsigned fictional fixture, not a verified signature." steps={[{"x": 3, "y": 16.7, "text": "Use JSON for automation and inspect status, not only ok."}]} />

```sh
esemnbun verify --json unsigned.pdf
```

`valid` and `unconfirmed` exit 0; the latter leaves trust unconfirmed. `invalid`, `incomplete` and `no_recognized_signature` exit 2. Missing originals alone mean incomplete, not proven modification. Exit 1 is usage/input failure; card operations use 3 wrong PIN, 4 blocked PIN, 5 no reader/card and 6 trust-service network failure. Stop after PIN errors. The app cannot unblock the card.

## 5. Connect an MCP host with explicit file access

Configure a local host that supports the implemented protocol with an absolute executable path and a trusted root you selected. Substitute your own existing physical directory. Client-advertised roots do not grant access. Symlinks, path traversal and special files are rejected. No root means discovery only. The helper uses stdio, not a network signing endpoint. Files are bounded to 8 MiB; detached XML originals need an explicitly selected detached root.

<GuideScreenshot src="/img/guide/macos-cli/en/mcp.svg" alt="5. Connect an MCP host with explicit file access" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 58.5, "text": "Choose the installed executable and a narrow document root."}, {"text": "Let the host discover capabilities, then request offline verification."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing
```

Use `capabilities` and `verify_document` first. Tool input identifies `{rootId,relativePath}`; never put a PIN or document contents in tool arguments. MCP verification returns minimized metadata. The host may send that metadata to its own external services. See [complete MCP setup and policy](https://esemnbun.md/packages/mcp.md) for exact protocol and host configuration. [Configurations and reusable skills for ten AI agents](https://esemnbun.md/docs/integrations/mcp-agents/) (English).

```json
{
  "command": "/opt/homebrew/bin/esemnbun-mcp",
  "args": [
    "--root",
    "documents=/Users/me/Documents/Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```

## 6. Request signing with foreground Mac approval

In the Mac app enable the agent approval broker in Settings and use its configured private spool directory. The app and helper must run as the same user. The directory and requests/responses/outputs subdirectories must already exist with mode 0700. Start the helper with that directory. In your host call prepare_signing for a PDF, review the native certificate/document request, approve with the card PIN, poll get_job and retrieve the completed output. cancel_job requests cancellation; it cannot undo a signature already in progress. Requests expire after five minutes and outputs are retained for 24 hours. Keep the app running. Windows and Linux also offer desktop approval with their platform-specific private directory; installed-build validation is required.

<GuideScreenshot src="/img/guide/macos-cli/en/broker.svg" alt="6. Request signing with foreground Mac approval" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 33.8, "text": "Enable the Mac app broker and use its displayed private directory."}, {"x": 3, "y": 76.1, "text": "Prepare a request in the host, then approve in the app."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing \
  --broker-directory /Users/me/PrivateBroker
```

## 7. Configure explicit unattended signing

This advanced opt-in signs without a per-document approval dialog. Provision credentials independently, pin the exact signing-certificate DER SHA-256, and create a dedicated private output directory. Use secret-provider references, never PIN values. The helper checks the card certificate before reading a secret or sending VERIFY. Physical-card/provider behavior needs validation for your installation before production use.

<GuideScreenshot src="/img/guide/macos-cli/en/unattended.svg" alt="7. Configure explicit unattended signing" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 27.4, "text": "Set a narrow input root and private output directory."}, {"x": 3, "y": 80.6, "text": "Pin the exact certificate and choose a secret-provider reference."}]} />

```sh
esemnbun-mcp \
  --root documents=/Users/me/Documents/Signing \
  --allow-unattended-signing \
  --signing-certificate-sha256 <CERTIFICATE_SHA256> \
  --signing-output-directory /Users/me/PrivateOutput \
  --pin-source keychain:service:account
```

macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN`, or `onepassword:op://Vault/Item/field`. Linux: `secret-service:service:account`, environment or 1Password. Windows: `credential:eSemnBun-Automation`, environment or 1Password with an explicit absolute op.exe path. A separately provisioned Keychain/Credential Manager entry must allow the intended access; the app biometric vault is not weakened. Authenticate 1Password outside MCP.

Replace `<CERTIFICATE_SHA256>` with the exact 64 hexadecimal digits before running. The output folder must already exist; macOS/Linux require ownership by you and mode0700. Windows allows only your account, SYSTEM and Administrators in its ACL.

Before signing, the helper creates `.unattended-signing-lock` in the output directory. Wrong PIN, interrupted execution or uncertain failure leaves this durable marker and prevents another automatic attempt. Inspect output and card outcome, reconcile deliberately, then remove the marker and restart only when appropriate. Never write an automatic lock-deletion/retry loop. A cancellation or timeout does not prove no signature was made.

## 8. Run the local browser connection

Run the bridge in the foreground and keep it running while using the supported site on this computer. The defaults are loopback HTTP18480 and HTTPS18443. Do not run the GUI bridge or vendor MoldSign on the same ports. Stop with Ctrl+C. The package needs its localhost HTTPS identity. Prefer the desktop app when you need native consent/PIN dialogs; a terminal bridge is not that approval UI.

<GuideScreenshot src="/img/guide/macos-cli/en/service.svg" alt="8. Run the local browser connection" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 33.8, "text": "Start the local browser bridge."}, {"x": 3, "y": 76.1, "text": "Stop with Ctrl+C when finished."}]} />

```sh
esemnbun server
# Ctrl+C
```

---

Advanced reference: macOS/Linux also expose `sign-hex <digestinfo_hex>` and `cms-for-hash <sha256_hex>`; Windows has sign-hex only. These are developer primitives, not document signing. Read the CLI contract before using them. For support include app/OS version, command without secrets, exit code and a fictional reproducer. Never attach PINs or confidential files.

<!-- file-protection-guides -->

## Encrypt a file with a password

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-password.svg" alt="Encrypt a file with a password" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc
```

## Encrypt for a certificate holder

Ask the recipient for their public encryption certificate (.cer/.der), exported using the next guide. Confirm its fingerprint with its owner through a trusted channel. A signing-only certificate is not sufficient. Encrypting for someone else needs their public certificate, not their card, private key or PIN.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-certificate.svg" alt="Encrypt for a certificate holder" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc --certificate recipient.cer
```

## Decrypt a received file

Ask the sender which method they used. For password files, obtain the password separately. For certificate files, connect the matching supported card and reader; you need its encryption key and PIN. A different card or signing-only card cannot unlock the file.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-decrypt.svg" alt="Decrypt a received file" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun decrypt Contract.enc Contract-opened.pdf
esemnbun encryption-certs
esemnbun decrypt Contract.enc Contract-opened.pdf --card SHA256
```

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

## Share your encryption certificate

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-export.svg" alt="Share your encryption certificate" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun encryption-certs
esemnbun encryption-certs --card SHA256 --out recipient.cer
```

Share only recipient.cer; exporting needs no PIN and never exports the private key.

## Remove a local file

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-remove.svg" alt="Remove a local file" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun remove-file disposable-copy.pdf --confirm-removal
```
