---
title: "Share your encryption certificate — Mac"
sidebar_label: "Share your encryption certificate"
description: "Share your encryption certificate"
pagination_prev: "platforms/macos/decrypt-file"
pagination_next: "platforms/macos/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Share your encryption certificate — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Share your encryption certificate

Illustrations use fictional data. Follow the instructions in your installed app.

## Share your encryption certificate

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

<GuideScreenshot src="/img/guide/macos/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" caption="Fictional data. Before completion." steps={[{"x": 67, "y": 48, "text": "Choose Certificate/card."}, {"x": 35, "y": 64, "text": "Choose Read my card; scroll if needed."}]} />

After discovery, select the intended identity and expand Certificate details. Choose Export encryption certificate, save the .cer file and share it with the sender. Compare its fingerprint separately. Only the public certificate is exported; the private key stays on the card. The screenshot shows the starting screen before discovery.
