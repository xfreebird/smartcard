---
title: "Encrypt for a certificate holder — Android phone"
sidebar_label: "Encrypt for a certificate holder"
description: "Encrypt for a certificate holder"
pagination_prev: "platforms/android/encrypt-password"
pagination_next: "platforms/android/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt for a certificate holder — Android phone

[Platform overview](../android.md) · [Installation and reader setup](./setup.md)

Encrypt for a certificate holder

## Encrypt for a certificate holder

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Ask the recipient for their public encryption certificate (.cer/.der), exported using the next guide. Confirm its fingerprint with its owner through a trusted channel. A signing-only certificate is not sufficient. Encrypting for someone else needs their public certificate, not their card, private key or PIN.

<GuideScreenshot src="/img/guide/android-phone/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" steps={[{"x": 27, "y": 20, "text": "Choose Encrypt."}, {"x": 30, "y": 31, "text": "Choose the source file."}, {"x": 27, "y": 43, "text": "Choose Certificate/card."}, {"x": 30, "y": 56, "text": "Choose the recipient’s certificate file."}, {"x": 50, "y": 88, "text": "Choose Encrypt, then save the new encrypted file."}]} />
