---
title: "macOS — illustrated desktop guide"
sidebar_position: 2
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# macOS — illustrated desktop guide

For eSemnBun 0.2.6 on macOS 15 or later. Follow one goal at a time; numbered markers correspond to the instructions below each image. Click an image to open its full-size capture.

## Install and connect your reader

Open [Downloads](/downloads/). Install the Mac App Store edition, or open the desktop DMG and drag eSemnBun to Applications. Eject the DMG and launch the installed copy. The TAR.GZ and Homebrew downloads are CLI/MCP tools; see the [terminal guide](./macos-cli.md).

You need macOS 15 or later, a compatible USB reader, an active supported electronic ID and its signing PIN. Use a suitable USB-C adapter if needed. NFC signing is unavailable.

<GuideScreenshot src="/img/guide/macos/en/connect.png" alt="Install and connect your reader" steps={[{"x": 8, "y": 11, "text": "Open Sign in the sidebar."}, {"x": 60, "y": 26, "text": "Connect the USB reader. This empty state changes when the reader is detected."}]} />

## Insert the card

The certificate is read without a PIN. Wait for the holder and expiry before starting a signature. The private signing key stays on the card.

<GuideScreenshot src="/img/guide/macos/en/empty-reader.png" alt="Insert the card" steps={[{"x": 60, "y": 25, "text": "Insert the card into the detected reader and leave it connected."}]} />

## Choose the identity and inspect its certificate

The card artwork uses certificate data and a neutral avatar, not a photograph read from your identity card. If the reader must be refreshed, use the top-right re-read control or the card context menu. Do not start another operation while one is in progress.

<GuideScreenshot src="/img/guide/macos/en/cards.png" alt="Choose the identity and inspect its certificate" steps={[{"x": 7, "y": 31, "text": "Open Card."}, {"x": 60, "y": 42, "text": "With several cards, swipe horizontally or use the carousel arrows to centre the intended identity."}, {"x": 82, "y": 57, "text": "Check holder, issuer, expiry and reader in Signing certificate."}]} />

## Add documents and choose their format

A PDF normally uses PAdES-T: the signature stays inside the PDF. Other files normally use detached XAdES-T: the XML and unchanged original belong together. Use the format control on a queued file when a recipient requires a different supported format. The row menu removes an unintended file.

<GuideScreenshot src="/img/guide/macos/en/sign.png" alt="Add documents and choose their format" steps={[{"x": 7, "y": 11, "text": "Open Sign."}, {"x": 69, "y": 71, "text": "Choose files, or drop files into the dashed area. Add the whole batch before signing."}, {"x": 36, "y": 53, "text": "Check each filename and its format. The PDF stamp control sits beside its format."}, {"x": 92, "y": 3, "text": "Check the selected card, then choose Sign. The button shows the batch size."}]} />

## Place a visible stamp on a PDF

Open Stamp off/Edit stamp on a queued PDF. A visible stamp is optional and does not replace the cryptographic signature. On a multipage PDF choose the page in the preview before applying.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/macos/en/stamp.png" alt="Place a visible stamp on a PDF" steps={[{"x": 83, "y": 17, "text": "Enable Visible stamp."}, {"x": 21, "y": 49, "text": "Drag the stamp to position it; drag a corner to resize it."}, {"x": 83, "y": 34, "text": "Choose the selected page or all pages; optionally apply the setting to all queued PDFs."}, {"x": 81, "y": 84, "text": "Choose Apply to return to the signing queue."}]} />

## Authorize the displayed batch

Use the signing PIN of the selected physical card, not your Mac login password. Stop after an incorrect-PIN result and verify the identity/PIN before another deliberate attempt. The remaining-attempt counter is a card safety limit. A new batch asks again.

<GuideScreenshot src="/img/guide/macos/en/pin.png" alt="Authorize the displayed batch" steps={[{"x": 49, "y": 28, "text": "Check the holder and every listed document. Cancel if anything is unexpected."}, {"x": 49, "y": 51, "text": "Enter the card PIN in the protected boxes."}, {"x": 49, "y": 62, "text": "Choose Remember PIN only if you want this card’s PIN stored in Keychain and unlocked by device authentication."}, {"x": 85, "y": 76, "text": "Choose Sign after the PIN is complete; keep the reader connected until completion."}]} />

## Wait for signing and the timestamp

Leave the reader connected while the app signs and obtains a timestamp. Timestamp/network failures and malformed input are different from an incorrect PIN. Read the actual error before deciding what to do next.

