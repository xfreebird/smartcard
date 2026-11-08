---
title: Android tablet
sidebar_position: 5
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Android tablet

Use a compatible USB/OTG reader and an active electronic ID with its signing PIN. Android 8 or later and USB host support are required. NFC signing is unavailable. Install from the channel listed on [Downloads](/downloads); an APK installs on a device, while an AAB is a store upload. Update through the same distribution channel.

The illustrations use fictional people and sample documents. Numbered circles point to the controls used in each journey. Tap an image to enlarge it. A preview result illustrates the interface; it is not a legally signed document.

A wide tablet window uses a left navigation rail and keeps signing controls in the content area. Rotate to landscape for more room. In split screen or a narrow window, the same app switches to compact navigation; enlarge the window to restore the rail. These are native tablet captures, not enlarged phone images. For compact navigation, see the [phone guide](./android.md).

## 1. Connect the reader and card

Connect the reader with the appropriate adapter. Permission is needed for the USB device, not broad access to every file. Reading the signing certificate does not require a PIN.

<GuideScreenshot src="/img/guide/android-tablet/en/connect.png" alt="Connect the reader and card" steps={[{"text": "Tap Allow and accept Android’s USB-access prompt for this reader.", "x": 13.5, "y": 32.9}, {"text": "Insert the card, wait for Card ready, and check the holder and expiry before signing."}]} />

## 2. Add files and prepare a batch

Keep the reader connected until every result appears. The original input remains separate from the signed output. You can also share documents from Files or another app to eSemnBun.

<GuideScreenshot src="/img/guide/android-tablet/en/sign.png" alt="Add files and prepare a batch" steps={[{"text": "Swipe to the intended card and check the Used for signing indicator.", "x": 17.3, "y": 18.4}, {"text": "Tap Add documents and select one or several files in the system picker. Download cloud files first if they are unavailable.", "x": 47.4, "y": 46.5}, {"text": "Review the expanded document rows. Open each file menu to change its format, stamp, or remove it."}, {"text": "Tap Sign when the card and the full document list are correct.", "x": 66, "y": 53.5}]} />

## 3. Choose PDF or XML signatures

PDF signature (PAdES-T) embeds the signature in a PDF. XAdES creates XML: keep the original beside a detached signature. Timestamped and validation-data formats need the relevant trust services. A visible stamp is optional and does not replace the digital signature.

<GuideScreenshot src="/img/guide/android-tablet/en/format.png" alt="Choose PDF or XML signatures" steps={[{"text": "Open the file’s three-dot menu. Choose the signature format for that file; remove a mistaken input from the same menu.", "x": 84.9, "y": 30.4}, {"text": "For PDFs, enable the visible-stamp option if you want to place a stamp before approval. XML signing here produces a detached signature; retain the original."}]} />

## 4. Place an optional visible stamp

The placement editor opens before the PIN request when a stamp is enabled. Review page content to avoid covering important text.

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

<GuideScreenshot src="/img/guide/android-tablet/en/results.png" alt="Open, save, or share the result" steps={[{"text": "Tap Open beside a completed file to open it in a compatible viewer.", "x": 85.4, "y": 24.5}, {"text": "In Documents → Signed documents, use the file’s menu for Open, Verify, Share, or Save as… when file-provider access is available. Save as lets you choose another location."}, {"text": "Clear results hides this completion list. Your saved outputs remain available in Documents.", "x": 84.9, "y": 18.7}]} />

## 7. Check a signed document

Verification does not require the card or PIN. A green result refers to the checks shown, not to the filename or the presence of a visible stamp.

<GuideScreenshot src="/img/guide/android-tablet/en/verify.png" alt="Check a signed document" steps={[{"text": "Open Verify, choose a signed PDF or XML, and wait for results. Use the system picker to select files from other apps or providers.", "x": 47.1, "y": 25.3}, {"text": "Read the verdict and each signature’s author, signing time, timestamp, integrity, signature, and trust-chain checks.", "x": 35.0, "y": 43.3}, {"text": "Remove an input with × to clear its result, or clear all results before a new check.", "x": 67.8, "y": 35.5}]} />

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

Documents contains a signed-output library and a separate activity history. A saved entry is a shortcut to a file, not a substitute for a backup.

<GuideScreenshot src="/img/guide/android-tablet/en/documents.png" alt="Find signed documents" steps={[{"text": "Open Documents and select Signed documents.", "x": 31.8, "y": 14.7}, {"text": "Tap a document row to open its signing-details modal. The app checks the current file again.", "x": 34.2, "y": 25.1}]} />

## 11. Read signing details without losing your list

The modal’s verdict is a fresh verification, not just a historical “signed” label. An unavailable file reports an access error; reselect a moved file in Verify.

<GuideScreenshot src="/img/guide/android-tablet/en/details.png" alt="Read signing details without losing your list" steps={[{"text": "Review the verdict and expand the certificate or technical details, just as in Verify. Supply an original if detached XML requests it.", "x": 44.3, "y": 64.6}, {"text": "Tap Close to return to the same signed-document list.", "x": 65.1, "y": 30.0}]} />

## 12. Clear history while keeping documents

History lists document operations and website requests. Clearing it does not clear Signed documents or delete signed files on storage.

<GuideScreenshot src="/img/guide/android-tablet/en/history.png" alt="Clear history while keeping documents" steps={[{"text": "Choose History in Documents and review the recent actions.", "x": 41.8, "y": 14.7}, {"text": "Tap Clear the list and confirm, then return to Signed documents to access saved outputs.", "x": 65.2, "y": 20.5}]} />

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

The displayed card uses certificate information and a neutral avatar, not a photograph read from your ID. The signing key stays on the physical card.

<GuideScreenshot src="/img/guide/android-tablet/en/card.png" alt="Inspect or refresh the card" steps={[{"text": "Open Card, select the intended identity, and inspect holder, issuer, validity, serial number, and fingerprint.", "x": 42.3, "y": 18.0}, {"text": "Use Re-read the card after reconnecting it; scroll down for the same action and certificate fields.", "x": 33.9, "y": 88.3}, {"text": "Delete stored PIN removes any previously saved app entry; it does not change the physical card PIN. Current Android approval does not offer saving a new PIN."}]} />

## 15. Language, appearance, demo, and support

Android controls the app language and appearance. On Android 13 or later, open system Settings → Apps → eSemnBun → Language and choose English, Romanian, or Russian. On older Android, the interface follows the device’s supported language. Use the system dark-theme setting for dark appearance.

<GuideScreenshot src="/img/guide/android-tablet/en/about.png" alt="Language, appearance, demo, and support" steps={[{"text": "Open the gear → General to enable demo mode after reading its explanation. Ordinary demo mode is labelled and produces samples, not valid signatures; disable it before real work.", "x": 38.4, "y": 14.4}, {"text": "Open About to find the version, official-source disclosure, and website. Include app/Android version, reader/adapter model, and reproduction steps in support requests.", "x": 45.3, "y": 29.8}]} />

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
