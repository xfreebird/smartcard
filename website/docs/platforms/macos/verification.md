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

## Verify a PDF and every signature

Verification does not require a reader or PIN. It checks the file you selected, not a visual stamp or a filename. Offline checks do not establish current certificate revocation status.

<GuideScreenshot src="/img/guide/macos/en/verify.png" alt="Read the document verdict first. Expand each signer to inspect that signature." steps={[{"text": "Read the document verdict first. Expand each signer to inspect that signature.", "x": 37, "y": 46}]} />

## Read integrity, trust and certificate details

A valid cryptographic signature, intact document, trusted chain and timestamp are separate checks. Scroll for all certificate and technical fields. Do not interpret an issuer’s registration number as the signer’s personal identifier.

<GuideScreenshot src="/img/guide/macos/en/certificate.png" alt="Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint." steps={[{"text": "Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint.", "x": 39, "y": 44}]} />

<GuideScreenshot src="/img/guide/macos/en/technical.png" alt="Expand Technical details under a signature to read the verification report. Select the same row again to collapse it." steps={[{"text": "Expand Technical details under a signature to read the verification report. Select the same row again to collapse it.", "x": 39, "y": 87}]} />

## Verify detached XML with its original

Add the XML in Verify. When the document digest cannot be checked, choose the original file(s) using the result’s Choose originals action. Supply the exact unchanged original, not the signed XML itself. Re-read the updated integrity result. An XML alone may be insufficient for a recipient.

<GuideScreenshot src="/img/guide/macos/en/verify-original.png" alt="Verify detached XML with its original" steps={[{"x": 38, "y": 35, "text": "Add the detached XML signature."}, {"x": 40, "y": 53, "text": "Read the missing-original/incomplete result and provide the original requested by the result."}]} />
