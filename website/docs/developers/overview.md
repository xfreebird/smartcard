---
title: Developer documentation
description: Understand eSemnBun from native screens to smart-card bytes, then build, test and deliver it.
---

eSemnBun lets a person sign documents with a Moldovan electronic identity card. The app prepares the document, asks for permission, sends a small cryptographic request to the card, and saves the result. **The signing private key stays on the card.** The reader is the cable between software and that key; it does not receive the whole PDF.

This handbook explains the implementation for contributors and curious readers. Start with the architecture if you are new to smart cards. Command examples assume an authorized checkout and run from the repository root unless shown otherwise. The developer handbook is maintained in **English**; the product guides also have Romanian and Russian translations.

## Choose a path

| I want to… | Read |
| --- | --- |
| Understand the components and data flow | [Layered architecture](architecture.md) |
| Follow a signature from a click to card commands | [Card protocol and signing sequence](card-protocol.md) |
| Understand the USB reader and individual bits | [Reader protocol: CCID and T=1](reader-protocol.md) |
| Understand PDF/XML signatures and the browser connection | [Formats, trust services and integrations](formats-and-bridge.md) |
| Change a native screen consistently | [Design system across platforms](design-system.md) |
| Compile and launch an app | [Build and run](build-and-run.md) |
| Run unit, integration or native automation tests | [Testing and automation](testing.md) |
| Package and distribute a version | [Release and store delivery](releasing.md) |
| Edit, preview and publish this website | [Website development and publishing](website.md) |
| Work with a coding agent | [Agent reference](agents.md) |
| Look up an unfamiliar abbreviation | [Glossary](glossary.md) |

## One signature, in everyday language

1. You choose a document and the identity card to use.
2. The app reads the card's public certificate. A certificate ties a public key to an identity; reading it does not require the signing PIN.
3. The app prepares the exact bytes to sign. For a PDF, these include cryptographic attributes describing the PDF's digest.
4. You approve. The app checks that the inserted card still matches the chosen certificate before sending a PIN.
5. The app and card communicate through an encrypted session. The card checks the PIN and uses its private key to produce an RSA signature.
6. The app obtains a timestamp when the selected format requires one, assembles the signed document, and saves it.

Verification follows a different path: it reads a signed file and checks its cryptographic evidence. It normally needs neither the card nor a PIN. A visible signature stamp is artwork; the cryptographic signature is what detects changes.

## How to read the source

The public product is **eSemnBun**; `MoldSign` remains the internal codename in modules, namespaces and some storage identifiers. The vendor's MoldSign software is a separate product. eSemnBun is independent software.

The executable source, manifests and workflow inputs decide current behavior. `spec/` contains cross-platform contracts and test vectors. Internal `docs/` and `PLAN.md` explain decisions and history, but older entries can describe superseded designs. Paths in this handbook are relative to the repository; source access may require permission. You do not need source access to read the explanations here.

The protocol examples show command structure and synthetic framing, not a captured person's transaction. Vendor authentication material, private keys, real PINs, personal certificates and raw captures are deliberately excluded. This is a description of the implemented card profile, not a promise that every national eID or USB reader implements it.
