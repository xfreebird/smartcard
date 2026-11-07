# Apple detached XML originals — 7 November 2026

Verify and saved-document details now present absent detached XML originals as incomplete verification. The document integrity row uses a question mark, the verdict says it cannot be confirmed, and the explanation asks for the original filename. Absence alone no longer produces a document-modified claim. Cryptographic signature and trust-chain checks remain visible independently.

The shared verification card offers **Choose original documents…** for XML documents in both screens. Users select all required originals with their original filenames; exact filename matching prevents a document reference from selecting unrelated files. Choosing another set starts a new verification task, hides older results during processing and checks cancellation and the selection generation before publishing. Clearing or replacing the Verify workspace also resets card-local inspection state. Picker cancellation retains the previous result. Saved-document inspection continues to leave Verify and History untouched.

`Validator.Report.missingDetachedReferences` is defaulted to an empty array for compatibility. XAdES validation records unavailable reference names there and keeps `contentIntact` false. Report summaries use `INCOMPLETE` and suppress the content-modified phrase while originals are missing. Consumers must inspect this field before interpreting a false integrity result as a mismatch. The existing lightweight XAdES parser's supported structures are unchanged.

Security-scoped access to the signed document and each selected original remains active until the background verification completes. The resolver reads only expected basenames, using the existing descriptor-relative regular-file reader. Selecting a file does not authorize reading its siblings. Traversal, symlinks beneath the permitted directory and non-regular files are rejected. An explicitly selected but inaccessible original stays missing; it does not silently fall back to a neighbouring copy. Files and data are not retained after inspection beyond the displayed report and selected URL state.

## Verification

Three focused Swift core tests passed with zero failures:

- A simulated card creates a genuine detached signature. Missing original yields incomplete, supplying original bytes restores integrity, and different bytes produce a real mismatch.
- Explicit companion resolution admits the selected original, rejects its unselected sibling, traversal and a symlink, and finds no originals in an empty signature directory.
- Existing nested-path, traversal, special-directory and symlink containment tests remain passing.

Command: `CLANG_MODULE_CACHE_PATH=/tmp/esemnbun-next-xml-clang swift test --disable-sandbox --package-path swift/MoldSignKit --scratch-path /tmp/esemnbun-next-xml-tests --filter 'DetachedDocumentAccessTests|BridgeEndToEndTests/testDetachedMissingOriginalIsIncompleteAndSelectedBytesResolveIt'`.

The initial default SwiftPM invocation was blocked by nested sandbox setup; the successful run disabled SwiftPM's nested manifest sandbox and kept build/cache output in temporary directories. No physical reader, real card or real-card PIN, network signing, release or store operation was used. Native application builds and UI/provider interaction validation are recorded by the enclosing validation pass; these three tests do not prove picker rendering or provider revocation behavior.
