# Cross-platform external-file size and PDF counter-signing

## Findings

`SignItem.sizeText` queried file metadata outside security-scoped access and converted every lookup failure to zero bytes. Signing already opens that access independently. The display now opens/closes access around the metadata lookup and uses the existing localized unknown-size text if metadata is unavailable. This changes neither the source file nor its output location.

The owner's payment PDF was inspected locally with `pdfinfo`, byte-level structure inspection and `pdfsig`. It is a one-page, unencrypted PDF with an existing signature. Poppler reported that signature as valid and covering the complete document, while its local certificate database did not trust the issuer. This is not proof that the app's trust store rejects the certificate. An exact in-app anchor error would need separate confirmation; rewriting a PDF cannot establish certificate trust.

The sample's current catalog and AcroForm are ordinary uncompressed objects, but `/Fields` references a separate array object. The Swift signer previously accepted only an inline array and would fail with `AcroForm /Fields not found`. Its cross-reference stream is not the immediate blocker: the root and required form objects are available to the existing parser.

## Change

The Swift signer resolves either an inline field array or an indirect plain-text array with the existing PDF token parser. It appends a new version of the AcroForm with all previous field references plus the new signature. It preserves the original document bytes and does not flatten, render, normalize or replace the existing signature. A missing or unsupported AcroForm/array fails instead of silently replacing the form and losing existing fields.

This is a targeted compatibility improvement, not a general PDF repair facility. Compressed form objects, nonzero-generation references and other unsupported structures still require a broader parser solution. Equivalent indirect-field resolution is implemented in the Kotlin and C# signers. The Swift core covers iOS, macOS, Linux and the Swift CLI; Kotlin covers Android; C# covers Windows and its CLI. The supplied private PDF and its contents were not added to the repository or modified.

## Validation status

- Read-only source PDF inspection completed; original signature cryptographic verification passed in Poppler. Certificate trust was not established by that check.
- Added a synthetic counter-signing regression with an indirect field array, checking original-byte preservation, retained field references and both signatures' content digests.
- Added counter-signing and missing/wrong-type/truncated array regressions in all three core suites (Swift, Kotlin and C#). Kotlin/C# counter-signing checks include cryptographic verification using synthetic keys; Swift checks both content digests and original-byte retention.
- `git diff --check` passed.
- Builds and automated tests were not run, per the owner's standing instruction. No physical-card commands were issued. Device verification of external-provider metadata and signing this PDF remains pending.

Owner-run focused core suite: `swift test --package-path swift/MoldSignKit --filter PdfSigningTests`. On iOS, compare a known-size file in the app's Documents folder with a file selected from another local folder and an iCloud/provider folder; inaccessible metadata must not display zero. Then counter-sign the sample and independently verify that its original signature remains intact.

## File-size audit across platforms

- iOS/macOS share `SignItem`: activate security-scoped access for metadata; return localized unavailable size on lookup failure.
- Linux now omits size when metadata cannot be read instead of reporting zero bytes.
- Android content-provider metadata already treats missing/NULL size as unknown and omits it in document rows. Local-file metadata now uses `Files.size` with an unknown fallback instead of `File.length`, which can return zero on failure. Android's minimum API level is 26, matching the NIO API used.
- Windows already catches inaccessible/missing-file metadata errors and omits the size. No Windows size-display change is needed.
- Real zero-length documents retain their existing platform display behavior. No file contents or provider permissions are changed to calculate a size.

Additional owner-run core suites: Android `./gradlew :core:test --tests md.moldsign.core.PadesCmsSignerTest` from `android/`; Windows `dotnet test windows/tests/MoldSign.Core.Tests --filter FullyQualifiedName~SigningCoreTests`; portable Swift via `scripts/test-portable-macos.sh`. None was run during this change. Native builds and file-picker verification on each OS remain pending.
