---
title: "Encrypt a file with a password — Android tablet"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/android-tablet/help"
pagination_next: "platforms/android-tablet/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — Android tablet

[Platform overview](../android-tablet.md) · [Get started](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

Open **Documents**, then choose **More actions → Protect files** in the top toolbar. Choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In eSemnBun 0.2.13 or later, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). The Moldovan ID signing certificate cannot decrypt these files.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"text": "Open the navigation menu and choose Protect files.", "x": 91.0, "y": 13.6}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"text": "Choose Encrypt, then select the source file.", "x": 45.7, "y": 26.6}, {"text": "Choose Password and select the AES key size. AES-256 is selected initially.", "x": 60.0, "y": 43.5}, {"text": "Enter and confirm a file password, then choose Encrypt.", "x": 30.6, "y": 57.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-certificate-light.png" alt="Encrypt for an RSA recipient" steps={[{"text": "For a recipient with an RSA encryption key, choose RSA certificate.", "x": 54.6, "y": 35.2}, {"text": "Select the recipient’s public .cer or .der certificate. To encrypt for your own card, connect its reader and choose Read my card.", "x": 31.1, "y": 43.5}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-complete-light.png" alt="Encrypted file saved" steps={[{"text": "Check the saved filename. This output is already in Documents.", "x": 29.6, "y": 27.9}, {"text": "Choose Save as… only if you also want a copy in another location.", "x": 46.4, "y": 84.6}, {"text": "Choose Close to return to the app. The saved file remains in Documents.", "x": 47.1, "y": 89.0}]} />

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
