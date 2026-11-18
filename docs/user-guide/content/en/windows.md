---
title: Windows — desktop app
sidebar_position: 6
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Windows desktop app

Applies to **eSemnBun 0.2.13**, Windows 10 **1809 or later**, and Windows 11. See the [Windows CLI guide](/docs/platforms/windows-cli/) for PowerShell and automation workflows.

## Install the appropriate edition

Use the **MSI** from [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) for standalone installation, or install [eSemnBun from Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Choose the architecture listed for your machine in the release assets. An unsigned development MSIX can require a signing certificate and is not a substitute for the public MSI.

1. Run the MSI and complete the installation, or install from the store.
2. Open **eSemnBun** from Start. The main window appears on the first launch.
3. Connect the reader. The miniLector uses the Windows CCID driver and Smart Card service.
4. Insert the card and wait for its certificate. Check the holder and expiry before signing.



Multiple cards appear in the horizontal carousel. Select the centred card you intend to sign with. The artwork uses certificate information and a neutral avatar, rather than your ID photograph.

### Choose and inspect your card

<GuideScreenshot src="/img/guide/windows/en/cards-current.png" alt="Open Settings and choose Cards and readers to inspect the selected holder, certificate and connected reader." steps={[{"text": "Open Settings and choose Cards and readers to inspect the selected holder, certificate and connected reader.", "x": 49, "y": 42}, {"text": "Use the card carousel to choose the intended holder before signing."}]} />

## Sign documents from the app or Explorer

In **Sign**, drag documents to the dashed drop zone or choose **Choose files…**. Where the installed edition provides an Explorer context-menu integration, you can send selected files into eSemnBun from Explorer as well.

1. Add the files and check the format beside each one.
2. For PDFs, use **PAdES-T** to embed the signature in the PDF. XAdES produces XML; detached XML must be kept with the original document.
3. Confirm the selected identity, choose **Sign**, and review the authorization request before entering the card PIN or authenticating a saved entry.
4. Keep the reader connected until completion. Use the result actions to open or locate output files.

Batch authorization applies to the approved document list and selected card. If an item fails, inspect its error before retrying. Completed outputs should not be confused with unsigned inputs. See [signing formats and errors](/docs/signing).

### Prepare the signing batch

<GuideScreenshot src="/img/guide/windows/en/queue.png" alt="Prepare the signing batch" steps={[{"x": 90.59, "y": 68.575, "text": "Choose files or drop them into the dashed area."}, {"x": 33.764, "y": 50.393, "text": "Check the file format; use Stamp off to add an optional PDF stamp."}, {"x": 88.561, "y": 95.847, "text": "Check the selected card and choose Sign for the listed batch."}]} />

### Position a visible PDF stamp

<GuideScreenshot src="/img/guide/windows/en/stamp.png" alt="Position a visible PDF stamp" steps={[{"x": 18.542, "y": 85.746, "text": "Drag the stamp to move it and a corner to resize it. Its text follows the application language."}, {"x": 69.28, "y": 34.231, "text": "Choose the selected page or all pages; optionally reuse the placement for all queued PDFs."}, {"x": 93.635, "y": 95.847, "text": "Choose Apply to save the placement before signing."}]} />

### Review signing authorization

<GuideScreenshot src="/img/guide/windows/en/pin.png" alt="Review signing authorization" steps={[{"x": 50, "y": 42.693, "text": "Check the selected identity and the complete document list."}, {"x": 50, "y": 64.165, "text": "Enter the physical card’s signing PIN only after checking the request. Never guess or retry automatically."}]} />

### Locate completed outputs

<GuideScreenshot src="/img/guide/windows/en/success.png" alt="Locate completed outputs" steps={[{"text": "Open the file directly from its row.", "x": 80, "y": 22}, {"text": "Use the folder button to show the saved file in its folder.", "x": 90, "y": 22}]} />

## Verify and inspect activity

Open **Verify** and choose or drop in a signed PDF/XML file. A detached XML signature also needs the original document. Inspect the signer, integrity, certificate chain, and available timestamp checks. A valid filename or green card status does not establish that a document signature is valid.

**Documents → History** records recent operations and provides actions for available files. Clearing history does not remove the signed documents themselves.

### Choose a document to verify

<GuideScreenshot src="/img/guide/windows/en/verify.png" alt="Choose a document to verify" steps={[{"x": 5.351, "y": 17.059, "text": "Open Verify. Verification needs no card or PIN."}, {"x": 60.148, "y": 28.171, "text": "Choose or drop the signed PDF or XML. Supply unchanged originals for detached XML when requested."}]} />

### Read the verification outcome

<GuideScreenshot src="/img/guide/windows/en/summary.png" alt="Read the verification outcome" steps={[{"x": 36.808, "y": 40.292, "text": "Check the overall outcome, then inspect each signature’s author and signing time."}, {"x": 42.897, "y": 85.746, "text": "Read the integrity, signature and trust checks individually. Scroll down for offline limits and certificate details."}]} />

### Inspect verification details

<GuideScreenshot src="/img/guide/windows/en/results.png" alt="Inspect verification details" steps={[{"text": "Expand Technical details to inspect the signature format and identifier.", "x": 44, "y": 48}, {"text": "Read the fields for this signature. Select the heading again to collapse the details.", "x": 49, "y": 66}]} />

## Settings, PINs, and tray controls

Open Settings. Demo mode is at the top. Choose the category for cards, saved PINs, language or appearance.

Settings contains language (Romanian, English, Russian), appearance, saved-PIN management, startup and reader-opening preferences, browser connection, demo mode, and About. Some controls depend on the installed distribution.

A saved PIN uses Windows security/authentication facilities. Deleting it removes the app's saved entry and does not change the physical card PIN. Check which card an entry belongs to before removing it.

The tray icon gives access to the app and its actions. Closing the main window can leave eSemnBun running; use **Quit** when you intend to stop it. In Settings, configure whether to open at sign-in or when a reader/card is inserted. Enable the relevant option first, then reconnect the reader to check the behavior.

Demo mode requires acceptance, shows fictional cards and sample documents, and remains labelled during normal use. Turn it off to return to your reader. About shows the icon, author, version, and website.

### Adjust language and appearance

<GuideScreenshot src="/img/guide/windows/en/settings-current.png" alt="Open Settings. Demo mode is at the top. Choose the category for cards, saved PINs, language or appearance." steps={[{"text": "Open Settings. Demo mode is at the top. Choose the category for cards, saved PINs, language or appearance.", "x": 32, "y": 18}]} />

### Browser connection and local requests

<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Browser connection and local requests" steps={[{"x": 24.631, "y": 24.13, "text": "Enable Browser connection for the intended website on this computer."}, {"x": 24.631, "y": 36.251, "text": "Optionally enable visible PDF stamps for website requests; choose placement once per batch."}]} />

### Find your installed version

<GuideScreenshot src="/img/guide/windows/en/about.png" alt="Find your installed version" steps={[{"x": 61.162, "y": 35.241, "text": "Open About in Settings and note the installed app version when reporting a problem."}]} />

## Use the browser bridge

Enable **Browser connection** in Settings. Open a supported service in a browser on the same Windows computer. When a request arrives, check its site, files, and selected card before authorization.

If another MoldSign server owns the ports, finish active vendor operations and use the offered conflict-resolution action where available. Only one bridge can use ports 18480/18443 at a time. If the browser asks for local-network access, grant it for the intended service so it can contact the local bridge. See [browser services](/docs/browser).


<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Browser connection" steps={[{"x": 25.138, "y": 23.827, "text": "Enable Browser connection only while using a supported website."}, {"x": 25.138, "y": 36.251, "text": "Optionally enable browser stamps to review their placement before signing."}]} />

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

<GuideScreenshot src="/img/guide/windows/en/none.png" alt="Recover when no reader is detected" steps={[{"x": 60.148, "y": 34.231, "text": "Read the connection guidance, reconnect the USB reader and insert the card."}, {"x": 88.561, "y": 13.019, "text": "Read the card again after correcting the connection. A PIN error requires a deliberate stop, not another guess."}]} />

## Find and open saved documents

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Choose a filename to inspect its signing details. The buttons beside it open the file and show its folder. The row menu offers verification and file protection. History lists recent operations. Clearing history keeps the saved files.

### Find signed documents

<GuideScreenshot src="/img/guide/windows/en/documents.png" alt="Find signed documents" steps={[{"text": "Select the filename to inspect its signing details.", "x": 38, "y": 24}, {"text": "Open the file directly from its row.", "x": 85, "y": 25}, {"text": "Use the folder button to show the saved file in its folder.", "x": 91, "y": 25}]} />

### Inspect a saved document

<GuideScreenshot src="/img/guide/windows/en/details.png" alt="Inspect a saved document" steps={[{"text": "Read the verification outcome and check the signer.", "x": 42, "y": 28}, {"text": "Open the document or show it in its folder.", "x": 47, "y": 22}]} />

## Approve local signing requests (MCP)

In **Settings → General**, scroll to **Advanced** and enable **Allow local signing requests (MCP)**. Copy the private directory shown below the switch into your MCP client configuration. Keep eSemnBun running and select the intended card. This option is unavailable while demo mode is on.

```powershell
& "C:\Program Files\eSemnBun\bin\esemnbun.exe" mcp `
  --root "documents=C:\Users\me\Documents\Signing" `
  --broker-directory "C:\Users\me\AppData\Local\MoldSign\MCP"
```

Use the actual directory displayed by your installation instead of the example below. A client can stage a PDF with `prepare_signing`, inspect its status with `get_job`, or cancel it with `cancel_job`. Review the PDF in the native preview and choose Sign only when you approve the request; card authorization follows. A saved PIN does not skip this approval. Cancelling or timing out is not proof that a signature was never made.

The screenshot uses an isolated demonstration profile: its directory is an example and its MCP switch is disabled. No MCP signing request was executed for this capture.


<GuideScreenshot src="/img/guide/windows/en/lower.png" alt="Browser connection and local requests" steps={[{"x": 24.631, "y": 82.716, "text": "Find the MCP switch under Advanced. Outside demo mode, enable it and copy the private directory into your client configuration."}, {"x": 47.97, "y": 92.817, "text": "Use the directory shown by your installation, not the demonstration path."}]} />

<!-- file-protection-guides -->


## Encrypt a file with a password

Open **Protect files** at the bottom of the navigation bar and choose **Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

Choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). The Moldovan ID signing certificate cannot decrypt these files.

