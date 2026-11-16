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

Open the **More** menu in the navigation bar and choose **Protect files**. Choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"x": 70, "y": 15, "text": "Open the navigation menu and choose Protect files."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-password-light.png" alt="Encrypt a file with a password" start={2} steps={[{"x": 30, "y": 21, "text": "Choose Encrypt."}, {"x": 30, "y": 33, "text": "Choose the source file."}, {"x": 25, "y": 59, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 50, "y": 87, "text": "Choose Encrypt. The encrypted copy is saved in Documents."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-complete-light.png" alt="Encrypted file saved" start={6} steps={[{"x": 25, "y": 33, "text": "Check the saved filename. This output is already in Documents."}, {"x": 25, "y": 83, "text": "Choose Save as… only if you also want a copy in another location."}, {"x": 75, "y": 88, "text": "Choose Close to return to the app. The saved file remains in Documents."}]} />

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
