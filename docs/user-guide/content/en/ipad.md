---
title: iPad
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# iPad

Follow the numbered circles to complete each goal. Tap an image to enlarge it.

Install eSemnBun through the available Apple distribution channel from [Downloads](/downloads). Launch the installed app. You need a supported active electronic ID, its correct signing PIN, a compatible wired reader and the appropriate [adapter](/devices). USB-C devices need a suitable USB connection; Lightning devices may need a powered Lightning adapter. NFC signing is not supported.

## Connect the reader and insert your card

The signing certificate is read without a PIN. An empty-reader prompt means the reader is detected but the card is not ready. Wait for the holder and expiry before adding a signing request.

<GuideScreenshot src="/img/guide/ipad/en/connect.png" alt="Connect the USB reader through the appropriate adapter." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Connect the USB reader through the appropriate adapter.", "x": 10.0, "y": 55.2}]} />
<GuideScreenshot src="/img/guide/ipad/en/empty-reader.png" alt="Insert the card when the app reports an empty reader." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Insert the card when the app reports an empty reader.", "x": 10.0, "y": 58.6}]} />

## Choose the identity that will sign

When several cards are connected, swipe the card carousel to centre the intended holder. The selected card is used for the operation. Open Card to check the certificate or re-read the card after reconnecting it. The neutral portrait is an illustration, not a photograph read from the ID.

<GuideScreenshot src="/img/guide/ipad/en/cards.png" alt="Swipe the card carousel to choose the intended holder." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Swipe the card carousel to choose the intended holder.", "x": 20.0, "y": 42.9}, {"text": "Open Card to inspect the certificate and reader; use the tab overflow if Card is hidden.", "x": 73.0, "y": 11.9}]} />
<GuideScreenshot src="/img/guide/ipad/en/card.png" alt="Check the holder, certificate validity and connected reader." steps={[{"text": "Check the holder, certificate validity and connected reader.", "x": 7, "y": 37}, {"text": "Use re-read after correcting the connection; deleting a saved PIN does not change the physical card PIN.", "x": 95, "y": 5}]} />

## Add documents and choose a signature format

Open Sign and choose files from Files or a cloud provider. Download cloud-only documents first if access fails. You can also send files from another app through its share sheet to the eSemnBun extension. Expand the file list, inspect each name, remove unintended files from its options, and choose the requested format. PDFs use PAdES-T; other files use XAdES. Detached XML must travel with its unchanged original. XAdES-BES has no timestamp, T adds one, and C adds certificate/status references. Enveloping XML includes its source content. Timestamped signing requires the public trust services.

<GuideScreenshot src="/img/guide/ipad/en/sign.png" alt="Confirm the selected holder before signing." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Confirm the selected holder before signing.", "x": 12.0, "y": 37.5}, {"text": "Choose files, or add more documents to the current queue.", "x": 79.0, "y": 75.0}, {"text": "Expand the queue, then open an individual file’s options to choose its format, stamp or removal.", "x": 93.0, "y": 40.0}, {"text": "Choose Sign only after reviewing the complete queue.", "x": 10.0, "y": 70.0}]} />

## Place a visible stamp in a PDF

Open a queued PDF’s options and choose Add/Edit stamp. A visible stamp is optional artwork; the cryptographic signature remains the actual signing proof. Position the stamp away from existing text.

Stamp text follows the selected app language (Romanian, English or Russian).

<GuideScreenshot src="/img/guide/ipad/en/stamp.png" alt="Drag the stamp to move it; drag its corner handles to resize it." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Drag the stamp to move it; drag its corner handles to resize it.", "x": 40, "y": 55}, {"text": "Select the page and choose Off, One page or All pages.", "x": 25, "y": 79}, {"text": "Optionally apply the placement to all queued PDFs, then choose Apply.", "x": 84, "y": 9}]} />

## Review the request and authorize signing

