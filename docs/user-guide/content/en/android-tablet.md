---
title: Android tablet
sidebar_position: 5
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Android tablet

Starting with eSemnBun 0.2.12, compatible iPhones and Android devices can sign with a compatible contactless card over NFC. A compatible USB reader remains available. Use an active Moldovan electronic identity card with a valid signing certificate and its signing PIN. Install or update through your device’s channel on [Downloads](/downloads).

Numbered circles point to the controls used in each journey. Tap an image to enlarge it.

A wide tablet window uses a left navigation rail and keeps signing controls in the content area. Rotate to landscape for more room. In split screen or a narrow window, the same app switches to compact navigation; enlarge the window to restore the rail. These are native tablet captures, not enlarged phone images. For compact navigation, see the [phone guide](./android.md).

## 1. Connect the reader and card

Use an active Moldovan electronic identity card with a valid signing certificate and its signing PIN.

### Sign over NFC

Starting with eSemnBun 0.2.12, compatible iPhones and Android devices can sign with a compatible contactless card over NFC. A compatible USB reader remains available. Choose **With your phone · NFC** in **Sign** and add your document. Tap **Continue**, review the request and confirm your signing PIN. Hold the card near the device’s NFC antenna until the app reports completion. Android devices need NFC enabled.

<GuideScreenshot src="/img/guide/android-tablet/en/nfc-sign.png" alt="The Sign screen with NFC selected" steps={[{"text": "The Sign screen with NFC selected", "x": 45, "y": 75}]} />

### Sign with a USB card reader

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing.

<GuideScreenshot src="/img/guide/android-tablet/en/reader-sign.png" alt="The Sign screen with a USB card reader selected" steps={[{"text": "The Sign screen with a USB card reader selected", "x": 48, "y": 78}]} />

## 2. Add files and prepare a batch

### Choose how to sign

Choose **With your phone · NFC** in **Sign** and add your document. Tap **Continue**, review the request and confirm your signing PIN. Hold the card near the device’s NFC antenna until the app reports completion. Android devices need NFC enabled.

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing. With USB, keep the reader connected and the card inserted until the signature and timestamp are complete.

For USB, keep the reader connected until every result appears. The original input remains separate from the signed output. You can also share documents from Files or another app to eSemnBun.

<GuideScreenshot src="/img/guide/android-tablet/en/sign.png" alt="Add files and prepare a batch" steps={[{"text": "Swipe to the intended card and check the Used for signing indicator.", "x": 17.3, "y": 18.4}, {"text": "Tap Add documents and select one or several files in the system picker. Download cloud files first if they are unavailable.", "x": 47.4, "y": 46.5}, {"text": "Review the expanded document rows. Open each file menu to change its format, stamp, or remove it."}, {"text": "Tap Sign when the card and the full document list are correct.", "x": 66, "y": 53.5}]} />

## 3. Choose PDF or XML signatures

PDF signature (PAdES-T) embeds the signature in a PDF. XAdES creates XML: keep the original beside a detached signature. Timestamped and validation-data formats need the relevant trust services. A visible stamp is optional and does not replace the digital signature.

<GuideScreenshot src="/img/guide/android-tablet/en/format.png" alt="Choose PDF or XML signatures" steps={[{"text": "Open the file’s three-dot menu. Choose the signature format for that file; remove a mistaken input from the same menu.", "x": 84.9, "y": 30.4}, {"text": "For PDFs, enable the visible-stamp option if you want to place a stamp before approval. XML signing here produces a detached signature; retain the original."}]} />

## 4. Place an optional visible stamp

The placement editor opens before the PIN request when a stamp is enabled. Review page content to avoid covering important text.

The stamp labels follow the app language chosen in General settings.

<GuideScreenshot src="/img/guide/android-tablet/en/stamp.png" alt="Place an optional visible stamp" steps={[{"text": "Drag the stamp on the page; use its resize handles to fit the available space.", "x": 38, "y": 58}, {"text": "Use the page arrows, then choose One page, All pages, or Off.", "x": 46.1, "y": 83.2}, {"text": "Choose whether the placement applies to all queued PDFs, then tap Apply. Cancel returns without approving a signature.", "x": 93.9, "y": 93.5}]} />

