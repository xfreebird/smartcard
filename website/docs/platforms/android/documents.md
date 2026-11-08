---
title: "Find saved documents — Android phone"
sidebar_label: "Find saved documents"
description: "Open signing details, share saved files and clear recent history."
pagination_prev: "platforms/android/results"
pagination_next: "platforms/android/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Find saved documents — Android phone

[Platform overview](../android.md) · [Installation and reader setup](./setup.md)

Open signing details, share saved files and clear recent history.

Illustrations use fictional data. Follow the instructions in your installed app.

## Find signed documents

Files contains a signed-output library and a separate activity history. A saved entry is a shortcut to a file, not a substitute for a backup.

<GuideScreenshot src="/img/guide/android-phone/en/documents.png" alt="Find signed documents" steps={[{"text": "Open Files and select Signed documents.", "x": 5.8, "y": 16.6}, {"text": "Tap a document row to open its signing-details modal. The app checks the current file again.", "x": 15.5, "y": 29.1}]} />

## Read signing details without losing your list

The modal’s verdict is a fresh verification, not just a historical “signed” label. An unavailable file reports an access error; reselect a moved file in Verify.

<GuideScreenshot src="/img/guide/android-phone/en/details.png" alt="Read signing details without losing your list" steps={[{"text": "Review the verdict and expand the certificate or technical details, just as in Verify. Supply an original if detached XML requests it.", "x": 34.6, "y": 72.9}, {"text": "Tap Close to return to the same signed-document list.", "x": 78.6, "y": 20.5}]} />

## Clear history while keeping documents

History lists document operations and website requests. Clearing it does not clear Signed documents or delete signed files on storage.

<GuideScreenshot src="/img/guide/android-phone/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Choose History in Files and review the recent actions.", "x": 43.6, "y": 16.6}, {"text": "Tap Clear the list and confirm, then return to Signed documents to access saved outputs.", "x": 72.0, "y": 23.6}]} />