<GuideScreenshot src="/img/guide/macos/en/progress.png" alt="Wait for signing and the timestamp" steps={[{"x": 60, "y": 42, "text": "Wait for the current signing step to finish."}]} />

## Find, preview and share the completed output

Standalone macOS normally writes a new file beside the source, with a signed suffix, without overwriting the original. The App Store edition uses its permitted storage and explicit export/share actions. Keep a detached XML together with its original.

<GuideScreenshot src="/img/guide/macos/en/success.png" alt="Find, preview and share the completed output" steps={[{"x": 80, "y": 53, "text": "Click the completed row or Show in Finder to locate the output."}, {"x": 90, "y": 53, "text": "Use Preview to inspect the output. Use Share for the signed PDF, then choose its destination."}]} />

## Recover from a failed document

A batch can contain successful and failed items. Keep completed outputs. Correct the failed input or connection before starting another deliberate operation; there is no automatic PIN retry. An unchanged malformed PDF will fail again.

<GuideScreenshot src="/img/guide/macos/en/file-error.png" alt="Recover from a failed document" steps={[{"x": 57, "y": 54, "text": "Read the error on the affected file; use its row menu to remove it if necessary."}]} />

## Verify a PDF and every signature

Verification does not require a reader or PIN. It checks the file you selected, not a visual stamp or a filename. Offline checks do not establish current certificate revocation status.

<GuideScreenshot src="/img/guide/macos/en/verify.png" alt="Verify a PDF and every signature" steps={[{"x": 7, "y": 15, "text": "Open Verify."}, {"x": 58, "y": 10, "text": "Choose signed files or drop them into the dashed area."}, {"x": 32, "y": 35, "text": "Expand each Author row, including additional signatures on the same document."}, {"x": 35, "y": 17, "text": "Use Clear results before starting a separate inspection."}]} />

## Read integrity, trust and certificate details

A valid cryptographic signature, intact document, trusted chain and timestamp are separate checks. Scroll for all certificate and technical fields. Do not interpret an issuer’s registration number as the signer’s personal identifier.

<GuideScreenshot src="/img/guide/macos/en/certificate.png" alt="Read integrity, trust and certificate details" steps={[{"x": 32, "y": 35, "text": "Expand the signature to read signer, signing time and timestamp."}, {"x": 34, "y": 57, "text": "Read each integrity, signature and trust-chain check."}, {"x": 34, "y": 68, "text": "Expand Certificate details and inspect subject, issuer and key information."}]} />

## Verify detached XML with its original

Add the XML in Verify. When the document digest cannot be checked, choose the original file(s) using the result’s Choose originals action. Supply the exact unchanged original, not the signed XML itself. Re-read the updated integrity result. An XML alone may be insufficient for a recipient.

<GuideScreenshot src="/img/guide/macos/en/verify-original.png" alt="Verify detached XML with its original" steps={[{"x": 58, "y": 10, "text": "Add the detached XML signature."}, {"x": 42, "y": 39, "text": "Read the missing-original/incomplete result and provide the original requested by the result."}]} />

## Recognize a modified or invalid signature

An invalid result is not repaired by renaming the file or adding a stamp. Request an intact signed copy from its sender and verify that copy.

<GuideScreenshot src="/img/guide/macos/en/verify-invalid.png" alt="Recognize a modified or invalid signature" steps={[{"x": 43, "y": 27, "text": "Read the document’s invalid status, then expand the author to identify the failed check."}]} />

## Distinguish unconfirmed trust

Unconfirmed trust is different from proven document modification. Read the signature and trust-chain details, and follow your recipient’s certificate policy before relying on the document.

<GuideScreenshot src="/img/guide/macos/en/verify-untrusted.png" alt="Distinguish unconfirmed trust" steps={[{"x": 43, "y": 27, "text": "Read the unconfirmed-trust status and expand its details."}]} />

## Recognize an unsigned document

A visible signature image or stamp is not proof of an electronic signature. If no recognized signature is present, ask for the actual signed output rather than a screenshot or scanned copy.

<GuideScreenshot src="/img/guide/macos/en/verify-unsigned.png" alt="Recognize an unsigned document" steps={[{"x": 43, "y": 27, "text": "Check the no-signature result before sharing the file as signed."}]} />

