---
title: "Change settings — Windows"
sidebar_label: "Change settings"
description: "Manage language, appearance, saved PINs, startup and updates."
pagination_prev: "platforms/windows/documents"
pagination_next: "platforms/windows/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Change settings — Windows

[Platform overview](../windows.md) · [Installation and reader setup](./setup.md)

Manage language, appearance, saved PINs, startup and updates.

Open Settings. Demo mode is at the top. Choose the category for cards, saved PINs, language or appearance.

## Settings, PINs, and tray controls

Settings contains language (Romanian, English, Russian), appearance, saved-PIN management, startup and reader-opening preferences, browser connection, demo mode, and About. Some controls depend on the installed distribution.

A saved PIN uses Windows security/authentication facilities. Deleting it removes the app's saved entry and does not change the physical card PIN. Check which card an entry belongs to before removing it.

The tray icon gives access to the app and its actions. Closing the main window can leave eSemnBun running; use **Quit** when you intend to stop it. In Settings, configure whether to open at sign-in or when a reader/card is inserted. Enable the relevant option first, then reconnect the reader to check the behavior.

Demo mode requires acceptance, shows fictional cards and sample documents, and remains labelled during normal use. Turn it off to return to your reader. About shows the icon, author, version, and website.

### Adjust language and appearance

<GuideScreenshot src="/img/guide/windows/en/settings-current.png" alt="Open Settings. Demo mode is at the top. Choose the category for cards, saved PINs, language or appearance." steps={[{"text": "Open Settings. Demo mode is at the top. Choose the category for cards, saved PINs, language or appearance."}]} />

### Browser connection and local requests

<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Browser connection and local requests" steps={[{"x": 24.631, "y": 24.13, "text": "Enable Browser connection for the intended website on this computer."}, {"x": 24.631, "y": 36.251, "text": "Optionally enable visible PDF stamps for website requests; choose placement once per batch."}]} />

### Find your installed version

<GuideScreenshot src="/img/guide/windows/en/about.png" alt="Find your installed version" steps={[{"x": 61.162, "y": 35.241, "text": "Open About in Settings and note the installed app version when reporting a problem."}]} />
