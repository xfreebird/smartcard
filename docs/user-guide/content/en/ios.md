---
title: iPhone
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# iPhone

Follow the numbered circles to complete each goal. Tap an image to enlarge it.

Install eSemnBun through the available Apple distribution channel from [Downloads](/downloads). Launch the installed app. You need a supported active electronic ID, its correct signing PIN, a compatible wired reader and the appropriate [adapter](/devices). USB-C devices need a suitable USB connection; Lightning devices may need a powered Lightning adapter. NFC signing is not supported.

## Connect the reader and insert your card

The signing certificate is read without a PIN. An empty-reader prompt means the reader is detected but the card is not ready. Wait for the holder and expiry before adding a signing request.

<GuideScreenshot src="/img/guide/iphone/en/connect.png" alt="Connect the USB reader through the appropriate adapter." steps={[{"text": "Connect the USB reader through the appropriate adapter.", "x": 25, "y": 28}]} />
<GuideScreenshot src="/img/guide/iphone/en/empty-reader.png" alt="Insert the card when the app reports an empty reader." steps={[{"text": "Insert the card when the app reports an empty reader.", "x": 25, "y": 29}]} />

## Choose the identity that will sign

When several cards are connected, swipe the card carousel to centre the intended holder. The selected card is used for the operation. Open Card to check the certificate or re-read the card after reconnecting it. The neutral portrait is an illustration, not a photograph read from the ID.

<GuideScreenshot src="/img/guide/iphone/en/cards.png" alt="Swipe the card carousel to choose the intended holder." steps={[{"text": "Swipe the card carousel to choose the intended holder.", "x": 28, "y": 27}, {"text": "Open Card to inspect the certificate and reader; use the tab overflow if Card is hidden.", "x": 84, "y": 94}]} />
<GuideScreenshot src="/img/guide/iphone/en/card.png" alt="Check the holder, certificate validity and connected reader." steps={[{"text": "Check the holder, certificate validity and connected reader.", "x": 6, "y": 50}, {"text": "Use re-read after correcting the connection; deleting a saved PIN does not change the physical card PIN.", "x": 90, "y": 9}]} />

## Add documents and choose a signature format

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

Keep the reader and card connected while signing and obtaining the timestamp. Completion is shown separately from the input queue. Use the available result action, or open Documents and select the completed file, then Share to save it in Files or send it to another app. Share the signed output, not the unsigned source; include the original with detached XML.

<GuideScreenshot src="/img/guide/iphone/en/progress.png" alt="Wait for the current signing stage to finish without removing the card." steps={[{"text": "Wait for the current signing stage to finish without removing the card.", "x": 10, "y": 45}]} />
<GuideScreenshot src="/img/guide/iphone/en/success.png" alt="Check completion and the output name before opening or sharing the result." steps={[{"text": "Check completion and the output name before opening or sharing the result.", "x": 35, "y": 49}]} />

## Recover from a failed document

Read the error on the affected item. Keep outputs that already completed and correct the input or connection before starting another deliberate batch. There is no automatic PIN retry. If the PIN is incorrect, stop and confirm the PIN and selected card; after three incorrect attempts the card can be blocked. The app cannot unblock it. Reconnecting cannot repair an invalid PDF.

<GuideScreenshot src="/img/guide/iphone/en/file-error.png" alt="Read the error on the failed item before making another attempt." steps={[{"text": "Read the error on the failed item before making another attempt.", "x": 50, "y": 72}]} />

## Verify a signed PDF and inspect its certificate

Verification needs a file, not a reader or PIN. In Verify, choose the signed PDF or XML. Expand each signature, then its certificate and technical sections. Check every signature when a file is countersigned. Offline results distinguish document integrity, cryptographic signature, embedded trust and timestamp information; they are not a current revocation check.

<GuideScreenshot src="/img/guide/iphone/en/verify.png" alt="Open Verify and add the signed document." steps={[{"text": "Open Verify and add the signed document.", "x": 26, "y": 24}, {"text": "Expand the signature row to read its result and signer.", "x": 8, "y": 48}]} />
<GuideScreenshot src="/img/guide/iphone/en/certificate.png" alt="Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity." steps={[{"text": "Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity.", "x": 9, "y": 87}]} />

## Supply the original for a detached XML signature

A detached XML signature cannot prove the original document’s digest until its unchanged source is available. In the incomplete result, use Choose originals and select the matching original files in the system picker. Wait for the result to update. Selecting another file changes the evidence; a missing original alone does not prove modification.

<GuideScreenshot src="/img/guide/iphone/en/incomplete.png" alt="Read which original is missing." steps={[{"text": "Read which original is missing.", "x": 8, "y": 50}, {"text": "Choose the unchanged original files and wait for the updated check.", "x": 8, "y": 55}]} />

## Understand an unexpected verification result

Invalid means a signature or document-integrity check failed. Unconfirmed trust means the embedded chain is not confirmed; it is different from a proven altered document. Unsigned or unrecognized means no supported signature was found. Do not treat the filename or a green file icon as proof. An inaccessible saved file is unavailable, not necessarily unsigned.

