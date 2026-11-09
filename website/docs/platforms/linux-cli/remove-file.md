---
title: "Remove a local file — Linux · Command line (CLI)"
sidebar_label: "Remove a local file"
description: "Remove a local file"
pagination_prev: "platforms/linux-cli/share-certificate"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Remove a local file — Linux · Command line (CLI)

[Platform overview](../linux-cli.md) · [Installation and reader setup](./setup.md)

Remove a local file

Illustrations use fictional data. Follow the instructions in your installed app.

## Remove a local file

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/linux-cli/en/protect-remove.svg" alt="Remove a local file" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun remove-file disposable-copy.pdf --confirm-removal
```
