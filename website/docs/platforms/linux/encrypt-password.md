---
title: "Encrypt a file with a password — Linux"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/linux/help"
pagination_next: "platforms/linux/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

Open the main menu in the window header, then **Protect files → Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

Choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). By default, use a certificate intended for encryption. **Card public key compatibility** explicitly allows the card’s public RSA key. Exporting it or encrypting a file does not prove that the card can decrypt; the matching card must support the required private-key operation.

<GuideScreenshot src="/img/guide/linux/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"text": "Choose the file to encrypt.", "x": 50, "y": 29}, {"text": "Select AES-128, AES-192 or AES-256. AES-256 is selected by default.", "x": 45, "y": 56}, {"text": "Enter and confirm a new file password.", "x": 31, "y": 68}, {"text": "Choose Encrypt, then save the encrypted copy.", "x": 50, "y": 91}]} />

<GuideScreenshot src="/img/guide/linux/en/protect-certificate-light.png" alt="Encrypt for an RSA recipient" steps={[{"text": "Select RSA certificate.", "x": 42.7, "y": 44.2}, {"text": "Choose the recipient’s public encryption certificate.", "x": 50.0, "y": 58.4}, {"text": "To encrypt for your own card, connect its reader and read its encryption certificate.", "x": 49.8, "y": 63.9}, {"text": "Use Card public key compatibility only when the workflow requires the card’s public RSA key.", "x": 36.5, "y": 53.4}]} />

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Use the close button in the window header when finished. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
