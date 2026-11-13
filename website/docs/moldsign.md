---
title: MoldSign alternative for Moldova’s electronic ID
description: Use eSemnBun to sign PDFs with a Moldovan electronic identity card. Compare the MoldSign workflow, connect a USB reader, and sign on desktop or mobile.
sidebar_label: MoldSign alternative
sidebar_position: 2
---

# A MoldSign alternative for your electronic identity card

**eSemnBun** is a free, open-source app for signing documents with a supported Moldovan electronic identity card. It offers a native desktop workflow and a way to use the same card from a phone with a compatible USB reader.

In Romanian, this workflow is called **semnătură electronică cu cartea de identitate**. You authorize a signing operation with the card PIN; the private signing key stays on the card.

The signature binds the document to the signing certificate and lets a verifier detect changes to the signed content. A picture of a handwritten signature or a visible PDF stamp alone does not provide that cryptographic check. See [signing and verification](./signing.md) for how to inspect the result.

## Choose your MoldSign alternative

- [MoldSign alternative for Windows](./platforms/windows.md): desktop installation, USB reader setup and browser integration.
- [MoldSign alternative for Mac](./platforms/macos.md): DMG and Mac App Store workflows, with separate CLI tools.
- [MoldSign alternative for Linux](./platforms/linux.md): native GNOME packages, PC/SC setup and command-line tools.
- [MoldSign MCP for AI agents](./mcp-moldsign.md): local verification and explicitly configured PDF signing on Windows, Mac and Linux.

Get the appropriate edition from [Downloads](/downloads/). The platform guide lists its requirements and available features.

## MoldSign, MSign, and eSemnBun

These names describe different things:

| Name | Role |
| --- | --- |
| MoldSign | The vendor signing suite, including its desktop app and local server |
| MSign | The signing service at [msign.gov.md](https://msign.gov.md/#/) |
| eSemnBun | An independent app that signs documents and handles compatible local signing requests |

eSemnBun is developed by Nicolae Ghimbovschi and is not affiliated with STISC. It does not issue certificates, activate identity cards, or replace the identity-card provider. Website acceptance depends on the service and its requirements.

## What you need

- A supported electronic identity card with an active signing certificate.
- The correct signing PIN for that card.
- A compatible USB reader, such as the bit4id miniLector POCKET EVO.
- The appropriate adapter for your computer, iPhone, iPad, or Android device.
- Internet access for timestamped signing and online trust services.

A contactless/NFC reader is not the supported workflow. The app uses a wired USB card reader. An identity card without an active signing certificate cannot become a signing card just by installing the app.

## How to sign a PDF with your identity card

1. Install eSemnBun for your device and open it.
2. Connect the reader, insert the card, and wait for the certificate to load.
3. Check the holder, expiry, and selected card.
4. Add your PDF and choose **PAdES-T** to embed the signature in the output PDF.
5. Review the request and authorize using the card PIN.
6. Save or share the signed output, then use **Verify** to inspect its signature.

You can approve several listed documents as a batch. For detached XAdES, keep the original document with the XML signature. Read the [signing and verification guide](./signing.md) for format choices and failed-document recovery.

## Sign from a computer or a phone

The macOS GitHub edition is signed and notarized and installs through a DMG. The Mac App Store edition uses a sandboxed workflow. Windows has an MSI installer and Linux has native desktop packages and a CLI.

The iPhone, iPad, and Android apps let you sign using a compatible USB reader and adapter. Their in-app browsers help with services whose identity-card login is hidden in the mobile layout. This is signing with your identity card on a mobile device, not a mobile operator's SIM-signature service.

Choose your [platform guide](./platforms.md) for installation, USB permissions, file sharing, and browser setup.

## Use MSign and other supported services

For a desktop browser workflow, enable the local connection and keep the app running on the same computer as the browser. On mobile or in the sandboxed Mac edition, use the offered in-app browser workflow. Check the requesting site and operation before authorizing.

Only one local signing server can occupy the expected ports. If MoldSign Server is already running, resolve that conflict before enabling the eSemnBun bridge. See [government services](./browser.md).

## Questions before you start

### Can I use any identity card?

No. You need a supported electronic card with an active signing certificate, a compatible reader, and the correct PIN. eSemnBun does not enroll or activate cards.

### Can I sign without a reader?

No. This workflow requires the physical card and a wired compatible USB reader; NFC is not supported.

### Is a timestamp or a valid certificate enough to verify a file?

No. Verification also checks the signed content and signature. Review each result and the recipient's requirements. The app's offline checks do not establish current revocation status by themselves.

### What if the PIN is wrong?

Stop and confirm the selected card and PIN before trying again. Repeated wrong attempts can block the card. See [troubleshooting](./troubleshooting.md).
