---
title: macOS — desktop app and CLI
sidebar_position: 2
---

import PlatformScreenshots from '@site/src/components/PlatformScreenshots';

# macOS — desktop app and CLI

Current documentation version: **0.2.0**.

## Choose a distribution

| Distribution | Best for | Important limits |
| --- | --- | --- |
| GitHub DMG | Full desktop integration, including the configurable reader/card insertion helper and standalone update checks. | Download from the [GitHub release](https://github.com/xfreebird/smartcard/releases/latest). |
| Mac App Store | Sandboxed macOS installation and store-managed updates. | The insertion helper and standalone update checks are unavailable. Browser integration follows the sandboxed workflow. |
| CLI | Automation and terminal workflows. | It has no graphical settings or browser UI. |

Install the DMG by moving eSemnBun to Applications, then open it once. The app shows its main window on first launch. Connect a supported USB reader and insert the card; the selected card stays selected after a signature.

<PlatformScreenshots platform="macos" alt="eSemnBun for macOS" />

## Desktop app

Use **Sign** to add files and sign one or several documents, **Verify** to inspect a signed PDF or XAdES result, and **Card** to review the currently selected certificate. Settings contains language, theme, saved PINs, demo mode, browser bookmarks, and About.

The menu-bar item brings an existing window to the front. It can also open Settings and About. If another local signing application occupies the browser bridge port, eSemnBun can identify it and offer to close the vendor server before reconnecting.

Use **Check for updates** only in the GitHub desktop build. Store installs use their store's update service.

## Command line

The executable is `esemnbun`. It can list readers, inspect certificates, sign PDFs or XAdES files, validate signatures, and provide the local browser bridge.

```sh
esemnbun readers
esemnbun cert --out leaf.der
esemnbun sign input.pdf output-signed.pdf
esemnbun verify output-signed.pdf
```

Supply a PIN only through standard input, the secure prompt, or the documented environment path. Never put a PIN in a command line, shell history, file, or support request. See the [CLI contract](https://github.com/xfreebird/smartcard/blob/main/spec/cli.md) for all commands and exit codes.
