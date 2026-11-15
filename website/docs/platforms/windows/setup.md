---
title: "Get started — Windows"
sidebar_label: "Get started"
description: "Install, connect a reader and choose your card."
pagination_prev: "platforms/windows"
pagination_next: "platforms/windows/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Get started — Windows

[Platform overview](../windows.md)

Install, connect a reader and choose your card.

## Install the appropriate edition

Use the **MSI** from [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) for standalone installation, or install [eSemnBun from Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Choose the architecture listed for your machine in the release assets. An unsigned development MSIX can require a signing certificate and is not a substitute for the public MSI.

1. Run the MSI and complete the installation, or install from the store.
2. Open **eSemnBun** from Start. The main window appears on the first launch.
3. Connect the reader. The miniLector uses the Windows CCID driver and Smart Card service.
4. Insert the card and wait for its certificate. Check the holder and expiry before signing.



Multiple cards appear in the horizontal carousel. Select the centred card you intend to sign with. The artwork uses certificate information and a neutral avatar, rather than your ID photograph.

### Choose and inspect your card

<GuideScreenshot src="/img/guide/windows/en/card.png" alt="Choose and inspect your card" steps={[{"x": 5.351, "y": 26.15, "text": "Open Card after connecting the reader and inserting the card."}, {"x": 60.148, "y": 31.201, "text": "Check the holder and expiry; select the intended card in the carousel."}, {"x": 51.015, "y": 58.474, "text": "Inspect the certificate and reader before signing."}]} />
