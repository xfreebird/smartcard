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

<GuideScreenshot src="/img/guide/macos/en/browser.png" alt="Use a service and manage bookmarks" steps={[{"x": 51, "y": 57, "text": "Enter a memorable bookmark title."}, {"x": 48, "y": 60, "text": "Check the complete website address and choose an icon below it."}, {"x": 65, "y": 75, "text": "Choose Save once title and URL are valid; Done closes the manager."}]} />

## Check every website signing request

Navigate to the service’s electronic-ID login/signing action. Read the requesting origin and whole document list in eSemnBun. Do not approve an unexpected request. Temporary site trust is optional and limited; it does not authorize an unknown future document list. After approval, complete the PIN step and return to the service for its outcome.

<GuideScreenshot src="/img/guide/macos/en/consent.png" alt="Check every website signing request" steps={[{"x": 51, "y": 16, "text": "Confirm the exact requesting site."}, {"x": 49, "y": 44, "text": "Scroll through all documents and confirm the selected card and format."}, {"x": 81, "y": 92, "text": "Choose Sign only for the expected request, or Refuse to cancel it."}]} />

## Browser settings and cleanup

1. Open **Settings → Browser connection** and enable responses when you need the local browser connection. Both the Mac App Store and standalone editions support the built-in Browser and compatible external browsers.
2. To use an external browser, keep eSemnBun running on the same Mac, connect the USB reader, insert your card and wait for its identity to appear. Visit a supported site and grant the browser’s requested local-network permission for that intended workflow. Review the site and selected identity in eSemnBun before approving a request.
3. If MoldSign occupies the ports, finish its operation and quit it. The standalone edition can offer a quit/reconnect action; in the Mac App Store edition, quit the conflicting app yourself, then retry the connection. For an unknown port owner, resolve the conflict before retrying. Never bypass a browser certificate warning.
4. In **Browser → bookmarks menu → Clear browsing data**, select cache, cookies and/or history, then confirm. Removing cookies can sign you out. It does not remove saved documents or saved PINs.

Optional browser PDF stamps have their own Browser connection preference. The standalone edition additionally offers legacy desktop-client access; enable it only for the desktop software you intend to use. The Mac App Store edition does not accept browser requests containing arbitrary local file paths. See the [browser guide](/docs/browser) for service requirements.
