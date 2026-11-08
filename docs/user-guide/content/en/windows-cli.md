---
title: Windows CLI
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Windows — command-line guide

Reach a specific goal using the numbered terminal examples below. Commands stay in English. The illustrated panels are instructional examples, not screenshots of a real card signing. Only the capability and unsigned-fixture verification results were captured from a local executable; no real PIN, card or credential provider was used.

You need a supported electronic ID and its correct signing PIN, a compatible USB reader and any required adapter for card operations. NFC is not supported. Verification needs no reader or PIN. Keep your original documents. The private signing key stays on the card.

:::info
The Windows CLI currently supports help, capabilities, readers, cert, sign-hex and mcp. Normal sign/xades/verify/server/cms-for-hash commands are not implemented. Use the desktop app for those document workflows, or the separately configured MCP verification/unattended tools. Windows MCP has no foreground desktop approval broker. Do not assume command parity from the macOS/Linux examples.
:::

## 1. Install and discover what your executable supports

Open [Downloads](/downloads/) and choose your platform. CLI archives contain terminal and MCP tools; the desktop application is a separate installation. Use the package-manager instructions there for the current version and signing-key fingerprint. Then locate the command and inspect capabilities before automating.

<GuideScreenshot src="/img/guide/windows-cli/en/install.svg" alt="1. Install and discover what your executable supports" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 30.6, "text": "Install through the selected platform channel."}, {"x": 3, "y": 78.3, "text": "Run capability discovery before using card commands."}]} />

```powershell
scoop bucket add esemnbun https://github.com/xfreebird/homebrew-utils
scoop install esemnbun/esemnbun-cli
Get-Command esemnbun
esemnbun capabilities --json
```

For Chocolatey, download the project .nupkg to an empty folder, then run:

```powershell
choco install esemnbun-cli --source . --yes
```

## 2. Find the reader and check the certificate

Connect the USB reader and insert your card. List readers, then inspect the signing certificate without entering a PIN. With several cards, use the exact reader name and check the holder before every signing request. These commands below are examples; a reader was not accessed to create this guide.

<GuideScreenshot src="/img/guide/windows-cli/en/reader.svg" alt="2. Find the reader and check the certificate" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "List connected readers and card presence."}, {"x": 3, "y": 53.5, "text": "Read the intended certificate; replace the reader name."}, {"x": 3, "y": 83.2, "text": "Calculate SHA-256 of the exported certificate. Use these 64 hexadecimal digits for unattended signing, not the SHA-1 shown by cert."}]} />

```powershell
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
Get-FileHash leaf.der -Algorithm SHA256
```

## 3. Verify and interpret the result

Windows offline verification is available through MCP verify_document, not the normal verify CLI command. Launch the host with an explicit root and supply input `{rootId,relativePath}`; inspect integrity/signature/chain fields. Missing originals require the explicit detached root. No reader/PIN is used. It does not check current revocation.

<GuideScreenshot src="/img/guide/windows-cli/en/verification.svg" alt="command-line guide" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 18.3, "text": "Start the MCP server with the folder you selected."}, {"x": 3, "y": 41.2, "text": "In your MCP client, choose the verify_document tool."}, {"x": 3, "y": 64.1, "text": "Supply this tool input, then inspect integrity, signature and chain fields. This is an example, not captured output."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```


## 4. Connect an MCP host with explicit file access

Configure a local host that supports the implemented protocol with an absolute executable path and a trusted root you selected. Substitute your own existing physical directory. Client-advertised roots do not grant access. Symlinks, path traversal and special files are rejected. No root means discovery only. The helper uses stdio, not a network signing endpoint. Files are bounded to 8 MiB; detached XML originals need an explicitly selected detached root.

<GuideScreenshot src="/img/guide/windows-cli/en/mcp.svg" alt="5. Connect an MCP host with explicit file access" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 58.5, "text": "Choose the installed executable and a narrow document root."}, {"text": "Let the host discover capabilities, then request offline verification."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

Use `capabilities` and `verify_document` first. Tool input identifies `{rootId,relativePath}`; never put a PIN or document contents in tool arguments. MCP verification returns minimized metadata. The host may send that metadata to its own external services. See [complete MCP setup and policy](https://esemnbun.md/packages/mcp.md) for exact protocol and host configuration.

```json
{
  "command": "C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe",
  "args": [
    "mcp",
    "--root",
    "documents=C:\\Users\\me\\Documents\\Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```

## 5. Configure explicit unattended signing

This advanced opt-in signs without a per-document approval dialog. Provision credentials independently, pin the exact signing-certificate DER SHA-256, and create a dedicated private output directory. Use secret-provider references, never PIN values. The helper checks the card certificate before reading a secret or sending VERIFY. Physical-card/provider behavior needs validation for your installation before production use.

<GuideScreenshot src="/img/guide/windows-cli/en/unattended.svg" alt="7. Configure explicit unattended signing" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 27.4, "text": "Set a narrow input root and private output directory."}, {"x": 3, "y": 80.6, "text": "Pin the exact certificate and choose a secret-provider reference."}]} />

```powershell
esemnbun mcp `
  --root "documents=C:\Users\me\Documents\Signing" `
  --allow-unattended-signing `
  --signing-certificate-sha256 <CERTIFICATE_SHA256> `
  --signing-output-directory C:\Users\me\PrivateOutput `
  --pin-source credential:eSemnBun-Automation
```

macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN`, or `onepassword:op://Vault/Item/field`. Linux: environment or 1Password. Windows: `credential:eSemnBun-Automation`, environment or 1Password with an explicit absolute op.exe path. A separately provisioned Keychain/Credential Manager entry must allow the intended access; the app biometric vault is not weakened. Authenticate 1Password outside MCP.

Replace `<CERTIFICATE_SHA256>` with the exact 64 hexadecimal digits before running. The output folder must already exist; macOS/Linux require ownership by you and mode0700. Windows allows only your account, SYSTEM and Administrators in its ACL.

Before signing, the helper creates `.unattended-signing-lock` in the output directory. Wrong PIN, interrupted execution or uncertain failure leaves this durable marker and prevents another automatic attempt. Inspect output and card outcome, reconcile deliberately, then remove the marker and restart only when appropriate. Never write an automatic lock-deletion/retry loop. A cancellation or timeout does not prove no signature was made.

---

Advanced reference: macOS/Linux also expose `sign-hex <digestinfo_hex>` and `cms-for-hash <sha256_hex>`; Windows has sign-hex only. These are developer primitives, not document signing. Read the CLI contract before using them. For support include app/OS version, command without secrets, exit code and a fictional reproducer. Never attach PINs or confidential files.
