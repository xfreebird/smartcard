---
title: iPad
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# iPad

Install eSemnBun through the available Apple distribution channel from [Downloads](/downloads). Launch the installed app. You need a supported active electronic ID, its correct signing PIN, a compatible wired reader and the appropriate [adapter](/devices). USB-C devices need a suitable USB connection; Lightning devices may need a powered Lightning adapter. NFC signing is not supported.

## Connect the reader and insert your card

Use an active Moldovan electronic identity card with a valid signing certificate and its signing PIN.

### Sign with a USB card reader

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing.

<GuideScreenshot src="/img/guide/ipad/en/reader-sign.png" alt="The Sign screen with a USB card reader selected" steps={[{"text": "The Sign screen with a USB card reader selected", "x": 40, "y": 39}]} />

## Choose the identity that will sign

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved cards and PINs** to manage stored PINs.

<GuideScreenshot src="/img/guide/ipad/en/cards-current.png" alt="Inspect the selected identity before signing." steps={[{"text": "Inspect the selected identity before signing.", "x": 15, "y": 25}]} />

<GuideScreenshot src="/img/guide/ipad/en/batch-current.png" alt="Review the selected document before tapping Continue." steps={[{"text": "Review the selected document before tapping Continue.", "x": 38, "y": 19}]} />

<GuideScreenshot src="/img/guide/ipad/en/consent-current.png" alt="Review and approve the request in the PIN sheet." steps={[{"text": "Review and approve the request in the PIN sheet.", "x": 50, "y": 27}]} />

## Add documents and choose a signature format

### Choose how to sign

For USB, connect the reader with the appropriate [adapter](/devices), select **With a card reader** in **Sign**, and insert the card. When several cards are connected, select the intended holder before continuing. With USB, keep the reader connected and the card inserted until the signature and timestamp are complete.

Open Sign and choose files from Files or a cloud provider. Download cloud-only documents first if access fails. You can also send files from another app through its share sheet to the eSemnBun extension. Expand the file list, inspect each name, remove unintended files from its options, and choose the requested format. PDFs use PAdES-T; other files use XAdES. Detached XML must travel with its unchanged original. XAdES-BES has no timestamp, T adds one, and C adds certificate/status references. Enveloping XML includes its source content. Timestamped signing requires the public trust services.

<GuideScreenshot src="/img/guide/ipad/en/sign.png" alt="Confirm the selected holder before signing." steps={[{"text": "Confirm the selected holder before signing.", "x": 20, "y": 16}, {"text": "Choose files, or add more documents to the current queue.", "x": 85, "y": 30}, {"text": "Open an individual file’s options to choose its format, stamp or removal.", "x": 93, "y": 16}, {"text": "Review the complete queue, then tap the floating Sign button near the bottom.", "x": 85, "y": 95}]} />

## Place a visible stamp in a PDF

Open a queued PDF’s options and choose Add/Edit stamp. A visible stamp is optional artwork; the cryptographic signature remains the actual signing proof. Position the stamp away from existing text.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/ipad/en/stamp.png" alt="Drag the stamp to move it; drag its corner handles to resize it." steps={[{"text": "Drag the stamp to move it; drag its corner handles to resize it.", "x": 42, "y": 55}, {"text": "Select the page and choose Off, One page or All pages.", "x": 25, "y": 70}, {"text": "Optionally apply the placement to all queued PDFs, then choose Apply.", "x": 79, "y": 26}]} />

## Review the request and authorize signing

For website requests, inspect the requesting origin and the whole document list before allowing the operation. Cancel unexpected requests. For a local batch, review the queued documents and PIN sheet. Each new batch needs approval; a batch session covers only the listed documents and selected card.

<GuideScreenshot src="/img/guide/ipad/en/consent.png" alt="Check the requesting website and intended operation." steps={[{"text": "Check the requesting website and intended operation.", "x": 20, "y": 50}, {"text": "Review all documents; allow only a request you initiated.", "x": 79, "y": 74}]} />
<GuideScreenshot src="/img/guide/ipad/en/pin.png" alt="Check the holder and selected filenames." steps={[{"text": "Check the holder and selected filenames.", "x": 50, "y": 21}, {"text": "Enter the correct QSCD signing PIN in the protected field.", "x": 30, "y": 28}, {"text": "Use Remember PIN only on a trusted personal device; later access requires the offered device authentication.", "x": 73, "y": 32.5}, {"text": "Choose Sign to authorize, or Cancel to stop.", "x": 94, "y": 70}]} />

