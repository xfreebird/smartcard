---
title: "Check a signature — Mac"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/macos/signing"
pagination_next: "platforms/macos/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

Illustrations use fictional data. Follow the instructions in your installed app.

## Verify a PDF and every signature

Verification does not require a reader or PIN. It checks the file you selected, not a visual stamp or a filename. Offline checks do not establish current certificate revocation status.

<GuideScreenshot src="/img/guide/macos/en/verify.png" alt="Verify a PDF and every signature" steps={[{"x": 7, "y": 15, "text": "Open Verify."}, {"x": 58, "y": 10, "text": "Choose signed files or drop them into the dashed area."}, {"x": 32, "y": 35, "text": "Expand each Author row, including additional signatures on the same document."}, {"x": 35, "y": 17, "text": "Use Clear results before starting a separate inspection."}]} />

## Read integrity, trust and certificate details

A valid cryptographic signature, intact document, trusted chain and timestamp are separate checks. Scroll for all certificate and technical fields. Do not interpret an issuer’s registration number as the signer’s personal identifier.

<GuideScreenshot src="/img/guide/macos/en/certificate.png" alt="Read integrity, trust and certificate details" steps={[{"x": 32, "y": 35, "text": "Expand the signature to read signer, signing time and timestamp."}, {"x": 34, "y": 57, "text": "Read each integrity, signature and trust-chain check."}, {"x": 34, "y": 68, "text": "Expand Certificate details and inspect subject, issuer and key information."}]} />

## Verify detached XML with its original

Add the XML in Verify. When the document digest cannot be checked, choose the original file(s) using the result’s Choose originals action. Supply the exact unchanged original, not the signed XML itself. Re-read the updated integrity result. An XML alone may be insufficient for a recipient.

<GuideScreenshot src="/img/guide/macos/en/verify-original.png" alt="Verify detached XML with its original" steps={[{"x": 58, "y": 10, "text": "Add the detached XML signature."}, {"x": 42, "y": 39, "text": "Read the missing-original/incomplete result and provide the original requested by the result."}]} />
