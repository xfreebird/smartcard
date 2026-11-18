---
title: iPhone
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# iPhone

Starting with eSemnBun 0.2.12, compatible iPhones and Android devices can sign with a compatible contactless card over NFC. A compatible USB reader remains available. Use an active Moldovan electronic identity card with a valid signing certificate and its signing PIN. Install or update through your device’s channel on [Downloads](/downloads).

For USB, connect the reader using the appropriate [adapter](/devices). Lightning devices may need a powered Lightning adapter.

## Connect the reader and insert your card

Use an active Moldovan electronic identity card with a valid signing certificate and its signing PIN.

### Sign over NFC

Starting with eSemnBun 0.2.12, compatible iPhones and Android devices can sign with a compatible contactless card over NFC. A compatible USB reader remains available. Choose **With your phone · NFC** in **Sign** and add your document. Tap **Continue**, review the request and confirm your signing PIN. Hold the card near the phone’s NFC antenna until the app reports completion.

<GuideScreenshot src="/img/guide/iphone/en/nfc-sign.png" alt="The Sign screen with NFC selected" steps={[{"text": "The Sign screen with NFC selected", "x": 36, "y": 56}]} />

### Sign with a USB card reader

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing.

<GuideScreenshot src="/img/guide/iphone/en/reader-sign.png" alt="The Sign screen with a USB card reader selected" steps={[{"text": "The Sign screen with a USB card reader selected", "x": 38, "y": 59}]} />

## Choose the identity that will sign

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved cards and PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.

<GuideScreenshot src="/img/guide/iphone/en/cards-current.png" alt="Inspect the selected identity before signing." steps={[{"text": "Inspect the selected identity before signing.", "x": 29, "y": 34}]} />

<GuideScreenshot src="/img/guide/iphone/en/batch-current.png" alt="Review the selected document before tapping Continue." steps={[{"text": "Review the selected document before tapping Continue.", "x": 37, "y": 28}]} />

## Add documents and choose a signature format

### Choose how to sign

Choose **With your phone · NFC** in **Sign** and add your document. Tap **Continue**, review the request and confirm your signing PIN. Hold the card near the phone’s NFC antenna until the app reports completion.

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing. With USB, keep the reader connected and the card inserted until the signature and timestamp are complete.

Open Sign and choose files from Files or a cloud provider. Download cloud-only documents first if access fails. You can also send files from another app through its share sheet to the eSemnBun extension. Expand the file list, inspect each name, remove unintended files from its options, and choose the requested format. PDFs use PAdES-T; other files use XAdES. Detached XML must travel with its unchanged original. XAdES-BES has no timestamp, T adds one, and C adds certificate/status references. Enveloping XML includes its source content. Timestamped signing requires the public trust services.

<GuideScreenshot src="/img/guide/iphone/en/sign.png" alt="Confirm the selected holder before signing." steps={[{"text": "Confirm the selected holder before signing.", "x": 45, "y": 28}, {"text": "Choose files, or add more documents to the current queue.", "x": 50, "y": 69}, {"text": "Expand the queue, then open an individual file’s options to choose its format, stamp or removal.", "x": 78, "y": 53}, {"text": "Review the complete queue, then tap the floating Sign button near the bottom.", "x": 68, "y": 85.5}]} />

## Place a visible stamp in a PDF

Open a queued PDF’s options and choose Add/Edit stamp. A visible stamp is optional artwork; the cryptographic signature remains the actual signing proof. Position the stamp away from existing text.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/iphone/en/stamp.png" alt="Drag the stamp to move it; drag its corner handles to resize it." steps={[{"text": "Drag the stamp to move it; drag its corner handles to resize it.", "x": 30, "y": 61}, {"text": "Select the page and choose Off, One page or All pages.", "x": 25, "y": 86}, {"text": "Optionally apply the placement to all queued PDFs, then choose Apply.", "x": 87, "y": 12}]} />

## Review the request and authorize signing

For website requests, inspect the requesting origin and the whole document list before allowing the operation. Cancel unexpected requests. For a local batch, review the queued documents and PIN sheet. Each new batch needs approval; a batch session covers only the listed documents and selected card.

