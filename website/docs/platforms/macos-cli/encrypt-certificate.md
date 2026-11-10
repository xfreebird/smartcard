---
title: "Encrypt for a certificate holder — Mac · Command line (CLI)"
sidebar_label: "Encrypt for a certificate holder"
description: "Encrypt for a certificate holder"
pagination_prev: "platforms/macos-cli/encrypt-password"
pagination_next: "platforms/macos-cli/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Encrypt for a certificate holder — Mac · Command line (CLI)

[Platform overview](../macos-cli.md) · [Installation and reader setup](./setup.md)

Encrypt for a certificate holder

## Encrypt for a certificate holder

The Moldovan ID card does not provide the encryption key required by these certificate/card commands. Use password encryption for that card. The CLI certificate commands are retained for compatible encryption certificates and hardware; a signing-only certificate is not suitable.

Ask the recipient for their public encryption certificate (.cer/.der), exported using the next guide. Confirm its fingerprint with its owner through a trusted channel. A signing-only certificate is not sufficient. Encrypting for someone else needs their public certificate, not their card, private key or PIN.

Instructional command example — no operation executed.

<GuideScreenshot src="/img/guide/macos-cli/en/protect-certificate.svg" alt="Encrypt for a certificate holder" steps={[{"x": 20, "y": 25, "text": "Run the command with your own filenames. Use a new output path. Enter secrets only in the hidden prompt; replace SHA256 with the full encryption-certificate fingerprint."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc --certificate recipient.cer
```