## Wait for completion and save the signed output

Keep the reader and card connected while signing and obtaining the timestamp. Completion is shown separately from the input queue. Use the available result action, or open Documents and select the completed file, then Share to save it in Files or send it to another app. Share the signed output, not the unsigned source; include the original with detached XML.

<GuideScreenshot src="/img/guide/ipad/en/progress.png" alt="Wait for the current signing stage to finish without removing the card." steps={[{"text": "Wait for the current signing stage to finish without removing the card.", "x": 9, "y": 26.5}]} />
<GuideScreenshot src="/img/guide/ipad/en/success.png" alt="Select the completed file to open it. Use Share beside its name to send a copy." steps={[{"text": "Select the completed file to open it. Use Share beside its name to send a copy.", "x": 31, "y": 20}]} />

## Recover from a failed document

Read the error on the affected item. Keep outputs that already completed and correct the input or connection before starting another deliberate batch. There is no automatic PIN retry. If the PIN is incorrect, stop and confirm the PIN and selected card; after three incorrect attempts the card can be blocked. The app cannot unblock it. Reconnecting cannot repair an invalid PDF.

<GuideScreenshot src="/img/guide/ipad/en/file-error.png" alt="Read the error on the failed item before making another attempt." steps={[{"text": "Read the error on the failed item before making another attempt.", "x": 47, "y": 19}]} />

## Verify a signed PDF and inspect its certificate

Verification needs a file, not a reader or PIN. In Verify, choose the signed PDF or XML. Expand each signature, then its certificate and technical sections. Check every signature when a file is countersigned. Offline results distinguish document integrity, cryptographic signature, embedded trust and timestamp information; they are not a current revocation check.

<GuideScreenshot src="/img/guide/ipad/en/verify-current.png" alt="The Verify screen" steps={[{"text": "The Verify screen", "x": 50, "y": 94}]} />

<GuideScreenshot src="/img/guide/ipad/en/verify.png" alt="Read the document verdict first. Expand each signer to inspect that signature." steps={[{"text": "Read the document verdict first. Expand each signer to inspect that signature.", "x": 19, "y": 38}, {"text": "Use Clear results in the navigation bar to clear this verification session.", "x": 96, "y": 6.8}]} />
<GuideScreenshot src="/img/guide/ipad/en/certificate.png" alt="Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint." steps={[{"text": "Open Certificate details to inspect the signer’s public certificate, issuer and fingerprint.", "x": 21, "y": 53}]} />

<GuideScreenshot src="/img/guide/ipad/en/technical.png" alt="Expand Technical details under a signature to read the verification report. Select the same row again to collapse it." steps={[{"text": "Expand Technical details under a signature to read the verification report. Select the same row again to collapse it.", "x": 20, "y": 58}]} />

## Supply the original for a detached XML signature

A detached XML signature cannot prove the original document’s digest until its unchanged source is available. In the incomplete result, use Choose originals and select the matching original files in the system picker. Wait for the result to update. Selecting another file changes the evidence; a missing original alone does not prove modification.

<GuideScreenshot src="/img/guide/ipad/en/incomplete.png" alt="Read which original is missing." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read which original is missing.", "x": 23, "y": 24}, {"text": "Choose the unchanged original files and wait for the updated check.", "x": 25, "y": 40}]} />

## Understand an unexpected verification result

Invalid means a signature or document-integrity check failed. Unconfirmed trust means the embedded chain is not confirmed; it is different from a proven altered document. Unsigned or unrecognized means no supported signature was found. Do not treat the filename or a green file icon as proof. An inaccessible saved file is unavailable, not necessarily unsigned.

<GuideScreenshot src="/img/guide/ipad/en/invalid.png" alt="Read the failed checks; obtain the correct signed file or unchanged original from its sender." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read the failed checks; obtain the correct signed file or unchanged original from its sender.", "x": 23, "y": 24}]} />
<GuideScreenshot src="/img/guide/ipad/en/untrusted.png" alt="Read the trust warning separately from integrity and signature checks." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read the trust warning separately from integrity and signature checks.", "x": 47, "y": 27}]} />
<GuideScreenshot src="/img/guide/ipad/en/unsigned.png" alt="Confirm that you chose the signed output, then inspect whether any supported signature was found." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Confirm that you chose the signed output, then inspect whether any supported signature was found.", "x": 33, "y": 27}]} />