For website requests, inspect the requesting origin and the whole document list before allowing the operation. Cancel unexpected requests. For a local batch, review the queued documents and PIN sheet. Each new batch needs approval; a batch session covers only the listed documents and selected card.

<GuideScreenshot src="/img/guide/ipad/en/consent.png" alt="Check the requesting website and intended operation." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Check the requesting website and intended operation.", "x": 7.1, "y": 12.5}, {"text": "Review all documents; allow only a request you initiated.", "x": 91.4, "y": 87.5}]} />
<GuideScreenshot src="/img/guide/ipad/en/pin.png" alt="Check the holder and selected filenames." steps={[{"text": "Check the holder and selected filenames.", "x": 50, "y": 19}, {"text": "Enter the correct QSCD signing PIN in the protected field.", "x": 30, "y": 27}, {"text": "Use Remember PIN only on a trusted personal device; later access requires the offered device authentication.", "x": 73, "y": 31}, {"text": "Choose Sign to authorize, or Cancel to stop.", "x": 94, "y": 70}]} />

## Wait for completion and save the signed output

Keep the reader and card connected while signing and obtaining the timestamp. Completion is shown separately from the input queue. Use the available result action, or open Documents and select the completed file, then Share to save it in Files or send it to another app. Share the signed output, not the unsigned source; include the original with detached XML.

<GuideScreenshot src="/img/guide/ipad/en/progress.png" alt="Wait for the current signing stage to finish without removing the card." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Wait for the current signing stage to finish without removing the card.", "x": 9.0, "y": 82.5}]} />
<GuideScreenshot src="/img/guide/ipad/en/success.png" alt="Check completion and the output name before opening or sharing the result." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Check completion and the output name before opening or sharing the result.", "x": 9.0, "y": 41.4}]} />

## Recover from a failed document

Read the error on the affected item. Keep outputs that already completed and correct the input or connection before starting another deliberate batch. There is no automatic PIN retry. If the PIN is incorrect, stop and confirm the PIN and selected card; after three incorrect attempts the card can be blocked. The app cannot unblock it. Reconnecting cannot repair an invalid PDF.

<GuideScreenshot src="/img/guide/ipad/en/file-error.png" alt="Read the error on the failed item before making another attempt." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read the error on the failed item before making another attempt.", "x": 47.0, "y": 43.2}]} />

## Verify a signed PDF and inspect its certificate

Verification needs a file, not a reader or PIN. In Verify, choose the signed PDF or XML. Expand each signature, then its certificate and technical sections. Check every signature when a file is countersigned. Offline results distinguish document integrity, cryptographic signature, embedded trust and timestamp information; they are not a current revocation check.

<GuideScreenshot src="/img/guide/ipad/en/verify.png" alt="Open Verify and add the signed document." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Open Verify and add the signed document.", "x": 37.0, "y": 36.6}, {"text": "Expand the signature row to read its result and signer.", "x": 11.0, "y": 80.5}]} />
<GuideScreenshot src="/img/guide/ipad/en/certificate.png" alt="Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity." steps={[{"text": "Scroll the expanded signature to Certificate details, then review identity, validity and fingerprint separately from document integrity.", "x": 13, "y": 59}]} />

## Supply the original for a detached XML signature

A detached XML signature cannot prove the original document’s digest until its unchanged source is available. In the incomplete result, use Choose originals and select the matching original files in the system picker. Wait for the result to update. Selecting another file changes the evidence; a missing original alone does not prove modification.

<GuideScreenshot src="/img/guide/ipad/en/incomplete.png" alt="Read which original is missing." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read which original is missing.", "x": 20.0, "y": 66.0}, {"text": "Choose the unchanged original files and wait for the updated check.", "x": 10.0, "y": 70.0}]} />

## Understand an unexpected verification result

Invalid means a signature or document-integrity check failed. Unconfirmed trust means the embedded chain is not confirmed; it is different from a proven altered document. Unsigned or unrecognized means no supported signature was found. Do not treat the filename or a green file icon as proof. An inaccessible saved file is unavailable, not necessarily unsigned.

