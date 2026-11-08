---
title: "Sign documents — Linux · Command line (CLI)"
sidebar_label: "Sign documents"
description: "Add files, choose the format and stamp, approve and save the output."
pagination_prev: "platforms/linux-cli/setup"
pagination_next: "platforms/linux-cli/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign documents — Linux · Command line (CLI)

[Platform overview](../linux-cli.md) · [Installation and reader setup](./setup.md)

Add files, choose the format and stamp, approve and save the output.

Illustrations use fictional data. Follow the instructions in your installed app.

## Sign PDF or create an XML signature

PDF signing embeds a PAdES-T signature and timestamp. Omitting the output path creates a separate `-semnat.pdf` file; existing outputs are not overwritten. XAdES defaults to detached XML and SHA-256: retain the unchanged original with the XML. Choose BES without timestamp, T with timestamp, or C with certificate/revocation references. Use `--enveloping` only when the recipient wants the original inside XML. Timestamped formats need network access; C also obtains status references.

<GuideScreenshot src="/img/guide/linux-cli/en/sign.svg" alt="3. Sign PDF or create an XML signature" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Start PDF signing and respond to the no-echo PIN prompt."}, {"x": 3, "y": 53.5, "text": "Create the XML level your recipient requires."}, {"x": 3, "y": 83.2, "text": "Use enveloping only when needed; keep originals for detached XML."}]} />

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf
esemnbun xades XAdES-T Declaration.txt Declaration.xml
esemnbun xades XAdES-BES Declaration.txt Embedded.xml --enveloping
```

Enter the PIN only through the no-echo prompt or an existing secret-input caller with `--pin-stdin`. Input precedence is stdin, `MSIGN_PIN`, then prompt. Never put a PIN in command arguments, screenshots, scripts or logs. An incorrect PIN needs a deliberate stop and review; never retry automatically.

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf --pin-stdin
```
