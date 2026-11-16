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

Check the holder, document names, format, and requesting website when one is shown. Current Android builds ask for the PIN for each new approval; saving a PIN is not offered. Never send your PIN in a support request.

<GuideScreenshot src="/img/guide/android-tablet/en/pin.png" alt="Review and authorize" steps={[{"text": "Enter the selected card’s signing PIN in the protected field. The approval covers only the listed request.", "x": 31.8, "y": 54.8}, {"text": "Tap Sign. Keep the app and reader available while the batch completes. Cancel if the request is unexpected.", "x": 60.9, "y": 62.5}]} />

## Follow signing progress

The progress card names the active stage: connecting, authentication, certificate read, PIN verification, signing, timestamping, revocation information, or writing the output. A stage can take time while an external service responds.

<GuideScreenshot src="/img/guide/android-tablet/en/sign-progress.png" alt="Follow signing progress" steps={[{"text": "After approval, watch the active stage and keep the reader connected. Wait for a completed result before opening or sharing the output.", "x": 8.0, "y": 45.5}, {"text": "If the operation reports an error, follow that message. Do not enter the PIN repeatedly or start another batch while the current request is active."}]} />

## Recover from a failed item

An error belongs to the affected file. Review the remaining rows and completed outputs; a failure is not evidence that every document failed. This illustration shows a timestamp-service error on one item in a mixed batch.

<GuideScreenshot src="/img/guide/android-tablet/en/sign-failure.png" alt="Recover from a failed item" steps={[{"text": "Read the message under the failed file. For a timestamp/network error, restore connectivity or wait for the service to recover. For an unreadable input, replace it with a valid source file.", "x": 45.2, "y": 27.6}, {"text": "Keep successful outputs, correct the cause, and deliberately start a new signing attempt only for the files that still need it. There is no automatic PIN retry; after a wrong-PIN warning, stop and confirm the card and PIN before any further attempt."}]} />

## 6. Open, save, or share the result

On Android 10 and later, ordinary signed output is saved under Downloads/eSemnBun. Keep both the XML and original document for detached XAdES. If one file fails, read its error and check completed files before starting another batch.

<GuideScreenshot src="/img/guide/android-tablet/en/results.png" alt="Open, save, or share the result" steps={[{"text": "Tap Open beside a completed file to open it in a compatible viewer.", "x": 85.4, "y": 24.5}, {"text": "In Documents → Saved documents, use the file’s menu for Open, Verify, Share, or Save as… when file-provider access is available. Save as lets you choose another location."}, {"text": "Clear results hides this completion list. Your saved outputs remain available in Documents.", "x": 84.9, "y": 18.7}]} />

## 7. Check a signed document

Verification does not require the card or PIN. A green result refers to the checks shown, not to the filename or the presence of a visible stamp.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-current.png" alt="The Verify screen" steps={[{"text": "The Verify screen", "x": 53, "y": 28}]} />

## Understand an invalid signature

Invalid means that document integrity or the cryptographic signature check failed. It can indicate changed bytes or a damaged/incorrect signature. A valid-looking stamp, familiar filename, or recognized author does not override this result.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-invalid.png" alt="Understand an invalid signature" steps={[{"text": "Read Invalid signature and the failed check. Do not treat this copy as verified.", "x": 35.0, "y": 44.0}, {"text": "Expand Technical details, compare with the sender’s original signed output, and request a fresh intact copy if needed. Check every listed signature when the document contains more than one.", "x": 46.8, "y": 76.9}]} />

## Understand an unconfirmed trust chain

Cannot be confirmed is distinct from Invalid signature. In this example the signature and document integrity pass, but the certificate is outside the recognized MDQSign chain. Missing original documents can also produce an unconfirmed result, with a different explanation.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-unconfirmed.png" alt="Understand an unconfirmed trust chain" steps={[{"text": "Read the reason below Cannot be confirmed and inspect the separate Integrity, Signature, and Trust chain checks.", "x": 35.0, "y": 44.0}, {"text": "Inspect certificate details to identify the signer and issuer. Establish the required trust with the sender or receiving service before relying on the document. Offline integrity checks do not establish current revocation status or guarantee legal acceptance.", "x": 47.3, "y": 71.8}]} />

## Recognize an unsigned or unsupported file

No signature means the app found no signature it can read in the selected file. You may have selected the unsigned input, or the file may use an unsupported signature format. A picture of a signature is not an electronic signature.

<GuideScreenshot src="/img/guide/android-tablet/en/verify-none.png" alt="Recognize an unsigned or unsupported file" steps={[{"text": "Read No signature, then check that you selected the completed signed PDF or the XML signature rather than its unsigned original.", "x": 35.0, "y": 44.0}, {"text": "Choose the correct signed output and verify again. Ask the sender for a supported PDF/XML signature if the result remains unchanged.", "x": 47.1, "y": 26.0}]} />

## 8. Inspect certificate and technical details

An invalid signature differs from an unconfirmed trust chain. Missing originals or unavailable trust information can prevent a complete conclusion. Inspect the separate checks before relying on a document.

<GuideScreenshot src="/img/guide/android-tablet/en/certificate.png" alt="Inspect certificate and technical details" steps={[{"text": "Expand Certificate details to inspect the signer, issuer, serial number, public key, and fingerprint. Scroll within the screen if needed.", "x": 47.3, "y": 71.1}, {"text": "Expand Technical details for the checks behind the verdict; collapse it when finished.", "x": 46.8, "y": 88.5}]} />

