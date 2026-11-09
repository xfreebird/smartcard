---
title: "Approve local signing — Windows"
sidebar_label: "Approve local signing"
description: "Prepare a PDF and review its foreground approval request."
pagination_prev: "platforms/windows/browser"
pagination_next: "platforms/windows/help"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Approve local signing — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md) · [Connect an agent with MCP](../windows-cli/mcp.md)

Prepare a PDF and review its foreground approval request.

## Approve local signing requests (MCP)

In **Settings → General**, scroll to **Advanced** and enable **Allow local signing requests (MCP)**. Copy the private directory shown below the switch into your MCP client configuration. Keep eSemnBun running and select the intended card. This option is unavailable while demo mode is on.

```powershell
& "C:\Program Files\eSemnBun\bin\esemnbun.exe" mcp `
  --root "documents=C:\Users\me\Documents\Signing" `
  --broker-directory "C:\Users\me\AppData\Local\MoldSign\MCP"
```

Use the actual directory displayed by your installation instead of the example below. A client can stage a PDF with `prepare_signing`, inspect its status with `get_job`, or cancel it with `cancel_job`. Review the PDF in the native preview and choose Sign only when you approve the request; card authorization follows. A saved PIN does not skip this approval. Cancelling or timing out is not proof that a signature was never made.

The screenshot uses an isolated demonstration profile: its directory is an example and its MCP switch is disabled. No MCP signing request was executed for this capture.


<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Browser connection and local requests" steps={[{"x": 25, "y": 82, "text": "Find the MCP switch under Advanced. Outside demo mode, enable it and copy the private directory into your client configuration."}, {"x": 48, "y": 92, "text": "Use the directory shown by your installation, not the demonstration path."}]} />

<!-- file-protection-guides -->
