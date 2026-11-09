---
title: "Verify with MCP — Windows · Command line (CLI)"
sidebar_label: "Verify with MCP"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/windows-cli/setup"
pagination_next: "platforms/windows-cli/mcp"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verify with MCP — Windows · Command line (CLI)

[Platform overview](../windows-cli.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

## Verify and interpret the result

Windows offline verification is available through MCP verify_document, not the normal verify CLI command. Launch the host with an explicit root and supply input `{rootId,relativePath}`; inspect integrity/signature/chain fields. Missing originals require the explicit detached root. No reader/PIN is used. It does not check current revocation.

<GuideScreenshot src="/img/guide/windows-cli/en/verification.svg" alt="command-line guide" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 18.3, "text": "Start the MCP server with the folder you selected."}, {"x": 3, "y": 41.2, "text": "In your MCP client, choose the verify_document tool."}, {"x": 3, "y": 64.1, "text": "Supply this tool input, then inspect integrity, signature and chain fields. This is an example, not captured output."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```
