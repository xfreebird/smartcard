---
title: "Get started — Mac · Command line (CLI)"
sidebar_label: "Get started"
description: "Install, connect a reader and choose your card."
pagination_prev: "platforms/macos-cli"
pagination_next: "platforms/macos-cli/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — Mac · Command line (CLI)

[Platform overview](../macos-cli.md)

Install, connect a reader and choose your card.

Illustrations use fictional data. Follow the instructions in your installed app.

## Install and discover what your executable supports

Open [Downloads](/downloads/) and choose your platform. CLI archives contain terminal and MCP tools; the desktop application is a separate installation. Use the package-manager instructions there for the current version and signing-key fingerprint. Then locate the command and inspect capabilities before automating.

<GuideScreenshot src="/img/guide/macos-cli/en/install.svg" alt="1. Install and discover what your executable supports" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "Install through the selected platform channel."}, {"x": 3, "y": 83.2, "text": "Run capability discovery before using card commands."}]} />

```sh
brew install xfreebird/utils/esemnbun-cli
command -v esemnbun
esemnbun capabilities --json
```

<GuideScreenshot src="/img/guide/macos-cli/en/capability.svg" alt="command-line guide" caption="Captured local read-only capability output." steps={[{"x": 3, "y": 5.1, "text": "Run capability discovery before using card commands."}]} />

```sh
esemnbun capabilities --json
```

The captured local build reports MCP unavailable from its ordinary CLI capability envelope; the separate installed esemnbun-mcp helper has its own discovery. Always inspect your installed binaries.

## Find the reader and check the certificate

Connect the USB reader and insert your card. List readers, then inspect the signing certificate without entering a PIN. With several cards, use the exact reader name and check the holder before every signing request. These commands below are examples; a reader was not accessed to create this guide.

<GuideScreenshot src="/img/guide/macos-cli/en/reader.svg" alt="2. Find the reader and check the certificate" caption="Illustrative command example. Copy the commands below; replace example paths and reader names." steps={[{"x": 3, "y": 23.8, "text": "List connected readers and card presence."}, {"x": 3, "y": 53.5, "text": "Read the intended certificate; replace the reader name."}, {"x": 3, "y": 83.2, "text": "Calculate SHA-256 of the exported certificate. Use these 64 hexadecimal digits for unattended signing, not the SHA-1 shown by cert."}]} />

```sh
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
shasum -a 256 leaf.der
```
