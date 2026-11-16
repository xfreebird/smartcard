---
title: "Find saved documents — Mac"
sidebar_label: "Find saved documents"
description: "Open signing details, share saved files and clear recent history."
pagination_prev: "platforms/macos/results"
pagination_next: "platforms/macos/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Find saved documents — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Open signing details, share saved files and clear recent history.

## Find a saved signed document

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents and operation History are separate collections. Entries refer to files; if a file has moved or disappeared, choose the file again from its new location for verification.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="Find a saved signed document" steps={[{"x": 49, "y": 7, "text": "Open Documents and choose Saved documents."}, {"x": 34, "y": 13, "text": "Use Search documents to filter by filename."}, {"x": 45, "y": 15, "text": "Click the document row to open its signing-details modal."}]} />

## Inspect and hand off a saved document

The details modal uses the same verification presentation as Verify. Inspecting a saved document does not replace the files in the Verify workspace. Preview is a file preview, not a separate security validation.

<GuideScreenshot src="/img/guide/macos/en/details.png" alt="Inspect and hand off a saved document" steps={[{"x": 33, "y": 48, "text": "Expand the author to inspect signature and certificate details."}, {"x": 35, "y": 58, "text": "Choose Preview to read the file."}, {"x": 43, "y": 58, "text": "Choose Share to export/send the signed output."}, {"x": 53, "y": 58, "text": "Choose Show in Finder to locate the file."}]} />

## Clear operation history while keeping documents

Choose the trash control, read the confirmation and confirm only if you want to remove the operation list. This does not delete signed files or the separate Saved documents collection. Return to Saved documents to continue using your saved output.

<GuideScreenshot src="/img/guide/macos/en/history.png" alt="Clear operation history while keeping documents" steps={[{"x": 64, "y": 8, "text": "In Documents, select History."}, {"x": 73, "y": 8, "text": "Choose the trash control and confirm the history-only cleanup."}, {"x": 51, "y": 8, "text": "Return to Saved documents; the saved collection remains available."}]} />
