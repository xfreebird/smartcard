---
title: "Linux — illustrated desktop guide"
sidebar_position: 7
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Linux — illustrated desktop guide

Follow the numbered screenshots for eSemnBun 0.2.6 on Linux. The captures show a native GTK desktop with fictional people and sample documents. Numbered circles are guide annotations; the demo banner is hidden only in isolated documentation captures. Successful-looking preview states do not demonstrate a real electronic signature. Tap an image to enlarge it, then choose Actual size to inspect small controls.

Install the desktop package for your distribution and architecture from [Downloads](/downloads/), then open eSemnBun from your application launcher. DEB/RPM/Flatpak desktop downloads open a graphical app; the package-manager CLI feeds and terminal archives install command-line tools. See the [Linux CLI guide](./linux-cli.md) for terminal and MCP setup. Ubuntu 24.04/Fedora are supported desktop targets; check the chosen package’s requirements. You need an active supported electronic ID, its correct signing PIN, a compatible USB reader and an adapter if needed. NFC signing is unavailable. The private signing key remains on the card.

The host needs a running PC/SC service and CCID driver. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Enable socket activation with `sudo systemctl enable --now pcscd.socket`. Run the desktop app in your graphical session; SSH reader-access policy can differ.

## 1. Connect a reader

Connect the reader directly or through the appropriate USB adapter. No signing PIN is needed to discover the reader or read a certificate. A PC/SC service failure is different from an unplugged reader.

<GuideScreenshot src="/img/guide/linux/en/connect.png" alt="Connect a reader" steps={[{"text": "Open Sign.", "x": 32, "y": 3}, {"text": "Attach a compatible USB reader; read the connection prompt.", "x": 50, "y": 28}]} />

## 2. Insert the card

Insert your electronic ID and wait for the certificate read. Check the holder and expiry before adding a signing request. Do not keep reconnecting while an operation is already running.

<GuideScreenshot src="/img/guide/linux/en/empty.png" alt="Insert the card" steps={[{"text": "Insert the card and wait for its holder and expiry.", "x": 50, "y": 28}]} />

## 3. Choose the intended identity

With several cards, select the intended identity in the carousel. The card artwork uses certificate information and a neutral avatar, not a photograph read from your ID. Re-read the card with the refresh control if needed.

<GuideScreenshot src="/img/guide/linux/en/cards.png" alt="Choose the intended identity" steps={[{"text": "Open Card.", "x": 68, "y": 3}, {"text": "Choose the dot for the intended card, or scroll the carousel.", "x": 50, "y": 37}, {"text": "Inspect the public certificate and reader details below.", "x": 57, "y": 65}]} />

## 4. Add documents and prepare a batch

Choose or drop all the intended files into Sign. You can select multiple documents. Review every filename and remove unintended inputs before authorization. Drag/drop behavior depends on your file manager; choosing files remains available.

<GuideScreenshot src="/img/guide/linux/en/sign.png" alt="Add documents and prepare a batch" steps={[{"text": "Open Sign.", "x": 32, "y": 3}, {"text": "Choose files or drop them into the dashed area.", "x": 48, "y": 77}, {"text": "Use the row menu to remove an unintended file.", "x": 73, "y": 49}, {"text": "Choose Sign only when the complete queue is correct.", "x": 91, "y": 95}]} />

## 5. Choose the signature format

PDF signature is PAdES-T and stays inside the PDF. XML signature is XAdES-BES; XML with timestamp is XAdES-T; XML with validation data is XAdES-C. Timestamped/status-data formats need the corresponding network services. Detached XML must remain with its unchanged original.

<GuideScreenshot src="/img/guide/linux/en/format.png" alt="Choose the signature format" steps={[{"text": "Open the three-dot file menu.", "x": 74, "y": 49}, {"text": "Select the format requested by your recipient.", "x": 72, "y": 67}, {"text": "Remove an unintended file from the same menu.", "x": 73, "y": 87}]} />

