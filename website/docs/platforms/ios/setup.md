---
title: "Get started — iPhone"
sidebar_label: "Get started"
description: "Install, connect a reader and choose your card."
pagination_prev: "platforms/ios"
pagination_next: "platforms/ios/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — iPhone

[Platform overview](../ios.md)

Install, connect a reader and choose your card.



## Connect the reader and insert your card

Use an active Moldovan electronic identity card with a valid signing certificate and its signing PIN.

### Sign over NFC

Starting with eSemnBun 0.2.12, compatible iPhones and Android devices can sign with a compatible contactless card over NFC. A compatible USB reader remains available. Choose **With your phone · NFC** in **Sign** and add your document. Tap **Continue**, review the request and confirm your signing PIN. Hold the card near the phone’s NFC antenna until the app reports completion. Android devices need NFC enabled.

<GuideScreenshot src="/img/guide/iphone/en/nfc-sign.png" alt="The Sign screen with NFC selected" steps={[{"text": "The Sign screen with NFC selected"}]} />

### Sign with a USB card reader

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing.

<GuideScreenshot src="/img/guide/iphone/en/reader-sign.png" alt="The Sign screen with a USB card reader selected" steps={[{"text": "The Sign screen with a USB card reader selected"}]} />

## Choose the identity that will sign

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.

<GuideScreenshot src="/img/guide/iphone/en/cards-current.png" alt="Inspect the selected identity before signing." steps={[{"text": "Inspect the selected identity before signing."}]} />

<GuideScreenshot src="/img/guide/iphone/en/batch-current.png" alt="Review the selected document before tapping Continue." steps={[{"text": "Review the selected document before tapping Continue."}]} />

## Use a smaller or wider iPhone window

Portrait uses compact tabs. Rotate the phone or expand a supported device/window when you need more space for the card and files. Scroll to reach document options and the PIN review when the keyboard reduces available space. Device posture and rotation support follow iOS; do not assume a foldable posture is identical to a standard landscape phone.
