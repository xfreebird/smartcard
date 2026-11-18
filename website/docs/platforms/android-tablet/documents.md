---
title: "Find saved documents — Android tablet"
sidebar_label: "Find saved documents"
description: "Open signing details, share saved files and clear recent history."
pagination_prev: "platforms/android-tablet/results"
pagination_next: "platforms/android-tablet/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Find saved documents — Android tablet

[Platform overview](../android-tablet.md) · [Get started](./setup.md)

Open signing details, share saved files and clear recent history.

## Find signed documents

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents contains a signed-output library and a separate activity history. A saved entry is a shortcut to a file, not a substitute for a backup.

<GuideScreenshot src="/img/guide/android-tablet/en/documents.png" alt="Find signed documents" steps={[{"text": "Tap the filename for signing details.", "x": 34.5, "y": 20.7}, {"text": "Choose Share directly on the file row, or open More actions for Open, Verify, Protect files and Save as.", "x": 65.3, "y": 21.6}]} />

## Read signing details without losing your list

The modal’s verdict is a fresh verification, not just a historical “signed” label. An unavailable file reports an access error; reselect a moved file in Verify.

<GuideScreenshot src="/img/guide/android-tablet/en/details.png" alt="Read signing details without losing your list" steps={[{"text": "Read the verification result and expand Technical details to inspect the checks.", "x": 29.1, "y": 65.4}, {"text": "Use Open or Share below the result. Close returns to the document list.", "x": 31.2, "y": 73.5}]} />

## Clear history while keeping documents

History lists document operations and website requests. Clearing it does not clear Saved documents or delete signed files on storage.

<GuideScreenshot src="/img/guide/android-tablet/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Choose History to see the full filename, outcome and date for each operation.", "x": 41.8, "y": 14.7}, {"text": "Clear the activity list to remove history entries while keeping saved documents.", "x": 69.3, "y": 14.7}]} />
