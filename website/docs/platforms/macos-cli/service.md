---
title: "Run the browser service — Mac · Command line (CLI)"
sidebar_label: "Run the browser service"
description: "Start and stop the local bridge or supported user service."
pagination_prev: "platforms/macos-cli/unattended"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Run the browser service — Mac · Command line (CLI)

[Platform overview](../macos-cli.md) · [Installation and reader setup](./setup.md)

Start and stop the local bridge or supported user service.

Illustrations use fictional data. Follow the instructions in your installed app.

## Run the local browser connection

Run the bridge in the foreground and keep it running while using the supported site on this computer. The defaults are loopback HTTP18480 and HTTPS18443. Do not run the GUI bridge or vendor MoldSign on the same ports. Stop with Ctrl+C. The package needs its localhost HTTPS identity. Prefer the desktop app when you need native consent/PIN dialogs; a terminal bridge is not that approval UI.

<GuideScreenshot src="/img/guide/macos-cli/en/service.svg" alt="8. Run the local browser connection" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 33.8, "text": "Start the local browser bridge."}, {"x": 3, "y": 76.1, "text": "Stop with Ctrl+C when finished."}]} />

```sh
esemnbun server
# Ctrl+C
```

---

Advanced reference: macOS/Linux also expose `sign-hex <digestinfo_hex>` and `cms-for-hash <sha256_hex>`; Windows has sign-hex only. These are developer primitives, not document signing. Read the CLI contract before using them. For support include app/OS version, command without secrets, exit code and a fictional reproducer. Never attach PINs or confidential files.
