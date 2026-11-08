---
title: Linux CLI
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Linux — command-line guide

Reach a specific goal using the numbered terminal examples below. Commands stay in English. The illustrated panels are instructional examples, not screenshots of a real card signing. Only the capability and unsigned-fixture verification results were captured from a local executable; no real PIN, card or credential provider was used.

You need a supported electronic ID and its correct signing PIN, a compatible USB reader and any required adapter for card operations. NFC is not supported. Verification needs no reader or PIN. Keep your original documents. The private signing key stays on the card.

## 1. Install and discover what your executable supports

Open [Downloads](/downloads/) and choose your platform. CLI archives contain terminal and MCP tools; the desktop application is a separate installation. Use the package-manager instructions there for the current version and signing-key fingerprint. Then locate the command and inspect capabilities before automating.

On Ubuntu install `pcscd libccid`; on Fedora use `pcsc-lite pcsc-lite-ccid`. Enable `pcscd.socket`. Run card operations in a permitted local session: SSH PC/SC access may differ. CLI packages do not install the GNOME window. Linux uses glibc/OpenSSL/libcurl/PCSC; the archive is not Alpine/musl.

Configure the signed APT repository from Downloads before running apt install. On Fedora use dnf instead.

<GuideScreenshot src="/img/guide/linux-cli/en/install.svg" alt="1. Install and discover what your executable supports" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Install through the selected platform channel."}, {"x": 3, "y": 83.2, "text": "Run capability discovery before using card commands."}]} />

```sh
sudo apt install esemnbun-cli
command -v esemnbun
esemnbun capabilities --json
```

## 2. Find the reader and check the certificate

Connect the USB reader and insert your card. List readers, then inspect the signing certificate without entering a PIN. With several cards, use the exact reader name and check the holder before every signing request. These commands below are examples; a reader was not accessed to create this guide.

<GuideScreenshot src="/img/guide/linux-cli/en/reader.svg" alt="2. Find the reader and check the certificate" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "List connected readers and card presence."}, {"x": 3, "y": 53.5, "text": "Read the intended certificate; replace the reader name."}, {"x": 3, "y": 83.2, "text": "Calculate SHA-256 of the exported certificate. Use these 64 hexadecimal digits for unattended signing, not the SHA-1 shown by cert."}]} />

```sh
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
sha256sum leaf.der
```

## 3. Sign PDF or create an XML signature

PDF signing embeds a PAdES-T signature and timestamp. Omitting the output path creates a separate `-semnat.pdf` file; existing outputs are not overwritten. XAdES defaults to detached XML and SHA-256: retain the unchanged original with the XML. Choose BES without timestamp, T with timestamp, or C with certificate/revocation references. Use `--enveloping` only when the recipient wants the original inside XML. Timestamped formats need network access; C also obtains status references.

<GuideScreenshot src="/img/guide/linux-cli/en/sign.svg" alt="3. Sign PDF or create an XML signature" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Start PDF signing and respond to the no-echo PIN prompt."}, {"x": 3, "y": 53.5, "text": "Create the XML level your recipient requires."}, {"x": 3, "y": 83.2, "text": "Use enveloping only when needed; keep originals for detached XML."}]} />

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

<GuideScreenshot src="/img/guide/linux-cli/en/verify.svg" alt="4. Verify and interpret the result" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Verify a PDF or XML using the original-document directory."}, {"x": 3, "y": 83.2, "text": "Use JSON for automation and inspect status, not only ok."}]} />

```sh
esemnbun verify Contract-semnat.pdf
esemnbun verify Declaration.xml /home/me/Originals
esemnbun verify --json Contract-semnat.pdf
```

`valid` and `unconfirmed` exit 0; the latter leaves trust unconfirmed. `invalid`, `incomplete` and `no_recognized_signature` exit 2. Missing originals alone mean incomplete, not proven modification. Exit 1 is usage/input failure; card operations use 3 wrong PIN, 4 blocked PIN, 5 no reader/card and 6 trust-service network failure. Stop after PIN errors. The app cannot unblock the card.

## 5. Connect an MCP host with explicit file access

Configure a local host that supports the implemented protocol with an absolute executable path and a trusted root you selected. Substitute your own existing physical directory. Client-advertised roots do not grant access. Symlinks, path traversal and special files are rejected. No root means discovery only. The helper uses stdio, not a network signing endpoint. Files are bounded to 8 MiB; detached XML originals need an explicitly selected detached root.

<GuideScreenshot src="/img/guide/linux-cli/en/mcp.svg" alt="5. Connect an MCP host with explicit file access" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 58.5, "text": "Choose the installed executable and a narrow document root."}, {"text": "Let the host discover capabilities, then request offline verification."}]} />

```sh
esemnbun-mcp --root documents=/home/me/Documents/Signing
```

