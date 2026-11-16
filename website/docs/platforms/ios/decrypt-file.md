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

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 90, "y": 6}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-light.png" alt="Decrypt a received file" start={2} steps={[{"x": 27, "y": 21, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 25, "y": 61, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 94, "text": "Choose Decrypt. Check the new output in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={5} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 25, "y": 59}, {"text": "Optionally choose Save a copy to export another copy.", "x": 25, "y": 73}, {"text": "Choose Done to return to Documents.", "x": 20, "y": 10}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
