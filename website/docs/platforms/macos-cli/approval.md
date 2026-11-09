---
title: "Approve local signing — Mac · Command line (CLI)"
sidebar_label: "Approve local signing"
description: "Prepare a PDF and review its foreground approval request."
pagination_prev: "platforms/macos-cli/mcp"
pagination_next: "platforms/macos-cli/unattended"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Approve local signing — Mac · Command line (CLI)

[Platform overview](../macos-cli.md) · [Installation and reader setup](./setup.md) · [Connect an agent with MCP](./mcp.md)

Prepare a PDF and review its foreground approval request.

## Request signing with foreground Mac approval

In the Mac app enable the agent approval broker in Settings and use its configured private spool directory. The app and helper must run as the same user. The directory and requests/responses/outputs subdirectories must already exist with mode 0700. Start the helper with that directory. In your host call prepare_signing for a PDF, review the native certificate/document request, approve with the card PIN, poll get_job and retrieve the completed output. cancel_job requests cancellation; it cannot undo a signature already in progress. Requests expire after five minutes and outputs are retained for 24 hours. Keep the app running. Windows and Linux also offer desktop approval with their platform-specific private directory; installed-build validation is required.

<GuideScreenshot src="/img/guide/macos-cli/en/broker.svg" alt="6. Request signing with foreground Mac approval" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 33.8, "text": "Enable the Mac app broker and use its displayed private directory."}, {"x": 3, "y": 76.1, "text": "Prepare a request in the host, then approve in the app."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing \
  --broker-directory /Users/me/PrivateBroker
```
