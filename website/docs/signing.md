---
title: Sign and verify
sidebar_position: 2
---
# Sign and verify documents

1. Add documents using the file picker or drop zone.
2. Review the selected identity and the format for each document.
3. Choose **Sign**, review the authorization request, and enter the correct card PIN.
4. Save, export or share the signed result using your platform's controls.

PDFs use PAdES to store the signature inside the PDF. XAdES creates an XML signature; keep the original document alongside a detached signature. Batch signing lets you authorize a list together; session PIN handling is limited to that signing workflow.

The signing key stays on the card. Timestamped signatures and online certificate-status checks contact public trust services, so an internet connection may be required.

## Verify a signature

Open **Verify**, choose a signed PDF or XAdES file, or use the drop zone. Review the validation result before sharing it. A technical validation result does not guarantee acceptance by every recipient or authority.

## Saved PINs

Use the dedicated saved-PIN settings to manage entries. Storage and authentication use platform-specific security facilities. Delete saved entries when you no longer want the app to remember them.
