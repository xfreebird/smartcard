---
title: "Sign on websites — Mac"
sidebar_label: "Sign on websites"
description: "Connect a service, review requests and manage website sessions."
pagination_prev: "platforms/macos/documents"
pagination_next: "platforms/macos/preferences"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Sign on websites — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Connect a service, review requests and manage website sessions.

## Use a service and manage bookmarks

Open Browser from the sidebar. Enter a trusted service’s HTTPS address and use the arrow to open it; back, forward and reload remain in the toolbar. Choose the bookmark menu for saved services, Add bookmark, Manage bookmarks and browser-data cleanup. In the bookmark dialog shown below, enter a title, URL and icon, then Save. Close with Done and select the saved service from the bookmark menu.

<GuideScreenshot src="/img/guide/macos/en/browser.png" alt="Use a service and manage bookmarks" steps={[{"x": 45, "y": 58, "text": "Enter a memorable bookmark title."}, {"x": 47, "y": 63, "text": "Check the complete website address and choose an icon below it."}, {"x": 68, "y": 82, "text": "Choose Save once title and URL are valid; Done closes the manager."}]} />

## Check every website signing request

Navigate to the service’s electronic-ID login/signing action. Read the requesting origin and whole document list in eSemnBun. Do not approve an unexpected request. Temporary site trust is optional and limited; it does not authorize an unknown future document list. After approval, complete the PIN step and return to the service for its outcome.

<GuideScreenshot src="/img/guide/macos/en/consent.png" alt="Check every website signing request" steps={[{"x": 51, "y": 16, "text": "Confirm the exact requesting site."}, {"x": 49, "y": 44, "text": "Scroll through all documents and confirm the selected card and format."}, {"x": 81, "y": 92, "text": "Choose Sign only for the expected request, or Refuse to cancel it."}]} />

## Browser settings and cleanup

1. Open **Settings → Browser connection**. Enable responses only when you need the local browser connection; the in-app Browser is the main workflow for the Store edition.
2. For external-browser use in the standalone edition, visit a supported site on the same Mac while eSemnBun is running. Grant the browser’s requested local-network permission for that intended workflow.
3. If recognized MoldSign software occupies the ports, finish its operation, then use the offered quit/reconnect action. For an unknown port owner, resolve the conflict before retrying. Never bypass a browser certificate warning.
4. In **Browser → bookmarks menu → Clear browsing data**, select cache, cookies and/or history, then confirm. Removing cookies can sign you out. It does not remove saved documents or saved PINs.

Optional browser PDF stamps and legacy desktop-client access have their own Browser connection preferences. Enable legacy access only for the desktop software you intend to use. See the [browser guide](/docs/browser) for service requirements.
