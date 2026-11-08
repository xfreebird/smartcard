---
title: "Get started — Linux"
sidebar_label: "Get started"
description: "Install, connect a reader and choose your card."
pagination_prev: "platforms/linux"
pagination_next: "platforms/linux/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — Linux

[Platform overview](../linux.md)

Install, connect a reader and choose your card.

Illustrations use fictional data. Follow the instructions in your installed app.

## Connect a reader

Connect the reader directly or through the appropriate USB adapter. No signing PIN is needed to discover the reader or read a certificate. A PC/SC service failure is different from an unplugged reader.

<GuideScreenshot src="/img/guide/linux/en/connect.png" alt="Connect a reader" steps={[{"text": "Open Sign.", "x": 32, "y": 3}, {"text": "Attach a compatible USB reader; read the connection prompt.", "x": 50, "y": 28}]} />

## Insert the card

Insert your electronic ID and wait for the certificate read. Check the holder and expiry before adding a signing request. Do not keep reconnecting while an operation is already running.

<GuideScreenshot src="/img/guide/linux/en/empty.png" alt="Insert the card" steps={[{"text": "Insert the card and wait for its holder and expiry.", "x": 50, "y": 28}]} />

## Choose the intended identity

With several cards, select the intended identity in the carousel. The card artwork uses certificate information and a neutral avatar, not a photograph read from your ID. Re-read the card with the refresh control if needed.

<GuideScreenshot src="/img/guide/linux/en/cards.png" alt="Choose the intended identity" steps={[{"text": "Open Card.", "x": 68, "y": 3}, {"text": "Choose the dot for the intended card, or scroll the carousel.", "x": 50, "y": 37}, {"text": "Inspect the public certificate and reader details below.", "x": 57, "y": 65}]} />
