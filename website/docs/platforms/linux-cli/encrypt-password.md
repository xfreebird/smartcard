---
title: "Encrypt a file with a password — Linux · Command line (CLI)"
sidebar_label: "Encrypt a file with a password"
description: "Encrypt a file with a password"
pagination_prev: "platforms/linux-cli/service"
pagination_next: "platforms/linux-cli/encrypt-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt a file with a password — Linux · Command line (CLI)

[Platform overview](../linux-cli.md) · [Installation and reader setup](./setup.md)

Encrypt a file with a password

Illustrations use fictional data. Follow the instructions in your installed app.

## Encrypt a file with a password

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/linux-cli/en/protect-password.svg" alt="Encrypt a file with a password" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc
```
