---
title: "Sign documents — Android phone"
sidebar_label: "Sign documents"
description: "Add files, choose the format and stamp, approve and save the output."
pagination_prev: "platforms/android/setup"
pagination_next: "platforms/android/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign documents — Android phone

[Platform overview](../android.md) · [Installation and reader setup](./setup.md)

Add files, choose the format and stamp, approve and save the output.

## Add files and prepare a batch

Keep the reader connected until every result appears. The original input remains separate from the signed output. You can also share documents from Files or another app to eSemnBun.

<GuideScreenshot src="/img/guide/android-phone/en/sign.png" alt="Add files and prepare a batch" steps={[{"text": "Swipe to the intended card and check the Used for signing indicator.", "x": 9.1, "y": 19.5}, {"text": "Tap Add documents and select one or several files in the system picker. Download cloud files first if they are unavailable.", "x": 14.1, "y": 65.1}, {"text": "Expand Show files to review each filename. Use the batch menu for shared settings or the row menu for one file.", "x": 13.6, "y": 58.5}, {"text": "Tap Sign when the card and the full document list are correct.", "x": 53, "y": 84}]} />

## Choose PDF or XML signatures

PDF signature (PAdES-T) embeds the signature in a PDF. XAdES creates XML: keep the original beside a detached signature. Timestamped and validation-data formats need the relevant trust services. A visible stamp is optional and does not replace the digital signature.

<GuideScreenshot src="/img/guide/android-phone/en/format.png" alt="Choose PDF or XML signatures" steps={[{"text": "Open the file’s three-dot menu. Choose the signature format for that file; remove a mistaken input from the same menu.", "x": 51.1, "y": 22.8}, {"text": "For PDFs, enable the visible-stamp option if you want to place a stamp before approval. XML signing here produces a detached signature; retain the original."}]} />

## Place an optional visible stamp

The placement editor opens before the PIN request when a stamp is enabled. Review page content to avoid covering important text.

The stamp labels follow the app language chosen in General settings.

<GuideScreenshot src="/img/guide/android-phone/en/stamp.png" alt="Place an optional visible stamp" steps={[{"text": "Drag the stamp on the page; use its resize handles to fit the available space.", "x": 38, "y": 58}, {"text": "Use the page arrows, then choose One page, All pages, or Off.", "x": 40.9, "y": 80.6}, {"text": "Choose whether the placement applies to all queued PDFs, then tap Apply. Cancel returns without approving a signature.", "x": 82.5, "y": 93.0}]} />

## Review and authorize

Check the holder, document names, format, and requesting website when one is shown. Current Android builds ask for the PIN for each new approval; saving a PIN is not offered. Never send your PIN in a support request.

<GuideScreenshot src="/img/guide/android-phone/en/pin.png" alt="Review and authorize" steps={[{"text": "Enter the selected card’s signing PIN in the protected field. The approval covers only the listed request.", "x": 6.8, "y": 55.7}, {"text": "Tap Sign. Keep the app and reader available while the batch completes. Cancel if the request is unexpected.", "x": 76.6, "y": 64.9}]} />

## Follow signing progress

The progress card names the active stage: connecting, authentication, certificate read, PIN verification, signing, timestamping, revocation information, or writing the output. A stage can take time while an external service responds.

<GuideScreenshot src="/img/guide/android-phone/en/sign-progress.png" alt="Follow signing progress" steps={[{"text": "After approval, watch the active stage and keep the reader connected. Wait for a completed result before opening or sharing the output.", "x": 13.6, "y": 49.7}, {"text": "If the operation reports an error, follow that message. Do not enter the PIN repeatedly or start another batch while the current request is active."}]} />

## Recover from a failed item

An error belongs to the affected file. Review the remaining rows and completed outputs; a failure is not evidence that every document failed. This illustration shows a timestamp-service error on one item in a mixed batch.

<GuideScreenshot src="/img/guide/android-phone/en/sign-failure.png" alt="Recover from a failed item" steps={[{"text": "Read the message under the failed file. For a timestamp/network error, restore connectivity or wait for the service to recover. For an unreadable input, replace it with a valid source file.", "x": 5.8, "y": 73.2}, {"text": "Keep successful outputs, correct the cause, and deliberately start a new signing attempt only for the files that still need it. There is no automatic PIN retry; after a wrong-PIN warning, stop and confirm the card and PIN before any further attempt."}]} />

## Open, save, or share the result

On Android 10 and later, ordinary signed output is saved under Downloads/eSemnBun. Keep both the XML and original document for detached XAdES. If one file fails, read its error and check completed files before starting another batch.

<GuideScreenshot src="/img/guide/android-phone/en/results.png" alt="Open, save, or share the result" steps={[{"text": "Tap Open beside a completed file to open it in a compatible viewer.", "x": 69.6, "y": 61.6}, {"text": "In Files → Saved documents, use the file’s menu for Open, Verify, Share, or Save as… when file-provider access is available. Save as lets you choose another location."}, {"text": "Clear results hides this completion list. Your saved outputs remain available in Files.", "x": 68.0, "y": 53.6}]} />