## 6. Place an optional visible PDF stamp

Open the file menu and choose Add stamp. A visible stamp is optional and is not the cryptographic signature. Position it without covering important content. This sample PDF contains an explicit unsigned-example label.

<GuideScreenshot src="/img/guide/linux/en/stamp.png" alt="Place an optional visible PDF stamp" steps={[{"text": "Enable the stamp and choose its page mode.", "x": 79, "y": 23}, {"text": "Drag/resize the placement in the PDF preview.", "x": 22, "y": 53}, {"text": "Apply the placement, or cancel to leave the queue unchanged.", "x": 80, "y": 83}]} />

## 7. Review and authorize the batch

Use the signing PIN for the selected card, not your Linux login password. Confirm the holder and whole file list before signing. A new batch requires another approval. Stop after an incorrect-PIN result and confirm the PIN; repeated guesses may block the card. The sample dialog disables saved-PIN access because it never uses a real keyring.

<GuideScreenshot src="/img/guide/linux/en/pin.png" alt="Review and authorize the batch" steps={[{"text": "Check the holder and listed filenames.", "x": 50, "y": 40}, {"text": "Enter the card PIN in the protected input.", "x": 50, "y": 54}, {"text": "Choose Sign; cancel if the request is unexpected.", "x": 61, "y": 66}]} />

## 8. Wait for signing and timestamping

Leave the reader connected until the result appears. Timestamp retrieval needs network access. A timestamp/network error differs from an incorrect PIN; read the specific error before another deliberate request.

<GuideScreenshot src="/img/guide/linux/en/progress.png" alt="Wait for signing and timestamping" steps={[{"text": "Wait for all current signing steps and the final result.", "x": 57, "y": 86}]} />

## 9. Locate the completed output

The app creates a separate output rather than replacing the input. Use the completed row to open/reveal the result. Retain the unchanged original with detached XML. The illustrated completion uses an unsigned fictional sample, not proof of signing.

<GuideScreenshot src="/img/guide/linux/en/success.png" alt="Locate the completed output" steps={[{"text": "Activate the completed result to locate/open its separate output.", "x": 70, "y": 48}]} />

## 10. Recover from a failed item

A batch may contain completed and failed items. Keep completed outputs, read the failed item’s message and correct the cause before starting a new deliberate request. There is no automatic PIN retry or repair of malformed input.

<GuideScreenshot src="/img/guide/linux/en/failure.png" alt="Recover from a failed item" steps={[{"text": "Read the affected file’s error before deciding on another request.", "x": 45, "y": 55}]} />

## 11. Verify a PDF

Verification needs neither a card nor a PIN. Open Verify and choose or drop a signed PDF/XML. Multiple selections are supported. Read every signature rather than relying on a filename or visual stamp. Checks run offline and do not establish current certificate revocation status.

<GuideScreenshot src="/img/guide/linux/en/verify.png" alt="Verify a PDF" steps={[{"text": "Open Verify and choose a signed file.", "x": 44, "y": 3}, {"text": "Read the overall result and number of signatures.", "x": 50, "y": 25}, {"text": "Inspect each author, integrity and trust check.", "x": 50, "y": 71}]} />

## 12. Inspect certificate and technical details

Scroll through the result, then expand Certificate details and Technical details. Integrity, cryptographic signature, certificate trust and timestamp are separate checks. Certificate issuer organization information is not the signer’s personal identifier.

<GuideScreenshot src="/img/guide/linux/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Certificate details and inspect the subject/issuer/key fields.", "x": 75, "y": 41}, {"text": "Expand Technical details for the format and signature identifier.", "x": 75, "y": 91}]} />

## 13. Recognize a modified document

An invalid result can mean the document bytes no longer match what was signed. Obtain an intact signed copy from the sender and verify that copy. Adding a stamp or renaming the file does not repair it.

