---
title: "Use Shortcuts and automation — iPhone"
sidebar_label: "Use Shortcuts and automation"
description: "Set up Siri, Spotlight, Handoff and the supported approval workflow."
pagination_prev: "platforms/ios/preferences"
pagination_next: "platforms/ios/help"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Use Shortcuts and automation — iPhone

[Platform overview](../ios.md) · [Get started](./setup.md)

Set up Siri, Spotlight, Handoff and the supported approval workflow.

## Use Shortcuts, Siri, Spotlight and Handoff

In Apple Shortcuts, create a shortcut, add an action, search eSemnBun and choose Open Documents, Prepare PDF for Signing or Verify PDF. Supply a PDF to the prepare/verify actions. Prepare opens eSemnBun with the PDF queued; you still review and approve signing in the foreground. Verify returns an offline result and opens the details. PDF input is limited to 32 MiB. Run a configured shortcut from Shortcuts or an available Siri phrase; Siri never receives your card PIN.


1. Open Shortcuts, add an action and search for eSemnBun.
2. Choose Open Documents, Prepare PDF for Signing or Verify PDF; provide a PDF when required.
3. Run the shortcut. Review the prepared queue or offline result in eSemnBun; signing still needs your approval.

For document search, enable Find signed documents in Siri and Spotlight in Settings, complete a signed app-owned PDF/XML, then search its filename in Spotlight. The opt-in index exposes filenames and dates, not document bodies, PINs or certificate identity. Current system Open/Search schemas require supported OS/SDK features; suggestions depend on your device, language and system settings. With Handoff enabled on compatible Apple devices, open Documents on one device and use its continuation affordance on the other. Handoff resumes Documents navigation; it does not transfer a PDF, PIN or card session. Siri, Spotlight and Handoff availability should be checked on your installed build; these documentation captures demonstrate app controls rather than a live cross-device result.
<GuideScreenshot src="/img/guide/iphone/en/settings.png" alt="Enable document discovery only if you want signed filenames and dates available to Siri and Spotlight." steps={[{"text": "Enable document discovery only if you want signed filenames and dates available to Siri and Spotlight.", "x": 86, "y": 65}, {"text": "After creating a signed app-owned document, search its filename in Spotlight and open the result."}, {"text": "For Handoff, open Documents on one compatible device and choose its continuation affordance on the other."}]} />
