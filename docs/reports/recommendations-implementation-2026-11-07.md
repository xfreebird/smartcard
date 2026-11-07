# Recommendations implementation — 7 November 2026

This first implementation pass addresses Documents on all five application platforms and begins the Siri, macOS and agent-integration recommendations. Changes are in the working tree, alongside the previous UX/security work. Nothing was committed, released or submitted to a store.

## Documents and History

Documents previously filtered the activity-history collection. Clearing that history, pruning it or reaching its 100-entry limit could therefore remove saved documents from the application list even when their files remained on disk.

Apple, Android, Windows and Linux now persist a separate signed-document library. Existing eligible history records migrate into that library before history cleanup. New successful local signing outputs update it independently of the history cap. Clearing History retains the library and files. Duplicate output paths or URIs use the latest record. This separation also applies to macOS/iOS demo storage without copying demo records into live preferences.

Previously cleared history metadata cannot be reconstructed automatically. This migration preserves records still available at upgrade; it does not restore deleted files or invent signature metadata.

Tapping a saved document opens a read-only signing-details modal using the same signature and certificate presentation as Verify. It checks the current file rather than treating its old signing-success entry as proof of validity. Inspection does not add another history event or replace the existing Verify workspace. Existing platform open/share/reveal actions remain available.

On Apple platforms, inaccessible files remain in the document library and show an unavailable-file state. Read failures propagate to that state rather than silently becoming an empty signature report. Android likewise retains unavailable records and reports access errors. Windows and Linux keep their existing missing-file pruning behavior; history clearing is independent of that pruning.

Android details support choosing detached XML companion documents and protect against stale results when that selection changes. Apple details explain that detached XML needs its original, but inherit Verify's remaining limitation: missing originals can still produce the existing invalid/modified interpretation, and the sheet has no companion-file picker. This remains follow-up work, not a new cryptographic guarantee.

## Siri and Shortcuts

The iOS app now declares authenticated foreground **Open Documents** and **Verify PDF** App Intents and discoverable App Shortcuts. Verification accepts a PDF up to 32 MiB, reads provider input in bounded chunks, uses a protected temporary copy, and removes that copy after verification, cancellation or failure.

Verification returns a structured offline outcome and routes full report metadata into Verify. It does not retain access to the source document or add a temporary path to History. Retained routing handles a request arriving before the UI is ready; generation checks prevent older shortcut completions from replacing newer shortcut navigation.

Titles, parameters, outcomes, errors and shortcut phrases have English, Romanian and Russian resources. Localized phrases do not establish Siri voice-recognition availability in those languages. No shortcut accepts a PIN, selects a signing certificate, signs a document or approves another signing request.

This is the first App Intents baseline. Latest Siri schema integration, signing preparation, detached XML inputs, document entities and indexing remain subsequent phases. Offline signature verification does not establish current certificate revocation status.

## Native macOS features

A separate localized **Verify with eSemnBun** Finder Service routes selected PDFs/XML into the foreground Verify workspace. The existing Sign Service and Open With signing-queue behavior remain available; receiving files never starts signing automatically.

Completed signing rows retain Finder reveal and gain native Quick Look preview. PDF outputs gain native sharing. Documents details also provide preview/share/reveal, with an explicit detached-XML companion explanation. Preview is independent of cryptographic verification.

Settings refresh login-item and reader-helper status when shown and when the app becomes active. State refresh reads OS status; it does not re-register an externally disabled service. Login items requiring approval provide a System Settings action.

Finder Service registration, sandboxed Store file access and system share/preview behavior still need native runtime validation. Spotlight, Handoff, token extensions and a background approval broker are not implemented in this pass.

## Agent and CLI integration

The macOS/Linux Swift CLI and Windows CLI now expose `capabilities` and `capabilities --json`, with a versioned metadata-only schema. Discovery runs before reader, card, environment or PIN access. It accurately identifies implemented commands and formats; Windows document signing and verification remain explicitly unavailable in that CLI.

Only capability discovery currently supports JSON. Other `--json` commands return a sanitized error before touching hardware or authentication. Diagnostic text goes to stderr, and neither output includes supplied paths, argument values or secrets. The Windows writer avoids reflection serialization for NativeAOT compatibility.

Structured `verify --json`, Windows verification parity, an MCP executable, pairing, desktop approval broker and remote access remain follow-up work. Capability metadata grants no signing permission.

## File-access hardening

Apple GUI and Linux GUI detached XML reads now use the descriptor-relative contained reader already introduced for the Swift CLI. Neighbour references cannot follow a symlink or special file outside their permitted directory. The Apple path retains its neighbouring-basename restriction.

The new inspection and automation entry points do not bypass the existing signing gate, certificate-match checks, consent or PIN handling.

## Verification performed

- Swift frontend syntax parsing passed for the changed Apple implementation and regression sources, and for the Swift CLI. This is a syntax check, not type checking or a native application build.
- Linux frontend syntax parsing passed for the changed document-library and presentation sources.
- Localization completeness, stable identifiers, formatting arguments and native export consistency passed across all platforms. Existing catalog identifiers were retained.
- macOS Info.plist, Windows XAML, Android string XML and localized App Shortcuts phrase JSON/token checks passed.
- Working-tree whitespace checks passed. Independent static review found and resolved Apple read-failure handling, detached-reference containment and an Android stale-modal-result race.

Focused regression sources were added for Apple library migration/history clearing/relaunch, duplicate and empty-library handling, and history-cap independence; Android migration/deduplication and cap independence; and Windows CLI JSON schema, sanitized failure handling and isolation from hardware/PIN/environment access.

No native builds, test suites, capability-process runs, simulator/device UI sessions, Siri sessions, OS-authentication checks or physical-card operations were run in this implementation pass, following the repository's owner-run build/test convention. These changes are not release-validated. Existing screenshots and PDFs describe the preceding review; no new-runtime screenshots are claimed here.

## Next validation and implementation

1. Build all application targets and run the new regression tests. On an upgrade profile, sign a document, clear History, restart and confirm Documents still contains it.
2. Exercise document modals with valid, invalid, unsigned, missing and inaccessible files, long names, both themes and compact/landscape sizes, including Duo. Confirm closing a modal preserves Verify results.
3. Validate Shortcuts discovery and metadata extraction on iOS 17 and newer, locked-device authentication, provider revocation, cancellation and large/malformed PDFs.
4. Validate Finder Services on cold/warm launch, Store sandbox access, preview/share cancellation and external login-item changes.
5. Add explicit missing-companion states and companion selection to Apple verification, then structured CLI verification and its cross-platform parity tests before introducing MCP.

## Detailed implementation records

- `documents-android-implementation-2026-11-07.md`
- `documents-desktop-implementation-2026-11-07.md`
- `shortcuts-implementation-2026-11-07.md`
- `agent-capabilities-implementation-2026-11-07.md`