## Find a saved signed document

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents and operation History are separate collections. Entries refer to files; if a file has moved or disappeared, choose the file again from its new location for verification.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="Find a saved signed document" steps={[{"x": 30, "y": 20, "text": "Open Documents and choose Saved documents."}, {"x": 82, "y": 3, "text": "Use Search documents to filter by filename."}, {"x": 45, "y": 15, "text": "Click the document row to open its signing-details modal."}]} />

## Inspect and hand off a saved document

The details modal uses the same verification presentation as Verify. Inspecting a saved document does not replace the files in the Verify workspace. Preview is a file preview, not a separate security validation.

<GuideScreenshot src="/img/guide/macos/en/details.png" alt="Inspect and hand off a saved document" steps={[{"x": 31, "y": 48, "text": "Expand the author to inspect signature and certificate details."}, {"x": 32, "y": 60, "text": "Choose Preview to read the file."}, {"x": 42, "y": 60, "text": "Choose Share to export/send the signed output."}, {"x": 54, "y": 60, "text": "Choose Show in Finder to locate the file; Done closes the modal."}]} />

## Clear operation history while keeping documents

Choose the trash control, read the confirmation and confirm only if you want to remove the operation list. This does not delete signed files or the separate Saved documents collection. Return to Saved documents to continue using your saved output.

<GuideScreenshot src="/img/guide/macos/en/history.png" alt="Clear operation history while keeping documents" steps={[{"x": 64, "y": 8, "text": "In Documents, select History."}, {"x": 73, "y": 8, "text": "Choose the trash control and confirm the history-only cleanup."}, {"x": 51, "y": 8, "text": "Return to Saved documents; the saved collection remains available."}]} />

## Use a service and manage bookmarks

Open Browser from the sidebar. Enter a trusted service’s HTTPS address and use the arrow to open it; back, forward and reload remain in the toolbar. Choose the bookmark menu for saved services, Add bookmark, Manage bookmarks and browser-data cleanup. In the bookmark dialog shown below, enter a title, URL and icon, then Save. Close with Done and select the saved service from the bookmark menu.

<GuideScreenshot src="/img/guide/macos/en/browser.png" alt="Use a service and manage bookmarks" steps={[{"x": 45, "y": 58, "text": "Enter a memorable bookmark title."}, {"x": 47, "y": 63, "text": "Check the complete website address and choose an icon below it."}, {"x": 68, "y": 82, "text": "Choose Save once title and URL are valid; Done closes the manager."}]} />

## Check every website signing request

Navigate to the service’s electronic-ID login/signing action. Read the requesting origin and whole document list in eSemnBun. Do not approve an unexpected request. Temporary site trust is optional and limited; it does not authorize an unknown future document list. After approval, complete the PIN step and return to the service for its outcome.

<GuideScreenshot src="/img/guide/macos/en/consent.png" alt="Check every website signing request" steps={[{"x": 51, "y": 16, "text": "Confirm the exact requesting site."}, {"x": 49, "y": 44, "text": "Scroll through all documents and confirm the selected card and format."}, {"x": 81, "y": 92, "text": "Choose Sign only for the expected request, or Refuse to cancel it."}]} />

## Set language, appearance and system discovery

Open eSemnBun → Settings (⌘,). General offers Romanian, English, Russian and system language, plus light, dark or system appearance. Saved PINs has its own tab. Delete an entry there to remove only the stored copy; this never changes the physical card PIN.

For Spotlight/Siri discovery, enable Find signed documents in Siri and Spotlight. Only readable app-owned signed PDF/XML filenames and dates are exposed. Document bodies, certificate identities and PINs are not indexed. In standalone macOS this excludes arbitrary files beside your originals; only eligible app-owned imports qualify. Disable discovery to remove this index.

<GuideScreenshot src="/img/guide/macos/en/settings.png" alt="Set language, appearance and system discovery" steps={[{"x": 83, "y": 24, "text": "Choose the interface language."}, {"x": 83, "y": 32, "text": "Choose Light, Dark or System."}, {"x": 90, "y": 41, "text": "Opt in to signed-document discovery if you want eligible filenames in Siri/Spotlight."}, {"x": 32, "y": 8, "text": "Open Saved PINs to inspect or delete saved entries without revealing their PIN values."}, {"x": 91, "y": 68, "text": "Enable local signing requests only when connecting an MCP client; every request still needs PDF review and approval."}]} />

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
2. Install/configure the [macOS CLI/MCP tools](./macos-cli.md), choose explicit trusted input roots and configure the private approval directory described there.
3. Ask the client to prepare a PDF. Read the native PDF preview, filename/hash and selected card in eSemnBun. Approve only the intended document, or cancel.
4. Complete the normal protected PIN step. The client polls the job and retrieves the completed result. A pending/unknown outcome is not permission to sign again.
5. Turn Local automation off to reject pending requests when finished.

