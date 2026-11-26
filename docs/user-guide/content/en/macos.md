---
title: "macOS — illustrated desktop guide"
sidebar_position: 2
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# macOS — illustrated desktop guide

For eSemnBun 0.2.12 on macOS 15 or later. Follow one goal at a time; numbered markers correspond to the instructions below each image. Click an image to open its full-size capture.

## Install and connect your reader

Open [Downloads](/downloads/). Install the Mac App Store edition, or open the desktop DMG and drag eSemnBun to Applications. Eject the DMG and launch the installed copy. The TAR.GZ and Homebrew downloads are CLI/MCP tools; see the [terminal guide](./macos-cli.md).

You need macOS 15 or later, a compatible USB reader, an active supported electronic ID and its signing PIN. Use a suitable USB-C adapter if needed. NFC signing is unavailable.

Both the Mac App Store and standalone editions detect compatible USB readers and inserted cards while eSemnBun is running. The Mac App Store edition also supports compatible websites in an external browser; using the built-in Browser is optional.

<GuideScreenshot src="/img/guide/macos/en/connect.png" alt="Install and connect your reader" steps={[{"x": 5, "y": 7, "text": "Open Sign in the sidebar."}, {"x": 59, "y": 17, "text": "Connect the USB reader. This empty state changes when the reader is detected."}]} />

## Insert the card

The certificate is read without a PIN. Wait for the holder and expiry before starting a signature. The private signing key stays on the card.

<GuideScreenshot src="/img/guide/macos/en/empty-reader.png" alt="Insert the card" steps={[{"x": 59, "y": 18, "text": "Insert the card into the detected reader and leave it connected."}]} />

## Choose the identity and inspect its certificate

The card artwork uses certificate data and a neutral avatar, not a photograph read from your identity card. If the reader must be refreshed, use the top-right re-read control or the card context menu. Do not start another operation while one is in progress.

<GuideScreenshot src="/img/guide/macos/en/cards-current.png" alt="Open Settings and choose Cards and readers to inspect the selected holder, certificate and connected reader." steps={[{"text": "Open Settings and choose Cards and readers to inspect the selected holder, certificate and connected reader.", "x": 25, "y": 42}, {"text": "Use the card carousel to choose the intended holder before signing."}]} />

## Add documents and choose their format

A PDF normally uses PAdES-T: the signature stays inside the PDF. Other files normally use detached XAdES-T: the XML and unchanged original belong together. Use the format control on a queued file when a recipient requires a different supported format. The row menu removes an unintended file.

<GuideScreenshot src="/img/guide/macos/en/sign.png" alt="Add documents and choose their format" steps={[{"x": 5, "y": 7, "text": "Open Sign."}, {"x": 67, "y": 47, "text": "Choose files, or drop files into the dashed area. Add the whole batch before signing."}, {"x": 40, "y": 41, "text": "Check each filename and its format. The PDF stamp control sits beside its format."}, {"x": 92, "y": 96, "text": "Check the selected card, then choose the floating Sign button at the bottom-right, or press ⌘Return. The button shows the batch size and stays visible while you scroll."}]} />

## Place a visible stamp on a PDF

Open Stamp off/Edit stamp on a queued PDF. A visible stamp is optional and does not replace the cryptographic signature. On a multipage PDF choose the page in the preview before applying.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/macos/en/stamp.png" alt="Place a visible stamp on a PDF" steps={[{"x": 95, "y": 6, "text": "Enable Visible stamp."}, {"x": 12, "y": 50, "text": "Drag the stamp to position it; drag a corner to resize it."}, {"x": 94, "y": 29, "text": "Choose the selected page or all pages; optionally apply the setting to all queued PDFs."}, {"x": 92, "y": 95, "text": "Choose Apply to return to the signing queue."}]} />

## Authorize the displayed batch

Use the signing PIN of the selected physical card, not your Mac login password. Stop after an incorrect-PIN result and verify the identity/PIN before another deliberate attempt. The remaining-attempt counter is a card safety limit. A new batch asks again.

<GuideScreenshot src="/img/guide/macos/en/pin.png" alt="Authorize the displayed batch" steps={[{"x": 50, "y": 32, "text": "Check the holder and every listed document. Cancel if anything is unexpected."}, {"x": 50, "y": 60, "text": "Enter the card PIN in the protected boxes."}, {"x": 78, "y": 85, "text": "Choose Remember PIN only if you want this card’s PIN stored in Keychain and unlocked by device authentication."}, {"x": 85, "y": 76, "text": "Choose Sign after the PIN is complete; keep the reader connected until completion."}]} />