## Find a saved document and open its signing details

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Open Documents and select a saved item. The signing-details modal uses the same verification presentation as Verify and does not replace the current Verify workspace. Preview opens the content; Share exports the chosen file. If a file has moved or is unreadable, choose it again from its real location.

<GuideScreenshot src="/img/guide/ipad/en/documents.png" alt="Select a filename to inspect its signatures. Use the adjacent actions to preview or share the file." steps={[{"text": "Select a filename to inspect its signatures. Use the adjacent actions to preview or share the file.", "x": 19, "y": 35}]} />
<GuideScreenshot src="/img/guide/ipad/en/details.png" alt="Expand a signer to see the checks. Use Preview or Share below the report." steps={[{"text": "Expand a signer to see the checks. Use Preview or Share below the report.", "x": 32.0, "y": 54.6}]} />

## Clear recent history while keeping saved documents

In Documents, switch to History, choose Clear list and confirm. This clears the recent-operations list, not signed files or the saved Documents collection. Return to Documents to find the retained outputs. To delete an exported file, manage it in Files or its storage provider.

<GuideScreenshot src="/img/guide/ipad/en/history.png" alt="Find the filename, outcome and date in History. Switch to Saved documents to act on an output file." steps={[{"text": "Find the filename, outcome and date in History. Switch to Saved documents to act on an output file.", "x": 74, "y": 22}]} />

## Log in or sign on a website

Open Browser, use Open an address or a saved service, and navigate to the site’s electronic-ID login or signing option. The browser requests desktop presentation for compatible identity-login flows. Keep eSemnBun foregrounded; the mobile connection stops when the app is backgrounded. Check the service and request before approving. The illustration keeps network and hardware inactive, so website navigation controls may be disabled.

<GuideScreenshot src="/img/guide/ipad/en/browser.png" alt="Open Browser and check the connection status." steps={[{"text": "Open Browser and check the connection status.", "x": 5, "y": 8}, {"text": "Use the address control to enter the service URL.", "x": 97, "y": 5}, {"text": "Use Services/Bookmarks to open, add or manage a saved address.", "x": 91, "y": 5}, {"text": "Use back, forward and reload while browsing.", "x": 6, "y": 97}]} />

To add a bookmark, open Services/Bookmarks → Add bookmark, then set its title, URL and icon and save it. Use Manage bookmarks to edit or remove one. To reset a session, open Clear browser data, select cache, cookies and/or history, then confirm. Clearing cookies can sign you out; it does not clear Documents or saved PINs. A website-side error needs the service’s own support, not repeated PIN attempts.

## Change language, appearance and privacy preferences

Open **Settings** to find Demo mode at the top, followed by cards, saved cards and PINs, language and appearance. Demo mode uses fictional data and produces no valid signatures.

Open **Settings → Cards and readers** to inspect a connected card. On the Sign screen, the top-right information button opens card details. Use **Settings → Saved cards and PINs** to manage stored PINs.

Choose Romanian, English, Russian or the system language, and Light, Dark or System appearance. About shows the installed version and support links. Enable browser PDF stamps when you want visible placement for supported website requests.

<GuideScreenshot src="/img/guide/ipad/en/cards-current.png" alt="Cards and readers in Settings" steps={[{"text": "Cards and readers in Settings", "x": 15, "y": 25}]} />

<GuideScreenshot src="/img/guide/ipad/en/saved-cards.png" alt="Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device." steps={[{"text": "Settings lists saved cards even after the reader is disconnected. Forget card removes that identity and its saved PIN from this device.", "x": 78, "y": 38}]} />

Deleting a saved PIN removes the copy on this device. It does not change or unblock the card PIN.

## Use Shortcuts, Siri, Spotlight and Handoff

In Apple Shortcuts, create a shortcut, add an action, search eSemnBun and choose Open Documents, Prepare PDF for Signing or Verify PDF. Supply a PDF to the prepare/verify actions. Prepare opens eSemnBun with the PDF queued; you still review and approve signing in the foreground. Verify returns an offline result and opens the details. PDF input is limited to 32 MiB. Run a configured shortcut from Shortcuts or an available Siri phrase; Siri never receives your card PIN.


1. Open Shortcuts, add an action and search for eSemnBun.
2. Choose Open Documents, Prepare PDF for Signing or Verify PDF; provide a PDF when required.
3. Run the shortcut. Review the prepared queue or offline result in eSemnBun; signing still needs your approval.