## 5. Review and authorize

Check the holder, document names, format, and requesting website when one is shown. You can reuse a saved PIN for the selected card when device authentication is available. Never send your PIN in a support request.

<GuideScreenshot src="/img/guide/android-tablet/en/pin.png" alt="Review and authorize" steps={[{"text": "Enter the selected card’s signing PIN in the protected field. The approval covers only the listed request.", "x": 31.8, "y": 54.8}, {"text": "Tap Sign. Keep the app and reader available while the batch completes. Cancel if the request is unexpected.", "x": 60.9, "y": 62.5}]} />

## Follow signing progress

The progress card names the active stage: connecting, authentication, certificate read, PIN verification, signing, timestamping, revocation information, or writing the output. A stage can take time while an external service responds.

<GuideScreenshot src="/img/guide/android-tablet/en/sign-progress.png" alt="Follow signing progress" steps={[{"text": "After approval, watch the active stage and keep the reader connected. Wait for a completed result before opening or sharing the output.", "x": 8.0, "y": 45.5}, {"text": "If the operation reports an error, follow that message. Do not enter the PIN repeatedly or start another batch while the current request is active."}]} />

## Recover from a failed item

An error belongs to the affected file. Review the remaining rows and completed outputs; a failure is not evidence that every document failed. This illustration shows a timestamp-service error on one item in a mixed batch.

<GuideScreenshot src="/img/guide/android-tablet/en/sign-failure.png" alt="Recover from a failed item" steps={[{"text": "Read the message under the failed file. For a timestamp/network error, restore connectivity or wait for the service to recover. For an unreadable input, replace it with a valid source file.", "x": 45.2, "y": 27.6}, {"text": "Keep successful outputs, correct the cause, and deliberately start a new signing attempt only for the files that still need it. There is no automatic PIN retry; after a wrong-PIN warning, stop and confirm the card and PIN before any further attempt."}]} />

## 6. Open, save, or share the result

On Android 10 and later, ordinary signed output is saved under Downloads/eSemnBun. Keep both the XML and original document for detached XAdES. If one file fails, read its error and check completed files before starting another batch.

<GuideScreenshot src="/img/guide/android-tablet/en/results.png" alt="Open, save, or share the result" steps={[{"text": "Tap a finished filename to open the document.", "x": 37.0, "y": 23.3}, {"text": "Use the Share icon beside the filename to send a copy.", "x": 65.5, "y": 23.3}, {"text": "View in Documents opens the saved library.", "x": 48.4, "y": 42.9}]} />

## 7. Check a signed document

Verification does not require the card or PIN. A green result refers to the checks shown, not to the filename or the presence of a visible stamp.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-current.png" alt="The Verify screen" steps={[{"text": "Choose a signed PDF or XML. Read its verdict, signer and checks.", "x": 3.0, "y": 18.9}, {"text": "Expand Technical details to see the report, then tap again to collapse it.", "x": 53.0, "y": 47.6}, {"text": "Use the bottom button to choose another signed document.", "x": 53.0, "y": 93.5}, {"text": "Use Clear results in the navigation bar to clear this verification session.", "x": 97.5, "y": 5.1}]} />

## Understand an invalid signature

Invalid means that document integrity or the cryptographic signature check failed. It can indicate changed bytes or a damaged/incorrect signature. A valid-looking stamp, familiar filename, or recognized author does not override this result.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-invalid.png" alt="Understand an invalid signature" steps={[{"text": "Read Invalid signature and the failed check. Do not treat this copy as verified.", "x": 3.0, "y": 18.9}, {"text": "Expand Technical details, compare with the sender’s original signed output, and request a fresh intact copy if needed. Check every listed signature when the document contains more than one.", "x": 53.0, "y": 47.6}]} />

## Understand an unconfirmed trust chain

