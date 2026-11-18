---
title: "Find saved documents — Linux"
sidebar_label: "Find saved documents"
description: "Open signing details, share saved files and clear recent history."
pagination_prev: "platforms/linux/results"
pagination_next: "platforms/linux/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Find saved documents — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Open signing details, share saved files and clear recent history.

## Find signed documents

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents contains a signed-output collection and separate operation History. Entries point to actual files and do not replace a backup. A missing or moved file needs to be selected again at its new location.

<GuideScreenshot src="/img/guide/linux/en/documents.png" alt="Find signed documents" steps={[{"text": "Select the filename to inspect its signing details.", "x": 28, "y": 30}, {"text": "Open the file directly from its row.", "x": 67, "y": 30}, {"text": "Use the folder button to show the saved file in its folder.", "x": 76, "y": 30}]} />

## Open signing details

Select a saved filename to verify its current contents in the details window. The example uses a fictional signer and a self-signed certificate, so its trust chain is unknown. Open the document or its folder from the bottom of the window.

<GuideScreenshot src="/img/guide/linux/en/details.png" alt="Open signing details" steps={[{"text": "Read the verification outcome and check the signer.", "x": 37, "y": 34}, {"text": "Open the document or show it in its folder.", "x": 65, "y": 79}]} />

## Clear history while keeping documents

Switch to History, choose Clear list and read the confirmation before accepting it. Clearing history removes operation entries, not signed files or the separate Saved documents collection. Return to Saved documents afterward.

<GuideScreenshot src="/img/guide/linux/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Review History; Saved documents returns to your saved collection.", "x": 14, "y": 11}, {"text": "Choose Clear list and confirm history-only removal.", "x": 73, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/en/history-confirm.png" alt="Clear history while keeping documents" start={3} steps={[{"x": 57, "y": 57, "text": "Read the history-only confirmation, then choose Clear list or Cancel. Saved documents remain available."}]} />