## 9. Supply the original for detached XML

Detached XML contains a reference to the signed document. Its original bytes are needed to check the document digest.

<GuideScreenshot src="/img/guide/android-tablet/en/original.png" alt="Supply the original for detached XML" steps={[{"text": "Tap Choose the signed document and select the exact original named in the message.", "x": 33.2, "y": 55.8}, {"text": "Wait for the refreshed result. A modified or different original will not match the signature. Share the XML together with the matching original."}]} />

## 10. Find signed documents

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Documents contains a signed-output library and a separate activity history. A saved entry is a shortcut to a file, not a substitute for a backup.

<GuideScreenshot src="/img/guide/android-tablet/en/documents.png" alt="Find signed documents" steps={[{"text": "Open Documents and select Saved documents.", "x": 31.8, "y": 14.7}, {"text": "Tap a document row to open its signing-details modal. The app checks the current file again.", "x": 34.2, "y": 25.1}]} />

## 11. Read signing details without losing your list

The modal’s verdict is a fresh verification, not just a historical “signed” label. An unavailable file reports an access error; reselect a moved file in Verify.

<GuideScreenshot src="/img/guide/android-tablet/en/details.png" alt="Read signing details without losing your list" steps={[{"text": "Review the verdict and expand the certificate or technical details, just as in Verify. Supply an original if detached XML requests it.", "x": 44.3, "y": 64.6}, {"text": "Tap Close to return to the same signed-document list.", "x": 65.1, "y": 30.0}]} />

## 12. Clear history while keeping documents

History lists document operations and website requests. Clearing it does not clear Saved documents or delete signed files on storage.

<GuideScreenshot src="/img/guide/android-tablet/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Choose History in Documents and review the recent actions.", "x": 41.8, "y": 14.7}, {"text": "Tap Clear the list and confirm, then return to Saved documents to access saved outputs.", "x": 65.2, "y": 20.5}]} />

## 13. Sign on a website

Use only a service whose address and request you recognize. The app is independent from the Moldovan government; official sources are linked in Browser and About. Website appearance can differ from these illustrations.

<GuideScreenshot src="/img/guide/android-tablet/en/browser.png" alt="Sign on a website" steps={[{"text": "Open Browser and enable Browser connection for a service in an external browser on this same device. Allow its notification request when prompted.", "x": 34.2, "y": 50.8}, {"text": "Alternatively, tap Open in app browser. Enter a service address or choose it from Services. The embedded browser uses desktop presentation for compatible identity login.", "x": 46.9, "y": 69.5}, {"text": "Enable visible website stamps if needed. Check the card and requesting site in every approval, then enter your PIN.", "x": 31.8, "y": 44.3}]} />

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

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.

## 15. Language, appearance, demo, and support

Open **Settings** to find Demo mode at the top, followed by cards, saved PINs, language and appearance. Demo mode uses fictional data and produces no valid signatures.

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.

Choose Romanian, English, Russian or the system language, and Light, Dark or System appearance. About shows the installed version and support links. Enable browser PDF stamps when you want visible placement for supported website requests.

<GuideScreenshot src="/img/guide/android-tablet/en/cards-current.png" alt="Cards and readers in Settings" steps={[{"text": "Cards and readers in Settings", "x": 41, "y": 38}]} />

Deleting a saved PIN removes the copy on this device. It does not change or unblock the card PIN.

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

Open the **More** menu in the navigation bar and choose **Protect files**. Choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"x": 70, "y": 15, "text": "Open the navigation menu and choose Protect files."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-password-light.png" alt="Encrypt a file with a password" start={2} steps={[{"x": 30, "y": 21, "text": "Choose Encrypt."}, {"x": 30, "y": 33, "text": "Choose the source file."}, {"x": 25, "y": 59, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 50, "y": 87, "text": "Choose Encrypt. The encrypted copy is saved in Documents."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-complete-light.png" alt="Encrypted file saved" start={6} steps={[{"x": 25, "y": 33, "text": "Check the saved filename. This output is already in Documents."}, {"x": 25, "y": 83, "text": "Choose Save as… only if you also want a copy in another location."}, {"x": 75, "y": 88, "text": "Choose Close to return to the app. The saved file remains in Documents."}]} />

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

Open the **More** menu in the navigation bar and choose **Protect files**. Choose **Encrypt** or **Decrypt**, then select a file you can read.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/android-tablet/en/protect-menu-light.png" alt="Open file protection" steps={[{"x": 70, "y": 15, "text": "Open the navigation menu and choose Protect files."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-light.png" alt="Decrypt a received file" start={2} steps={[{"x": 30, "y": 21, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 25, "y": 59, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 87, "text": "Choose Decrypt. The new output is saved in Documents."}]} />

<GuideScreenshot src="/img/guide/android-tablet/en/protect-decrypt-complete-light.png" alt="Decrypted file saved" start={5} steps={[{"x": 25, "y": 33, "text": "Check the saved filename. This output is already in Documents."}, {"x": 25, "y": 83, "text": "Choose Save as… only if you also want a copy in another location."}, {"x": 75, "y": 88, "text": "Choose Close to return to the app. The saved file remains in Documents."}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The result is saved automatically in the app’s private storage and appears in **Documents → Saved documents**. Choose **Close** when finished, or **Save as…** to export it with the Android file picker. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
