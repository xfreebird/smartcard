---
title: "Share your encryption certificate — Windows · Command line (CLI)"
sidebar_label: "Share your encryption certificate"
description: "Share your encryption certificate"
pagination_prev: "platforms/windows-cli/decrypt-file"
pagination_next: "platforms/windows-cli/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Share your encryption certificate — Windows · Command line (CLI)

[Platform overview](../windows-cli.md) · [Installation and reader setup](./setup.md)

Share your encryption certificate

## Share your encryption certificate

Certificate/card commands use an encryption certificate by default. Add `--card-public-key` only for the explicit card-public-key compatibility workflow. Successful encryption or certificate export does not prove decryption support: the matching card must provide the required private-key operation.

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/windows-cli/en/protect-export.svg" alt="Share your encryption certificate" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun encryption-certs
esemnbun encryption-certs --card SHA256 --out recipient.cer
```

Share only recipient.cer; exporting needs no PIN and never exports the private key.
