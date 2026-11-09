---
title: "Encrypt for a certificate holder — Linux"
sidebar_label: "Encrypt for a certificate holder"
description: "Encrypt for a certificate holder"
pagination_prev: "platforms/linux/encrypt-password"
pagination_next: "platforms/linux/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt for a certificate holder — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Encrypt for a certificate holder

Illustrations use fictional data. Follow the instructions in your installed app.

## Encrypt for a certificate holder

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Ask the recipient for their public encryption certificate (.cer/.der), exported using the next guide. Confirm its fingerprint with its owner through a trusted channel. A signing-only certificate is not sufficient. Encrypting for someone else needs their public certificate, not their card, private key or PIN.

<GuideScreenshot src="/img/guide/linux/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" caption="Fictional data. Before completion." steps={[{"x": 26.9, "y": 16.3, "text": "Choose Encrypt."}, {"x": 32.2, "y": 33.3, "text": "Choose the source file."}, {"x": 28.7, "y": 47.3, "text": "Choose Certificate/card."}, {"x": 41.1, "y": 61.2, "text": "Choose the recipient’s certificate file."}, {"x": 50.0, "y": 89.1, "text": "Choose Encrypt, then save the new encrypted file."}]} />
