---
title: "Decrypt a received file — iPhone"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/ios/encrypt-password"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — iPhone

[Platform overview](../ios.md) · [Get started](./setup.md)

Decrypt a received file

## Decrypt a received file

In **Documents**, select the **Protect files** shield in the toolbar. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file in version 0.2.13, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="In Documents, open Protect files using the shield in the toolbar." steps={[{"text": "In Documents, open Protect files using the shield in the toolbar.", "x": 90, "y": 10}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-light.png" alt="Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt." steps={[{"text": "Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt.", "x": 83, "y": 48}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-rsa-decrypt.png" alt="For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN." steps={[{"text": "For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN.", "x": 30.8, "y": 68.2}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 68}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
