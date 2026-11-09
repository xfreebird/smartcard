---
title: "Share your encryption certificate — Windows"
sidebar_label: "Share your encryption certificate"
description: "Share your encryption certificate"
pagination_prev: "platforms/windows/decrypt-file"
pagination_next: "platforms/windows/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Share your encryption certificate — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Share your encryption certificate

Illustrations use fictional data. Follow the instructions in your installed app.

## Share your encryption certificate

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

<GuideScreenshot src="/img/guide/windows/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" caption="Fictional data. Before completion." steps={[{"x": 40, "y": 42, "text": "Choose Certificate/card."}, {"x": 37, "y": 61, "text": "Choose Read my card; scroll if needed."}]} />

After discovery, select the intended identity and expand Certificate details. Choose Export encryption certificate, save the .cer file and share it with the sender. Compare its fingerprint separately. Only the public certificate is exported; the private key stays on the card. The screenshot shows the starting screen before discovery.
