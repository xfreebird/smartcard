---
title: "Decrypt a received file — Linux"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/linux/encrypt-password"
pagination_next: "platforms/linux/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Decrypt a received file

## Decrypt a received file

Open the main menu in the window header, then **Protect files → Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/linux/en/protect-decrypt-light.png" alt="Decrypt a received file" steps={[{"x": 41, "y": 17, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 36, "y": 49, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 90, "text": "Choose Decrypt and save the result under a new filename."}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Use the close button in the window header when finished. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
