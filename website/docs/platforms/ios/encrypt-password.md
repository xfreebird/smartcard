---
title: "Encrypt a file with a password — iPhone"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/ios/help"
pagination_next: "platforms/ios/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — iPhone

[Platform overview](../ios.md) · [Get started](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

In **Documents**, select the **Protect files** shield in the toolbar. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In version 0.2.13, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). By default, use a certificate intended for encryption. **Card public key compatibility** explicitly allows the card’s public RSA key. Exporting it or encrypting a file does not prove that the card can decrypt; the matching card must support the required private-key operation.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="In Documents, open Protect files using the shield in the toolbar." steps={[{"text": "In Documents, open Protect files using the shield in the toolbar.", "x": 90, "y": 10}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-password-light.png" alt="Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt." steps={[{"text": "Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt.", "x": 81, "y": 55}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-certificate-light.png" alt="Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN." steps={[{"text": "Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN.", "x": 43.1, "y": 69.1}, {"text": "Use Card public key compatibility only when the workflow requires the card’s public RSA key.", "x": 35.2, "y": 55.2}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 68}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
