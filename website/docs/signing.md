---
title: Sign and verify
sidebar_position: 2
---

# Sign and verify documents

This guide applies to **0.2.0**. Follow your [platform guide](./platforms.md) for installation, reader permissions, output locations, and system sharing.

## Prepare the signing workspace

1. Connect the reader and insert the card. Wait for its certificate to load.
2. Check the holder, certificate expiry, and selected card. With multiple cards, select the intended signer before starting.
3. Add documents with the file picker, drop zone, or the platform's share/import integration.
4. Review every filename and its format. Remove files that should not be in the batch.

The card illustration reflects certificate details. It is not a copy of the physical ID or proof that a document has already been signed.

## Choose a signature format

| Format | Result | What the recipient needs |
| --- | --- | --- |
| PAdES-T | Signed PDF with an embedded signature and timestamp | The output PDF |
| XAdES-BES | XML signature without a timestamp | XML plus original for detached signatures |
| XAdES-T | XML signature with a timestamp | XML plus original for detached signatures |
| XAdES-C | XML signature with certificate/revocation references | XML plus original for detached signatures |

PDFs default to PAdES-T. Other documents use XAdES. A PDF can also be signed using XAdES when the recipient requests that format; this creates an XML signature over the PDF bytes rather than embedding a signature in the PDF.

A **detached** XML signature references a separate original document. Keep the original bytes unchanged and supply both files to the recipient. An **enveloping** XML signature carries the document content inside the XML where that option is offered. Confirm the recipient's requirements before choosing a format.

## Authorize one document or a batch

Choose **Sign**, review the request, and enter the correct card PIN or authenticate the saved entry offered by your device. The private signing key stays on the card.

Batch approval is scoped to the selected certificate and listed documents. The app can reuse the approved session PIN during that batch. It is not permission for later documents or a new batch. Keep the card and reader connected and avoid switching identities while signing.

Timestamped signatures contact public trust services. XAdES-C also obtains certificate-status references. A valid PIN cannot overcome an unavailable timestamp service or a malformed document.

## Find and share the signed files

Use the completed result's open, reveal, export, or share action. Output names typically include `-semnat`; the original file remains separate. Store and mobile installations may require an explicit export or system share step.

For a PDF signature, send the output PDF. For detached XAdES, send both XML and the unchanged original. Do not send only a screenshot of the completion message: the recipient needs the signed file itself.

## Handle a failed document

A failed item needs its own error inspected. Use its retry action where offered after correcting the cause. Completed outputs and pending/failed inputs are separate states; inspect the batch result before resubmitting files.

| Error | Practical recovery |
| --- | --- |
| Malformed PDF, such as missing Root/trailer | Open the source in a PDF application and export a valid copy, then add that new file. Retrying unchanged bytes does not fix PDF structure. |
| File inaccessible or cloud download incomplete | Download/open it locally and select it again with the system picker. |
| Timestamp/network failure | Check connectivity and service availability, then deliberately retry. |
| Card changed or removed | Reinsert the intended card, verify the holder, and start a new approval. |
| Incorrect PIN | Stop; check the card and PIN before another attempt. |
| PIN blocked | Contact the official card provider; the app cannot unblock it. |

## Understand verification results

Open **Verify** and choose or drop in a signed PDF/XML file. Supply the original document when verifying detached XAdES. A file with no signatures is not a successfully verified signed document.

Review each signature separately:

- **Document integrity:** whether the signed bytes/digests still match. An altered file may fail even if the signer certificate is genuine.
- **Signature:** whether the cryptographic signature can be verified against the signing certificate.
- **Certificate chain:** whether the certificate links to a trust anchor known to the validator. An untrusted chain and modified document are different problems.
- **Signing time and timestamp:** available time information. A self-declared signing time is different from timestamp evidence issued by a timestamp service.

Offline verification does not establish current online revocation status. The presence of an XAdES-C reference does not by itself establish that every later policy check passes. Review the result and the recipient's requirements before relying on it; an app validation result does not guarantee acceptance by every service.

## Saved PINs and demo mode

Saved-PIN management is available in the dedicated settings area. Storage and unlocking use the platform's security facilities. Removing an entry deletes the saved copy, not the PIN on the card; removing browser cookies does not remove saved PINs.

Normal demo mode requires acceptance and remains labelled. It uses fictional identities and sample files; its output is not a real electronic signature. Turn it off before signing with your own card.
