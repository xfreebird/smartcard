---
title: "Windows · Command line (CLI) guides"
sidebar_label: "Windows · Command line (CLI)"
hide_table_of_contents: true
pagination_prev: null
pagination_next: "platforms/windows-cli/setup"
---

import GuideDirectory from '@site/src/components/GuideDirectory';
import GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';

# Windows · Command line (CLI) guides

Choose what you want to do. Each task has its own short illustrated guide.

<GuideDirectory platform="windows-cli" />
<GuideAnchorRedirect platform="windows-cli" />

## Before you begin

Reach a specific goal using the numbered terminal examples below. Commands stay in English. The illustrated panels are instructional examples, not screenshots of a real card signing. Only the capability and unsigned-fixture verification results were captured from a local executable; no real PIN, card or credential provider was used.

You need a supported electronic ID and its correct signing PIN, a compatible USB reader and any required adapter for card operations. NFC is not supported. Verification needs no reader or PIN. Keep your original documents. The private signing key stays on the card.

:::info
The Windows CLI currently supports help, capabilities, readers, cert, sign-hex, mcp, encrypt, decrypt, encryption-certs and remove-file. Normal sign/xades/verify/server/cms-for-hash commands are not implemented. Use the desktop app for those document workflows, or the separately configured MCP verification/unattended tools. Enable local signing requests in Windows app Settings and configure --broker-directory for foreground approval. Do not assume command parity from the macOS/Linux examples.
:::
