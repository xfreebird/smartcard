---
title: "Linux — illustrated desktop guide"
sidebar_position: 7
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Linux — illustrated desktop guide

Follow the numbered screenshots for eSemnBun 0.2.13 on Linux. Tap an image to enlarge it, then choose Actual size to inspect small controls.

Install the desktop package for your distribution and architecture from [Downloads](/downloads/), then open eSemnBun from your application launcher. DEB/RPM/Flatpak desktop downloads open a graphical app; the package-manager CLI feeds and terminal archives install command-line tools. See the [Linux CLI guide](./linux-cli.md) for terminal and MCP setup. Ubuntu 24.04/Fedora are supported desktop targets; check the chosen package’s requirements. You need an active supported electronic ID, its correct signing PIN, a compatible USB reader and an adapter if needed. NFC signing is unavailable. The private signing key remains on the card.

The host needs a running PC/SC service and CCID driver. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Enable socket activation with `sudo systemctl enable --now pcscd.socket`. Run the desktop app in your graphical session; SSH reader-access policy can differ.

## 1. Connect a reader

Connect the reader directly or through the appropriate USB adapter. No signing PIN is needed to discover the reader or read a certificate. A PC/SC service failure is different from an unplugged reader.

<GuideScreenshot src="/img/guide/linux/en/connect.png" alt="Connect a reader" steps={[{"text": "Open Sign.", "x": 41, "y": 3}, {"text": "Attach a compatible USB reader; read the connection prompt.", "x": 50, "y": 23}]} />

## 2. Insert the card

Insert your electronic ID and wait for the certificate read. Check the holder and expiry before adding a signing request. Do not keep reconnecting while an operation is already running.

<GuideScreenshot src="/img/guide/linux/en/empty.png" alt="Insert the card" steps={[{"text": "Insert the card and wait for its holder and expiry.", "x": 50, "y": 26}]} />

## 3. Choose the intended identity

With several cards, select the intended identity in the carousel. The card artwork uses certificate information and a neutral avatar, not a photograph read from your ID. Re-read the card with the refresh control if needed.

<GuideScreenshot src="/img/guide/linux/en/cards-current.png" alt="Open Preferences from the application menu. Choose Cards and readers." steps={[{"text": "Open Preferences from the application menu. Choose Cards and readers.", "x": 50, "y": 27}, {"text": "Use the carousel to choose the intended card.", "x": 50, "y": 43}, {"text": "Scroll down to see the certificate and connected reader.", "x": 47, "y": 76}]} />

## 4. Add documents and prepare a batch

Choose or drop all the intended files into Sign. You can select multiple documents. Review every filename and remove unintended inputs before authorization. Drag/drop behavior depends on your file manager; choosing files remains available.

<GuideScreenshot src="/img/guide/linux/en/sign.png" alt="Add documents and prepare a batch" steps={[{"text": "Open Sign.", "x": 41, "y": 3}, {"text": "Choose files or drop them into the dashed area.", "x": 50, "y": 76}, {"text": "Use the row menu to remove an unintended file.", "x": 73, "y": 49}, {"text": "Choose Sign only when the complete queue is correct.", "x": 91, "y": 95}]} />

## 5. Choose the signature format

PDF signature is PAdES-T and stays inside the PDF. XML signature is XAdES-BES; XML with timestamp is XAdES-T; XML with validation data is XAdES-C. Timestamped/status-data formats need the corresponding network services. Detached XML must remain with its unchanged original.

<GuideScreenshot src="/img/guide/linux/en/format.png" alt="Choose the signature format" steps={[{"text": "Open the three-dot file menu.", "x": 70, "y": 49}, {"text": "Select the format requested by your recipient.", "x": 70, "y": 66}, {"text": "Remove an unintended file from the same menu.", "x": 73, "y": 87}]} />

## 6. Place an optional visible PDF stamp

Open the file menu and choose Add stamp. A visible stamp is optional and is not the cryptographic signature. Position it without covering important content. This sample PDF contains an explicit unsigned-example label.

<GuideScreenshot src="/img/guide/linux/en/stamp.png" alt="Place an optional visible PDF stamp" steps={[{"text": "Enable the stamp and choose its page mode.", "x": 79, "y": 23}, {"text": "Drag/resize the placement in the PDF preview.", "x": 22, "y": 53}, {"text": "Apply the placement, or cancel to leave the queue unchanged.", "x": 80, "y": 83}]} />

## 7. Review and authorize the batch

