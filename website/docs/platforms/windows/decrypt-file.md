---
title: "Decrypt a received file — Windows"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/windows/encrypt-certificate"
pagination_next: "platforms/windows/share-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Decrypt a received file

Illustrations use fictional data. Follow the instructions in your installed app.

## Decrypt a received file

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Ask the sender which method they used. For password files, obtain the password separately. For certificate files, connect the matching supported card and reader; you need its encryption key and PIN. A different card or signing-only card cannot unlock the file.

<GuideScreenshot src="/img/guide/windows/en/protect-decrypt-light.png" alt="Decrypt a received file" caption="Fictional data. Before completion." steps={[{"x": 40, "y": 25, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 40, "y": 60, "text": "Choose Password and enter the password supplied by the sender."}, {"x": 40, "y": 88, "text": "Choose Decrypt and save the result under a new filename."}]} />

For card decryption: choose Certificate/card, then Read my card. Select the matching encryption identity, inspect its details, enter its PIN and choose Decrypt. Save under a new name. If no supported encryption identity appears, ask the sender for a password-encrypted copy. Stop after a PIN error; do not retry automatically.

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.
