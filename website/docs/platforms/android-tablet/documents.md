---
title: "Find saved documents — Android tablet"
sidebar_label: "Find saved documents"
description: "Open signing details, share saved files and clear recent history."
pagination_prev: "platforms/android-tablet/results"
pagination_next: "platforms/android-tablet/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Find saved documents — Android tablet

[Platform overview](../android-tablet.md) · [Installation and reader setup](./setup.md)

Open signing details, share saved files and clear recent history.

## Find signed documents

Documents contains a signed-output library and a separate activity history. A saved entry is a shortcut to a file, not a substitute for a backup.

<GuideScreenshot src="/img/guide/android-tablet/en/documents.png" alt="Find signed documents" steps={[{"text": "Open Documents and select Signed documents.", "x": 31.8, "y": 14.7}, {"text": "Tap a document row to open its signing-details modal. The app checks the current file again.", "x": 34.2, "y": 25.1}]} />

## Read signing details without losing your list

The modal’s verdict is a fresh verification, not just a historical “signed” label. An unavailable file reports an access error; reselect a moved file in Verify.

<GuideScreenshot src="/img/guide/android-tablet/en/details.png" alt="Read signing details without losing your list" steps={[{"text": "Review the verdict and expand the certificate or technical details, just as in Verify. Supply an original if detached XML requests it.", "x": 44.3, "y": 64.6}, {"text": "Tap Close to return to the same signed-document list.", "x": 65.1, "y": 30.0}]} />

## Clear history while keeping documents

History lists document operations and website requests. Clearing it does not clear Signed documents or delete signed files on storage.

<GuideScreenshot src="/img/guide/android-tablet/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Choose History in Documents and review the recent actions.", "x": 41.8, "y": 14.7}, {"text": "Tap Clear the list and confirm, then return to Signed documents to access saved outputs.", "x": 65.2, "y": 20.5}]} />
