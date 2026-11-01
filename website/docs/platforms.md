---
title: Platform guides
sidebar_position: 4
---

# Platform guides

These guides document the current **0.2.0** release line. Each platform has its own install path, capabilities, and release channel; use the guide that matches the app or command you installed.

| Platform | Documentation version | Application guide | Command-line guide |
| --- | --- | --- | --- |
| macOS | 0.2.0 | [Mac App Store and GitHub desktop app](./platforms/macos.md) | [macOS CLI](./platforms/macos.md#command-line) |
| iOS and iPadOS | 0.2.0 | [iPhone and iPad](./platforms/ios.md) | — |
| Android | 0.2.0 | [Phone and tablet](./platforms/android.md) | — |
| Linux | 0.2.0 | [GNOME desktop app](./platforms/linux.md) | [Linux CLI](./platforms/linux.md#command-line) |
| Windows | 0.2.0 | [Desktop app](./platforms/windows.md) | [Windows CLI](./platforms/windows.md#command-line) |

Every screenshot in these guides is captured from the native app using isolated mock data. Capture mode prevents reader, card, bridge, PIN, and signing I/O; it is used only to make documentation repeatable and is never enabled for ordinary users.

## A shared signing model

Connect a compatible USB reader, insert the electronic ID card, choose the right card when more than one is available, add documents, and confirm the request with the card PIN. The key stays on the card. NFC is not supported.

The desktop and mobile apps share signing, verification, saved-PIN management, language, theme, and demo controls where those capabilities make sense for the operating system. Browser integration and hardware access follow the limits of the installed platform and distribution channel.
