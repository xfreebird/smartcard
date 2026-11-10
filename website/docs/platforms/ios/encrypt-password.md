---
title: "Encrypt a file with a password — iPhone"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/ios/help"
pagination_next: "platforms/ios/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — iPhone

[Platform overview](../ios.md) · [Installation and reader setup](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 90, "y": 6}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-password-light.png" alt="Encrypt a file with a password" start={2} steps={[{"x": 27, "y": 21, "text": "Choose Encrypt."}, {"x": 25, "y": 40, "text": "Choose the source file."}, {"x": 25, "y": 70, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 50, "y": 94, "text": "Choose Encrypt. The encrypted copy is saved in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={6} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 25, "y": 59}, {"text": "Optionally choose Save a copy to export another copy.", "x": 25, "y": 73}, {"text": "Choose Done to return to Documents.", "x": 20, "y": 10}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