Cannot be confirmed is distinct from Invalid signature. In this example the signature and document integrity pass, but the certificate is outside the recognized MDQSign chain. Missing original documents can also produce an unconfirmed result, with a different explanation.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-unconfirmed.png" alt="Understand an unconfirmed trust chain" steps={[{"text": "Read the reason below Cannot be confirmed and inspect the separate Integrity, Signature, and Trust chain checks.", "x": 3.0, "y": 18.9}, {"text": "Inspect certificate details to identify the signer and issuer. Establish the required trust with the sender or receiving service before relying on the document. Offline integrity checks do not establish current revocation status or guarantee legal acceptance.", "x": 53.0, "y": 41.7}]} />

## Recognize an unsigned or unsupported file

No signature means the app found no signature it can read in the selected file. You may have selected the unsigned input, or the file may use an unsupported signature format. A picture of a signature is not an electronic signature.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-none.png" alt="Recognize an unsigned or unsupported file" steps={[{"text": "Read No signature, then check that you selected the completed signed PDF or the XML signature rather than its unsigned original.", "x": 3.0, "y": 18.9}, {"text": "Choose the correct signed output and verify again. Ask the sender for a supported PDF/XML signature if the result remains unchanged.", "x": 53.0, "y": 93.5}]} />

## 8. Inspect certificate and technical details

An invalid signature differs from an unconfirmed trust chain. Missing originals or unavailable trust information can prevent a complete conclusion. Inspect the separate checks before relying on a document.

<GuideScreenshot src="/img/guide/android-tablet/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Certificate details to inspect the signer, issuer, serial number, public key, and fingerprint. Scroll within the screen if needed.", "x": 53.0, "y": 41.7}, {"text": "Expand Technical details for the checks behind the verdict; collapse it when finished.", "x": 53.0, "y": 57.1}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/verify-technical.png" alt="Expanded technical details" steps={[{"text": "Read the diagnostics for this signature. Tap Technical details again to collapse the report.", "x": 38.4, "y": 52.7}]} />

## 9. Supply the original for detached XML

Detached XML contains a reference to the signed document. Its original bytes are needed to check the document digest.

<GuideScreenshot src="/img/guide/android-tablet/en/original.png" alt="Supply the original for detached XML" steps={[{"text": "Tap Choose the signed document and select the exact original named in the message.", "x": 3.0, "y": 35.3}, {"text": "Wait for the refreshed result. A modified or different original will not match the signature. Share the XML together with the matching original."}]} />

## 10. Find signed documents

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents contains a signed-output library and a separate activity history. A saved entry is a shortcut to a file, not a substitute for a backup.

<GuideScreenshot src="/img/guide/android-tablet/en/documents.png" alt="Find signed documents" steps={[{"text": "Tap the filename for signing details.", "x": 34.5, "y": 20.7}, {"text": "Choose Share directly on the file row, or open More actions for Open, Verify, Protect files and Save as.", "x": 65.3, "y": 21.6}]} />

## 11. Read signing details without losing your list

The modal’s verdict is a fresh verification, not just a historical “signed” label. An unavailable file reports an access error; reselect a moved file in Verify.

<GuideScreenshot src="/img/guide/android-tablet/en/details.png" alt="Read signing details without losing your list" steps={[{"text": "Read the verification result and expand Technical details to inspect the checks.", "x": 29.1, "y": 65.4}, {"text": "Use Open or Share below the result. Close returns to the document list.", "x": 31.2, "y": 73.5}]} />

## 12. Clear history while keeping documents

History lists document operations and website requests. Clearing it does not clear Saved documents or delete signed files on storage.

<GuideScreenshot src="/img/guide/android-tablet/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Choose History to see the full filename, outcome and date for each operation.", "x": 41.8, "y": 14.7}, {"text": "Clear the activity list to remove history entries while keeping saved documents.", "x": 69.3, "y": 14.7}]} />

## 13. Sign on a website

Use only a service whose address and request you recognize. The app is independent from the Moldovan government; official sources are linked in Browser and About. Website appearance can differ from these illustrations.