<GuideScreenshot src="/img/guide/iphone/en/consent.png" alt="Check the requesting website and intended operation." steps={[{"text": "Check the requesting website and intended operation.", "x": 16, "y": 52}, {"text": "Review all documents; allow only a request you initiated.", "x": 86, "y": 91}]} />
<GuideScreenshot src="/img/guide/iphone/en/pin.png" alt="Check the holder and selected filenames." steps={[{"text": "Check the holder and selected filenames.", "x": 49, "y": 23}, {"text": "Enter the correct QSCD signing PIN in the protected field.", "x": 8, "y": 34}, {"text": "Use Remember PIN only on a trusted personal device; later access requires the offered device authentication.", "x": 86, "y": 40}, {"text": "Choose Sign to authorize, or Cancel to stop.", "x": 88, "y": 63}]} />

## Wait for completion and save the signed output

For NFC, hold the card in place until the app completes the scan. For USB, keep the reader connected and the card inserted until signing and timestamping finish. Completion is shown separately from the input queue. Use the available result action, or open Documents and select the completed file, then Share to save it in Files or send it to another app. Share the signed output, not the unsigned source; include the original with detached XML.

<GuideScreenshot src="/img/guide/iphone/en/progress.png" alt="Wait for the current signing stage to finish without removing the card." steps={[{"text": "Wait for the current signing stage to finish without removing the card.", "x": 10, "y": 45}]} />
<GuideScreenshot src="/img/guide/iphone/en/success.png" alt="Select the completed file to open it. Use Share beside its name to send a copy." steps={[{"text": "Select the completed file to open it. Use Share beside its name to send a copy.", "x": 39, "y": 29}]} />

## Recover from a failed document

Read the error on the affected item. Keep outputs that already completed and correct the input or connection before starting another deliberate batch. There is no automatic PIN retry. If the PIN is incorrect, stop and confirm the PIN and selected card; after three incorrect attempts the card can be blocked. The app cannot unblock it. Reconnecting cannot repair an invalid PDF.

<GuideScreenshot src="/img/guide/iphone/en/file-error.png" alt="Read the error on the failed item before making another attempt." steps={[{"text": "Read the error on the failed item before making another attempt.", "x": 50, "y": 72}]} />

## Verify a signed PDF and inspect its certificate

Verification needs a file, not a reader or PIN. In Verify, choose the signed PDF or XML. Expand each signature, then its certificate and technical sections. Check every signature when a file is countersigned. Offline results distinguish document integrity, cryptographic signature, embedded trust and timestamp information; they are not a current revocation check.

<GuideScreenshot src="/img/guide/iphone/en/verify-current.png" alt="The Verify screen" steps={[{"text": "The Verify screen", "x": 50, "y": 86}]} />

<GuideScreenshot src="/img/guide/iphone/en/verify.png" alt="Read the document verdict first. Expand each signer to inspect that signature." steps={[{"text": "Read the document verdict first. Expand each signer to inspect that signature.", "x": 34, "y": 37}]} />
<GuideScreenshot src="/img/guide/iphone/en/certificate.png" alt="Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint." steps={[{"text": "Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint.", "x": 40, "y": 72}]} />

<GuideScreenshot src="/img/guide/iphone/en/technical.png" alt="Expand Technical details under a signature to read the verification report. Select the same row again to collapse it." steps={[{"text": "Expand Technical details under a signature to read the verification report. Select the same row again to collapse it.", "x": 35, "y": 65}]} />

## Supply the original for a detached XML signature

A detached XML signature cannot prove the original document’s digest until its unchanged source is available. In the incomplete result, use Choose originals and select the matching original files in the system picker. Wait for the result to update. Selecting another file changes the evidence; a missing original alone does not prove modification.

<GuideScreenshot src="/img/guide/iphone/en/incomplete.png" alt="Read which original is missing." steps={[{"text": "Read which original is missing.", "x": 43, "y": 25}, {"text": "Choose the unchanged original files and wait for the updated check.", "x": 45, "y": 44}]} />

## Understand an unexpected verification result

Invalid means a signature or document-integrity check failed. Unconfirmed trust means the embedded chain is not confirmed; it is different from a proven altered document. Unsigned or unrecognized means no supported signature was found. Do not treat the filename or a green file icon as proof. An inaccessible saved file is unavailable, not necessarily unsigned.