<GuideScreenshot src="/img/guide/ipad/en/invalid.png" alt="Read the failed checks; obtain the correct signed file or unchanged original from its sender." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read the failed checks; obtain the correct signed file or unchanged original from its sender.", "x": 13.0, "y": 65.9}]} />
<GuideScreenshot src="/img/guide/ipad/en/untrusted.png" alt="Read the trust warning separately from integrity and signature checks." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Read the trust warning separately from integrity and signature checks.", "x": 13.0, "y": 65.9}]} />
<GuideScreenshot src="/img/guide/ipad/en/unsigned.png" alt="Confirm that you chose the signed output, then inspect whether any supported signature was found." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Confirm that you chose the signed output, then inspect whether any supported signature was found.", "x": 13.0, "y": 73.0}]} />

## Find a saved document and open its signing details

Saved documents contains signed, encrypted and decrypted outputs. Select a signed file to view signature details. An encrypted file offers decryption; its ciphertext is not sent to signature verification. Decrypted files retain their output type and can be opened or exported.

Open Documents and select a saved item. The signing-details modal uses the same verification presentation as Verify and does not replace the current Verify workspace. Preview opens the content; Share exports the chosen file. If a file has moved or is unreadable, choose it again from its real location.

<GuideScreenshot src="/img/guide/ipad/en/documents-protection-light.png" alt="Open Documents and select the intended file." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Open Documents and select the intended file.", "x": 20, "y": 22}, {"text": "Use the search field to narrow the saved-document list.", "x": 95, "y": 4}]} />
<GuideScreenshot src="/img/guide/ipad/en/details.png" alt="Review the document’s signing details." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Review the document’s signing details.", "x": 10.0, "y": 52.9}, {"text": "Choose Preview to read the file or Share to save/send it.", "x": 5.7, "y": 79.4}, {"text": "Choose Done to return to the library.", "x": 92.9, "y": 11.8}]} />

## Clear recent history while keeping saved documents

In Documents, switch to History, choose Clear list and confirm. This clears the recent-operations list, not signed files or the saved Documents collection. Return to Documents to find the retained outputs. To delete an exported file, manage it in Files or its storage provider.

<GuideScreenshot src="/img/guide/ipad/en/history.png" alt="Switch between Documents and History." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Switch between Documents and History.", "x": 74.0, "y": 32.6}, {"text": "Clear the history list only when you intend to remove those recent records.", "x": 91.0, "y": 11.6}]} />

## Log in or sign on a website

Open Browser, use Open an address or a saved service, and navigate to the site’s electronic-ID login or signing option. The browser requests desktop presentation for compatible identity-login flows. Keep eSemnBun foregrounded; the mobile connection stops when the app is backgrounded. Check the service and request before approving. The illustration keeps network and hardware inactive, so website navigation controls may be disabled.

<GuideScreenshot src="/img/guide/ipad/en/browser.png" alt="Open Browser and check the connection status." steps={[{"text": "Open Browser and check the connection status.", "x": 5, "y": 8}, {"text": "Use the address control to enter the service URL.", "x": 97, "y": 5}, {"text": "Use Services/Bookmarks to open, add or manage a saved address.", "x": 91, "y": 5}, {"text": "Use back, forward and reload while browsing.", "x": 6, "y": 97}]} />

To add a bookmark, open Services/Bookmarks → Add bookmark, then set its title, URL and icon and save it. Use Manage bookmarks to edit or remove one. To reset a session, open Clear browser data, select cache, cookies and/or history, then confirm. Clearing cookies can sign you out; it does not clear Documents or saved PINs. A website-side error needs the service’s own support, not repeated PIN attempts.

## Change language, appearance and privacy preferences

