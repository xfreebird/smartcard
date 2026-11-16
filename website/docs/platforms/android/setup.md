---
title: "Get started — Android phone"
sidebar_label: "Get started"
description: "Install the app and set up NFC or a USB card reader."
pagination_prev: "platforms/android"
pagination_next: "platforms/android/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — Android phone

[Platform overview](../android.md)

Install the app and set up NFC or a USB card reader.

## Connect the reader and card

Use an active Moldovan electronic identity card with a valid signing certificate and its signing PIN.

### Sign over NFC

Starting with eSemnBun 0.2.12, compatible iPhones and Android devices can sign with a compatible contactless card over NFC. A compatible USB reader remains available. Choose **With your phone · NFC** in **Sign** and add your document. Tap **Continue**, review the request and confirm your signing PIN. Hold the card near the device’s NFC antenna until the app reports completion. Android devices need NFC enabled.

<GuideScreenshot src="/img/guide/android-phone/en/nfc-sign.png" alt="The Sign screen with NFC selected" steps={[{"text": "The Sign screen with NFC selected", "x": 29, "y": 53}]} />

### Sign with a USB card reader

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing.

<GuideScreenshot src="/img/guide/android-phone/en/reader-sign.png" alt="The Sign screen with a USB card reader selected" steps={[{"text": "The Sign screen with a USB card reader selected", "x": 29, "y": 53}]} />

## Inspect or refresh the card

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.
