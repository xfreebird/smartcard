---
title: "Share your encryption certificate — Mac · Command line (CLI)"
sidebar_label: "Share your encryption certificate"
description: "Share your encryption certificate"
pagination_prev: "platforms/macos-cli/decrypt-file"
pagination_next: "platforms/macos-cli/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Share your encryption certificate — Mac · Command line (CLI)

[Platform overview](../macos-cli.md) · [Installation and reader setup](./setup.md)

Share your encryption certificate

## Share your encryption certificate

The Moldovan ID card does not provide the encryption key required by these certificate/card commands. Use password encryption for that card. The CLI certificate commands are retained for compatible encryption certificates and hardware; a signing-only certificate is not suitable.

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-export.svg" alt="Share your encryption certificate" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun encryption-certs
esemnbun encryption-certs --card SHA256 --out recipient.cer
```

Share only recipient.cer; exporting needs no PIN and never exports the private key.