<GuideScreenshot src="/img/guide/android-tablet/en/browser.png" alt="Sign on a website" steps={[{"text": "On compatible devices, open Authentication to choose NFC or a card reader.", "x": 39.0, "y": 11.5}, {"text": "Open Browser and enable Browser connection for a service in an external browser on this same device. Allow its notification request when prompted.", "x": 40.9, "y": 20.1}, {"text": "Alternatively, tap Open in app browser. Enter a service address or choose it from Services. The embedded browser uses desktop presentation for compatible identity login.", "x": 53.0, "y": 38.8}, {"text": "Enable visible website stamps if needed. Check the card and requesting site in every approval, then enter your PIN."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/browser-authentication.png" alt="On compatible devices, open Authentication to choose NFC or a card reader." steps={[{"text": "Choose NFC or Card reader. The blue row is selected.", "x": 35.5, "y": 53.1}, {"text": "Choose a known card and check its serial number.", "x": 37.9, "y": 69.1}, {"text": "Use Read NFC card to identify another card. This step does not ask for a PIN.", "x": 51.0, "y": 77.1}]} />

## Use browser controls and services

These browser views contain no signed-in account or personal data. Connect your reader before starting a real identity request.

<GuideScreenshot src="/img/guide/android-tablet/en/browser-menu.png" alt="Use browser controls and services" steps={[{"text": "Use Services to choose a built-in service or a saved bookmark.", "x": 17.5, "y": 31.9}, {"text": "Dismiss the menu, enter a full HTTPS address, and tap Go. Use Back, Forward, and Reload to navigate; Close returns to the Browser workspace."}]} />

## Add a useful bookmark

Open Services → Add bookmark. Use only an address you recognize. The title and icon help identify the service later.

<GuideScreenshot src="/img/guide/android-tablet/en/bookmark.png" alt="Add a useful bookmark" steps={[{"text": "Enter a title and the service URL.", "x": 33.0, "y": 38.8}, {"text": "Choose an icon, then Save. Cancel leaves bookmarks unchanged.", "x": 32.0, "y": 50.3}]} />

## Edit or remove bookmarks

Open Services → Manage bookmarks. Changes affect the saved shortcuts, not your identity card or signed documents.

<GuideScreenshot src="/img/guide/android-tablet/en/bookmarks.png" alt="Edit or remove bookmarks" steps={[{"text": "Tap a bookmark row to edit its title, URL, or icon; save the changes."}, {"text": "Use the trash button to remove a shortcut, or Add bookmark to create another. Close returns to browsing.", "x": 57.4, "y": 67.0}]} />

## Reset a website session

Open Services → Clear browsing data. Clearing cookies signs you out. Removing cookies or history closes the current page; app documents remain stored.

<GuideScreenshot src="/img/guide/android-tablet/en/browser-data.png" alt="Reset a website session" steps={[{"text": "Select cache, cookies, and/or browser history according to what you want to reset.", "x": 33.5, "y": 49.5}, {"text": "Tap Clear selected data to apply, or Cancel to keep the session.", "x": 55.3, "y": 59.7}]} />

## 14. Inspect or refresh the card

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved cards and PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.

## 15. Language, appearance, demo, and support

Open **Settings** to find Demo mode at the top, followed by cards, saved PINs, language and appearance. Demo mode uses fictional data and produces no valid signatures.

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved cards and PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.

Choose Romanian, English, Russian or the system language, and Light, Dark or System appearance. About shows the installed version and support links. Enable browser PDF stamps when you want visible placement for supported website requests.

<GuideScreenshot src="/img/guide/android-tablet/en/cards-current.png" alt="Cards and readers in Settings" steps={[{"text": "Cards and readers in Settings", "x": 36.3, "y": 29.5}]} />

Settings → Saved cards and PINs lists remembered cards even after disconnection. Forget card removes the identity and any PIN saved on this device for both USB and NFC. The PIN on the card stays the same.

<GuideScreenshot src="/img/guide/android-tablet/en/saved-cards.png" alt="Saved cards and PINs" steps={[{"text": "Choose Forget card and confirm the card name.", "x": 58.9, "y": 55.4}]} />

## Troubleshooting

| Problem | What to do |
| --- | --- |
| Reader missing | Check OTG/USB host support, adapter, and cable; reconnect and grant USB access. |
| Empty or unreadable card | Reinsert it and wait; use Re-read once the reader is ready. |
| Incorrect PIN or remaining-attempt warning | Stop and confirm the selected card and PIN. Repeated attempts can block the card. |
| Timestamp or network error | Check connectivity and the service error, then review completed outputs before retrying. |
| File moved or cloud-only | Download it locally, select it again, or open it from Verify. |
| Website login/download problem | Check the address and connection. Signed-in browser downloads may need an external browser. |

For background on result meanings, see [Signing and verification](/docs/signing). For reader and adapter choices, see [Devices](/devices).

<!-- file-protection-guides -->

If the NFC session is interrupted, keep the card near the antenna until the scan closes. Confirm the selected card and PIN before retrying a failed PIN entry. You can switch to a compatible USB reader in Sign.

## Encrypt a file with a password

Open **Documents**, then choose **More actions → Protect files** in the top toolbar. Choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In eSemnBun 0.2.13 or later, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). By default, use a certificate intended for encryption. **Card public key compatibility** explicitly allows the card’s public RSA key. Exporting it or encrypting a file does not prove that the card can decrypt; the matching card must support the required private-key operation.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"text": "Open the navigation menu and choose Protect files.", "x": 91.0, "y": 13.6}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-password-light.png" alt="Encrypt a file with a password" steps={[{"text": "Choose Encrypt, then select the source file.", "x": 45.7, "y": 26.6}, {"text": "Choose Password and select the AES key size. AES-256 is selected initially.", "x": 60.0, "y": 43.5}, {"text": "Enter and confirm a file password, then choose Encrypt.", "x": 30.6, "y": 57.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-certificate-light.png" alt="Encrypt for an RSA recipient" steps={[{"text": "For a recipient with an RSA encryption key, choose RSA certificate.", "x": 59.3, "y": 31.8}, {"text": "Select the recipient’s public .cer or .der certificate. To encrypt for your own card, connect its reader and choose Read my card.", "x": 38.4, "y": 45.6}, {"text": "Use Card public key compatibility only when the workflow requires the card’s public RSA key.", "x": 48.4, "y": 37.3}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-complete-light.png" alt="Encrypted file saved" steps={[{"text": "Check the saved filename. This output is already in Documents.", "x": 29.6, "y": 27.9}, {"text": "Choose Save as… only if you also want a copy in another location.", "x": 46.4, "y": 84.6}, {"text": "Choose Close to return to the app. The saved file remains in Documents.", "x": 47.1, "y": 89.0}]} />

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

Open **Documents**, then choose **More actions → Protect files** in the top toolbar. Choose **Encrypt** or **Decrypt**, then select a file you can read.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"text": "Open the navigation menu and choose Protect files.", "x": 91.0, "y": 13.6}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-light.png" alt="Decrypt a received file" steps={[{"text": "Choose Decrypt and select the received encrypted file.", "x": 42.5, "y": 26.6}, {"text": "Enter the password supplied by the sender in the Password field.", "x": 30.6, "y": 42.1}, {"text": "Choose Decrypt. The new output is saved in Documents.", "x": 46.7, "y": 89.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-rsa-decrypt-light.png" alt="Decrypt with the recipient’s card" steps={[{"text": "Select the encrypted file. The app identifies the RSA certificate format.", "x": 29.6, "y": 36.8}, {"text": "Connect the card containing the recipient’s matching private key. Choose Read my card, then authorize decryption with its PIN.", "x": 35.5, "y": 46.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-complete-light.png" alt="Decrypted file saved" steps={[{"text": "Check the saved filename. This output is already in Documents.", "x": 29.6, "y": 27.9}, {"text": "Choose Save as… only if you also want a copy in another location.", "x": 46.4, "y": 84.6}, {"text": "Choose Close to return to the app. The saved file remains in Documents.", "x": 47.1, "y": 89.0}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
