---
title: "Use Shortcuts and automation — Mac"
sidebar_label: "Use Shortcuts and automation"
description: "Set up Siri, Spotlight, Handoff and the supported approval workflow."
pagination_prev: "platforms/macos/preferences"
pagination_next: "platforms/macos/help"
---



# Use Shortcuts and automation — Mac

[Platform overview](../macos.md) · [Installation and reader setup](./setup.md)

Set up Siri, Spotlight, Handoff and the supported approval workflow.

## Use Shortcuts and Siri

1. Open Apple **Shortcuts** and create a shortcut. In the action search, choose **eSemnBun**.
2. Add **Open Documents** to open the collection, **Prepare PDF for Signing** to stage a PDF, or **Verify PDF** to inspect PDF signatures offline. Supply a PDF to the file actions; the limit is 32 MiB.
3. Run the shortcut and review the foreground eSemnBun screen. Preparing a PDF does not sign it: connect the intended card and complete the normal Sign/PIN approval yourself.
4. Give the shortcut a memorable name and invoke it through Siri if Siri supports your system language and configuration. Inspect the full verification result in the app, including trust limitations.

The system’s suggested actions, newer Siri search/open presentation and language availability depend on your macOS/SDK version and Siri configuration. Live Siri invocation is not illustrated or claimed as validated here. No shortcut silently signs, changes a PIN or approves a website request.

## Find documents with Spotlight and resume with Handoff

1. Enable discovery in General as illustrated above. Sign an eligible app-owned PDF/XML and keep its file readable.
2. Open Spotlight with **⌘Space**, search its filename and select the eSemnBun result. The app opens the corresponding saved-document details when the entry is still eligible.
3. To resume on another Apple device, keep both devices signed into the same Apple Account with Bluetooth, Wi-Fi and Handoff enabled. Open Documents in eSemnBun, then use the system’s Handoff entry on the other device.
4. Handoff resumes **Documents navigation only**. It does not copy the file, transfer a PIN or continue a pending signature. Independently move the file through your chosen file-sharing method if needed.

Spotlight indexing is opt-in and limited; a file written beside its source by the standalone app is not automatically eligible.

## Approve a local automation request

The standalone macOS edition offers a foreground signing approval broker. The App Store edition does not include this broker.

1. In **Settings → General → Local automation**, enable **Allow signing requests from local clients** only for a client you intend to use.
2. Install/configure the [macOS CLI/MCP tools](../macos-cli.md), choose explicit trusted input roots and configure the private approval directory described there.
3. Ask the client to prepare a PDF. Read the native PDF preview, filename/hash and selected card in eSemnBun. Approve only the intended document, or cancel.
4. Complete the normal protected PIN step. The client polls the job and retrieves the completed result. A pending/unknown outcome is not permission to sign again.
5. Turn Local automation off to reject pending requests when finished.

The setup toggle is visible in the General screenshot above. A physical-card broker signature and unattended credential retrieval are not illustrated by these captures. Unattended MCP is a separate explicit CLI policy, not a way to bypass this approval window.
