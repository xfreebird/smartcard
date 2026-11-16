---
title: "Decrypt a received file — Android tablet"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/android-tablet/encrypt-password"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — Android tablet

[Platform overview](../android-tablet.md) · [Get started](./setup.md)

Decrypt a received file

## Decrypt a received file

Open the **More** menu in the navigation bar and choose **Protect files**. Choose **Encrypt** or **Decrypt**, then select a file you can read.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"x": 70, "y": 15, "text": "Open the navigation menu and choose Protect files."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-light.png" alt="Decrypt a received file" start={2} steps={[{"x": 30, "y": 21, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 25, "y": 59, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 87, "text": "Choose Decrypt. The new output is saved in Documents."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-complete-light.png" alt="Decrypted file saved" start={5} steps={[{"x": 25, "y": 33, "text": "Check the saved filename. This output is already in Documents."}, {"x": 25, "y": 83, "text": "Choose Save as… only if you also want a copy in another location."}, {"x": 75, "y": 88, "text": "Choose Close to return to the app. The saved file remains in Documents."}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