<GuideScreenshot src="/img/guide/linux/en/invalid.png" alt="Recognize a modified document" steps={[{"text": "Read the invalid verdict.", "x": 49, "y": 25}, {"text": "Inspect the failed integrity/signature check.", "x": 47, "y": 70}]} />

## 14. Distinguish unconfirmed trust

An unconfirmed/unknown chain is different from proven document modification. Check integrity and signature separately, then apply your recipient’s certificate policy before relying on the file.

<GuideScreenshot src="/img/guide/linux/en/untrusted.png" alt="Distinguish unconfirmed trust" steps={[{"text": "Read the unconfirmed verdict.", "x": 48, "y": 25}, {"text": "Inspect the trust-chain check separately.", "x": 70, "y": 86}]} />

## 15. Recognize an unsigned file

No recognized signature means this file has no signature the app can verify. A scanned signature image or visible stamp is not a substitute. Ask for the actual electronic signed output.

<GuideScreenshot src="/img/guide/linux/en/unsigned.png" alt="Recognize an unsigned file" steps={[{"text": "Read the no-signature verdict before sending the file as signed.", "x": 50, "y": 26}]} />

## 16. Verify detached XML with its original

For detached XAdES, put the exact unchanged original beside the XML, using the name referenced by the signature, then select the XML again in Verify. This Linux version has no inline Choose originals picker: the original-file relationship is resolved from the XML’s folder. A missing original prevents a complete integrity conclusion.

<GuideScreenshot src="/img/guide/linux/en/format.png" alt="Verify detached XML with its original" steps={[{"text": "Keep the detached XML and original together, then choose the XML again in Verify.", "x": 73, "y": 67}]} />

## 17. Find signed documents

Documents contains a signed-output collection and separate operation History. Entries point to actual files and do not replace a backup. A missing or moved file needs to be selected again at its new location.

<GuideScreenshot src="/img/guide/linux/en/documents.png" alt="Find signed documents" steps={[{"text": "Open Documents.", "x": 55, "y": 3}, {"text": "Select the saved document row.", "x": 42, "y": 26}, {"text": "Use Signing details or the folder icon for the selected file.", "x": 36, "y": 37}]} />

## 18. Open signing details

Click the document row or Signing details to open the modal. It verifies the currently readable file without replacing the Verify workspace or adding another operation entry. The sample is genuinely unsigned, so this modal correctly says no signature was found. Close it to return to the collection; the folder icon on the list reveals the file.

<GuideScreenshot src="/img/guide/linux/en/details.png" alt="Open signing details" steps={[{"text": "Read the fresh result in the signing-details modal.", "x": 50, "y": 27}, {"text": "Close the modal to return to the same list.", "x": 73, "y": 12}]} />

## 19. Clear history while keeping documents

Switch to History, choose Clear list and read the confirmation before accepting it. Clearing history removes operation entries, not signed files or the separate Signed documents collection. Return to Signed documents afterward.

