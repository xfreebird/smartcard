---
title: "Get started — Mac"
sidebar_label: "Get started"
description: "Install, connect a reader and choose your card."
pagination_prev: "platforms/macos"
pagination_next: "platforms/macos/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — Mac

[Platform overview](../macos.md)

Install, connect a reader and choose your card.

## Install and connect your reader

Open [Downloads](/downloads/). Install the Mac App Store edition, or open the desktop DMG and drag eSemnBun to Applications. Eject the DMG and launch the installed copy. The TAR.GZ and Homebrew downloads are CLI/MCP tools; see the [terminal guide](../macos-cli.md).

You need macOS 15 or later, a compatible USB reader, an active supported electronic ID and its signing PIN. Use a suitable USB-C adapter if needed. NFC signing is unavailable.

<GuideScreenshot src="/img/guide/macos/en/connect.png" alt="Install and connect your reader" steps={[{"x": 8, "y": 11, "text": "Open Sign in the sidebar."}, {"x": 60, "y": 26, "text": "Connect the USB reader. This empty state changes when the reader is detected."}]} />

## Insert the card

The certificate is read without a PIN. Wait for the holder and expiry before starting a signature. The private signing key stays on the card.

<GuideScreenshot src="/img/guide/macos/en/empty-reader.png" alt="Insert the card" steps={[{"x": 60, "y": 25, "text": "Insert the card into the detected reader and leave it connected."}]} />

## Choose the identity and inspect its certificate

The card artwork uses certificate data and a neutral avatar, not a photograph read from your identity card. If the reader must be refreshed, use the top-right re-read control or the card context menu. Do not start another operation while one is in progress.

<GuideScreenshot src="/img/guide/macos/en/cards.png" alt="Choose the identity and inspect its certificate" steps={[{"x": 7, "y": 31, "text": "Open Card."}, {"x": 60, "y": 42, "text": "With several cards, swipe horizontally or use the carousel arrows to centre the intended identity."}, {"x": 82, "y": 57, "text": "Check holder, issuer, expiry and reader in Signing certificate."}]} />