For document search, enable Find signed documents in Siri and Spotlight in Settings, complete a signed app-owned PDF/XML, then search its filename in Spotlight. The opt-in index exposes filenames and dates, not document bodies, PINs or certificate identity. Current system Open/Search schemas require supported OS/SDK features; suggestions depend on your device, language and system settings. With Handoff enabled on compatible Apple devices, open Documents on one device and use its continuation affordance on the other. Handoff resumes Documents navigation; it does not transfer a PDF, PIN or card session. Siri, Spotlight and Handoff availability should be checked on your installed build; these documentation captures demonstrate app controls rather than a live cross-device result.
<GuideScreenshot src="/img/guide/ipad/en/settings.png" alt="Enable document discovery only if you want signed filenames and dates available to Siri and Spotlight." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Enable document discovery only if you want signed filenames and dates available to Siri and Spotlight.", "x": 82, "y": 67}, {"text": "After creating a signed app-owned document, search its filename in Spotlight and open the result."}, {"text": "For Handoff, open Documents on one compatible device and choose its continuation affordance on the other."}]} />

## Use iPad windows and Files alongside signing

This guide uses native iPad captures, not enlarged phone screenshots. The layout follows available window width. In a wider window, keep the card and file controls visible together; in a narrow window, expect compact navigation. Use Files beside eSemnBun to locate documents and choose or drag them where the system permits. If a split window hides controls, enlarge it or scroll before signing. Keep the app active for a website request. The captures below show the native portrait window; they do not establish that every multitasking gesture has been exercised.

## Get help without sharing secrets

For no reader, check the cable, adapter and power. For an empty reader, reinsert the card and wait. For a repeated card error, stop the operation before reconnecting. For a locked PIN, contact the official card provider. When requesting [support](/support), include app/iOS versions, reader and adapter models and reproduction steps with a fictional sample. Never send your PIN, private identity details or confidential documents.


## Other guides

[iPhone](./ios.md) · [iPad](./ipad.md) · [macOS](./macos.md) · [Android](./android.md) · [Linux](./linux.md)

<!-- file-protection-guides -->


## Encrypt a file with a password

In **Documents**, choose **Protect files** in the toolbar. When space is limited, open the More (…) menu to find it. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

In version 0.2.13, choose **Password** and select AES-128, AES-192 or AES-256. AES-256 is the default. To encrypt for a recipient, choose **RSA certificate** and select their public encryption certificate (.cer or .der). By default, use a certificate intended for encryption. **Card public key compatibility** explicitly allows the card’s public RSA key. Exporting it or encrypting a file does not prove that the card can decrypt; the matching card must support the required private-key operation.

<GuideScreenshot src="/img/guide/ipad/en/documents-protection-light.png" alt="Open More (…) and choose Protect files." steps={[{"text": "Open More (…) and choose Protect files.", "x": 72, "y": 15}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-password-light.png" alt="Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt." steps={[{"text": "Select the source file and Password. Choose the AES key size, enter and confirm a password, then choose Encrypt.", "x": 79, "y": 57}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-certificate-light.png" alt="Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN." steps={[{"text": "Choose RSA certificate, then select the recipient’s public encryption certificate. Encryption does not require the recipient’s PIN.", "x": 32.0, "y": 66.6}, {"text": "Use Card public key compatibility only when the workflow requires the card’s public RSA key.", "x": 30.1, "y": 57.5}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 62}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

In **Documents**, choose **Protect files** in the toolbar. When space is limited, open the More (…) menu to find it. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

For a password-encrypted file, obtain the password from the sender through a separate trusted channel. The file specifies the AES key size. For an RSA-encrypted file in version 0.2.13, connect the card that holds the recipient’s matching encryption key, read the card and authorize decryption with its PIN.

<GuideScreenshot src="/img/guide/ipad/en/documents-protection-light.png" alt="Open More (…) and choose Protect files." steps={[{"text": "Open More (…) and choose Protect files.", "x": 72, "y": 15}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-decrypt-light.png" alt="Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt." steps={[{"text": "Select the encrypted file. When Password appears, enter the password the sender shared separately and choose Decrypt.", "x": 80, "y": 52}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-rsa-decrypt.png" alt="For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN." steps={[{"text": "For an RSA file, connect the recipient’s card and reader and choose Read my card. Authorize with that card’s PIN.", "x": 27.5, "y": 65.8}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-decrypt-complete-light.png" alt="The result is saved in Documents. Choose Save a copy to export it, or Done to return." steps={[{"text": "The result is saved in Documents. Choose Save a copy to export it, or Done to return.", "x": 50, "y": 62}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
