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

Open **Documents**, then choose **More actions → Protect files** in the top toolbar. Choose **Encrypt** or **Decrypt**, then select a file you can read.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"text": "Open the navigation menu and choose Protect files.", "x": 91.0, "y": 13.6}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-light.png" alt="Decrypt a received file" steps={[{"text": "Choose Decrypt and select the received encrypted file.", "x": 42.5, "y": 26.6}, {"text": "Enter the password supplied by the sender in the Password field.", "x": 30.6, "y": 42.1}, {"text": "Choose Decrypt. The new output is saved in Documents.", "x": 46.7, "y": 89.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-rsa-decrypt-light.png" alt="Decrypt with the recipient’s card" steps={[{"text": "Select the encrypted file. The app identifies the RSA certificate format.", "x": 29.6, "y": 36.8}, {"text": "Connect the card containing the recipient’s matching private key. Choose Read my card, then authorize decryption with its PIN.", "x": 31.1, "y": 43.9}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-complete-light.png" alt="Decrypted file saved" steps={[{"text": "Check the saved filename. This output is already in Documents.", "x": 29.6, "y": 27.9}, {"text": "Choose Save as… only if you also want a copy in another location.", "x": 46.4, "y": 84.6}, {"text": "Choose Close to return to the app. The saved file remains in Documents.", "x": 47.1, "y": 89.0}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
