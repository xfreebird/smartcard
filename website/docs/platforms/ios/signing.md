---
title: "Sign documents — iPhone"
sidebar_label: "Sign documents"
description: "Add files, choose the format and stamp, approve and save the output."
pagination_prev: "platforms/ios/setup"
pagination_next: "platforms/ios/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign documents — iPhone

[Platform overview](../ios.md) · [Installation and reader setup](./setup.md)

Add files, choose the format and stamp, approve and save the output.

## Add documents and choose a signature format

Open Sign and choose files from Files or a cloud provider. Download cloud-only documents first if access fails. You can also send files from another app through its share sheet to the eSemnBun extension. Expand the file list, inspect each name, remove unintended files from its options, and choose the requested format. PDFs use PAdES-T; other files use XAdES. Detached XML must travel with its unchanged original. XAdES-BES has no timestamp, T adds one, and C adds certificate/status references. Enveloping XML includes its source content. Timestamped signing requires the public trust services.

<GuideScreenshot src="/img/guide/iphone/en/sign.png" alt="Confirm the selected holder before signing." steps={[{"text": "Confirm the selected holder before signing.", "x": 31, "y": 27}, {"text": "Choose files, or add more documents to the current queue.", "x": 29, "y": 69}, {"text": "Expand the queue, then open an individual file’s options to choose its format, stamp or removal.", "x": 78, "y": 53}, {"text": "Choose Sign only after reviewing the complete queue.", "x": 78, "y": 9}]} />

## Place a visible stamp in a PDF

Open a queued PDF’s options and choose Add/Edit stamp. A visible stamp is optional artwork; the cryptographic signature remains the actual signing proof. Position the stamp away from existing text.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/iphone/en/stamp.png" alt="Drag the stamp to move it; drag its corner handles to resize it." steps={[{"text": "Drag the stamp to move it; drag its corner handles to resize it.", "x": 30, "y": 61}, {"text": "Select the page and choose Off, One page or All pages.", "x": 25, "y": 86}, {"text": "Optionally apply the placement to all queued PDFs, then choose Apply.", "x": 87, "y": 12}]} />

## Review the request and authorize signing

For website requests, inspect the requesting origin and the whole document list before allowing the operation. Cancel unexpected requests. For a local batch, review the queued documents and PIN sheet. Each new batch needs approval; a batch session covers only the listed documents and selected card.

<GuideScreenshot src="/img/guide/iphone/en/consent.png" alt="Check the requesting website and intended operation." steps={[{"text": "Check the requesting website and intended operation.", "x": 16, "y": 52}, {"text": "Review all documents; allow only a request you initiated.", "x": 86, "y": 91}]} />
<GuideScreenshot src="/img/guide/iphone/en/pin.png" alt="Check the holder and selected filenames." steps={[{"text": "Check the holder and selected filenames.", "x": 49, "y": 23}, {"text": "Enter the correct QSCD signing PIN in the protected field.", "x": 8, "y": 34}, {"text": "Use Remember PIN only on a trusted personal device; later access requires the offered device authentication.", "x": 86, "y": 40}, {"text": "Choose Sign to authorize, or Cancel to stop.", "x": 88, "y": 63}]} />

## Wait for completion and save the signed output

Keep the reader and card connected while signing and obtaining the timestamp. Completion is shown separately from the input queue. Use the available result action, or open Documents and select the completed file, then Share to save it in Files or send it to another app. Share the signed output, not the unsigned source; include the original with detached XML.

<GuideScreenshot src="/img/guide/iphone/en/progress.png" alt="Wait for the current signing stage to finish without removing the card." steps={[{"text": "Wait for the current signing stage to finish without removing the card.", "x": 10, "y": 45}]} />
<GuideScreenshot src="/img/guide/iphone/en/success.png" alt="Check completion and the output name before opening or sharing the result." steps={[{"text": "Check completion and the output name before opening or sharing the result.", "x": 35, "y": 49}]} />

## Recover from a failed document

Read the error on the affected item. Keep outputs that already completed and correct the input or connection before starting another deliberate batch. There is no automatic PIN retry. If the PIN is incorrect, stop and confirm the PIN and selected card; after three incorrect attempts the card can be blocked. The app cannot unblock it. Reconnecting cannot repair an invalid PDF.

<GuideScreenshot src="/img/guide/iphone/en/file-error.png" alt="Read the error on the failed item before making another attempt." steps={[{"text": "Read the error on the failed item before making another attempt.", "x": 50, "y": 72}]} />
