---
title: "Sign on websites — Windows"
sidebar_label: "Sign on websites"
description: "Connect a service, review requests and manage website sessions."
pagination_prev: "platforms/windows/preferences"
pagination_next: "platforms/windows/approval"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign on websites — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Connect a service, review requests and manage website sessions.

Illustrations use fictional data. Follow the instructions in your installed app.

## Use the browser bridge

Enable **Browser connection** in Settings. Open a supported service in a browser on the same Windows computer. When a request arrives, check its site, files, and selected card before authorization.

If another MoldSign server owns the ports, finish active vendor operations and use the offered conflict-resolution action where available. Only one bridge can use ports 18480/18443 at a time. If the browser asks for local-network access, grant it for the intended service so it can contact the local bridge. See [browser services](/docs/browser).


<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Browser connection" steps={[{"x": 25.5, "y": 23.7, "text": "Enable Browser connection only while using a supported website."}, {"x": 25.5, "y": 36, "text": "Optionally enable browser stamps to review their placement before signing."}]} />