Use the signing PIN for the selected card, not your Linux login password. Confirm the holder and whole file list before signing. A new batch requires another approval. Stop after an incorrect-PIN result and confirm the PIN; repeated guesses may block the card. The sample dialog disables saved-PIN access because it never uses a real keyring.

<GuideScreenshot src="/img/guide/linux/en/pin.png" alt="Review and authorize the batch" steps={[{"text": "Check the holder and listed filenames.", "x": 50, "y": 36}, {"text": "Enter the card PIN in the protected input.", "x": 50, "y": 48}, {"text": "Choose Sign; cancel if the request is unexpected.", "x": 59, "y": 64}]} />

## 8. Wait for signing and timestamping

Leave the reader connected until the result appears. Timestamp retrieval needs network access. A timestamp/network error differs from an incorrect PIN; read the specific error before another deliberate request.

<GuideScreenshot src="/img/guide/linux/en/progress.png" alt="Wait for signing and timestamping" steps={[{"text": "Wait for all current signing steps and the final result.", "x": 50, "y": 90}]} />

## 9. Locate the completed output

The app creates a separate output rather than replacing the input. Use the completed row to open/reveal the result. Retain the unchanged original with detached XML.

<GuideScreenshot src="/img/guide/linux/en/success.png" alt="Locate the completed output" steps={[{"text": "Open the file directly from its row.", "x": 72, "y": 52}, {"text": "Use the folder button to show the saved file in its folder.", "x": 80, "y": 52}]} />

## 10. Recover from a failed item

A batch may contain completed and failed items. Keep completed outputs, read the failed item’s message and correct the cause before starting a new deliberate request. There is no automatic PIN retry or repair of malformed input.

<GuideScreenshot src="/img/guide/linux/en/failure.png" alt="Recover from a failed item" steps={[{"text": "Read the affected file’s error before deciding on another request.", "x": 36, "y": 50}]} />

## 11. Verify a PDF

Verification needs neither a card nor a PIN. Open Verify and choose or drop a signed PDF/XML. Multiple selections are supported. Read every signature rather than relying on a filename or visual stamp. Checks run offline and do not establish current certificate revocation status.

<GuideScreenshot src="/img/guide/linux/en/verify.png" alt="Verify a PDF" steps={[{"text": "Open Verify and choose a signed file.", "x": 50, "y": 4}, {"text": "Read the overall result and number of signatures.", "x": 50, "y": 28}, {"text": "Inspect each author, integrity and trust check.", "x": 27, "y": 47}]} />

## 12. Inspect certificate and technical details

Scroll through the result, then expand Certificate details and Technical details. Integrity, cryptographic signature, certificate trust and timestamp are separate checks. Certificate issuer organization information is not the signer’s personal identifier.

<GuideScreenshot src="/img/guide/linux/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Technical details to inspect the signature format and identifier.", "x": 29, "y": 61}, {"text": "Read the fields for this signature. Select the heading again to collapse the details.", "x": 29, "y": 76}]} />

## 13. Recognize a modified document

An invalid result can mean the document bytes no longer match what was signed. Obtain an intact signed copy from the sender and verify that copy. Adding a stamp or renaming the file does not repair it.

<GuideScreenshot src="/img/guide/linux/en/invalid.png" alt="Recognize a modified document" steps={[{"text": "Read the invalid verdict.", "x": 49, "y": 25}, {"text": "Inspect the failed integrity/signature check.", "x": 47, "y": 70}]} />

## 14. Distinguish unconfirmed trust

An unconfirmed/unknown chain is different from proven document modification. Check integrity and signature separately, then apply your recipient’s certificate policy before relying on the file.

<GuideScreenshot src="/img/guide/linux/en/untrusted.png" alt="Distinguish unconfirmed trust" steps={[{"text": "Read the unconfirmed verdict.", "x": 48, "y": 25}, {"text": "Inspect the trust-chain check separately.", "x": 70, "y": 86}]} />

## 15. Recognize an unsigned file

No recognized signature means this file has no signature the app can verify. A scanned signature image or visible stamp is not a substitute. Ask for the actual electronic signed output.

<GuideScreenshot src="/img/guide/linux/en/unsigned.png" alt="Recognize an unsigned file" steps={[{"text": "Read the no-signature verdict before sending the file as signed.", "x": 49, "y": 25}]} />

## 16. Verify detached XML with its original

For detached XAdES, put the exact unchanged original beside the XML, using the name referenced by the signature, then select the XML again in Verify. This Linux version has no inline Choose originals picker: the original-file relationship is resolved from the XML’s folder. A missing original prevents a complete integrity conclusion.

