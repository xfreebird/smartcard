---
title: "Remove a local file — Windows · Command line (CLI)"
sidebar_label: "Remove a local file"
description: "Remove a local file"
pagination_prev: "platforms/windows-cli/share-certificate"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Remove a local file — Windows · Command line (CLI)

[Platform overview](../windows-cli.md) · [Installation and reader setup](./setup.md)

Remove a local file

## Remove a local file

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/windows-cli/en/protect-remove.svg" alt="Remove a local file" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun remove-file disposable-copy.pdf --confirm-removal
```