<GuideScreenshot src="/img/guide/iphone/en/invalid.png" alt="Read the failed checks; obtain the correct signed file or unchanged original from its sender." steps={[{"text": "Read the failed checks; obtain the correct signed file or unchanged original from its sender.", "x": 40, "y": 25}]} />
<GuideScreenshot src="/img/guide/iphone/en/untrusted.png" alt="Read the trust warning separately from integrity and signature checks." steps={[{"text": "Read the trust warning separately from integrity and signature checks.", "x": 49, "y": 27}]} />
<GuideScreenshot src="/img/guide/iphone/en/unsigned.png" alt="Confirm that you chose the signed output, then inspect whether any supported signature was found." steps={[{"text": "Confirm that you chose the signed output, then inspect whether any supported signature was found.", "x": 48, "y": 27}]} />

## Find a saved document and open its signing details

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Open Documents and select a saved item. The signing-details modal uses the same verification presentation as Verify and does not replace the current Verify workspace. Preview opens the content; Share exports the chosen file. If a file has moved or is unreadable, choose it again from its real location.

<GuideScreenshot src="/img/guide/iphone/en/documents.png" alt="Select a filename to inspect its signatures. Use the adjacent actions to preview or share the file." steps={[{"text": "Select a filename to inspect its signatures. Use the adjacent actions to preview or share the file.", "x": 35, "y": 40}]} />
<GuideScreenshot src="/img/guide/iphone/en/details.png" alt="Expand a signer to see the checks. Use Preview or Share below the report." steps={[{"text": "Expand a signer to see the checks. Use Preview or Share below the report.", "x": 28, "y": 51}]} />

## Clear recent history while keeping saved documents

In Documents, switch to History, choose Clear list and confirm. This clears the recent-operations list, not signed files or the saved Documents collection. Return to Documents to find the retained outputs. To delete an exported file, manage it in Files or its storage provider.

<GuideScreenshot src="/img/guide/iphone/en/history.png" alt="Find the filename, outcome and date in History. Switch to Saved documents to act on an output file." steps={[{"text": "Find the filename, outcome and date in History. Switch to Saved documents to act on an output file.", "x": 73, "y": 29}]} />

## Log in or sign on a website

Open Browser, use Open an address or a saved service, and navigate to the site’s electronic-ID login or signing option. The browser requests desktop presentation for compatible identity-login flows. Keep eSemnBun foregrounded; the mobile connection stops when the app is backgrounded. Check the service and request before approving. The illustration keeps network and hardware inactive, so website navigation controls may be disabled.

<GuideScreenshot src="/img/guide/iphone/en/browser.png" alt="Open Browser and check the connection status." steps={[{"text": "Open Browser and check the connection status.", "x": 8, "y": 15}, {"text": "Use the address control to enter the service URL.", "x": 88, "y": 9}, {"text": "Use Services/Bookmarks to open, add or manage a saved address.", "x": 77, "y": 9}, {"text": "Use back, forward and reload while browsing.", "x": 18, "y": 87}]} />

To add a bookmark, open Services/Bookmarks → Add bookmark, then set its title, URL and icon and save it. Use Manage bookmarks to edit or remove one. To reset a session, open Clear browser data, select cache, cookies and/or history, then confirm. Clearing cookies can sign you out; it does not clear Documents or saved PINs. A website-side error needs the service’s own support, not repeated PIN attempts.

## Change language, appearance and privacy preferences

Open **Settings** to find Demo mode at the top, followed by cards, saved cards and PINs, language and appearance. Demo mode uses fictional data and produces no valid signatures.

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved cards and PINs** to manage stored PINs. The same remembered card and PIN are used for NFC and USB.

Choose Romanian, English, Russian or the system language, and Light, Dark or System appearance. About shows the installed version and support links. Enable browser PDF stamps when you want visible placement for supported website requests.

<GuideScreenshot src="/img/guide/iphone/en/cards-current.png" alt="Cards and readers in Settings" steps={[{"text": "Cards and readers in Settings", "x": 29, "y": 34}]} />

