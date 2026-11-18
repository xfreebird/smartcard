---
title: "Change settings — Mac"
sidebar_label: "Change settings"
description: "Manage language, appearance, saved PINs, startup and updates."
pagination_prev: "platforms/macos/browser"
pagination_next: "platforms/macos/automation"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Change settings — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Manage language, appearance, saved PINs, startup and updates.

## Set language, appearance and system discovery

Open Settings. Demo mode is at the top. Choose the category for cards, saved PINs, language or appearance.

For Spotlight/Siri discovery, enable Find signed documents in Siri and Spotlight. Only readable app-owned signed PDF/XML filenames and dates are exposed. Document bodies, certificate identities and PINs are not indexed. In standalone macOS this excludes arbitrary files beside your originals; only eligible app-owned imports qualify. Disable discovery to remove this index.

<GuideScreenshot src="/img/guide/macos/en/settings.png" alt="Set language, appearance and system discovery" steps={[{"x": 87, "y": 61, "text": "Choose the interface language."}, {"x": 88, "y": 69, "text": "Choose Light, Dark or System."}, {"x": 91, "y": 88, "text": "Opt in to signed-document discovery if you want eligible filenames in Siri/Spotlight."}, {"x": 31, "y": 3, "text": "Open Saved PINs to inspect or delete saved entries without revealing their PIN values."}, {"x": 53, "y": 3, "text": "Enable local signing requests only when connecting an MCP client; every request still needs PDF review and approval."}]} />

## Menu bar, startup, updates and help

1. Click the menu-bar eSemnBun icon to reopen the main window, Settings or About. Closing a window can leave the app running; choose **Quit** to end it.
2. In **Settings → General**, scroll to startup settings. Choose **Start at sign-in** if desired. If macOS asks for approval, use **System Settings → General → Login Items**.
3. The standalone edition has an optional reader/card insertion helper, which can open the app after it quits. Enable it and approve its background item when asked. The Mac App Store edition has no such launcher: **Open window on card insertion** works only while eSemnBun is running in the menu bar. Closing the window can leave it running; **Quit** stops insertion detection. After Quit, reopen it manually. **Start at sign-in** launches it at your next login.
4. In standalone installations, use **Check for updates** and install the newer DMG. App Store copies update through the App Store. Keep the same distribution when updating.
5. Use **About eSemnBun** to find the installed version; use Help or the [support page](/support) with app/macOS version, reader/adapter model and reproduction steps. Never send a PIN.

Normal Demo mode is an intentional Settings option with fictional data and a visible notice; it cannot produce valid electronic signatures.