Use `capabilities` and `verify_document` first. Tool input identifies `{rootId,relativePath}`; never put a PIN or document contents in tool arguments. MCP verification returns minimized metadata. The host may send that metadata to its own external services. See [complete MCP setup and policy](https://esemnbun.md/packages/mcp.md) for exact protocol and host configuration. [Configurations and reusable skills for ten AI agents](https://esemnbun.md/docs/integrations/mcp-agents/) (English).

```json
{
  "command": "/usr/bin/esemnbun-mcp",
  "args": [
    "--root",
    "documents=/home/me/Documents/Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```

### Enable signing with desktop approval

Enable local signing requests in the GNOME app and keep it running. Add the private broker directory shown in Preferences to the helper command below. Use your actual directory; the screenshot uses an isolated capture location. Call `prepare_signing`, inspect the PDF in the app, explicitly approve and enter the PIN there, then use `get_job` to retrieve the result. `cancel_job` requests cancellation; a cancellation or timeout does not prove no signature was created. PINs never belong in MCP arguments. This per-document workflow is separate from unattended signing below.

```sh
esemnbun-mcp \
  --root documents=/home/me/Documents/Signing \
  --broker-directory "$HOME/.local/share/eSemnBun/AgentBroker"
```

<GuideScreenshot src="/img/guide/linux/en/settings.png" alt="Enable signing with desktop approval" caption="Native Settings capture with fictional data. The opt-in is disabled in this isolated screenshot session; no live MCP approval or card signing was performed." steps={[{"x": 71, "y": 26, "text": "Enable local signing requests in the desktop app; each PDF still needs native review and approval."}, {"x": 50, "y": 27.4, "text": "Copy the private broker directory displayed by your own installation into the MCP launch configuration."}]} />

## 7. Configure explicit unattended signing

This advanced opt-in signs without a per-document approval dialog. Provision credentials independently, pin the exact signing-certificate DER SHA-256, and create a dedicated private output directory. Use secret-provider references, never PIN values. The helper checks the card certificate before reading a secret or sending VERIFY. Physical-card/provider behavior needs validation for your installation before production use.

<GuideScreenshot src="/img/guide/linux-cli/en/unattended.svg" alt="7. Configure explicit unattended signing" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 27.4, "text": "Set a narrow input root and private output directory."}, {"x": 3, "y": 80.6, "text": "Pin the exact certificate and choose a secret-provider reference."}]} />

```sh
esemnbun-mcp \
  --root documents=/home/me/Documents/Signing \
  --allow-unattended-signing \
  --signing-certificate-sha256 <CERTIFICATE_SHA256> \
  --signing-output-directory /home/me/PrivateOutput \
  --pin-source env:ESEMNBUN_AUTOMATION_PIN
```

macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN`, or `onepassword:op://Vault/Item/field`. Linux: `secret-service:service:account`, environment or 1Password. Windows: `credential:eSemnBun-Automation`, environment or 1Password with an explicit absolute op.exe path. A separately provisioned Keychain/Credential Manager entry must allow the intended access; the app biometric vault is not weakened. Authenticate 1Password outside MCP.

Replace `<CERTIFICATE_SHA256>` with the exact 64 hexadecimal digits before running. The output folder must already exist; macOS/Linux require ownership by you and mode0700. Windows allows only your account, SYSTEM and Administrators in its ACL.

Before signing, the helper creates `.unattended-signing-lock` in the output directory. Wrong PIN, interrupted execution or uncertain failure leaves this durable marker and prevents another automatic attempt. Inspect output and card outcome, reconcile deliberately, then remove the marker and restart only when appropriate. Never write an automatic lock-deletion/retry loop. A cancellation or timeout does not prove no signature was made.

## 8. Run the local browser connection

Run the bridge in the foreground and keep it running while using the supported site on this computer. The defaults are loopback HTTP18480 and HTTPS18443. Do not run the GUI bridge or vendor MoldSign on the same ports. Stop with Ctrl+C. The package needs its localhost HTTPS identity. Prefer the desktop app when you need native consent/PIN dialogs; a terminal bridge is not that approval UI.

<GuideScreenshot src="/img/guide/linux-cli/en/service.svg" alt="8. Run the local browser connection" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Start the local browser bridge."}, {"x": 3, "y": 83.2, "text": "Stop with Ctrl+C when finished."}]} />

```sh
sudo systemctl enable --now pcscd.socket
esemnbun server
# Ctrl+C
```

---

Advanced reference: macOS/Linux also expose `sign-hex <digestinfo_hex>` and `cms-for-hash <sha256_hex>`; Windows has sign-hex only. These are developer primitives, not document signing. Read the CLI contract before using them. For support include app/OS version, command without secrets, exit code and a fictional reproducer. Never attach PINs or confidential files.
