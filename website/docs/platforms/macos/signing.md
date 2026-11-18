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

<GuideScreenshot src="/img/guide/macos/en/sign.png" alt="Add documents and choose their format" steps={[{"x": 5, "y": 7, "text": "Open Sign."}, {"x": 67, "y": 47, "text": "Choose files, or drop files into the dashed area. Add the whole batch before signing."}, {"x": 40, "y": 41, "text": "Check each filename and its format. The PDF stamp control sits beside its format."}, {"x": 92, "y": 96, "text": "Check the selected card, then choose the floating Sign button at the bottom-right, or press ⌘Return. The button shows the batch size and stays visible while you scroll."}]} />

## Place a visible stamp on a PDF

Open Stamp off/Edit stamp on a queued PDF. A visible stamp is optional and does not replace the cryptographic signature. On a multipage PDF choose the page in the preview before applying.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/macos/en/stamp.png" alt="Place a visible stamp on a PDF" steps={[{"x": 95, "y": 6, "text": "Enable Visible stamp."}, {"x": 12, "y": 50, "text": "Drag the stamp to position it; drag a corner to resize it."}, {"x": 94, "y": 29, "text": "Choose the selected page or all pages; optionally apply the setting to all queued PDFs."}, {"x": 92, "y": 95, "text": "Choose Apply to return to the signing queue."}]} />

## Authorize the displayed batch

Use the signing PIN of the selected physical card, not your Mac login password. Stop after an incorrect-PIN result and verify the identity/PIN before another deliberate attempt. The remaining-attempt counter is a card safety limit. A new batch asks again.

<GuideScreenshot src="/img/guide/macos/en/pin.png" alt="Authorize the displayed batch" steps={[{"x": 50, "y": 32, "text": "Check the holder and every listed document. Cancel if anything is unexpected."}, {"x": 50, "y": 60, "text": "Enter the card PIN in the protected boxes."}, {"x": 78, "y": 85, "text": "Choose Remember PIN only if you want this card’s PIN stored in Keychain and unlocked by device authentication."}, {"x": 85, "y": 76, "text": "Choose Sign after the PIN is complete; keep the reader connected until completion."}]} />

## Wait for signing and the timestamp

Leave the reader connected while the app signs and obtains a timestamp. Timestamp/network failures and malformed input are different from an incorrect PIN. Read the actual error before deciding what to do next.

<GuideScreenshot src="/img/guide/macos/en/progress.png" alt="Wait for signing and the timestamp" steps={[{"x": 59, "y": 36, "text": "Wait for the current signing step to finish."}]} />

## Find, preview and share the completed output

Standalone macOS normally writes a new file beside the source, with a signed suffix, without overwriting the original. The App Store edition uses its permitted storage and explicit export/share actions. Keep a detached XML together with its original.

In Mac App Store version 0.2.13, you can also choose a folder in **Settings → General → Documents** to automatically receive copies of signed documents. Choose the folder in the system dialog to grant access.

<GuideScreenshot src="/img/guide/macos/en/export-folder.png" alt="Choose a folder for automatic copies of signed documents from the Mac App Store edition." steps={[{"text": "Choose a folder for automatic copies of signed documents from the Mac App Store edition.", "x": 14, "y": 94}]} />

<GuideScreenshot src="/img/guide/macos/en/success.png" alt="Use Preview beside the completed filename. The adjacent controls save a copy, share the document or reveal it in Finder." steps={[{"text": "Use Preview beside the completed filename. The adjacent controls save a copy, share the document or reveal it in Finder.", "x": 73, "y": 69}]} />

## Recover from a failed document

A batch can contain successful and failed items. Keep completed outputs. Correct the failed input or connection before starting another deliberate operation; there is no automatic PIN retry. An unchanged malformed PDF will fail again.

<GuideScreenshot src="/img/guide/macos/en/file-error.png" alt="Recover from a failed document" steps={[{"x": 42, "y": 41, "text": "Read the error on the affected file; use its row menu to remove it if necessary."}]} />
