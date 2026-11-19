---
title: "Understand verification results — Android phone"
sidebar_label: "Understand verification results"
description: "Distinguish invalid signatures, unconfirmed trust and unsigned files."
pagination_prev: "platforms/android/verification"
pagination_next: "platforms/android/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Understand verification results — Android phone

[Platform overview](../android.md) · [Get started](./setup.md)

Distinguish invalid signatures, unconfirmed trust and unsigned files.

## Understand an invalid signature

Invalid means that document integrity or the cryptographic signature check failed. It can indicate changed bytes or a damaged/incorrect signature. A valid-looking stamp, familiar filename, or recognized author does not override this result.

<GuideScreenshot src="/img/guide/android-phone/en/verify-invalid.png" alt="Understand an invalid signature" steps={[{"text": "Read Invalid signature and the failed check. Do not treat this copy as verified.", "x": 40.2, "y": 21.2}, {"text": "Expand Technical details, compare with the sender’s original signed output, and request a fresh intact copy if needed. Check every listed signature when the document contains more than one.", "x": 50.0, "y": 59.7}]} />

## Understand an unconfirmed trust chain

Cannot be confirmed is distinct from Invalid signature. In this example the signature and document integrity pass, but the certificate is outside the recognized MDQSign chain. Missing original documents can also produce an unconfirmed result, with a different explanation.

<GuideScreenshot src="/img/guide/android-phone/en/verify-unconfirmed.png" alt="Understand an unconfirmed trust chain" steps={[{"text": "Read the reason below Cannot be confirmed and inspect the separate Integrity, Signature, and Trust chain checks.", "x": 45.3, "y": 21.2}, {"text": "Inspect certificate details to identify the signer and issuer. Establish the required trust with the sender or receiving service before relying on the document. Offline integrity checks do not establish current revocation status or guarantee legal acceptance.", "x": 50.0, "y": 52.6}]} />

## Recognize an unsigned or unsupported file

No signature means the app found no signature it can read in the selected file. You may have selected the unsigned input, or the file may use an unsupported signature format. A picture of a signature is not an electronic signature.

<GuideScreenshot src="/img/guide/android-phone/en/verify-none.png" alt="Recognize an unsigned or unsupported file" steps={[{"text": "Read No signature, then check that you selected the completed signed PDF or the XML signature rather than its unsigned original.", "x": 35.6, "y": 21.2}, {"text": "Choose the correct signed output and verify again. Ask the sender for a supported PDF/XML signature if the result remains unchanged.", "x": 50.0, "y": 84.2}]} />
