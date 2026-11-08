---
title: "Check a signature — Mac · Command line (CLI)"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/macos-cli/signing"
pagination_next: "platforms/macos-cli/mcp"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — Mac · Command line (CLI)

[Platform overview](../macos-cli.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

Illustrations use fictional data. Follow the instructions in your installed app.

## Verify and interpret the result

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
