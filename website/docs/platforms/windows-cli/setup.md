---
title: "Get started — Windows · Command line (CLI)"
sidebar_label: "Get started"
description: "Install, connect a reader and choose your card."
pagination_prev: "platforms/windows-cli"
pagination_next: "platforms/windows-cli/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — Windows · Command line (CLI)

[Platform overview](../windows-cli.md)

Install, connect a reader and choose your card.

Illustrations use fictional data. Follow the instructions in your installed app.

## Install and discover what your executable supports

Open [Downloads](/downloads/) and choose your platform. CLI archives contain terminal and MCP tools; the desktop application is a separate installation. Use the package-manager instructions there for the current version and signing-key fingerprint. Then locate the command and inspect capabilities before automating.

<GuideScreenshot src="/img/guide/windows-cli/en/install.svg" alt="1. Install and discover what your executable supports" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 30.6, "text": "Install through the selected platform channel."}, {"x": 3, "y": 78.3, "text": "Run capability discovery before using card commands."}]} />

```powershell
scoop bucket add esemnbun https://github.com/xfreebird/homebrew-utils
scoop install esemnbun/esemnbun-cli
Get-Command esemnbun
esemnbun capabilities --json
```

For Chocolatey, download the project .nupkg to an empty folder, then run:

```powershell
choco install esemnbun-cli --source . --yes
```

## Find the reader and check the certificate

Connect the USB reader and insert your card. List readers, then inspect the signing certificate without entering a PIN. With several cards, use the exact reader name and check the holder before every signing request. These commands below are examples; a reader was not accessed to create this guide.

<GuideScreenshot src="/img/guide/windows-cli/en/reader.svg" alt="2. Find the reader and check the certificate" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "List connected readers and card presence."}, {"x": 3, "y": 53.5, "text": "Read the intended certificate; replace the reader name."}, {"x": 3, "y": 83.2, "text": "Calculate SHA-256 of the exported certificate. Use these 64 hexadecimal digits for unattended signing, not the SHA-1 shown by cert."}]} />

```powershell
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
Get-FileHash leaf.der -Algorithm SHA256
```
