---
title: "Decrypt a received file — Mac · Command line (CLI)"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/macos-cli/encrypt-certificate"
pagination_next: "platforms/macos-cli/share-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — Mac · Command line (CLI)

[Platform overview](../macos-cli.md) · [Installation and reader setup](./setup.md)

Decrypt a received file

Illustrations use fictional data. Follow the instructions in your installed app.

## Decrypt a received file

Ask the sender which method they used. For password files, obtain the password separately. For certificate files, connect the matching supported card and reader; you need its encryption key and PIN. A different card or signing-only card cannot unlock the file.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-decrypt.svg" alt="Decrypt a received file" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun decrypt Contract.enc Contract-opened.pdf
esemnbun encryption-certs
esemnbun decrypt Contract.enc Contract-opened.pdf --card SHA256
```

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.
