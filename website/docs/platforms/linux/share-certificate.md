---
title: "Share your encryption certificate — Linux"
sidebar_label: "Share your encryption certificate"
description: "Share your encryption certificate"
pagination_prev: "platforms/linux/decrypt-file"
pagination_next: "platforms/linux/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Share your encryption certificate — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Share your encryption certificate

## Share your encryption certificate

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

<GuideScreenshot src="/img/guide/linux/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" steps={[{"x": 28.7, "y": 47.3, "text": "Choose Certificate/card."}, {"x": 41.1, "y": 69.0, "text": "Choose Read my card; scroll if needed."}]} />

After discovery, select the intended identity and expand Certificate details. Choose Export encryption certificate, save the .cer file and share it with the sender. Compare its fingerprint separately. Only the public certificate is exported; the private key stays on the card. The screenshot shows the starting screen before discovery.
