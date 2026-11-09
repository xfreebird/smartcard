---
title: "Approve local signing — Linux"
sidebar_label: "Approve local signing"
description: "Prepare a PDF and review its foreground approval request."
pagination_prev: "platforms/linux/preferences"
pagination_next: "platforms/linux/help"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Approve local signing — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md) · [Connect an agent with MCP](../linux-cli/mcp.md)

Prepare a PDF and review its foreground approval request.

## Approve a local MCP signing request

In Preferences, enable local signing requests only when you intend to use an MCP client. Copy the private broker directory shown in the setting into the helper configuration. Keep the desktop app running. Each request opens a staged PDF for review: check the document, card and operation, approve it explicitly, then enter the PIN in the native dialog. A saved PIN never replaces approval. Cancel unexpected requests.

<GuideScreenshot src="/img/guide/linux/en/settings.png" alt="Approve a local MCP signing request" steps={[{"x": 71, "y": 26, "text": "Enable local signing requests in the desktop app; each PDF still needs native review and approval."}, {"x": 50, "y": 27.4, "text": "Copy the private broker directory displayed by your own installation into the MCP launch configuration."}]} />
