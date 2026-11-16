---
title: "Sign documents — Linux"
sidebar_label: "Sign documents"
description: "Add files, choose the format and stamp, approve and save the output."
pagination_prev: "platforms/linux/setup"
pagination_next: "platforms/linux/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign documents — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Add files, choose the format and stamp, approve and save the output.

## Add documents and prepare a batch

Choose or drop all the intended files into Sign. You can select multiple documents. Review every filename and remove unintended inputs before authorization. Drag/drop behavior depends on your file manager; choosing files remains available.

<GuideScreenshot src="/img/guide/linux/en/sign.png" alt="Add documents and prepare a batch" steps={[{"text": "Open Sign.", "x": 41, "y": 3}, {"text": "Choose files or drop them into the dashed area.", "x": 50, "y": 76}, {"text": "Use the row menu to remove an unintended file.", "x": 73, "y": 49}, {"text": "Choose Sign only when the complete queue is correct.", "x": 91, "y": 95}]} />

## Choose the signature format

PDF signature is PAdES-T and stays inside the PDF. XML signature is XAdES-BES; XML with timestamp is XAdES-T; XML with validation data is XAdES-C. Timestamped/status-data formats need the corresponding network services. Detached XML must remain with its unchanged original.

<GuideScreenshot src="/img/guide/linux/en/format.png" alt="Choose the signature format" steps={[{"text": "Open the three-dot file menu.", "x": 70, "y": 49}, {"text": "Select the format requested by your recipient.", "x": 70, "y": 66}, {"text": "Remove an unintended file from the same menu.", "x": 73, "y": 87}]} />

## Place an optional visible PDF stamp

Open the file menu and choose Add stamp. A visible stamp is optional and is not the cryptographic signature. Position it without covering important content. This sample PDF contains an explicit unsigned-example label.

<GuideScreenshot src="/img/guide/linux/en/stamp.png" alt="Place an optional visible PDF stamp" steps={[{"text": "Enable the stamp and choose its page mode.", "x": 79, "y": 23}, {"text": "Drag/resize the placement in the PDF preview.", "x": 22, "y": 53}, {"text": "Apply the placement, or cancel to leave the queue unchanged.", "x": 80, "y": 83}]} />

## Review and authorize the batch

Use the signing PIN for the selected card, not your Linux login password. Confirm the holder and whole file list before signing. A new batch requires another approval. Stop after an incorrect-PIN result and confirm the PIN; repeated guesses may block the card. The sample dialog disables saved-PIN access because it never uses a real keyring.

<GuideScreenshot src="/img/guide/linux/en/pin.png" alt="Review and authorize the batch" steps={[{"text": "Check the holder and listed filenames.", "x": 50, "y": 36}, {"text": "Enter the card PIN in the protected input.", "x": 50, "y": 48}, {"text": "Choose Sign; cancel if the request is unexpected.", "x": 59, "y": 64}]} />

## Wait for signing and timestamping

Leave the reader connected until the result appears. Timestamp retrieval needs network access. A timestamp/network error differs from an incorrect PIN; read the specific error before another deliberate request.

<GuideScreenshot src="/img/guide/linux/en/progress.png" alt="Wait for signing and timestamping" steps={[{"text": "Wait for all current signing steps and the final result.", "x": 50, "y": 90}]} />

## Locate the completed output

The app creates a separate output rather than replacing the input. Use the completed row to open/reveal the result. Retain the unchanged original with detached XML.

<GuideScreenshot src="/img/guide/linux/en/success.png" alt="Locate the completed output" steps={[{"text": "Activate the completed result to locate/open its separate output.", "x": 63, "y": 42}]} />

## Recover from a failed item

A batch may contain completed and failed items. Keep completed outputs, read the failed item’s message and correct the cause before starting a new deliberate request. There is no automatic PIN retry or repair of malformed input.

<GuideScreenshot src="/img/guide/linux/en/failure.png" alt="Recover from a failed item" steps={[{"text": "Read the affected file’s error before deciding on another request.", "x": 36, "y": 50}]} />
