---
title: "Change settings — Linux"
sidebar_label: "Change settings"
description: "Manage language, appearance, saved PINs, startup and updates."
pagination_prev: "platforms/linux/browser"
pagination_next: "platforms/linux/approval"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Change settings — Linux

[Platform overview](../linux.md) · [Installation and reader setup](./setup.md)

Manage language, appearance, saved PINs, startup and updates.

## Choose language and appearance

Open Preferences from the application menu. Demo mode is at the top. Use Cards and readers to inspect cards and Saved PINs to manage the stored copies.

Open the application menu → Preferences. Choose System, Light or Dark appearance and System, Romanian, English or Russian language. Changes apply to the interface. These captures use native translated controls.

<GuideScreenshot src="/img/guide/linux/en/settings-current.png" alt="Open Preferences from the application menu. Demo mode is at the top. Use Cards and readers to inspect cards and Saved PINs to manage the stored copies." steps={[{"text": "Open Preferences from the application menu. Demo mode is at the top. Use Cards and readers to inspect cards and Saved PINs to manage the stored copies.", "x": 68, "y": 17}]} />

## Manage saved PINs and website access

Saved PINs use the desktop Secret Service/system keyring. When normal signing offers Remember PIN, save only intentionally and unlock the keyring if asked. If it is unavailable or locked, enter the PIN for that operation instead. Delete all PINs removes saved copies only; it does not change or unblock the physical card PIN. Enable Browser connection only for a website workflow you intend to use.

<GuideScreenshot src="/img/guide/linux/en/saved-pins.png" alt="Open Saved PINs in Preferences to manage copies stored on this device." steps={[{"text": "Open Saved PINs in Preferences to manage copies stored on this device.", "x": 51, "y": 38}]} />

## Keep the app available in the background

Scroll lower in Preferences for background and startup options. Run in background keeps the browser connection available after closing the window. Start at sign-in launches background detection. Show the app on card insertion works while the app is already running in the background; it is not a separate always-on reader service.

<GuideScreenshot src="/img/guide/linux/en/background.png" alt="Keep the app available in the background" steps={[{"text": "Choose background operation and startup if required.", "x": 68, "y": 75}, {"text": "Choose whether insertion should open the running app.", "x": 68, "y": 89}]} />

## Find the version and update safely

Open the application menu → About eSemnBun to find the installed version and website. Use the application’s Check for updates command when available, or your original package channel. Install a compatible replacement package; the update check does not silently replace your app. Include app/OS versions and the reader model in support requests, never your PIN.

<GuideScreenshot src="/img/guide/linux/en/about.png" alt="Find the version and update safely" steps={[{"text": "Open About eSemnBun.", "x": 58, "y": 7}, {"text": "Read the version and website before requesting support.", "x": 50, "y": 27}]} />

## Open help and application commands

The application menu contains Preferences, About, Check for Updates and Quit. Open [troubleshooting](/docs/troubleshooting) for online help. Closing the window may leave the app running when background mode is enabled; choose Quit to end it. For terminal automation continue with the Linux CLI guide.

<GuideScreenshot src="/img/guide/linux/en/menu.png" alt="Open help and application commands" steps={[{"text": "Open the application menu.", "x": 89, "y": 3}, {"text": "Choose the intended Preferences, Help, update or Quit action.", "x": 89, "y": 14}]} />