<GuideScreenshot src="/img/guide/linux/en/verify.png" alt="Verify detached XML with its original" steps={[{"text": "Keep the detached XML and original together, then choose the XML again in Verify.", "x": 50, "y": 4}]} />

## 17. Find signed documents

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents contains a signed-output collection and separate operation History. Entries point to actual files and do not replace a backup. A missing or moved file needs to be selected again at its new location.

<GuideScreenshot src="/img/guide/linux/en/documents.png" alt="Find signed documents" steps={[{"text": "Select the filename to inspect its signing details.", "x": 28, "y": 30}, {"text": "Open the file directly from its row.", "x": 67, "y": 30}, {"text": "Use the folder button to show the saved file in its folder.", "x": 76, "y": 30}]} />

## 18. Open signing details

Select a saved filename to verify its current contents in the details window. The example uses a fictional signer and a self-signed certificate, so its trust chain is unknown. Open the document or its folder from the bottom of the window.

<GuideScreenshot src="/img/guide/linux/en/details.png" alt="Open signing details" steps={[{"text": "Read the verification outcome and check the signer.", "x": 37, "y": 34}, {"text": "Open the document or show it in its folder.", "x": 65, "y": 79}]} />

## 19. Clear history while keeping documents

Switch to History, choose Clear list and read the confirmation before accepting it. Clearing history removes operation entries, not signed files or the separate Saved documents collection. Return to Saved documents afterward.

<GuideScreenshot src="/img/guide/linux/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Review History; Saved documents returns to your saved collection.", "x": 14, "y": 11}, {"text": "Choose Clear list and confirm history-only removal.", "x": 73, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/en/history-confirm.png" alt="Clear history while keeping documents" start={3} steps={[{"x": 57, "y": 57, "text": "Read the history-only confirmation, then choose Clear list or Cancel. Saved documents remain available."}]} />

## 20. Choose language and appearance

Open Preferences from the application menu. Demo mode is at the top. Use Cards and readers to inspect cards and Saved PINs to manage the stored copies.

Open the application menu → Preferences. Choose System, Light or Dark appearance and System, Romanian, English or Russian language. Changes apply to the interface. These captures use native translated controls.

<GuideScreenshot src="/img/guide/linux/en/settings-current.png" alt="Open Preferences from the application menu. Demo mode is at the top. Use Cards and readers to inspect cards and Saved PINs to manage the stored copies." steps={[{"text": "Open Preferences from the application menu. Demo mode is at the top. Use Cards and readers to inspect cards and Saved PINs to manage the stored copies.", "x": 68, "y": 17}]} />

## 21. Manage saved PINs and website access

Saved PINs use the desktop Secret Service/system keyring. When normal signing offers Remember PIN, save only intentionally and unlock the keyring if asked. If it is unavailable or locked, enter the PIN for that operation instead. Delete all PINs removes saved copies only; it does not change or unblock the physical card PIN. Enable Browser connection only for a website workflow you intend to use.

<GuideScreenshot src="/img/guide/linux/en/saved-pins.png" alt="Open Saved PINs in Preferences to manage copies stored on this device." steps={[{"text": "Open Saved PINs in Preferences to manage copies stored on this device.", "x": 51, "y": 38}]} />

## 22. Keep the app available in the background

Scroll lower in Preferences for background and startup options. Run in background keeps the browser connection available after closing the window. Start at sign-in launches background detection. Show the app on card insertion works while the app is already running in the background; it is not a separate always-on reader service.

<GuideScreenshot src="/img/guide/linux/en/background.png" alt="Keep the app available in the background" steps={[{"text": "Choose background operation and startup if required.", "x": 68, "y": 75}, {"text": "Choose whether insertion should open the running app.", "x": 68, "y": 89}]} />

## 23. Find the version and update safely

Open the application menu → About eSemnBun to find the installed version and website. Use the application’s Check for updates command when available, or your original package channel. Install a compatible replacement package; the update check does not silently replace your app. Include app/OS versions and the reader model in support requests, never your PIN.

<GuideScreenshot src="/img/guide/linux/en/about.png" alt="Find the version and update safely" steps={[{"text": "Open About eSemnBun.", "x": 58, "y": 7}, {"text": "Read the version and website before requesting support.", "x": 50, "y": 27}]} />

## 24. Open help and application commands

The application menu contains Preferences, About, Check for Updates and Quit. Open [troubleshooting](/docs/troubleshooting) for online help. Closing the window may leave the app running when background mode is enabled; choose Quit to end it. For terminal automation continue with the Linux CLI guide.

<GuideScreenshot src="/img/guide/linux/en/menu.png" alt="Open help and application commands" steps={[{"text": "Open the application menu.", "x": 89, "y": 3}, {"text": "Choose the intended Preferences, Help, update or Quit action.", "x": 89, "y": 14}]} />

## 25. Approve a local MCP signing request

In Preferences, enable local signing requests only when you intend to use an MCP client. Copy the private broker directory shown in the setting into the helper configuration. Keep the desktop app running. Each request opens a staged PDF for review: check the document, card and operation, approve it explicitly, then enter the PIN in the native dialog. A saved PIN never replaces approval. Cancel unexpected requests.

<GuideScreenshot src="/img/guide/linux/en/settings.png" alt="Approve a local MCP signing request" steps={[{"x": 68, "y": 84, "text": "Enable local signing requests in the desktop app; each PDF still needs native review and approval."}, {"x": 43, "y": 86, "text": "Copy the private broker directory displayed by your own installation into the MCP launch configuration."}]} />


## Use government websites in your own browser

Linux uses an external browser; it does not include the Apple/Android in-app browser or bookmark manager. In Preferences, enable Browser connection and open the intended supported service on this same Linux machine. Keep eSemnBun running. Check the exact requesting site, document list, card and operation in the consent/PIN dialog before approving. Optional website stamps are configured separately. Enable legacy MoldSign Desktop access only for the client software you intend to use. The packaged HTTPS identity is used automatically; Import replaces it only when deliberately configured. Never bypass a browser certificate warning. If another bridge owns the ports, finish its operation and resolve the conflict before reconnecting. Bookmarks, cookies and browsing-history cleanup belong to your external browser. Website consent, keyring retrieval and live portal completion are not demonstrated by these isolated captures.

## Recover safely

No reader: check PC/SC, CCID, cable and adapter. Empty reader: insert/reinsert the card and wait. Wrong holder: select the right card before PIN entry. Incorrect or blocked PIN: stop and contact the card provider when necessary; eSemnBun cannot unblock it. Unavailable file: select the actual current file, not an old entry. Missing original: restore the unchanged detached original beside XML. For support use a fictional example and never send PINs, confidential documents or full identity-card data.

<!-- file-protection-guides -->


## Encrypt a file with a password

Open the main menu in the window header, then **Protect files → Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

Choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). The Moldovan ID signing certificate cannot decrypt these files.

