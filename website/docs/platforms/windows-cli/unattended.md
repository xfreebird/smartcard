---
title: "Configure unattended signing — Windows · Command line (CLI)"
sidebar_label: "Configure unattended signing"
description: "Pin the certificate, choose a secret provider and restrict output."
pagination_prev: "platforms/windows-cli/mcp"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Configure unattended signing — Windows · Command line (CLI)

[Platform overview](../windows-cli.md) · [Installation and reader setup](./setup.md) · [Connect an agent with MCP](./mcp.md)

Pin the certificate, choose a secret provider and restrict output.

Illustrations use fictional data. Follow the instructions in your installed app.

## Configure explicit unattended signing

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
