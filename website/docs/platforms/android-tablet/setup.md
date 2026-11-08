---
title: "Get started — Android tablet"
sidebar_label: "Get started"
description: "Install, connect a reader and choose your card."
pagination_prev: "platforms/android-tablet"
pagination_next: "platforms/android-tablet/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — Android tablet

[Platform overview](../android-tablet.md)

Install, connect a reader and choose your card.

Illustrations use fictional data. Follow the instructions in your installed app.

## Connect the reader and card

Connect the reader with the appropriate adapter. Permission is needed for the USB device, not broad access to every file. Reading the signing certificate does not require a PIN.

<GuideScreenshot src="/img/guide/android-tablet/en/connect.png" alt="Connect the reader and card" steps={[{"text": "Tap Allow and accept Android’s USB-access prompt for this reader.", "x": 13.5, "y": 32.9}, {"text": "Insert the card, wait for Card ready, and check the holder and expiry before signing."}]} />

## Inspect or refresh the card

The displayed card uses certificate information and a neutral avatar, not a photograph read from your ID. The signing key stays on the physical card.

<GuideScreenshot src="/img/guide/android-tablet/en/card.png" alt="Inspect or refresh the card" steps={[{"text": "Open Card, select the intended identity, and inspect holder, issuer, validity, serial number, and fingerprint.", "x": 42.3, "y": 18.0}, {"text": "Use Re-read the card after reconnecting it; scroll down for the same action and certificate fields.", "x": 33.9, "y": 88.3}, {"text": "Delete stored PIN removes any previously saved app entry; it does not change the physical card PIN. Current Android approval does not offer saving a new PIN."}]} />
