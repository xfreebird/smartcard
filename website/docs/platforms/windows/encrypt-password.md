---
title: "Encrypt a file with a password — Windows"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/windows/help"
pagination_next: "platforms/windows/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

Open **Protect files** at the bottom of the navigation bar and choose **Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

Choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). By default, use a certificate intended for encryption. **Card public key compatibility** explicitly allows the card’s public RSA key. Exporting it or encrypting a file does not prove that the card can decrypt; the matching card must support the required private-key operation.

<GuideScreenshot src="/img/guide/windows/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"text": "Choose the file to encrypt.", "x": 36, "y": 29}, {"text": "Select AES-128, AES-192 or AES-256. AES-256 is selected by default.", "x": 59, "y": 50}, {"text": "Enter and confirm a new file password.", "x": 41, "y": 62}, {"text": "Choose Encrypt, then save the encrypted copy.", "x": 41, "y": 88}]} />

<GuideScreenshot src="/img/guide/windows/en/protect-certificate-light.png" alt="Encrypt for an RSA recipient" steps={[{"text": "Select RSA certificate.", "x": 47.7, "y": 40.7}, {"text": "Choose the recipient’s public encryption certificate.", "x": 39.6, "y": 59.4}, {"text": "To encrypt for your own card, connect its reader and read its encryption certificate.", "x": 35.7, "y": 64.8}, {"text": "Use Card public key compatibility only when the workflow requires the card’s public RSA key.", "x": 38.9, "y": 45.9}]} />

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Choose **Close** to close the completed operation. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
