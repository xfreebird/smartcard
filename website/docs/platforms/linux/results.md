---
title: "Understand verification results — Linux"
sidebar_label: "Understand verification results"
description: "Distinguish invalid signatures, unconfirmed trust and unsigned files."
pagination_prev: "platforms/linux/verification"
pagination_next: "platforms/linux/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Understand verification results — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Distinguish invalid signatures, unconfirmed trust and unsigned files.

## Recognize a modified document

An invalid result can mean the document bytes no longer match what was signed. Obtain an intact signed copy from the sender and verify that copy. Adding a stamp or renaming the file does not repair it.

<GuideScreenshot src="/img/guide/linux/en/invalid.png" alt="Recognize a modified document" steps={[{"text": "Read the invalid verdict.", "x": 49, "y": 25}, {"text": "Inspect the failed integrity/signature check.", "x": 47, "y": 70}]} />

## Distinguish unconfirmed trust

An unconfirmed/unknown chain is different from proven document modification. Check integrity and signature separately, then apply your recipient’s certificate policy before relying on the file.

<GuideScreenshot src="/img/guide/linux/en/untrusted.png" alt="Distinguish unconfirmed trust" steps={[{"text": "Read the unconfirmed verdict.", "x": 48, "y": 25}, {"text": "Inspect the trust-chain check separately.", "x": 70, "y": 86}]} />

## Recognize an unsigned file

No recognized signature means this file has no signature the app can verify. A scanned signature image or visible stamp is not a substitute. Ask for the actual electronic signed output.

<GuideScreenshot src="/img/guide/linux/en/unsigned.png" alt="Recognize an unsigned file" steps={[{"text": "Read the no-signature verdict before sending the file as signed.", "x": 50, "y": 26}]} />
