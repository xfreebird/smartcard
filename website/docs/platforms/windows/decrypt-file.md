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

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/windows/en/protect-decrypt-light.png" alt="Decrypt a received file" steps={[{"x": 40, "y": 24, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 40, "y": 56, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 40, "y": 86, "text": "Choose Decrypt and save the result under a new filename."}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Choose **Close** to close the completed operation. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