<GuideScreenshot src="/img/guide/linux/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Review History; Signed documents returns to your saved collection.", "x": 17, "y": 10}, {"text": "Choose Clear list and confirm history-only removal.", "x": 79, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/en/history-confirm.png" alt="Clear history while keeping documents" start={3} steps={[{"x": 57, "y": 57, "text": "Read the history-only confirmation, then choose Clear list or Cancel. Signed documents remain available."}]} />

## 20. Choose language and appearance

Open the application menu → Preferences. Choose System, Light or Dark appearance and System, Romanian, English or Russian language. Changes apply to the interface. These captures use native translated controls.

<GuideScreenshot src="/img/guide/linux/en/settings.png" alt="Choose language and appearance" steps={[{"text": "Choose the appearance.", "x": 69, "y": 41}, {"text": "Choose the interface language.", "x": 69, "y": 48}]} />

## 21. Manage saved PINs and website access

Saved PINs use the desktop Secret Service/system keyring. When normal signing offers Remember PIN, save only intentionally and unlock the keyring if asked. If it is unavailable or locked, enter the PIN for that operation instead. Delete all PINs removes saved copies only; it does not change or unblock the physical card PIN. Enable Browser connection only for a website workflow you intend to use.

<GuideScreenshot src="/img/guide/linux/en/settings.png" alt="Manage saved PINs and website access" steps={[{"text": "Delete saved PIN copies only if you intend to enter them again.", "x": 68, "y": 65}, {"text": "Enable the browser connection only for your intended service.", "x": 69, "y": 85}]} />

## 22. Keep the app available in the background

Scroll lower in Preferences for background and startup options. Run in background keeps the browser connection available after closing the window. Start at sign-in launches background detection. Show the app on card insertion works while the app is already running in the background; it is not a separate always-on reader service.

<GuideScreenshot src="/img/guide/linux/en/background.png" alt="Keep the app available in the background" steps={[{"text": "Choose background operation and startup if required.", "x": 70, "y": 75}, {"text": "Choose whether insertion should open the running app.", "x": 70, "y": 90}]} />

## 23. Find the version and update safely

Open Preferences → About eSemnBun to find the installed version and website. Use the application’s Check for updates command when available, or your original package channel. Install a compatible replacement package; the update check does not silently replace your app. Include app/OS versions and the reader model in support requests, never your PIN.

<GuideScreenshot src="/img/guide/linux/en/about.png" alt="Find the version and update safely" steps={[{"text": "Open About eSemnBun.", "x": 58, "y": 7}, {"text": "Read the version and website before requesting support.", "x": 50, "y": 27}]} />

## 24. Open help and application commands

The application menu contains Preferences, About, Check for Updates and Quit. Open [troubleshooting](/docs/troubleshooting) for online help. Closing the window may leave the app running when background mode is enabled; choose Quit to end it. For terminal automation continue with the Linux CLI guide.

<GuideScreenshot src="/img/guide/linux/en/menu.png" alt="Open help and application commands" steps={[{"text": "Open the application menu."}, {"text": "Choose the intended Preferences, Help, update or Quit action.", "x": 87, "y": 35}]} />


## 25. Approve a local MCP signing request

In Preferences, enable local signing requests only when you intend to use an MCP client. Copy the private broker directory shown in the setting into the helper configuration. Keep the desktop app running. Each request opens a staged PDF for review: check the document, card and operation, approve it explicitly, then enter the PIN in the native dialog. A saved PIN never replaces approval. Cancel unexpected requests.

<GuideScreenshot src="/img/guide/linux/en/settings.png" alt="Approve a local MCP signing request" caption="Native Settings capture with fictional data. The opt-in is disabled in this isolated screenshot session; no live MCP approval or card signing was performed." steps={[{"x": 71, "y": 26, "text": "Enable local signing requests in the desktop app; each PDF still needs native review and approval."}, {"x": 50, "y": 27.4, "text": "Copy the private broker directory displayed by your own installation into the MCP launch configuration."}]} />


## Use government websites in your own browser

Linux uses an external browser; it does not include the Apple/Android in-app browser or bookmark manager. In Preferences, enable Browser connection and open the intended supported service on this same Linux machine. Keep eSemnBun running. Check the exact requesting site, document list, card and operation in the consent/PIN dialog before approving. Optional website stamps are configured separately. Enable legacy MoldSign Desktop access only for the client software you intend to use. The packaged HTTPS identity is used automatically; Import replaces it only when deliberately configured. Never bypass a browser certificate warning. If another bridge owns the ports, finish its operation and resolve the conflict before reconnecting. Bookmarks, cookies and browsing-history cleanup belong to your external browser. Website consent, keyring retrieval and live portal completion are not demonstrated by these isolated captures.

## Recover safely

No reader: check PC/SC, CCID, cable and adapter. Empty reader: insert/reinsert the card and wait. Wrong holder: select the right card before PIN entry. Incorrect or blocked PIN: stop and contact the card provider when necessary; eSemnBun cannot unblock it. Unavailable file: select the actual current file, not an old entry. Missing original: restore the unchanged detached original beside XML. For support use a fictional example and never send PINs, confidential documents or full identity-card data.

<!-- file-protection-guides -->


## Encrypt a file with a password

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

<GuideScreenshot src="/img/guide/linux/en/protect-password-light.png" alt="Encrypt a file with a password" caption="Native English interface; fictional data. Before completion." steps={[{"x": 37, "y": 30, "text": "Choose Encrypt."}, {"x": 40, "y": 41, "text": "Choose the source file."}, {"x": 40, "y": 59, "text": "Choose Password, enter a new password and repeat it in the confirmation field."}, {"x": 50, "y": 77, "text": "Choose Encrypt, then save the new encrypted file."}]} />


## Encrypt for a certificate holder

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Ask the recipient for their public encryption certificate (.cer/.der), exported using the next guide. Confirm its fingerprint with its owner through a trusted channel. A signing-only certificate is not sufficient. Encrypting for someone else needs their public certificate, not their card, private key or PIN.

<GuideScreenshot src="/img/guide/linux/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" caption="Native English interface; fictional data. Before completion." steps={[{"x": 37, "y": 30, "text": "Choose Encrypt."}, {"x": 40, "y": 41, "text": "Choose the source file."}, {"x": 38, "y": 50, "text": "Choose Certificate/card."}, {"x": 45, "y": 59, "text": "Choose the recipient’s certificate file."}, {"x": 50, "y": 77, "text": "Choose Encrypt, then save the new encrypted file."}]} />


## Decrypt a received file

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Ask the sender which method they used. For password files, obtain the password separately. For certificate files, connect the matching supported card and reader; you need its encryption key and PIN. A different card or signing-only card cannot unlock the file.

<GuideScreenshot src="/img/guide/linux/en/protect-decrypt-light.png" alt="Decrypt a received file" caption="Native English interface; fictional data. Before completion." steps={[{"x": 37, "y": 30, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 40, "y": 59, "text": "Choose Password and enter the password supplied by the sender."}, {"x": 50, "y": 77, "text": "Choose Decrypt and save the result under a new filename."}]} />

For card decryption: choose Certificate/card, then Read my card. Select the matching encryption identity, inspect its details, enter its PIN and choose Decrypt. Save under a new name. If no supported encryption identity appears, ask the sender for a password-encrypted copy. Stop after a PIN error; do not retry automatically.

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.


## Share your encryption certificate

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Connect your supported card and USB reader. No document or PIN is required to export a public certificate. The card must expose an encryption identity; the usual signing certificate is not interchangeable.

<GuideScreenshot src="/img/guide/linux/en/protect-certificate-light.png" alt="Encrypt for a certificate holder" caption="Native English interface; fictional data. Before completion." steps={[{"x": 38, "y": 50, "text": "Choose Certificate/card."}, {"x": 45, "y": 64, "text": "Choose Read my card; scroll if needed."}]} />

After discovery, select the intended identity and expand Certificate details. Choose Export encryption certificate, save the .cer file and share it with the sender. Compare its fingerprint separately. Only the public certificate is exported; the private key stays on the card. The screenshot shows the starting screen before discovery.


## Remove a local file

Open Documents → Protect files. Select a file you can read; scroll the form when needed. These guides describe the new file-protection feature; it may not yet be in your installed store version.

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

<GuideScreenshot src="/img/guide/linux/en/protect-remove-light.png" alt="Remove a local file" caption="Native English interface; fictional data. Before completion." steps={[{"x": 37, "y": 30, "text": "Choose Remove file."}, {"x": 40, "y": 41, "text": "Select the exact file you intend to remove and read the warning."}, {"x": 50, "y": 77, "text": "Confirm removal only after checking the filename. Then choose Remove file and complete any confirmation shown."}]} />
