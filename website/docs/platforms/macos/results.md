---
title: "Understand verification results — Mac"
sidebar_label: "Understand verification results"
description: "Distinguish invalid signatures, unconfirmed trust and unsigned files."
pagination_prev: "platforms/macos/verification"
pagination_next: "platforms/macos/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Understand verification results — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Distinguish invalid signatures, unconfirmed trust and unsigned files.

## Recognize a modified or invalid signature

An invalid result is not repaired by renaming the file or adding a stamp. Request an intact signed copy from its sender and verify that copy.

<GuideScreenshot src="/img/guide/macos/en/verify-invalid.png" alt="Recognize a modified or invalid signature" steps={[{"x": 43, "y": 27, "text": "Read the document’s invalid status, then expand the author to identify the failed check."}]} />

## Distinguish unconfirmed trust

Unconfirmed trust is different from proven document modification. Read the signature and trust-chain details, and follow your recipient’s certificate policy before relying on the document.

<GuideScreenshot src="/img/guide/macos/en/verify-untrusted.png" alt="Distinguish unconfirmed trust" steps={[{"x": 43, "y": 27, "text": "Read the unconfirmed-trust status and expand its details."}]} />

## Recognize an unsigned document

A visible signature image or stamp is not proof of an electronic signature. If no recognized signature is present, ask for the actual signed output rather than a screenshot or scanned copy.

<GuideScreenshot src="/img/guide/macos/en/verify-unsigned.png" alt="Recognize an unsigned document" steps={[{"x": 43, "y": 27, "text": "Check the no-signature result before sharing the file as signed."}]} />
