---
title: "Linux guides"
sidebar_label: "Linux"
hide_table_of_contents: true
pagination_prev: null
pagination_next: "platforms/linux/setup"
---

import GuideDirectory from '@site/src/components/GuideDirectory';
import GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';

# Linux guides

Choose what you want to do. Each task has its own short illustrated guide.

<GuideDirectory platform="linux" />
<GuideAnchorRedirect platform="linux" />

## Before you begin

Follow the numbered screenshots for eSemnBun 0.2.6 on Linux. Tap an image to enlarge it, then choose Actual size to inspect small controls.

Install the desktop package for your distribution and architecture from [Downloads](/downloads/), then open eSemnBun from your application launcher. DEB/RPM/Flatpak desktop downloads open a graphical app; the package-manager CLI feeds and terminal archives install command-line tools. See the [Linux CLI guide](./linux-cli.md) for terminal and MCP setup. Ubuntu 24.04/Fedora are supported desktop targets; check the chosen package’s requirements. You need an active supported electronic ID, its correct signing PIN, a compatible USB reader and an adapter if needed. NFC signing is unavailable. The private signing key remains on the card.

The host needs a running PC/SC service and CCID driver. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Enable socket activation with `sudo systemctl enable --now pcscd.socket`. Run the desktop app in your graphical session; SSH reader-access policy can differ.
