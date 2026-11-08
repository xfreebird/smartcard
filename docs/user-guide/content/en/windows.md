---
title: Windows — desktop app
sidebar_position: 6
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Windows desktop app

Applies to **eSemnBun 0.2.6**, Windows 10 **1809 or later**, and Windows 11. See the [Windows CLI guide](/docs/platforms/windows-cli/) for PowerShell and automation workflows.

## Install the appropriate edition

Use the **MSI** from [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) for standalone installation, or install [eSemnBun from Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Choose the architecture listed for your machine in the release assets. An unsigned development MSIX can require a signing certificate and is not a substitute for the public MSI.

1. Run the MSI and complete the installation, or install from the store.
2. Open **eSemnBun** from Start. The main window appears on the first launch.
3. Connect the reader. The miniLector uses the Windows CCID driver and Smart Card service.
4. Insert the card and wait for its certificate. Check the holder and expiry before signing.



Multiple cards appear in the horizontal carousel. Select the centred card you intend to sign with. The artwork uses certificate information and a neutral avatar, rather than your ID photograph.

### Choose and inspect your card

<GuideScreenshot src="/img/guide/windows/en/card.png" alt="Choose and inspect your card" steps={[{"x": 6, "y": 26, "text": "Open Card after connecting the reader and inserting the card."}, {"x": 60, "y": 31, "text": "Check the holder and expiry; select the intended card in the carousel."}, {"x": 51, "y": 58, "text": "Inspect the certificate and reader before signing."}]} />

## Sign documents from the app or Explorer

In **Sign**, drag documents to the dashed drop zone or choose **Choose files…**. Where the installed edition provides an Explorer context-menu integration, you can send selected files into eSemnBun from Explorer as well.

1. Add the files and check the format beside each one.
2. For PDFs, use **PAdES-T** to embed the signature in the PDF. XAdES produces XML; detached XML must be kept with the original document.
3. Confirm the selected identity, choose **Sign**, and review the authorization request before entering the card PIN or authenticating a saved entry.
4. Keep the reader connected until completion. Use the result actions to open or locate output files.

Batch authorization applies to the approved document list and selected card. If an item fails, inspect its error before retrying. Completed outputs should not be confused with unsigned inputs. See [signing formats and errors](/docs/signing).

### Prepare the signing batch

<GuideScreenshot src="/img/guide/windows/en/queue.png" alt="Prepare the signing batch" steps={[{"x": 90, "y": 68, "text": "Choose files or drop them into the dashed area."}, {"x": 34, "y": 50, "text": "Check the file format; use Stamp off to add an optional PDF stamp."}, {"x": 88, "y": 95, "text": "Check the selected card and choose Sign for the listed batch."}]} />

### Position a visible PDF stamp

<GuideScreenshot src="/img/guide/windows/en/stamp.png" alt="Position a visible PDF stamp" steps={[{"x": 19, "y": 85, "text": "Move and resize the stamp in the PDF preview."}, {"x": 93, "y": 95, "text": "Check the page options and apply the stamp before signing."}]} />

### Review signing authorization

<GuideScreenshot src="/img/guide/windows/en/pin.png" alt="Review signing authorization" steps={[{"x": 50, "y": 42, "text": "Check the selected identity and the complete document list."}, {"x": 50, "y": 63, "text": "Enter the physical card’s signing PIN only after checking the request. Never guess or retry automatically."}]} />

### Locate completed outputs

<GuideScreenshot src="/img/guide/windows/en/success.png" alt="Locate completed outputs" steps={[{"x": 90, "y": 23, "text": "Inspect each completed row and use its open or reveal action."}, {"x": 44, "y": 23, "text": "Keep detached XML together with its unchanged original. The shown outputs are fictional fixtures."}]} />

## Verify and inspect activity

Open **Verify** and choose or drop in a signed PDF/XML file. A detached XML signature also needs the original document. Inspect the signer, integrity, certificate chain, and available timestamp checks. A valid filename or green card status does not establish that a document signature is valid.

**Documents → History** records recent operations and provides actions for available files. Clearing history does not remove the signed documents themselves.

### Choose a document to verify

<GuideScreenshot src="/img/guide/windows/en/verify.png" alt="Choose a document to verify" steps={[{"x": 6, "y": 17, "text": "Open Verify. Verification needs no card or PIN."}, {"x": 60, "y": 28, "text": "Choose or drop the signed PDF or XML. Supply unchanged originals for detached XML when requested."}]} />

### Read the verification outcome

<GuideScreenshot src="/img/guide/windows/en/summary.png" alt="Read the verification outcome" steps={[{"x": 37, "y": 40, "text": "Check the overall outcome, then inspect each signature’s author and signing time."}, {"x": 43, "y": 85, "text": "Read the integrity, signature and trust checks individually. Scroll down for offline limits and certificate details."}]} />

### Inspect verification details

<GuideScreenshot src="/img/guide/windows/en/results.png" alt="Inspect verification details" steps={[{"x": 60, "y": 14, "text": "Read the offline verification limits: timestamp trust and current revocation may remain unchecked."}, {"x": 60, "y": 23, "text": "Expand certificate and technical details to inspect the signer, validity dates and timestamp fields."}]} />

## Settings, PINs, and tray controls

Settings contains language (Romanian, English, Russian), appearance, saved-PIN management, startup and reader-opening preferences, browser connection, demo mode, and About. Some controls depend on the installed distribution.

A saved PIN uses Windows security/authentication facilities. Deleting it removes the app's saved entry and does not change the physical card PIN. Check which card an entry belongs to before removing it.

The tray icon gives access to the app and its actions. Closing the main window can leave eSemnBun running; use **Quit** when you intend to stop it. In Settings, configure whether to open at sign-in or when a reader/card is inserted. Enable the relevant option first, then reconnect the reader to check the behavior.

Demo mode requires acceptance, shows fictional cards and sample documents, and remains labelled during normal use. Turn it off to return to your reader. About shows the icon, author, version, and website.

### Adjust language and appearance

<GuideScreenshot src="/img/guide/windows/en/settings.png" alt="Adjust language and appearance" steps={[{"x": 7, "y": 96, "text": "Open Settings."}, {"x": 28, "y": 88, "text": "Choose the application language and appearance."}]} />

### Manage saved PINs and browser connection

<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Manage saved PINs and browser connection" steps={[{"x": 27, "y": 21, "text": "Check saved-PIN preferences. Removing an app entry does not change the card PIN."}, {"x": 27, "y": 44, "text": "Enable Browser connection, then open the intended service in the browser on this computer. Review every signing request."}]} />

### Find your installed version

<GuideScreenshot src="/img/guide/windows/en/about.png" alt="Find your installed version" steps={[{"x": 61, "y": 35, "text": "Open About in Settings and note the installed app version when reporting a problem."}]} />

## Use the browser bridge

Enable **Browser connection** in Settings. Open a supported service in a browser on the same Windows computer. When a request arrives, check its site, files, and selected card before authorization.

If another MoldSign server owns the ports, finish active vendor operations and use the offered conflict-resolution action where available. Only one bridge can use ports 18480/18443 at a time. If the browser asks for local-network access, grant it for the intended service so it can contact the local bridge. See [browser services](/docs/browser).

### Manage saved PINs and browser connection

<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Manage saved PINs and browser connection" steps={[{"x": 27, "y": 21, "text": "Check saved-PIN preferences. Removing an app entry does not change the card PIN."}, {"x": 27, "y": 44, "text": "Enable Browser connection, then open the intended service in the browser on this computer. Review every signing request."}]} />

## Update or resolve a problem

Microsoft Store installations update through the store. Standalone builds offer update checks that lead to the download page; install the replacement MSI from the release.

| Symptom | Next step |
| --- | --- |
| Reader missing | Check Device Manager for the smart-card reader; reconnect it and verify the Smart Card service. |
| Certificate does not load | Reinsert the card and allow the read to finish. |
| Wrong identity | Select the intended card before entering its PIN. |
| Browser port occupied | Stop the competing recognized server, then reconnect. |
| Saved PIN unavailable | Use manual PIN entry and review Windows authentication/settings. |
| Document fails | Inspect its error, preserve the source, and correct the cause before retrying. |

Stop after an incorrect-PIN result and verify the PIN rather than guessing. Report app/Windows versions, MSI or Store edition, architecture, reader model, and reproduction steps. See [troubleshooting](/docs/troubleshooting).

### Recover when no reader is detected

<GuideScreenshot src="/img/guide/windows/en/none.png" alt="Recover when no reader is detected" steps={[{"x": 60, "y": 34, "text": "Read the connection guidance, reconnect the USB reader and insert the card."}, {"x": 88, "y": 13, "text": "Read the card again after correcting the connection. A PIN error requires a deliberate stop, not another guess."}]} />

## Find and open saved documents
Open Documents and select the signed-document list. Choose an entry to open its signing details, then use the available open/reveal actions. Switch to history to review recent operations. Clearing recent history keeps the independent signed-document library; it does not delete signed files.

### Find signed documents

<GuideScreenshot src="/img/guide/windows/en/documents.png" alt="Find signed documents" steps={[{"x": 51, "y": 18, "text": "Open Documents, then select the signed-document list."}, {"x": 33, "y": 31, "text": "Choose a saved document to open its signing details."}]} />

### Inspect a saved document

<GuideScreenshot src="/img/guide/windows/en/details.png" alt="Inspect a saved document" steps={[{"x": 51, "y": 45, "text": "Review this document’s signing information before opening or sharing its file."}]} />
