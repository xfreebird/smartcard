---
title: "Encrypt a file with a password — Android phone"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/android/help"
pagination_next: "platforms/android/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — Android phone

[Platform overview](../android.md) · [Get started](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

Open **Files**, then choose **More actions → Protect files** in the top toolbar. Choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In eSemnBun 0.2.13 or later, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). By default, use a certificate intended for encryption. **Card public key compatibility** explicitly allows the card’s public RSA key. Exporting it or encrypting a file does not prove that the card can decrypt; the matching card must support the required private-key operation.

<GuideScreenshot src="/img/guide/android-phone/en/protect-menu-light.png" alt="Open file protection" steps={[{"text": "Open the navigation menu and choose Protect files.", "x": 70.1, "y": 15.3}]} />

<GuideScreenshot src="/img/guide/android-phone/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"text": "Choose Encrypt, then select the source file.", "x": 38.8, "y": 30.5}, {"text": "Choose Password and select the AES key size. AES-256 is selected initially.", "x": 72.8, "y": 51.0}, {"text": "Enter and confirm a file password, then choose Encrypt.", "x": 11.0, "y": 67.2}]} />

<GuideScreenshot src="/img/guide/android-phone/en/protect-certificate-light.png" alt="Encrypt for an RSA recipient" steps={[{"text": "For a recipient with an RSA encryption key, choose RSA certificate.", "x": 70.6, "y": 37.9}, {"text": "Select the recipient’s public .cer or .der certificate. To encrypt for your own card, connect its reader and choose Read my card.", "x": 35.5, "y": 56.8}, {"text": "Use Card public key compatibility only when the workflow requires the card’s public RSA key.", "x": 43.7, "y": 44.5}]} />

<GuideScreenshot src="/img/guide/android-phone/en/protect-complete-light.png" alt="Encrypted file saved" steps={[{"text": "Check the saved filename. This output is already in Documents.", "x": 7.1, "y": 32.0}, {"text": "Choose Save as… only if you also want a copy in another location.", "x": 41.3, "y": 82.9}, {"text": "Choose Close to return to the app. The saved file remains in Documents.", "x": 43.9, "y": 88.1}]} />

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
