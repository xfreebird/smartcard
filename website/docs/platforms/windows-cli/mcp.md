---
title: "Connect an agent with MCP — Windows · Command line (CLI)"
sidebar_label: "Connect an agent with MCP"
description: "Choose trusted folders and configure your MCP host."
pagination_prev: "platforms/windows-cli/verification"
pagination_next: "platforms/windows-cli/unattended"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Connect an agent with MCP — Windows · Command line (CLI)

[Platform overview](../windows-cli.md) · [Installation and reader setup](./setup.md)

Choose trusted folders and configure your MCP host.

Illustrations use fictional data. Follow the instructions in your installed app.

## Connect an MCP host with explicit file access

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
