---
title: "Check a signature — iPhone"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/ios/signing"
pagination_next: "platforms/ios/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — iPhone

[Platform overview](../ios.md) · [Get started](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

## Verify a signed PDF and inspect its certificate

Verification needs a file, not a reader or PIN. In Verify, choose the signed PDF or XML. Expand each signature, then its certificate and technical sections. Check every signature when a file is countersigned. Offline results distinguish document integrity, cryptographic signature, embedded trust and timestamp information; they are not a current revocation check.

<GuideScreenshot src="/img/guide/iphone/en/verify-current.png" alt="The Verify screen" steps={[{"text": "The Verify screen", "x": 50, "y": 87}]} />
<GuideScreenshot src="/img/guide/iphone/en/certificate.png" alt="Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity." steps={[{"text": "Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity.", "x": 9, "y": 87}]} />

## Supply the original for a detached XML signature

A detached XML signature cannot prove the original document’s digest until its unchanged source is available. In the incomplete result, use Choose originals and select the matching original files in the system picker. Wait for the result to update. Selecting another file changes the evidence; a missing original alone does not prove modification.

<GuideScreenshot src="/img/guide/iphone/en/incomplete.png" alt="Read which original is missing." steps={[{"text": "Read which original is missing.", "x": 8, "y": 50}, {"text": "Choose the unchanged original files and wait for the updated check.", "x": 8, "y": 55}]} />