<GuideScreenshot src="/img/guide/iphone/en/saved-cards.png" alt="Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device." steps={[{"text": "Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device.", "x": 80, "y": 30}]} />

Deleting a saved PIN removes the copy on this device. It does not change or unblock the card PIN.

## Use Shortcuts, Siri, Spotlight and Handoff

In Apple Shortcuts, create a shortcut, add an action, search eSemnBun and choose Open Documents, Prepare PDF for Signing or Verify PDF. Supply a PDF to the prepare/verify actions. Prepare opens eSemnBun with the PDF queued; you still review and approve signing in the foreground. Verify returns an offline result and opens the details. PDF input is limited to 32 MiB. Run a configured shortcut from Shortcuts or an available Siri phrase; Siri never receives your card PIN.


1. Open Shortcuts, add an action and search for eSemnBun.
2. Choose Open Documents, Prepare PDF for Signing or Verify PDF; provide a PDF when required.
3. Run the shortcut. Review the prepared queue or offline result in eSemnBun; signing still needs your approval.

For document search, enable Find signed documents in Siri and Spotlight in Settings, complete a signed app-owned PDF/XML, then search its filename in Spotlight. The opt-in index exposes filenames and dates, not document bodies, PINs or certificate identity. Current system Open/Search schemas require supported OS/SDK features; suggestions depend on your device, language and system settings. With Handoff enabled on compatible Apple devices, open Documents on one device and use its continuation affordance on the other. Handoff resumes Documents navigation; it does not transfer a PDF, PIN or card session. Siri, Spotlight and Handoff availability should be checked on your installed build; these documentation captures demonstrate app controls rather than a live cross-device result.
<GuideScreenshot src="/img/guide/iphone/en/settings.png" alt="Enable document discovery only if you want signed filenames and dates available to Siri and Spotlight." steps={[{"text": "Enable document discovery only if you want signed filenames and dates available to Siri and Spotlight.", "x": 86, "y": 65}, {"text": "After creating a signed app-owned document, search its filename in Spotlight and open the result."}, {"text": "For Handoff, open Documents on one compatible device and choose its continuation affordance on the other."}]} />

## Use a smaller or wider iPhone window

Portrait uses compact tabs. Rotate the phone or expand a supported device/window when you need more space for the card and files. Scroll to reach document options and the PIN review when the keyboard reduces available space. Device posture and rotation support follow iOS; do not assume a foldable posture is identical to a standard landscape phone.

## Get help without sharing secrets

For no reader, check the cable, adapter and power. For an empty reader, reinsert the card and wait. For a repeated card error, stop the operation before reconnecting. For a locked PIN, contact the official card provider. When requesting [support](/support), include app/iOS versions, reader and adapter models and reproduction steps with a fictional sample. Never send your PIN, private identity details or confidential documents.

If the NFC session is interrupted, keep the card near the antenna until the scan closes. Confirm the selected card and PIN before retrying a failed PIN entry. You can switch to a compatible USB reader in Sign.

## Other guides

[iPhone](./ios.md) · [iPad](./ipad.md) · [macOS](./macos.md) · [Android](./android.md) · [Linux](./linux.md)

<!-- file-protection-guides -->


## Encrypt a file with a password

In **Documents**, select the **Protect files** shield in the toolbar. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In version 0.2.13, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). The Moldovan ID signing certificate cannot decrypt these files.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="In Documents, open Protect files using the shield in the toolbar." steps={[{"text": "In Documents, open Protect files using the shield in the toolbar.", "x": 90, "y": 10}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-password-light.png" alt="Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt." steps={[{"text": "Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt.", "x": 81, "y": 55}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-certificate-light.png" alt="Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN." steps={[{"text": "Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN.", "x": 43, "y": 63}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 68}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

In **Documents**, select the **Protect files** shield in the toolbar. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file in version 0.2.13, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="In Documents, open Protect files using the shield in the toolbar." steps={[{"text": "In Documents, open Protect files using the shield in the toolbar.", "x": 90, "y": 10}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-light.png" alt="Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt." steps={[{"text": "Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt.", "x": 83, "y": 48}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-rsa-decrypt.png" alt="For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN." steps={[{"text": "For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN.", "x": 30, "y": 62}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 68}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
