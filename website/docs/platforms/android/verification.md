---
title: "Check a signature — Android phone"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/android/signing"
pagination_next: "platforms/android/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — Android phone

[Platform overview](../android.md) · [Get started](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

## Check a signed document

Verification does not require the card or PIN. A green result refers to the checks shown, not to the filename or the presence of a visible stamp.

<GuideScreenshot src="/img/guide/android-phone/en/verify-current.png" alt="The Verify screen" steps={[{"text": "Choose a signed PDF or XML. Read its verdict, signer and checks.", "x": 38.3, "y": 21.2}, {"text": "Expand Technical details to see the report, then tap again to collapse it.", "x": 50.0, "y": 59.7}, {"text": "Use the bottom button to choose another signed document.", "x": 50.0, "y": 84.2}, {"text": "Use Clear results in the navigation bar to clear this verification session.", "x": 90.3, "y": 6.2}]} />

## Inspect certificate and technical details

An invalid signature differs from an unconfirmed trust chain. Missing originals or unavailable trust information can prevent a complete conclusion. Inspect the separate checks before relying on a document.

<GuideScreenshot src="/img/guide/android-phone/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Certificate details to inspect the signer, issuer, serial number, public key, and fingerprint. Scroll within the screen if needed.", "x": 50.0, "y": 52.6}, {"text": "Expand Technical details for the checks behind the verdict; collapse it when finished.", "x": 50.0, "y": 71.1}]} />

<GuideScreenshot src="/img/guide/android-phone/en/verify-technical.png" alt="Expanded technical details" steps={[{"text": "Read the diagnostics for this signature. Tap Technical details again to collapse the report.", "x": 25.3, "y": 65.8}]} />

## Supply the original for detached XML

Detached XML contains a reference to the signed document. Its original bytes are needed to check the document digest.

<GuideScreenshot src="/img/guide/android-phone/en/original.png" alt="Supply the original for detached XML" steps={[{"text": "Tap Choose the signed document and select the exact original named in the message.", "x": 35.6, "y": 38.6}, {"text": "Wait for the refreshed result. A modified or different original will not match the signature. Share the XML together with the matching original."}]} />