Open Card, then Settings. Choose Romanian, English, Russian or System, and Light, Dark or System appearance. Enable browser PDF stamps only if you want a visible stamp for supported website requests. Normal Demo mode is intentionally labelled; it is for exploration and does not produce real signatures. About shows the installed version and help information. Updates come through the Apple channel used to install the app.

<GuideScreenshot src="/img/guide/ipad/en/settings.png" alt="Choose the interface language and appearance." caption="Native iPad portrait capture; unused canvas or surrounding sheet space cropped for legibility." steps={[{"text": "Choose the interface language and appearance.", "x": 82, "y": 29}, {"text": "Review the optional browser-stamp and document-discovery controls.", "x": 82, "y": 67}, {"text": "Use About for the app version; close Settings with Done.", "x": 84, "y": 9}]} />

To manage a saved PIN, open Card for that identity and use Delete saved PIN when available. Saving uses the platform’s protected vault and offered device authentication; deleting the saved copy does not change or unblock the physical card PIN. A different card needs its own PIN.

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

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

No card is needed. Create a password for this file and send it to the recipient through a separate trusted channel. This is not your card PIN. Encryption creates a separate output; keep the original until you have checked the result.

File protection uses a password. Certificate/card protection is unavailable for the Moldovan ID card, whose signing certificate cannot decrypt files. Ask for a password-encrypted copy if you received a certificate-encrypted file.

<GuideScreenshot src="/img/guide/ipad/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 90, "y": 6}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-password-light.png" alt="Encrypt a file with a password" start={2} steps={[{"x": 37, "y": 31, "text": "Choose Encrypt."}, {"x": 35, "y": 42, "text": "Choose the source file."}, {"x": 32, "y": 59, "text": "Enter a new password in Password, then repeat it in Confirm password."}, {"x": 50, "y": 73, "text": "Choose Encrypt. The encrypted copy is saved in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={6} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 35, "y": 53}, {"text": "Optionally choose Save a copy to export another copy.", "x": 35, "y": 61}, {"text": "Choose Done to return to Documents.", "x": 22, "y": 25}]} />

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.


## Decrypt a received file

Open **Documents**, open the menu in the navigation bar, and choose **Protect files**. In the form, choose **Encrypt** or **Decrypt**, then select a file you can read.

Obtain the password from the sender through a separate trusted channel. Select the encrypted file, then enter that password in the bordered **Password** field. No reader, card or card PIN is needed.

<GuideScreenshot src="/img/guide/ipad/en/documents-protection-light.png" alt="Open Documents, open the navigation-bar menu, then choose Protect files." steps={[{"text": "Open Documents, open the navigation-bar menu, then choose Protect files.", "x": 90, "y": 6}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-decrypt-light.png" alt="Decrypt a received file" start={2} steps={[{"x": 37, "y": 31, "text": "Choose Decrypt and select the received encrypted file."}, {"x": 32, "y": 55, "text": "Enter the password supplied by the sender in the Password field."}, {"x": 50, "y": 73, "text": "Choose Decrypt. Check the new output in Documents; choose Done when finished."}]} />

<GuideScreenshot src="/img/guide/ipad/en/protect-decrypt-complete-light.png" alt="Check the saved filename and operation. The output is already in Documents." start={5} steps={[{"text": "Check the saved filename and operation. The output is already in Documents.", "x": 35, "y": 53}, {"text": "Optionally choose Save a copy to export another copy.", "x": 35, "y": 61}, {"text": "Choose Done to return to Documents.", "x": 22, "y": 25}]} />

Open and check the saved output before relying on it. MoldSign-compatible encryption does not authenticate file contents: successful decryption alone does not prove integrity or the correct password.

Choose **Encrypt** or **Decrypt**. The new output is saved automatically in **Documents → Saved documents**. Choose **Done** to return, or **Save a copy** to export it to Files or another location. The original is kept.

Saved documents includes signed, encrypted and decrypted files. Use the filename and operation label to identify the result. Encryption does not create a digital signature; encrypted files must be decrypted before you can open or verify their contents.
