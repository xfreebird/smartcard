---
title: "Connect an agent with MCP — Linux · Command line (CLI)"
sidebar_label: "Connect an agent with MCP"
description: "Choose trusted folders and configure your MCP host."
pagination_prev: "platforms/linux-cli/verification"
pagination_next: "platforms/linux-cli/unattended"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Connect an agent with MCP — Linux · Command line (CLI)

[Platform overview](../linux-cli.md) · [Installation and reader setup](./setup.md)

Choose trusted folders and configure your MCP host.

## Connect an MCP host with explicit file access

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

<GuideScreenshot src="/img/guide/linux/en/settings.png" alt="Enable signing with desktop approval" steps={[{"x": 71, "y": 26, "text": "Enable local signing requests in the desktop app; each PDF still needs native review and approval."}, {"x": 50, "y": 27.4, "text": "Copy the private broker directory displayed by your own installation into the MCP launch configuration."}]} />
