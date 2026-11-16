---
title: "Check a signature — Linux"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/linux/signing"
pagination_next: "platforms/linux/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

## Verify a PDF

Verification needs neither a card nor a PIN. Open Verify and choose or drop a signed PDF/XML. Multiple selections are supported. Read every signature rather than relying on a filename or visual stamp. Checks run offline and do not establish current certificate revocation status.

<GuideScreenshot src="/img/guide/linux/en/verify.png" alt="Verify a PDF" steps={[{"text": "Open Verify and choose a signed file.", "x": 51, "y": 3}, {"text": "Read the overall result and number of signatures.", "x": 49, "y": 25}, {"text": "Inspect each author, integrity and trust check.", "x": 32, "y": 41}]} />

## Inspect certificate and technical details

Scroll through the result, then expand Certificate details and Technical details. Integrity, cryptographic signature, certificate trust and timestamp are separate checks. Certificate issuer organization information is not the signer’s personal identifier.

<GuideScreenshot src="/img/guide/linux/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Certificate details and inspect the subject/issuer/key fields.", "x": 75, "y": 57}, {"text": "Expand Technical details for the format and signature identifier.", "x": 48, "y": 79}]} />

## Verify detached XML with its original

For detached XAdES, put the exact unchanged original beside the XML, using the name referenced by the signature, then select the XML again in Verify. This Linux version has no inline Choose originals picker: the original-file relationship is resolved from the XML’s folder. A missing original prevents a complete integrity conclusion.

<GuideScreenshot src="/img/guide/linux/en/verify.png" alt="Verify detached XML with its original" steps={[{"text": "Keep the detached XML and original together, then choose the XML again in Verify.", "x": 49, "y": 25}]} />
