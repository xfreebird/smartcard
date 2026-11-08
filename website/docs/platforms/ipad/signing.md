---
title: "Sign documents — iPad"
sidebar_label: "Sign documents"
description: "Add files, choose the format and stamp, approve and save the output."
pagination_prev: "platforms/ipad/setup"
pagination_next: "platforms/ipad/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign documents — iPad

[Platform overview](../ipad.md) · [Installation and reader setup](./setup.md)

Add files, choose the format and stamp, approve and save the output.

Illustrations use fictional data. Follow the instructions in your installed app.

## Add documents and choose a signature format

Open Sign and choose files from Files or a cloud provider. Download cloud-only documents first if access fails. You can also send files from another app through its share sheet to the eSemnBun extension. Expand the file list, inspect each name, remove unintended files from its options, and choose the requested format. PDFs use PAdES-T; other files use XAdES. Detached XML must travel with its unchanged original. XAdES-BES has no timestamp, T adds one, and C adds certificate/status references. Enveloping XML includes its source content. Timestamped signing requires the public trust services.

<GuideScreenshot src="/img/guide/ipad/en/sign.png" alt="Confirm the selected holder before signing." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Confirm the selected holder before signing.", "x": 12.0, "y": 37.5}, {"text": "Choose files, or add more documents to the current queue.", "x": 79.0, "y": 75.0}, {"text": "Expand the queue, then open an individual file’s options to choose its format, stamp or removal.", "x": 93.0, "y": 40.0}, {"text": "Choose Sign only after reviewing the complete queue.", "x": 10.0, "y": 70.0}]} />

## Place a visible stamp in a PDF

Open a queued PDF’s options and choose Add/Edit stamp. A visible stamp is optional artwork; the cryptographic signature remains the actual signing proof. Position the stamp away from existing text.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/ipad/en/stamp.png" alt="Drag the stamp to move it; drag its corner handles to resize it." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Drag the stamp to move it; drag its corner handles to resize it.", "x": 40, "y": 55}, {"text": "Select the page and choose Off, One page or All pages.", "x": 25, "y": 79}, {"text": "Optionally apply the placement to all queued PDFs, then choose Apply.", "x": 84, "y": 9}]} />

## Review the request and authorize signing

For website requests, inspect the requesting origin and the whole document list before allowing the operation. Cancel unexpected requests. For a local batch, review the queued documents and PIN sheet. Each new batch needs approval; a batch session covers only the listed documents and selected card.

<GuideScreenshot src="/img/guide/ipad/en/consent.png" alt="Check the requesting website and intended operation." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Check the requesting website and intended operation.", "x": 7.1, "y": 12.5}, {"text": "Review all documents; allow only a request you initiated.", "x": 91.4, "y": 87.5}]} />
<GuideScreenshot src="/img/guide/ipad/en/pin.png" alt="Check the holder and selected filenames." steps={[{"text": "Check the holder and selected filenames.", "x": 50, "y": 19}, {"text": "Enter the correct QSCD signing PIN in the protected field.", "x": 30, "y": 27}, {"text": "Use Remember PIN only on a trusted personal device; later access requires the offered device authentication.", "x": 73, "y": 31}, {"text": "Choose Sign to authorize, or Cancel to stop.", "x": 94, "y": 70}]} />

## Wait for completion and save the signed output

Keep the reader and card connected while signing and obtaining the timestamp. Completion is shown separately from the input queue. Use the available result action, or open Documents and select the completed file, then Share to save it in Files or send it to another app. Share the signed output, not the unsigned source; include the original with detached XML.

<GuideScreenshot src="/img/guide/ipad/en/progress.png" alt="Wait for the current signing stage to finish without removing the card." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Wait for the current signing stage to finish without removing the card.", "x": 9.0, "y": 82.5}]} />
<GuideScreenshot src="/img/guide/ipad/en/success.png" alt="Check completion and the output name before opening or sharing the result." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Check completion and the output name before opening or sharing the result.", "x": 9.0, "y": 41.4}]} />

## Recover from a failed document

Read the error on the affected item. Keep outputs that already completed and correct the input or connection before starting another deliberate batch. There is no automatic PIN retry. If the PIN is incorrect, stop and confirm the PIN and selected card; after three incorrect attempts the card can be blocked. The app cannot unblock it. Reconnecting cannot repair an invalid PDF.

<GuideScreenshot src="/img/guide/ipad/en/file-error.png" alt="Read the error on the failed item before making another attempt." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read the error on the failed item before making another attempt.", "x": 47.0, "y": 43.2}]} />
