---
title: "Encrypt for a certificate holder — Android tablet"
sidebar_label: "Encrypt for a certificate holder"
description: "Encrypt for a certificate holder"
pagination_prev: "platforms/android-tablet/encrypt-password"
pagination_next: "platforms/android-tablet/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt for a certificate holder — Android tablet

[Platform overview](../android-tablet.md) · [Installation and reader setup](./setup.md)

Encrypt for a certificate holder

Illustrations use fictional data. Follow the instructions in your installed app.

## Encrypt for a certificate holder

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Ask the recipient for their public encryption certificate (.cer/.der), exported using the next guide. Confirm its fingerprint with its owner through a trusted channel. A signing-only certificate is not sufficient. Encrypting for someone else needs their public certificate, not their card, private key or PIN.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" caption="Fictional data. Before completion." steps={[{"x": 30, "y": 21, "text": "Choose Encrypt."}, {"x": 30, "y": 33, "text": "Choose the source file."}, {"x": 30, "y": 45, "text": "Choose Certificate/card."}, {"x": 28, "y": 58, "text": "Choose the recipient’s certificate file."}, {"x": 50, "y": 87, "text": "Choose Encrypt, then save the new encrypted file."}]} />
