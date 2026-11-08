---
title: "Check a signature — Android phone"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/android/signing"
pagination_next: "platforms/android/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — Android phone

[Platform overview](../android.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

Illustrations use fictional data. Follow the instructions in your installed app.

## Check a signed document

Verification does not require the card or PIN. A green result refers to the checks shown, not to the filename or the presence of a visible stamp.

<GuideScreenshot src="/img/guide/android-phone/en/verify.png" alt="Check a signed document" steps={[{"text": "Open Verify, choose a signed PDF or XML, and wait for results. Use the system picker to select files from other apps or providers.", "x": 32.8, "y": 29.3}, {"text": "Read the verdict and each signature’s author, signing time, timestamp, integrity, signature, and trust-chain checks.", "x": 18.5, "y": 51.0}, {"text": "Remove an input with × to clear its result, or clear all results before a new check.", "x": 80.5, "y": 41.6}]} />

## Inspect certificate and technical details

An invalid signature differs from an unconfirmed trust chain. Missing originals or unavailable trust information can prevent a complete conclusion. Inspect the separate checks before relying on a document.

<GuideScreenshot src="/img/guide/android-phone/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Certificate details to inspect the signer, issuer, serial number, public key, and fingerprint. Scroll within the screen if needed.", "x": 34.6, "y": 61.9}, {"text": "Expand Technical details for the checks behind the verdict; collapse it when finished.", "x": 32.4, "y": 82.9}]} />

## Supply the original for detached XML

Detached XML contains a reference to the signed document. Its original bytes are needed to check the document digest.

<GuideScreenshot src="/img/guide/android-phone/en/original.png" alt="Supply the original for detached XML" steps={[{"text": "Tap Choose the signed document and select the exact original named in the message.", "x": 11.6, "y": 68.4}, {"text": "Wait for the refreshed result. A modified or different original will not match the signature. Share the XML together with the matching original."}]} />
