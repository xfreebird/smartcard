# PDF-STAMP-01: optional visible signatures

Status: implemented in source; macOS Debug arm64 builds and launches with development signing and verified entitlements. Other platform builds, tests, rendering and viewer interoperability are pending.

## User flow

Stamps are optional. Existing signing stays invisible unless explicitly enabled.

- A file row’s options menu contains signing type and Add/Edit stamp. The row summarizes the current format and stamp state (off, page number, or all pages) as compact, colored icon tags left-aligned below the filename, on one line when space permits. Each file row has a subtle border. The stamp menu action opens a native preview. The stamp is enabled when explicitly opened with Add stamp; choose the page, drag to move it, resize with the four corner handles and optionally repeat it on every page.
- “Apply to all queued PDFs” copies the position to the current queue with one action. Individual documents can still be edited. This deliberately applies a template without previewing every input.
- Website signing has a separate, persisted preference, off by default. When enabled, show the placement editor once per origin/card/batch. Reuse its position (including the user's decision to sign invisibly) for later documents. Reopen placement if the chosen page does not exist in a later PDF.
- Cached batch positions are memory-only and expire after five minutes without use. A different site, certificate or batch gets a separate decision. Stopping/restarting the bridge must not reuse a prior batch's position.
- Cancelling placement cancels the request. It must not fall back to signing invisibly. Placement does not replace the existing site consent or PIN authorization.

Website requests carrying PDF bytes open placement before PIN authorization. Native Desktop Suite path routes retain their existing rule: authorize access before reading local paths, then preview. The CLI has no interactive PDF preview; its existing behavior remains invisible. The shared signing APIs accept an optional placement.

## Coordinates and identity

Swift `PDFStampPlacement`, Kotlin/C# `PdfStampPlacement` use zero-based page numbers and a normalized rectangle `(x, y, width, height)`, measured from the top-left of the displayed CropBox, including page rotation. Each target page maps that rectangle independently; mixed page sizes keep the same relative location. Crop offsets and rotations 0/90/180/270 are accounted for in the widget rectangle and appearance matrix.

A single-document editor binds placement to SHA-256 of the bytes it previewed. A changed input is rejected. Explicit queue templates omit this binding for the other documents, retaining it for the previewed source. Bridge reuse binds the template to each newly received PDF's bytes.

The placement carries a closed stamp language (`ro`, `en`, `ru`). Native editors capture the app's selected language (including the resolved system language) when opened; queue templates and website batch reuse preserve it. Unsupported languages fall back to Romanian. Shared signing APIs allow an explicit language; no arbitrary label strings come from website requests. The CLI still signs invisibly.

The PDF appearance and native preview reuse the same core text renderer. The six lines localize the signer/date/reason/location labels, European Moldova badge and eSemnBun footer. Certificate names, product names and the signature reason value `MoldSign Signature` remain unchanged; the date retains the unambiguous `yyyy.MM.dd HH:mm:ss` pattern and timezone. The localized badge fits inside its outline, and long lines scale to fit.

Final text comes from the certificate actually used to sign: common name, signing date with timezone, reason `MoldSign Signature`, location `Moldova`, the outlined European Moldova label, and a smaller left-aligned eSemnBun footer, localized as described above. The appearance, PDF signature dictionary and CMS use one captured signing time. Preview time is illustrative; the actual time is chosen when signing starts. The appearance paints no background fill, so existing page content remains visible underneath. Selection outlines and corner handles exist only in the editor. There is no handwritten autograph, copied government emblem or external tracking URL.

Liberation Serif Regular is embedded with an Identity-H CID font, explicit widths and a ToUnicode map, preserving Romanian/Cyrillic names and text extraction. The authoritative font, SIL Open Font License and derived metrics live in `swift/MoldSignKit/Sources/MoldSignKit/Resources/PDFStamp/`; Gradle and MSBuild package those same files. Unsupported characters cause an explicit failure rather than replacing the signer's name.

## PDF structure

All appearance objects are appended before hashing the signature ByteRange. Original bytes remain untouched. Existing page annotations and AcroForm fields are retained.

A signature field has **one** widget, on the chosen page. Its `/V` references the cryptographic signature and its `/AP /N` provides the visible stamp. Other pages get `/Stamp` appearances plus ordinary `/Link` annotations whose `/Dest` navigates to that signature widget's page/rectangle. No JavaScript is used. Signature-details behavior depends on the viewer; viewers supporting signature widgets can open the actual signature, while ordinary GoTo links navigate to it.

This follows the one-annotation restriction in [ISO 32000-2, signature fields](https://developer.adobe.com/document-services/docs/assets/5b15559b96303194340b99820d3a70fa/PDF_ISO_32000-2.pdf). Repeating a signature field's widget across pages is intentionally avoided.

The incremental signer's existing plain-object limitations remain: encrypted PDFs, compressed page dictionaries/object streams, unsupported generations, malformed page trees, unsupported AcroForm/annotation arrays and non-default UserUnit values cannot be stamped. Certified PDFs with `/Perms` are rejected. This is not a general-purpose PDF parser or a PDF normalization pass. An approval signature's earlier revision remains unchanged; that does not imply that adding annotations is permitted by every prior certification policy.

## Platform routes

- Apple: PDFKit preview; shared Swift signing core; iOS sheet / macOS authorization panel for website requests.
- Android: PdfRenderer on private temporary copies; JVM signing core; foreground placement dialog or a signing notification when a site requests signing while the app is backgrounded.
- Windows: Windows.Data.Pdf preview; .NET signing core; dispatcher-owned dialog, including browser requests.
- Linux: Poppler GLib/Cairo preview; Swift signing core; GTK placement window. Build dependency `poppler-glib` is included in the distro/CI recipes; font assets are installed under `share/moldsign/PDFStamp`.

## Validation to run

Native Debug builds and screenshots are authorized by the owner’s cross-platform UI review request. Unit/regression suites and real-card signing have not been run in this revision. Native builds: macOS, iOS Simulator, Android emulator, Windows x64 on ARM64, Fedora aarch64. Capture evidence lives outside version control in `dist/stamp-review/`.

1. Run Swift, Android Core and Windows Core suites, including the new PDFStamp tests and visible-counter-signature tests. Check ByteRange integrity, original-byte preservation, xref offsets and both signature revisions.
2. Build all five apps. Exercise light/dark, RO/EN/RU, phone/tablet, small desktop windows, cancellation and keyboard access.
3. Use unsigned and already-signed PDFs, inherited crop boxes, all four rotations, nonzero origins, reordered/nested page trees, indirect annotation arrays, existing forms, mixed page sizes, long Romanian/Cyrillic names and unsupported/encrypted inputs.
4. Render actual stamped outputs with Poppler and native viewers. Check text, border, orientation, bounding boxes, clipping and non-overlap at each chosen position. Open primary-widget signature details in Acrobat and follow duplicate-page links.
5. Exercise a multi-document msign.gov.md batch: disabled preference adds no prompts; enabled preference asks placement once, retains one PIN session, and reopens placement only if the chosen page is absent. Cancel and stop/restart while placement is open.
6. Verify the Windows/Linux installed packages include their preview dependencies and font resources, including Flatpak. Verify no private PDFs or certificate data remain in tracked files or logs.

The supplied personal PDF is a read-only reference; it is not a test fixture and must not be committed.

## Native editor refinement (2026-11-06)

- Explicit Add stamp/Edit stamp text replaces icon-only entry points; Apple places the format and stamp action together beneath the filename.
- All editors expose four corner handles instead of a size slider. Resizing keeps the opposite corner fixed, retains proportions, and clamps to page bounds. Apple supports accessibility adjustment; Windows supports keyboard arrows on the handles; Linux supports +/- on the focused preview.
- macOS uses a 820×620 print-style sheet with a scrollable page column, grouped settings, native page-scope radio controls, and a fixed action footer; iPhone and Android use vertically swipeable, paged previews above a fixed bottom panel with 48-point page navigation, a page counter, a single Off/One page/All pages segmented mode control, and batch reuse. Stamp movement consumes drags only on the stamp; the rest of the preview remains available for page scrolling. Windows uses a large resizable owned editor window with a continuous page column that scales to approximately 90% visible page height (bounded by available width), grouped scope radio controls, native Thumb controls, and a fixed inspector footer. GNOME uses the same page-column/inspector structure with inset AdwSwitchRow groups and fixed trailing action buttons. Selecting or resizing a stamp on a page makes that page the selected-page target; all-pages mode updates every preview.
- Website preview remains opt-in and once per supported site/card/batch; the editor itself does not introduce additional approval prompts.
- Debug-only capture entry points open the real editor with synthetic documents and fictional identities; they do not sign documents.