<GuideScreenshot src="/img/guide/windows/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"text": "Choose the file to encrypt.", "x": 36, "y": 29}, {"text": "Select AES-128, AES-192 or AES-256. AES-256 is selected by default.", "x": 59, "y": 50}, {"text": "Enter and confirm a new file password.", "x": 41, "y": 62}, {"text": "Choose Encrypt, then save the encrypted copy.", "x": 41, "y": 88}]} />

<GuideScreenshot src="/img/guide/windows/en/protect-certificate-light.png" alt="Encrypt for an RSA recipient" steps={[{"text": "Select RSA certificate.", "x": 48, "y": 45}, {"text": "Choose the recipient’s public encryption certificate.", "x": 40, "y": 55}, {"text": "To encrypt for your own card, connect its reader and read its encryption certificate.", "x": 36, "y": 60}]} />

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Choose **Close** to close the completed operation. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

Open **Protect files** at the bottom of the navigation bar and choose **Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/windows/en/protect-decrypt-light.png" alt="Decrypt a received file" steps={[{"text": "Choose the encrypted file. Its contents determine the decryption method.", "x": 33, "y": 33}, {"text": "For a password-encrypted file, enter the password supplied by the sender.", "x": 40, "y": 60}, {"text": "Choose Decrypt and save the result in a new file.", "x": 39, "y": 84}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Choose **Close** to close the completed operation. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Remove a local file

Open **Protect files** at the bottom of the navigation bar and choose **Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

<GuideScreenshot src="/img/guide/windows/en/protect-remove-light.png" alt="Remove a local file" steps={[{"text": "Choose the file and read its name and the removal warning.", "x": 33, "y": 43}, {"text": "Confirm removal only after checking the selected file.", "x": 38, "y": 61}, {"text": "Choose Remove file to complete the operation.", "x": 39, "y": 74}]} />
