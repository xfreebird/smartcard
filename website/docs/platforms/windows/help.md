---
title: "Fix a problem — Windows desktop reference"
sidebar_label: "Fix a problem"
description: "Resolve reader, PIN, document and connection problems safely."
pagination_prev: "platforms/windows/browser"
pagination_next: null
---



# Fix a problem — Windows desktop reference

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Resolve reader, PIN, document and connection problems safely.

## Update or resolve a problem

Microsoft Store installations update through the store. Standalone builds offer update checks that lead to the download page; install the replacement MSI from the release.

| Symptom | Next step |
| --- | --- |
| Reader missing | Check Device Manager for the smart-card reader; reconnect it and verify the Smart Card service. |
| Certificate does not load | Reinsert the card and allow the read to finish. |
| Wrong identity | Select the intended card before entering its PIN. |
| Browser port occupied | Stop the competing recognized server, then reconnect. |
| Saved PIN unavailable | Use manual PIN entry and review Windows authentication/settings. |
| Document fails | Inspect its error, preserve the source, and correct the cause before retrying. |

Stop after an incorrect-PIN result and verify the PIN rather than guessing. Report app/Windows versions, MSI or Store edition, architecture, reader model, and reproduction steps. See [troubleshooting](/docs/troubleshooting).
