---
title: "MoldSign MCP — electronic signatures for AI agents"
description: "Use eSemnBun as a local MCP server on Windows, Mac or Linux. Verify PDF/XML signatures and configure approved signing with a Moldovan electronic ID."
sidebar_label: "MoldSign MCP"
---

# MoldSign MCP: electronic signatures for local AI agents

**eSemnBun provides a local Model Context Protocol (MCP) server for verifying document signatures and, when explicitly configured, signing PDFs with a supported Moldovan electronic identity card.** It runs on Windows, macOS and Linux. It is an independent project, not an official MoldSign or STISC MCP service.

MCP connects an agent to installed tools. The eSemnBun website publishes documentation and downloads; it does not provide a remote signing endpoint. The MCP process runs on the computer that can access the selected files and, for signing, the card reader.

## Choose the right component

| Component | Purpose |
| --- | --- |
| Desktop app | Sign and verify documents through a graphical interface |
| MoldSign-compatible browser bridge | Handle supported requests from MSign and other allowed websites |
| eSemnBun MCP server | Expose explicitly configured local document tools to an MCP client over stdio |

These interfaces are different. A working browser bridge does not automatically configure an agent, and publishing a website does not expose your reader to cloud agents.

## Install on Windows, Mac or Linux

Start from [Downloads](/downloads/) and follow the guide for your installed CLI package:

| Platform | MCP command | Setup |
| --- | --- | --- |
| Windows | `esemnbun.exe mcp` | [Windows MCP guide](./platforms/windows-cli/mcp.md) |
| Mac / macOS | `esemnbun-mcp` | [Mac MCP guide](./platforms/macos-cli/mcp.md) |
| Linux | `esemnbun-mcp` | [Linux MCP guide](./platforms/linux-cli/mcp.md) |

Use an absolute executable path and a dedicated existing input folder. The Mac App Store app requires a separately installed CLI. SSH, WSL and containers have their own file and device access.

The [agent configuration guide](./integrations/mcp-agents.md) includes examples for Claude, Codex, Cursor, GitHub Copilot, Gemini CLI and other clients, plus a downloadable integration pack. These examples are not proof of a runtime-tested connection to every client. Use a client compatible with the protocol revisions in the [MCP contract](https://esemnbun.md/packages/mcp.md).

## What the agent can do

| Tool | Purpose and requirement |
| --- | --- |
| `capabilities` | Discover the configured roots, formats and available signing modes |
| `verify_document` | Verify PDF or XML signatures in an authorized folder, without contacting a reader or the network |
| `prepare_signing` | Prepare a PAdES-T PDF signing request when a native approval broker is configured |
| `get_job`, `cancel_job` | Inspect or request cancellation of a job on the same live connection |
| `sign_document` | Sign only when the operator has explicitly configured unattended signing |

For verification, use a fictional signed fixture in the selected folder. Example tool input:

```json
{"input":{"rootId":"documents","relativePath":"Contract-signed.pdf"}}
```

Read the returned verification verdict, not just whether the tool call succeeded. Detached XML signatures need the original documents and an explicitly selected detached root. Offline verification does not establish current certificate revocation status.

## Signing and privacy

Signing requires a supported card, an active signing certificate, a compatible USB reader and authorization. The private signing key stays on the card. The default verification setup does not enable unattended signing.

Configure foreground approval or certificate-pinned unattended signing separately, following the platform guide. Never put a card PIN in chat, tool arguments or a configuration example. The server returns minimized verification metadata rather than document contents; the MCP client may send that metadata to its own external services.

## Documentation for agents

The site offers a [plain-text index](https://esemnbun.md/llms.txt), a [combined reference](https://esemnbun.md/llms-full.txt), and a [JSON document catalog](https://esemnbun.md/discovery.json). These files are generated from the public guides and link back to the HTML pages for citation. The JSON catalog describes this website; it is not an MCP endpoint or an installation command.

For ordinary signing, begin with [the MoldSign alternative guide](./moldsign.md) or [signing and verification](./signing.md).