## Wait for signing and the timestamp

Leave the reader connected while the app signs and obtains a timestamp. Timestamp/network failures and malformed input are different from an incorrect PIN. Read the actual error before deciding what to do next.

<GuideScreenshot src="/img/guide/macos/en/progress.png" alt="Wait for signing and the timestamp" steps={[{"x": 59, "y": 36, "text": "Wait for the current signing step to finish."}]} />

## Find, preview and share the completed output

Standalone macOS normally writes a new file beside the source, with a signed suffix, without overwriting the original. The App Store edition uses its permitted storage and explicit export/share actions. Keep a detached XML together with its original.

In Mac App Store version 0.2.13, you can also choose a folder in **Settings → General → Documents** to automatically receive copies of signed documents. Choose the folder in the system dialog to grant access.

<GuideScreenshot src="/img/guide/macos/en/export-folder.png" alt="Choose a folder for automatic copies of signed documents from the Mac App Store edition." steps={[{"text": "Choose a folder for automatic copies of signed documents from the Mac App Store edition.", "x": 14, "y": 94}]} />

<GuideScreenshot src="/img/guide/macos/en/success.png" alt="Use Preview beside the completed filename. The adjacent controls save a copy, share the document or reveal it in Finder." steps={[{"text": "Use Preview beside the completed filename. The adjacent controls save a copy, share the document or reveal it in Finder.", "x": 73, "y": 69}]} />

## Recover from a failed document

A batch can contain successful and failed items. Keep completed outputs. Correct the failed input or connection before starting another deliberate operation; there is no automatic PIN retry. An unchanged malformed PDF will fail again.

<GuideScreenshot src="/img/guide/macos/en/file-error.png" alt="Recover from a failed document" steps={[{"x": 42, "y": 41, "text": "Read the error on the affected file; use its row menu to remove it if necessary."}]} />

## Verify a PDF and every signature

Verification does not require a reader or PIN. It checks the file you selected, not a visual stamp or a filename. Offline checks do not establish current certificate revocation status.

<GuideScreenshot src="/img/guide/macos/en/verify.png" alt="Read the document verdict first. Expand each signer to inspect that signature." steps={[{"text": "Read the document verdict first. Expand each signer to inspect that signature.", "x": 37, "y": 46}]} />

## Read integrity, trust and certificate details

A valid cryptographic signature, intact document, trusted chain and timestamp are separate checks. Scroll for all certificate and technical fields. Do not interpret an issuer’s registration number as the signer’s personal identifier.

<GuideScreenshot src="/img/guide/macos/en/certificate.png" alt="Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint." steps={[{"text": "Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint.", "x": 39, "y": 44}]} />

<GuideScreenshot src="/img/guide/macos/en/technical.png" alt="Expand Technical details under a signature to read the verification report. Select the same row again to collapse it." steps={[{"text": "Expand Technical details under a signature to read the verification report. Select the same row again to collapse it.", "x": 39, "y": 87}]} />

## Verify detached XML with its original

Add the XML in Verify. When the document digest cannot be checked, choose the original file(s) using the result’s Choose originals action. Supply the exact unchanged original, not the signed XML itself. Re-read the updated integrity result. An XML alone may be insufficient for a recipient.

<GuideScreenshot src="/img/guide/macos/en/verify-original.png" alt="Verify detached XML with its original" steps={[{"x": 38, "y": 35, "text": "Add the detached XML signature."}, {"x": 40, "y": 53, "text": "Read the missing-original/incomplete result and provide the original requested by the result."}]} />

## Recognize a modified or invalid signature

An invalid result is not repaired by renaming the file or adding a stamp. Request an intact signed copy from its sender and verify that copy.

<GuideScreenshot src="/img/guide/macos/en/verify-invalid.png" alt="Recognize a modified or invalid signature" steps={[{"x": 38, "y": 38, "text": "Read the document’s invalid status, then expand the author to identify the failed check."}]} />

## Distinguish unconfirmed trust

Unconfirmed trust is different from proven document modification. Read the signature and trust-chain details, and follow your recipient’s certificate policy before relying on the document.

<GuideScreenshot src="/img/guide/macos/en/verify-untrusted.png" alt="Distinguish unconfirmed trust" steps={[{"x": 54, "y": 40, "text": "Read the unconfirmed-trust status and expand its details."}]} />

