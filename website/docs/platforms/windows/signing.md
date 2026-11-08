---
title: "Sign documents — Windows"
sidebar_label: "Sign documents"
description: "Add files, choose the format and stamp, approve and save the output."
pagination_prev: "platforms/windows/setup"
pagination_next: "platforms/windows/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign documents — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Add files, choose the format and stamp, approve and save the output.

Illustrations use fictional data. Follow the instructions in your installed app.

## Sign documents from the app or Explorer

In **Sign**, drag documents to the dashed drop zone or choose **Choose files…**. Where the installed edition provides an Explorer context-menu integration, you can send selected files into eSemnBun from Explorer as well.

1. Add the files and check the format beside each one.
2. For PDFs, use **PAdES-T** to embed the signature in the PDF. XAdES produces XML; detached XML must be kept with the original document.
3. Confirm the selected identity, choose **Sign**, and review the authorization request before entering the card PIN or authenticating a saved entry.
4. Keep the reader connected until completion. Use the result actions to open or locate output files.

Batch authorization applies to the approved document list and selected card. If an item fails, inspect its error before retrying. Completed outputs should not be confused with unsigned inputs. See [signing formats and errors](/docs/signing).

### Prepare the signing batch

<GuideScreenshot src="/img/guide/windows/en/queue.png" alt="Prepare the signing batch" steps={[{"x": 90, "y": 68, "text": "Choose files or drop them into the dashed area."}, {"x": 34, "y": 50, "text": "Check the file format; use Stamp off to add an optional PDF stamp."}, {"x": 88, "y": 95, "text": "Check the selected card and choose Sign for the listed batch."}]} />

### Position a visible PDF stamp

<GuideScreenshot src="/img/guide/windows/en/stamp.png" alt="Position a visible PDF stamp" steps={[{"x": 19, "y": 85, "text": "Move and resize the stamp in the PDF preview."}, {"x": 93, "y": 95, "text": "Check the page options and apply the stamp before signing."}]} />

### Review signing authorization

<GuideScreenshot src="/img/guide/windows/en/pin.png" alt="Review signing authorization" steps={[{"x": 50, "y": 42, "text": "Check the selected identity and the complete document list."}, {"x": 50, "y": 63, "text": "Enter the physical card’s signing PIN only after checking the request. Never guess or retry automatically."}]} />

### Locate completed outputs

<GuideScreenshot src="/img/guide/windows/en/success.png" alt="Locate completed outputs" steps={[{"x": 90, "y": 23, "text": "Inspect each completed row and use its open or reveal action."}, {"x": 44, "y": 23, "text": "Keep detached XML together with its unchanged original. The shown outputs are fictional fixtures."}]} />
