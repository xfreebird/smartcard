---
title: "Sign documents — Mac"
sidebar_label: "Sign documents"
description: "Add files, choose the format and stamp, approve and save the output."
pagination_prev: "platforms/macos/setup"
pagination_next: "platforms/macos/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign documents — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Add files, choose the format and stamp, approve and save the output.

## Add documents and choose their format

A PDF normally uses PAdES-T: the signature stays inside the PDF. Other files normally use detached XAdES-T: the XML and unchanged original belong together. Use the format control on a queued file when a recipient requires a different supported format. The row menu removes an unintended file.

<GuideScreenshot src="/img/guide/macos/en/sign.png" alt="Add documents and choose their format" steps={[{"x": 7, "y": 11, "text": "Open Sign."}, {"x": 69, "y": 71, "text": "Choose files, or drop files into the dashed area. Add the whole batch before signing."}, {"x": 36, "y": 53, "text": "Check each filename and its format. The PDF stamp control sits beside its format."}, {"x": 92, "y": 3, "text": "Check the selected card, then choose Sign. The button shows the batch size."}]} />

## Place a visible stamp on a PDF

Open Stamp off/Edit stamp on a queued PDF. A visible stamp is optional and does not replace the cryptographic signature. On a multipage PDF choose the page in the preview before applying.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/macos/en/stamp.png" alt="Place a visible stamp on a PDF" steps={[{"x": 83, "y": 17, "text": "Enable Visible stamp."}, {"x": 21, "y": 49, "text": "Drag the stamp to position it; drag a corner to resize it."}, {"x": 83, "y": 34, "text": "Choose the selected page or all pages; optionally apply the setting to all queued PDFs."}, {"x": 81, "y": 84, "text": "Choose Apply to return to the signing queue."}]} />

## Authorize the displayed batch

Use the signing PIN of the selected physical card, not your Mac login password. Stop after an incorrect-PIN result and verify the identity/PIN before another deliberate attempt. The remaining-attempt counter is a card safety limit. A new batch asks again.

<GuideScreenshot src="/img/guide/macos/en/pin.png" alt="Authorize the displayed batch" steps={[{"x": 49, "y": 28, "text": "Check the holder and every listed document. Cancel if anything is unexpected."}, {"x": 49, "y": 51, "text": "Enter the card PIN in the protected boxes."}, {"x": 49, "y": 62, "text": "Choose Remember PIN only if you want this card’s PIN stored in Keychain and unlocked by device authentication."}, {"x": 85, "y": 76, "text": "Choose Sign after the PIN is complete; keep the reader connected until completion."}]} />

## Wait for signing and the timestamp

Leave the reader connected while the app signs and obtains a timestamp. Timestamp/network failures and malformed input are different from an incorrect PIN. Read the actual error before deciding what to do next.

<GuideScreenshot src="/img/guide/macos/en/progress.png" alt="Wait for signing and the timestamp" steps={[{"x": 60, "y": 42, "text": "Wait for the current signing step to finish."}]} />

## Find, preview and share the completed output

Standalone macOS normally writes a new file beside the source, with a signed suffix, without overwriting the original. The App Store edition uses its permitted storage and explicit export/share actions. Keep a detached XML together with its original.

<GuideScreenshot src="/img/guide/macos/en/success.png" alt="Find, preview and share the completed output" steps={[{"x": 80, "y": 53, "text": "Click the completed row or Show in Finder to locate the output."}, {"x": 90, "y": 53, "text": "Use Preview to inspect the output. Use Share for the signed PDF, then choose its destination."}]} />

## Recover from a failed document

A batch can contain successful and failed items. Keep completed outputs. Correct the failed input or connection before starting another deliberate operation; there is no automatic PIN retry. An unchanged malformed PDF will fail again.

<GuideScreenshot src="/img/guide/macos/en/file-error.png" alt="Recover from a failed document" steps={[{"x": 57, "y": 54, "text": "Read the error on the affected file; use its row menu to remove it if necessary."}]} />
