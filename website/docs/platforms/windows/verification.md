---
title: "Check a signature — Windows"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/windows/signing"
pagination_next: "platforms/windows/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

## Verify and inspect activity

Open **Verify** and choose or drop in a signed PDF/XML file. A detached XML signature also needs the original document. Inspect the signer, integrity, certificate chain, and available timestamp checks. A valid filename or green card status does not establish that a document signature is valid.

**Documents → History** records recent operations and provides actions for available files. Clearing history does not remove the signed documents themselves.

### Choose a document to verify

<GuideScreenshot src="/img/guide/windows/en/verify.png" alt="Choose a document to verify" steps={[{"x": 5.351, "y": 17.059, "text": "Open Verify. Verification needs no card or PIN."}, {"x": 60.148, "y": 28.171, "text": "Choose or drop the signed PDF or XML. Supply unchanged originals for detached XML when requested."}]} />

### Read the verification outcome

<GuideScreenshot src="/img/guide/windows/en/summary.png" alt="Read the verification outcome" steps={[{"x": 36.808, "y": 40.292, "text": "Check the overall outcome, then inspect each signature’s author and signing time."}, {"x": 42.897, "y": 85.746, "text": "Read the integrity, signature and trust checks individually. Scroll down for offline limits and certificate details."}]} />

### Inspect verification details

<GuideScreenshot src="/img/guide/windows/en/results.png" alt="Inspect verification details" steps={[{"x": 60.148, "y": 14.029, "text": "Read the offline verification limits: timestamp trust and current revocation may remain unchecked."}, {"x": 60.148, "y": 23.12, "text": "Expand certificate and technical details to inspect the signer, validity dates and timestamp fields."}]} />
