---
title: Windows — desktop app and CLI
sidebar_position: 6
---

import PlatformScreenshots from '@site/src/components/PlatformScreenshots';

# Windows — desktop app and CLI

Current documentation version: **0.2.0**.

## Desktop app

Use the signed MSI from [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) for the standalone desktop build, or install through Microsoft Store when it is available. The standalone MSI can include desktop integration such as opening the app for a reader/card insertion; store distribution follows the store sandbox and update model.

<PlatformScreenshots platform="windows" alt="eSemnBun for Windows" />

The desktop app provides Sign, Verify, Activity, Card, and Settings. It keeps selected cards centred in the carousel, handles failed documents in place with a retry action, and maintains the user’s selected card after signing. Settings holds language, appearance, saved PINs, demo mode, and About.

## Command line

The MSI installs `esemnbun.exe` under its `bin` folder and adds it to the system PATH. It can list readers, inspect a certificate, sign, verify, and host the compatible local browser bridge.

```powershell
esemnbun readers
esemnbun sign .\input.pdf .\input-signed.pdf
esemnbun verify .\input-signed.pdf
```

Use secure input or standard input for a PIN. Never add a PIN to a PowerShell command, profile, script, or log.
