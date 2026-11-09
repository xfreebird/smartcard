---
title: "Encrypt for a certificate holder — iPhone"
sidebar_label: "Encrypt for a certificate holder"
description: "Encrypt for a certificate holder"
pagination_prev: "platforms/ios/encrypt-password"
pagination_next: "platforms/ios/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt for a certificate holder — iPhone

[Platform overview](../ios.md) · [Installation and reader setup](./setup.md)

Encrypt for a certificate holder

Illustrations use fictional data. Follow the instructions in your installed app.

## Encrypt for a certificate holder

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Ask the recipient for their public encryption certificate (.cer/.der), exported using the next guide. Confirm its fingerprint with its owner through a trusted channel. A signing-only certificate is not sufficient. Encrypting for someone else needs their public certificate, not their card, private key or PIN.

<GuideScreenshot src="/img/guide/iphone/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" caption="Native Romanian interface; fictional data. Before completion." steps={[{"x": 27, "y": 23, "text": "Choose Encrypt."}, {"x": 25, "y": 39, "text": "Choose the source file."}, {"x": 28, "y": 54, "text": "Choose Certificate/card."}, {"x": 28, "y": 69, "text": "Choose the recipient’s certificate file."}, {"x": 50, "y": 91, "text": "Choose Encrypt, then save the new encrypted file."}]} />
