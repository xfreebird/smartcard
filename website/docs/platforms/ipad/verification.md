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

<GuideScreenshot src="/img/guide/ipad/en/verify-current.png" alt="The Verify screen" steps={[{"text": "The Verify screen", "x": 50, "y": 94}]} />

<GuideScreenshot src="/img/guide/ipad/en/verify.png" alt="Read the document verdict first. Expand each signer to inspect that signature." steps={[{"text": "Read the document verdict first. Expand each signer to inspect that signature.", "x": 19, "y": 38}]} />
<GuideScreenshot src="/img/guide/ipad/en/certificate.png" alt="Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint." steps={[{"text": "Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint.", "x": 21, "y": 53}]} />

<GuideScreenshot src="/img/guide/ipad/en/technical.png" alt="Expand Technical details under a signature to read the verification report. Select the same row again to collapse it." steps={[{"text": "Expand Technical details under a signature to read the verification report. Select the same row again to collapse it.", "x": 20, "y": 58}]} />

## Supply the original for a detached XML signature

A detached XML signature cannot prove the original document’s digest until its unchanged source is available. In the incomplete result, use Choose originals and select the matching original files in the system picker. Wait for the result to update. Selecting another file changes the evidence; a missing original alone does not prove modification.

<GuideScreenshot src="/img/guide/ipad/en/incomplete.png" alt="Read which original is missing." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read which original is missing.", "x": 23, "y": 24}, {"text": "Choose the unchanged original files and wait for the updated check.", "x": 25, "y": 40}]} />
