---
title: "Understand verification results — Android tablet"
sidebar_label: "Understand verification results"
description: "Distinguish invalid signatures, unconfirmed trust and unsigned files."
pagination_prev: "platforms/android-tablet/verification"
pagination_next: "platforms/android-tablet/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Understand verification results — Android tablet

[Platform overview](../android-tablet.md) · [Installation and reader setup](./setup.md)

Distinguish invalid signatures, unconfirmed trust and unsigned files.

## Understand an invalid signature

Invalid means that document integrity or the cryptographic signature check failed. It can indicate changed bytes or a damaged/incorrect signature. A valid-looking stamp, familiar filename, or recognized author does not override this result.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-invalid.png" alt="Understand an invalid signature" steps={[{"text": "Read Invalid signature and the failed check. Do not treat this copy as verified.", "x": 35.0, "y": 44.0}, {"text": "Expand Technical details, compare with the sender’s original signed output, and request a fresh intact copy if needed. Check every listed signature when the document contains more than one.", "x": 46.8, "y": 76.9}]} />

## Understand an unconfirmed trust chain

Cannot be confirmed is distinct from Invalid signature. In this example the signature and document integrity pass, but the certificate is outside the recognized MDQSign chain. Missing original documents can also produce an unconfirmed result, with a different explanation.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-unconfirmed.png" alt="Understand an unconfirmed trust chain" steps={[{"text": "Read the reason below Cannot be confirmed and inspect the separate Integrity, Signature, and Trust chain checks.", "x": 35.0, "y": 44.0}, {"text": "Inspect certificate details to identify the signer and issuer. Establish the required trust with the sender or receiving service before relying on the document. Offline integrity checks do not establish current revocation status or guarantee legal acceptance.", "x": 47.3, "y": 71.8}]} />

## Recognize an unsigned or unsupported file

No signature means the app found no signature it can read in the selected file. You may have selected the unsigned input, or the file may use an unsupported signature format. A picture of a signature is not an electronic signature.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-none.png" alt="Recognize an unsigned or unsupported file" steps={[{"text": "Read No signature, then check that you selected the completed signed PDF or the XML signature rather than its unsigned original.", "x": 35.0, "y": 44.0}, {"text": "Choose the correct signed output and verify again. Ask the sender for a supported PDF/XML signature if the result remains unchanged.", "x": 47.1, "y": 26.0}]} />
