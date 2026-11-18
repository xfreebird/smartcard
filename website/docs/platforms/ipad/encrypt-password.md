---
title: "Encrypt a file with a password — iPad"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/ipad/help"
pagination_next: "platforms/ipad/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — iPad

[Platform overview](../ipad.md) · [Installation and reader setup](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

In **Documents**, choose **Protect files** in the toolbar. When space is limited, open the More (…) menu to find it. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In version 0.2.13, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). The Moldovan ID signing certificate cannot decrypt these files.

<GuideScreenshot src="/img/guide/ipad/en/documents-protection-light.png" alt="Open More (…) and choose Protect files." steps={[{"text": "Open More (…) and choose Protect files.", "x": 72, "y": 15}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-password-light.png" alt="Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt." steps={[{"text": "Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt.", "x": 79, "y": 57}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-certificate-light.png" alt="Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN." steps={[{"text": "Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN.", "x": 34, "y": 62}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 62}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
