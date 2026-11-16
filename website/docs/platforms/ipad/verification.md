---
title: "Check a signature — iPad"
sidebar_label: "Check a signature"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/ipad/signing"
pagination_next: "platforms/ipad/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Check a signature — iPad

[Platform overview](../ipad.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

## Verify a signed PDF and inspect its certificate

Verification needs a file, not a reader or PIN. In Verify, choose the signed PDF or XML. Expand each signature, then its certificate and technical sections. Check every signature when a file is countersigned. Offline results distinguish document integrity, cryptographic signature, embedded trust and timestamp information; they are not a current revocation check.

<GuideScreenshot src="/img/guide/ipad/en/verify-current.png" alt="The Verify screen" steps={[{"text": "The Verify screen"}]} />
<GuideScreenshot src="/img/guide/ipad/en/certificate.png" alt="Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity." steps={[{"text": "Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity.", "x": 13, "y": 59}]} />

## Supply the original for a detached XML signature

A detached XML signature cannot prove the original document’s digest until its unchanged source is available. In the incomplete result, use Choose originals and select the matching original files in the system picker. Wait for the result to update. Selecting another file changes the evidence; a missing original alone does not prove modification.

<GuideScreenshot src="/img/guide/ipad/en/incomplete.png" alt="Read which original is missing." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read which original is missing.", "x": 20.0, "y": 66.0}, {"text": "Choose the unchanged original files and wait for the updated check.", "x": 10.0, "y": 70.0}]} />