<GuideScreenshot src="/img/guide/iphone/en/invalid.png" alt="Read the failed checks; obtain the correct signed file or unchanged original from its sender." steps={[{"text": "Read the failed checks; obtain the correct signed file or unchanged original from its sender.", "x": 14, "y": 41}]} />
<GuideScreenshot src="/img/guide/iphone/en/untrusted.png" alt="Read the trust warning separately from integrity and signature checks." steps={[{"text": "Read the trust warning separately from integrity and signature checks.", "x": 14, "y": 41}]} />
<GuideScreenshot src="/img/guide/iphone/en/unsigned.png" alt="Confirm that you chose the signed output, then inspect whether any supported signature was found." steps={[{"text": "Confirm that you chose the signed output, then inspect whether any supported signature was found.", "x": 14, "y": 41}]} />

## Find a saved document and open its signing details

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Open Documents and select a saved item. The signing-details modal uses the same verification presentation as Verify and does not replace the current Verify workspace. Preview opens the content; Share exports the chosen file. If a file has moved or is unreadable, choose it again from its real location.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="Open Documents and select the intended file." steps={[{"text": "Open Documents and select the intended file.", "x": 20, "y": 47}, {"text": "Use the search field to narrow the saved-document list.", "x": 20, "y": 22}]} />
<GuideScreenshot src="/img/guide/iphone/en/details.png" alt="Review the document’s signing details." steps={[{"text": "Review the document’s signing details.", "x": 12, "y": 31}, {"text": "Choose Preview to read the file or Share to save/send it.", "x": 8, "y": 44}, {"text": "Choose Done to return to the library.", "x": 90, "y": 12}]} />

## Clear recent history while keeping saved documents

In Documents, switch to History, choose Clear list and confirm. This clears the recent-operations list, not signed files or the saved Documents collection. Return to Documents to find the retained outputs. To delete an exported file, manage it in Files or its storage provider.

<GuideScreenshot src="/img/guide/iphone/en/history.png" alt="Switch between Documents and History." steps={[{"text": "Switch between Documents and History.", "x": 91, "y": 29}, {"text": "Clear the history list only when you intend to remove those recent records.", "x": 80, "y": 9}]} />

## Log in or sign on a website

Open Browser, use Open an address or a saved service, and navigate to the site’s electronic-ID login or signing option. The browser requests desktop presentation for compatible identity-login flows. Keep eSemnBun foregrounded; the mobile connection stops when the app is backgrounded. Check the service and request before approving. The illustration keeps network and hardware inactive, so website navigation controls may be disabled.

<GuideScreenshot src="/img/guide/iphone/en/browser.png" alt="Open Browser and check the connection status." steps={[{"text": "Open Browser and check the connection status.", "x": 8, "y": 15}, {"text": "Use the address control to enter the service URL.", "x": 88, "y": 9}, {"text": "Use Services/Bookmarks to open, add or manage a saved address.", "x": 77, "y": 9}, {"text": "Use back, forward and reload while browsing.", "x": 18, "y": 87}]} />

To add a bookmark, open Services/Bookmarks → Add bookmark, then set its title, URL and icon and save it. Use Manage bookmarks to edit or remove one. To reset a session, open Clear browser data, select cache, cookies and/or history, then confirm. Clearing cookies can sign you out; it does not clear Documents or saved PINs. A website-side error needs the service’s own support, not repeated PIN attempts.

## Change language, appearance and privacy preferences

Open Card, then Settings. Choose Romanian, English, Russian or System, and Light, Dark or System appearance. Enable browser PDF stamps only if you want a visible stamp for supported website requests. Normal Demo mode is intentionally labelled; it is for exploration and does not produce real signatures. About shows the installed version and help information. Updates come through the Apple channel used to install the app.

<GuideScreenshot src="/img/guide/iphone/en/settings.png" alt="Choose the interface language and appearance." steps={[{"text": "Choose the interface language and appearance.", "x": 95, "y": 29}, {"text": "Review the optional browser-stamp and document-discovery controls.", "x": 86, "y": 65}, {"text": "Use About for the app version; close Settings with Done.", "x": 88, "y": 12}]} />

To manage a saved PIN, open Card for that identity and use Delete saved PIN when available. Saving uses the platform’s protected vault and offered device authentication; deleting the saved copy does not change or unblock the physical card PIN. A different card needs its own PIN.

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


## Other guides

[iPhone](./ios.md) · [iPad](./ipad.md) · [macOS](./macos.md) · [Android](./android.md) · [Linux](./linux.md)

<!-- file-protection-guides -->


## Encrypt a file with a password

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 90, "y": 6}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-password-light.png" alt="Encrypt a file with a password" start={2} steps={[{"x": 27, "y": 21, "text": "Choose Encrypt."}, {"x": 25, "y": 40, "text": "Choose the source file."}, {"x": 25, "y": 70, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 50, "y": 94, "text": "Choose Encrypt. The encrypted copy is saved in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={6} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 25, "y": 59}, {"text": "Optionally choose Save a copy to export another copy.", "x": 25, "y": 73}, {"text": "Choose Done to return to Documents.", "x": 20, "y": 10}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/iphone/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 90, "y": 6}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-light.png" alt="Decrypt a received file" start={2} steps={[{"x": 27, "y": 21, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 25, "y": 61, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 94, "text": "Choose Decrypt. Check the new output in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/iphone/en/protect-decrypt-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={5} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 25, "y": 59}, {"text": "Optionally choose Save a copy to export another copy.", "x": 25, "y": 73}, {"text": "Choose Done to return to Documents.", "x": 20, "y": 10}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
