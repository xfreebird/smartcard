---
title: "Decrypt a received file — Windows"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/windows/encrypt-password"
pagination_next: "platforms/windows/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Decrypt a received file

## Decrypt a received file

Open **Protect files** at the bottom of the navigation bar and choose **Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/windows/en/protect-decrypt-light.png" alt="Decrypt a received file" steps={[{"text": "Choose the encrypted file. Its contents determine the decryption method.", "x": 33, "y": 33}, {"text": "For a password-encrypted file, enter the password supplied by the sender.", "x": 40, "y": 60}, {"text": "Choose Decrypt and save the result in a new file.", "x": 39, "y": 84}]} />

<GuideScreenshot src="/img/guide/windows/en/protect-rsa-decrypt-light.png" alt="For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN." steps={[{"text": "For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN.", "x": 36.4, "y": 61.4}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Choose **Close** to close the completed operation. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
