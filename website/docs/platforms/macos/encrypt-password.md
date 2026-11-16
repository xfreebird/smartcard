---
title: "Encrypt a file with a password — Mac"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/macos/help"
pagination_next: "platforms/macos/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

Open **Documents** and select the shield beside the trash button to open **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="Open Documents and select the shield beside the trash button." steps={[{"text": "Open Documents and select the shield beside the trash button.", "x": 68, "y": 6.6}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-password-light.png" alt="Encrypt a file with a password" start={2} steps={[{"x": 44, "y": 17, "text": "Choose Encrypt."}, {"x": 35, "y": 30, "text": "Choose the source file."}, {"x": 35, "y": 51, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 50, "y": 82, "text": "Choose Encrypt. The encrypted copy is saved in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={6} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 40, "y": 52}, {"text": "Optionally choose Save a copy to export another copy.", "x": 40, "y": 62}, {"text": "Choose Done to return to Documents.", "x": 70, "y": 90}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
