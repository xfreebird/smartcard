---
title: "Share your encryption certificate — Android phone"
sidebar_label: "Share your encryption certificate"
description: "Share your encryption certificate"
pagination_prev: "platforms/android/decrypt-file"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Share your encryption certificate — Android phone

[Platform overview](../android.md) · [Installation and reader setup](./setup.md)

Share your encryption certificate

## Share your encryption certificate

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

<GuideScreenshot src="/img/guide/android-phone/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" steps={[{"x": 27, "y": 43, "text": "Choose Certificate/card."}, {"x": 26, "y": 63, "text": "Choose Read my card; scroll if needed."}]} />

After discovery, select the intended identity and expand Certificate details. Choose Export encryption certificate, save the .cer file and share it with the sender. Compare its fingerprint separately. Only the public certificate is exported; the private key stays on the card. The screenshot shows the starting screen before discovery.
