---
title: Android phone and tablet
sidebar_position: 4
---

import PlatformScreenshots from '@site/src/components/PlatformScreenshots';

# Android phone and tablet

Current documentation version: **0.2.0**.

Install eSemnBun from Google Play when it is available, or use the release APK from [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest). The Android app supports ARM and x64 devices. Use an appropriate USB OTG adapter for the reader.

<PlatformScreenshots platform="android" alt="eSemnBun for Android" />

## Phone and tablet layouts

The phone layout keeps signing controls reachable above the system PIN keyboard. On tablets, eSemnBun uses the desktop-style arrangement with room for the selected card, document list, and file-browser actions.

Swipe the full-width card carousel to select a card. The chosen card remains selected through a signing operation. Open **Card** for its certificate information and **Verify** for a drop zone and validation results.

## Browser and sharing

The in-app browser supports service shortcuts, custom bookmarks, desktop-site presentation when an identity login is hidden on mobile, and clearing cache, cookies, or history. You can also import documents with Android sharing and send signed results onward with the normal system share sheet.

Settings includes language, appearance, saved PIN management, and demo mode. Demo mode must be explicitly accepted and remains visibly labelled during normal use.