## Recognize an unsigned document

A visible signature image or stamp is not proof of an electronic signature. If no recognized signature is present, ask for the actual signed output rather than a screenshot or scanned copy.

<GuideScreenshot src="/img/guide/macos/en/verify-unsigned.png" alt="Recognize an unsigned document" steps={[{"x": 43, "y": 40, "text": "Check the no-signature result before sharing the file as signed."}]} />

## Find a saved signed document

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents and operation History are separate collections. Entries refer to files; if a file has moved or disappeared, choose the file again from its new location for verification.

<GuideScreenshot src="/img/guide/macos/en/documents.png" alt="Select a filename to inspect its signatures. Use the adjacent actions to preview or share the file." steps={[{"text": "Select a filename to inspect its signatures. Use the adjacent actions to preview or share the file.", "x": 88, "y": 21}]} />

## Inspect and hand off a saved document

The details modal uses the same verification presentation as Verify. Inspecting a saved document does not replace the files in the Verify workspace. Preview is a file preview, not a separate security validation.

<GuideScreenshot src="/img/guide/macos/en/details.png" alt="Expand a signer to see the checks. Use Preview or Share below the report." steps={[{"text": "Expand a signer to see the checks. Use Preview or Share below the report.", "x": 13, "y": 71}]} />

## Clear operation history while keeping documents

Choose the trash control, read the confirmation and confirm only if you want to remove the operation list. This does not delete signed files or the separate Saved documents collection. Return to Saved documents to continue using your saved output.

<GuideScreenshot src="/img/guide/macos/en/history.png" alt="Find the filename, outcome and date in History. Switch to Saved documents to act on an output file." steps={[{"text": "Find the filename, outcome and date in History. Switch to Saved documents to act on an output file.", "x": 42, "y": 11}]} />

## Use a service and manage bookmarks

Open Browser from the sidebar. Enter a trusted service’s HTTPS address and use the arrow to open it; back, forward and reload remain in the toolbar. Choose the bookmark menu for saved services, Add bookmark, Manage bookmarks and browser-data cleanup. In the bookmark dialog shown below, enter a title, URL and icon, then Save. Close with Done and select the saved service from the bookmark menu.

<GuideScreenshot src="/img/guide/macos/en/browser.png" alt="Use a service and manage bookmarks" steps={[{"x": 51, "y": 57, "text": "Enter a memorable bookmark title."}, {"x": 48, "y": 60, "text": "Check the complete website address and choose an icon below it."}, {"x": 65, "y": 75, "text": "Choose Save once title and URL are valid; Done closes the manager."}]} />

## Check every website signing request

Navigate to the service’s electronic-ID login/signing action. Read the requesting origin and whole document list in eSemnBun. Do not approve an unexpected request. Temporary site trust is optional and limited; it does not authorize an unknown future document list. After approval, complete the PIN step and return to the service for its outcome.

<GuideScreenshot src="/img/guide/macos/en/consent.png" alt="Check every website signing request" steps={[{"x": 51, "y": 16, "text": "Confirm the exact requesting site."}, {"x": 49, "y": 44, "text": "Scroll through all documents and confirm the selected card and format."}, {"x": 81, "y": 92, "text": "Choose Sign only for the expected request, or Refuse to cancel it."}]} />

## Set language, appearance and system discovery

Open Settings. Demo mode is at the top. Choose the category for cards, saved cards and PINs, language or appearance.

For Spotlight/Siri discovery, enable Find signed documents in Siri and Spotlight. Only readable app-owned signed PDF/XML filenames and dates are exposed. Document bodies, certificate identities and PINs are not indexed. In standalone macOS this excludes arbitrary files beside your originals; only eligible app-owned imports qualify. Disable discovery to remove this index.

<GuideScreenshot src="/img/guide/macos/en/settings.png" alt="Choose the interface language." steps={[{"text": "Choose the interface language.", "x": 87, "y": 61}, {"text": "Choose an appearance.", "x": 88, "y": 69}, {"text": "Enable signed-document discovery for Siri and Spotlight if desired.", "x": 86, "y": 85}]} />

<GuideScreenshot src="/img/guide/macos/en/saved-cards.png" alt="Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device." steps={[{"text": "Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device.", "x": 86, "y": 28}]} />

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

