---
title: "Encrypt a file with a password — Windows"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/windows/help"
pagination_next: "platforms/windows/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Encrypt a file with a password

## Encrypt a file with a password

Open **Protect files** at the bottom of the navigation bar and choose **Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/windows/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"x": 39.852, "y": 18.087, "text": "Choose Encrypt."}, {"x": 34.779, "y": 30.239, "text": "Choose the source file."}, {"x": 39.852, "y": 55.556, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 39.852, "y": 92.011, "text": "Choose Encrypt, then save the new encrypted file."}]} />

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Choose **Close** to close the completed operation. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
