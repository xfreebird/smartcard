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

Open Settings. Demo mode is at the top. Choose the category for cards, saved cards and PINs, language or appearance.

For Spotlight/Siri discovery, enable Find signed documents in Siri and Spotlight. Only readable app-owned signed PDF/XML filenames and dates are exposed. Document bodies, certificate identities and PINs are not indexed. In standalone macOS this excludes arbitrary files beside your originals; only eligible app-owned imports qualify. Disable discovery to remove this index.

<GuideScreenshot src="/img/guide/macos/en/settings.png" alt="Choose the interface language." steps={[{"text": "Choose the interface language.", "x": 87, "y": 61}, {"text": "Choose an appearance.", "x": 88, "y": 69}, {"text": "Enable signed-document discovery for Siri and Spotlight if desired.", "x": 86, "y": 85}]} />

<GuideScreenshot src="/img/guide/macos/en/saved-cards.png" alt="Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device." steps={[{"text": "Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device.", "x": 86, "y": 28}]} />

## Menu bar, startup, updates and help

1. Click the menu-bar eSemnBun icon to reopen the main window, Settings or About. Closing a window can leave the app running; choose **Quit** to end it.
2. In **Settings → General**, scroll to startup settings. Choose **Start at sign-in** if desired. If macOS asks for approval, use **System Settings → General → Login Items**.
3. In the standalone edition, enable **Open the app when a reader or card is inserted** at first launch or in **Settings → General**, and approve the background item in System Settings if macOS asks. A separate helper then opens eSemnBun on insertion, even after Quit. The Mac App Store edition cannot do this: insertion opens its window only while eSemnBun is running in the menu bar. After Quit, reopen it manually, or choose **Start at sign-in** so that it runs after you sign in.
4. In standalone installations, use **Check for updates** and install the newer DMG. App Store copies update through the App Store. Keep the same distribution when updating.
5. Use **About eSemnBun** to find the installed version; use Help or the [support page](/support) with app/macOS version, reader/adapter model and reproduction steps. Never send a PIN.

<GuideScreenshot src="/img/guide/macos/en/onboarding.png" alt="Choose whether to start at sign-in or open eSemnBun when a reader or card is inserted. You can change either setting later." steps={[{"text": "Choose whether to start at sign-in or open eSemnBun when a reader or card is inserted. You can change either setting later.", "x": 37, "y": 55}]} />

<GuideScreenshot src="/img/guide/macos/en/menu-bar.png" alt="Open eSemnBun from the menu bar to check the current card and access recent documents." steps={[{"text": "Open eSemnBun from the menu bar to check the current card and access recent documents.", "x": 23, "y": 54}]} />

Normal Demo mode is an intentional Settings option with fictional data and a visible notice; it cannot produce valid electronic signatures.
