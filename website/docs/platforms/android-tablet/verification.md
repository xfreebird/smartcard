---
title: "Check a signature — Android tablet"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/android-tablet/signing"
pagination_next: "platforms/android-tablet/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — Android tablet

[Platform overview](../android-tablet.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

Illustrations use fictional data. Follow the instructions in your installed app.

## Check a signed document

Verification does not require the card or PIN. A green result refers to the checks shown, not to the filename or the presence of a visible stamp.

<GuideScreenshot src="/img/guide/android-tablet/en/verify.png" alt="Check a signed document" steps={[{"text": "Open Verify, choose a signed PDF or XML, and wait for results. Use the system picker to select files from other apps or providers.", "x": 47.1, "y": 25.3}, {"text": "Read the verdict and each signature’s author, signing time, timestamp, integrity, signature, and trust-chain checks.", "x": 35.0, "y": 43.3}, {"text": "Remove an input with × to clear its result, or clear all results before a new check.", "x": 67.8, "y": 35.5}]} />

## Inspect certificate and technical details

An invalid signature differs from an unconfirmed trust chain. Missing originals or unavailable trust information can prevent a complete conclusion. Inspect the separate checks before relying on a document.

<GuideScreenshot src="/img/guide/android-tablet/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Certificate details to inspect the signer, issuer, serial number, public key, and fingerprint. Scroll within the screen if needed.", "x": 47.3, "y": 71.1}, {"text": "Expand Technical details for the checks behind the verdict; collapse it when finished.", "x": 46.8, "y": 88.5}]} />

## Supply the original for detached XML

Detached XML contains a reference to the signed document. Its original bytes are needed to check the document digest.

<GuideScreenshot src="/img/guide/android-tablet/en/original.png" alt="Supply the original for detached XML" steps={[{"text": "Tap Choose the signed document and select the exact original named in the message.", "x": 33.2, "y": 55.8}, {"text": "Wait for the refreshed result. A modified or different original will not match the signature. Share the XML together with the matching original."}]} />