1. Open **Settings → Browser connection** and enable responses when you need the local browser connection. Both the Mac App Store and standalone editions support the built-in Browser and compatible external browsers.
2. To use an external browser, keep eSemnBun running on the same Mac, connect the USB reader, insert your card and wait for its identity to appear. Visit a supported site and grant the browser’s requested local-network permission for that intended workflow. Review the site and selected identity in eSemnBun before approving a request.
3. If MoldSign occupies the ports, finish its operation and quit it. The standalone edition can offer a quit/reconnect action; in the Mac App Store edition, quit the conflicting app yourself, then retry the connection. For an unknown port owner, resolve the conflict before retrying. Never bypass a browser certificate warning.
4. In **Browser → bookmarks menu → Clear browsing data**, select cache, cookies and/or history, then confirm. Removing cookies can sign you out. It does not remove saved documents or saved PINs.

Optional browser PDF stamps have their own Browser connection preference. The standalone edition additionally offers legacy desktop-client access; enable it only for the desktop software you intend to use. The Mac App Store edition does not accept browser requests containing arbitrary local file paths. See the [browser guide](/docs/browser) for service requirements.

## Menu bar, startup, updates and help

1. Click the menu-bar eSemnBun icon to reopen the main window, Settings or About. Closing a window can leave the app running; choose **Quit** to end it.
2. In **Settings → General**, scroll to startup settings. Choose **Start at sign-in** if desired. If macOS asks for approval, use **System Settings → General → Login Items**.
3. In the standalone edition, enable **Open the app when a reader or card is inserted** at first launch or in **Settings → General**, and approve the background item in System Settings if macOS asks. A separate helper then opens eSemnBun on insertion, even after Quit. The Mac App Store edition cannot do this: insertion opens its window only while eSemnBun is running in the menu bar. After Quit, reopen it manually, or choose **Start at sign-in** so that it runs after you sign in.
4. In standalone installations, use **Check for updates** and install the newer DMG. App Store copies update through the App Store. Keep the same distribution when updating.
5. Use **About eSemnBun** to find the installed version; use Help or the [support page](/support) with app/macOS version, reader/adapter model and reproduction steps. Never send a PIN.

<GuideScreenshot src="/img/guide/macos/en/onboarding.png" alt="Choose whether to start at sign-in or open eSemnBun when a reader or card is inserted. You can change either setting later." steps={[{"text": "Choose whether to start at sign-in or open eSemnBun when a reader or card is inserted. You can change either setting later.", "x": 37, "y": 55}]} />

<GuideScreenshot src="/img/guide/macos/en/menu-bar.png" alt="Open eSemnBun from the menu bar to check the current card and access recent documents." steps={[{"text": "Open eSemnBun from the menu bar to check the current card and access recent documents.", "x": 23, "y": 54}]} />

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

In **Documents**, select **Protect files** in the toolbar. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In version 0.2.13, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). By default, use a certificate intended for encryption. **Card public key compatibility** explicitly allows the card’s public RSA key. Exporting it or encrypting a file does not prove that the card can decrypt; the matching card must support the required private-key operation.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="In Documents, open Protect files using the shield in the toolbar." steps={[{"text": "In Documents, open Protect files using the shield in the toolbar.", "x": 91, "y": 11}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-password-light.png" alt="Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt." steps={[{"text": "Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt.", "x": 81, "y": 57}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-certificate-light.png" alt="Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN." steps={[{"text": "Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN.", "x": 29.5, "y": 60.7}, {"text": "Use Card public key compatibility only when the workflow requires the card’s public RSA key.", "x": 24.5, "y": 49.1}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 66}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

In **Documents**, select **Protect files** in the toolbar. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file in version 0.2.13, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/macos/en/documents-protection-light.png" alt="In Documents, open Protect files using the shield in the toolbar." steps={[{"text": "In Documents, open Protect files using the shield in the toolbar.", "x": 91, "y": 11}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-decrypt-light.png" alt="Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt." steps={[{"text": "Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt.", "x": 89, "y": 50}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-rsa-decrypt.png" alt="For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN." steps={[{"text": "For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN.", "x": 20.3, "y": 60.2}]} />

<GuideScreenshot src="/img/guide/macos/en/protect-decrypt-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 66}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Remove a local file

In **Documents**, select **Protect files** in the toolbar. Choose **Remove file** and select the file to remove.

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

<GuideScreenshot src="/img/guide/macos/en/protect-remove-light.png" alt="Confirm the exact filename before choosing Remove file. The app asks for confirmation before removal." steps={[{"text": "Confirm the exact filename before choosing Remove file. The app asks for confirmation before removal.", "x": 50, "y": 86}]} />