<GuideScreenshot src="/img/guide/linux/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"text": "Choose the file to encrypt.", "x": 50, "y": 29}, {"text": "Select AES-128, AES-192 or AES-256. AES-256 is selected by default.", "x": 45, "y": 56}, {"text": "Enter and confirm a new file password.", "x": 31, "y": 68}, {"text": "Choose Encrypt, then save the encrypted copy.", "x": 50, "y": 91}]} />

<GuideScreenshot src="/img/guide/linux/en/protect-certificate-light.png" alt="Encrypt for an RSA recipient" steps={[{"text": "Select RSA certificate.", "x": 44, "y": 46}, {"text": "Choose the recipient’s public encryption certificate.", "x": 50, "y": 58}, {"text": "To encrypt for your own card, connect its reader and read its encryption certificate.", "x": 50, "y": 65}]} />

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Use the close button in the window header when finished. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

Open the main menu in the window header, then **Protect files → Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/linux/en/protect-decrypt-light.png" alt="Decrypt a received file" steps={[{"text": "Choose the encrypted file. Its contents determine the decryption method.", "x": 50, "y": 29}, {"text": "For a password-encrypted file, enter the password supplied by the sender.", "x": 30, "y": 61}, {"text": "Choose Decrypt and save the result in a new file.", "x": 50, "y": 91}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**, then **Save a copy** and select a new output location. After saving, the file appears in **Documents → Saved documents**. Use the close button in the window header when finished. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Remove a local file

Open the main menu in the window header, then **Protect files → Encrypt**, **Decrypt** or **Remove file**. Select a file you can read; scroll the form when needed.

Desktop only. This permanently removes one supported regular local file after confirmation. It cannot guarantee erasure from SSDs, snapshots, backups or other copies. Unsupported locations and links are refused. Mobile document providers do not support this operation.

<GuideScreenshot src="/img/guide/linux/en/protect-remove-light.png" alt="Remove a local file" steps={[{"text": "Choose the file and read its name and the removal warning.", "x": 50, "y": 29}, {"text": "Confirm removal only after checking the selected file.", "x": 36, "y": 85}, {"text": "Choose Remove file to complete the operation.", "x": 50, "y": 91}]} />
