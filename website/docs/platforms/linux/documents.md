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

Documents contains a signed-output collection and separate operation History. Entries point to actual files and do not replace a backup. A missing or moved file needs to be selected again at its new location.

<GuideScreenshot src="/img/guide/linux/en/documents.png" alt="Find signed documents" steps={[{"text": "Open Documents.", "x": 55, "y": 3}, {"text": "Select the saved document row.", "x": 42, "y": 26}, {"text": "Use Signing details or the folder icon for the selected file.", "x": 36, "y": 37}]} />

## Open signing details

Click the document row or Signing details to open the modal. It verifies the currently readable file without replacing the Verify workspace or adding another operation entry. The sample is genuinely unsigned, so this modal correctly says no signature was found. Close it to return to the collection; the folder icon on the list reveals the file.

<GuideScreenshot src="/img/guide/linux/en/details.png" alt="Open signing details" steps={[{"text": "Read the fresh result in the signing-details modal.", "x": 50, "y": 27}, {"text": "Close the modal to return to the same list.", "x": 73, "y": 12}]} />

## Clear history while keeping documents

Switch to History, choose Clear list and read the confirmation before accepting it. Clearing history removes operation entries, not signed files or the separate Signed documents collection. Return to Signed documents afterward.

<GuideScreenshot src="/img/guide/linux/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Review History; Signed documents returns to your saved collection.", "x": 17, "y": 10}, {"text": "Choose Clear list and confirm history-only removal.", "x": 79, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/en/history-confirm.png" alt="Clear history while keeping documents" start={3} steps={[{"x": 57, "y": 57, "text": "Read the history-only confirmation, then choose Clear list or Cancel. Signed documents remain available."}]} />
