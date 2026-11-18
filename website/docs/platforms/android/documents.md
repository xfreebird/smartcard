---
title: "Find saved documents — Android phone"
sidebar_label: "Find saved documents"
description: "Open signing details, share saved files and clear recent history."
pagination_prev: "platforms/android/results"
pagination_next: "platforms/android/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Find saved documents — Android phone

[Platform overview](../android.md) · [Get started](./setup.md)

Open signing details, share saved files and clear recent history.

## Find signed documents

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Files contains a signed-output library and a separate activity history. A saved entry is a shortcut to a file, not a substitute for a backup.

<GuideScreenshot src="/img/guide/android-phone/en/documents.png" alt="Find signed documents" steps={[{"text": "Tap the filename for signing details.", "x": 15.8, "y": 23.6}, {"text": "Choose Share directly on the file row, or open More actions for Open, Verify, Protect files and Save as.", "x": 70.2, "y": 25.0}]} />

## Read signing details without losing your list

The modal’s verdict is a fresh verification, not just a historical “signed” label. An unavailable file reports an access error; reselect a moved file in Verify.

<GuideScreenshot src="/img/guide/android-phone/en/details.png" alt="Read signing details without losing your list" steps={[{"text": "Read the verification result and expand Technical details to inspect the checks.", "x": 10.0, "y": 70.6}, {"text": "Use Open or Share below the result. Close returns to the document list.", "x": 18.2, "y": 80.4}]} />

## Clear history while keeping documents

History lists document operations and website requests. Clearing it does not clear Saved documents or delete signed files on storage.

<GuideScreenshot src="/img/guide/android-phone/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Choose History to see the full filename, outcome and date for each operation.", "x": 42.8, "y": 16.6}, {"text": "Clear the activity list to remove history entries while keeping saved documents.", "x": 85.7, "y": 16.6}]} />
