---
title: "Decrypt a received file — Windows · Command line (CLI)"
sidebar_label: "Decrypt a received file"
description: "Decrypt a received file"
pagination_prev: "platforms/windows-cli/encrypt-certificate"
pagination_next: "platforms/windows-cli/share-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decrypt a received file — Windows · Command line (CLI)

[Platform overview](../windows-cli.md) · [Installation and reader setup](./setup.md)

Decrypt a received file

## Decrypt a received file

Certificate/card commands use an encryption certificate by default. Add `--card-public-key` only for the explicit card-public-key compatibility workflow. Successful encryption or certificate export does not prove decryption support: the matching card must provide the required private-key operation.

Ask the sender which method they used. For password files, obtain the password separately. For certificate files, connect the matching supported card and reader; you need its encryption key and PIN. A different card or signing-only card cannot unlock the file.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/windows-cli/en/protect-decrypt.svg" alt="Decrypt a received file" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun decrypt Contract.enc Contract-opened.pdf
esemnbun encryption-certs
esemnbun decrypt Contract.enc Contract-opened.pdf --card SHA256
```

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.
