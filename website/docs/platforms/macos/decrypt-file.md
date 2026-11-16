---
title: "Decrypt a received file — Mac"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/macos/encrypt-password"
pagination_next: "platforms/macos/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Decrypt a received file

## Decrypt a received file

Open **Documents** and select the shield beside the trash button to open **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="Open Documents and select the shield beside the trash button." steps={[{"text": "Open Documents and select the shield beside the trash button.", "x": 68, "y": 6.6}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-decrypt-light.png" alt="Decrypt a received file" start={2} steps={[{"x": 56, "y": 17, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 35, "y": 51, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 82, "text": "Choose Decrypt. Check the new output in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-decrypt-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={5} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 40, "y": 52}, {"text": "Optionally choose Save a copy to export another copy.", "x": 40, "y": 62}, {"text": "Choose Done to return to Documents.", "x": 70, "y": 90}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