The setup toggle is visible in the General screenshot above. A physical-card broker signature and unattended credential retrieval are not illustrated by these captures. Unattended MCP is a separate explicit CLI policy, not a way to bypass this approval window.

## Browser settings and cleanup

1. Open **Settings → Browser connection**. Enable responses only when you need the local browser connection; the in-app Browser is the main workflow for the Store edition.
2. For external-browser use in the standalone edition, visit a supported site on the same Mac while eSemnBun is running. Grant the browser’s requested local-network permission for that intended workflow.
3. If recognized MoldSign software occupies the ports, finish its operation, then use the offered quit/reconnect action. For an unknown port owner, resolve the conflict before retrying. Never bypass a browser certificate warning.
4. In **Browser → bookmarks menu → Clear browsing data**, select cache, cookies and/or history, then confirm. Removing cookies can sign you out. It does not remove saved documents or saved PINs.

Optional browser PDF stamps and legacy desktop-client access have their own Browser connection preferences. Enable legacy access only for the desktop software you intend to use. See the [browser guide](/docs/browser) for service requirements.

## Menu bar, startup, updates and help

1. Click the menu-bar eSemnBun icon to reopen the main window, Settings or About. Closing a window can leave the app running; choose **Quit** to end it.
2. In **Settings → General**, scroll to startup settings. Choose **Start at sign-in** if desired. If macOS asks for approval, use **System Settings → General → Login Items**.
3. The standalone edition has an optional reader/card insertion helper, which can open the app after it quits. Enable it and approve its background item when asked. The Store edition instead offers opening the window on insertion while its app is running.
4. In standalone installations, use **Check for updates** and install the newer DMG. App Store copies update through the App Store. Keep the same distribution when updating.
5. Use **About eSemnBun** to find the installed version; use Help or the [support page](/support) with app/macOS version, reader/adapter model and reproduction steps. Never send a PIN.

Normal Demo mode is an intentional Settings option with fictional data and a visible notice; it cannot produce valid electronic signatures.

## Recover safely

| What you see | Next action |
| --- | --- |
| No reader | Reconnect the compatible reader/adapter; try a direct USB connection. |
| Reader detected, no card | Insert/reinsert the card and wait for its certificate. |
| Card read error | Reinsert the card and inspect the error before another operation. |
| Wrong holder | Select the correct card before PIN entry. |
| Incorrect PIN / few attempts left | Stop and confirm the PIN; repeated guesses can block the card. |
| File moved / unavailable | Select its new location for verification; a missing file is not an invalid signature. |
| Store edition cannot write beside input | Use its Export/Share destination controls. |
| No Spotlight result | Check opt-in, app ownership, file readability and indexing time. |

For terminal automation, package-manager installation and unattended policy, continue with the [macOS CLI guide](./macos-cli.md).

<!-- file-protection-guides -->


## Encrypt a file with a password

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 59, "y": 3}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-password-light.png" alt="Encrypt a file with a password" start={2} steps={[{"x": 44, "y": 17, "text": "Choose Encrypt."}, {"x": 35, "y": 30, "text": "Choose the source file."}, {"x": 35, "y": 51, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 50, "y": 82, "text": "Choose Encrypt. The encrypted copy is saved in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={6} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 40, "y": 52}, {"text": "Optionally choose Save a copy to export another copy.", "x": 40, "y": 62}, {"text": "Choose Done to return to Documents.", "x": 70, "y": 90}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 59, "y": 3}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-decrypt-light.png" alt="Decrypt a received file" start={2} steps={[{"x": 56, "y": 17, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 35, "y": 51, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 82, "text": "Choose Decrypt. Check the new output in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-decrypt-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={5} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 40, "y": 52}, {"text": "Optionally choose Save a copy to export another copy.", "x": 40, "y": 62}, {"text": "Choose Done to return to Documents.", "x": 70, "y": 90}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Remove a local file

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

<GuideScreenshot src="/img/guide/macos/en/protect-remove-light.png" alt="Remove a local file" steps={[{"x": 67, "y": 17, "text": "Choose Remove file."}, {"x": 35, "y": 33, "text": "Select the exact file you intend to remove and read the warning."}, {"x": 50, "y": 81, "text": "Confirm removal only after checking the filename. Then choose Remove file and complete any confirmation shown."}]} />
