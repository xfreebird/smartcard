---
title: Linux — GNOME desktop app and CLI
sidebar_position: 5
---

import PlatformScreenshots from '@site/src/components/PlatformScreenshots';

# Linux — GNOME desktop app and CLI

Current documentation version: **0.2.0**. Ubuntu and Fedora are supported desktop targets.

## Desktop app

Install the package that matches your distribution: Flatpak, DEB, or RPM. The native GNOME app uses the same signing and verification flow as the other desktop versions, including theme, language, saved PINs, demo mode, a card carousel, a document drop zone, and browser-bridge configuration.

<PlatformScreenshots platform="linux" alt="eSemnBun for Linux" />

The desktop installation bundles the localhost certificate required by the compatible browser bridge. If a different signing server owns the local port, close it before enabling the eSemnBun bridge.

## Command line

The `esemnbun` command is installed beside the desktop app and supports reader discovery, certificate export, PAdES and XAdES signing, verification, and the local bridge.

```sh
esemnbun readers
esemnbun sign input.pdf output-signed.pdf
esemnbun verify output-signed.pdf
```

PIN input is deliberately kept out of command-line arguments. Use the secure prompt or the documented standard-input option. Review the [CLI contract](https://github.com/xfreebird/smartcard/blob/main/spec/cli.md) before automating a signing flow.
