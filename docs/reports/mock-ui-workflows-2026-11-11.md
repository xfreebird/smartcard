# Mock service UI workflow implementation

The native suites now invoke Sign and observe success, mixed document failure and fatal failure, using
injected scenario signers. The application batch policy, queue updates, activity history and output
presentation remain in the production workflow. The samples are explicitly unsigned; these tests do
not establish cryptographic or physical-reader behavior.

## Changes

- Apple: scenario `DocumentSigning` adapter, shared `SigningBatchRunner` for demo/live batches, native
  queue/format/stamp/history tests, single/batch consent refusal, and verification disclosure tests on
  both macOS and iOS. Answering a presentation-only consent now dismisses it even when no async
  decision is waiting; previously that isolated fixture could remain open.
- Android: instrumentation supplies `SigningService` through the application composition root. Demo
  and live requests execute `SignDocuments`; the demo output adapter saves only sample-provider bytes.
  Native tests assert signer call counts, continued/stopped work, saved outputs, result hiding, queue
  removal, XML selection, stamp cancel, history cancel/clear, PIN cancel and detail disclosures.
- Linux: a `DocumentSigning` scenario adapter feeds the real `BatchSigningService`, with a mock PIN
  store that never touches Secret Service. AT-SPI tests check outputs and their unsigned content,
  recoverable/fatal queue behavior, file options, stamp cancellation and history retention. The history
  clear button's accessible label now follows its current action instead of retaining the initial label.
- Windows: an `IDocumentSigner` scenario decorator supplies failures while `DocumentBatchSigner`
  owns continuation and fatal-stop policy. UI Automation drives file options, signing, stamp and PIN
  cancellation, saved/history filters and clear confirmation. Verification tests expand and collapse
  certificate and technical sections. Stable automation identifiers expose existing controls.
- Run instructions and journey catalog now link the mock suites and eight shared scenario groups.
  Apple has one wrapper for both XCTest suites. Android requires all 28 completion records. Desktop
  runners write per-scenario JSON results and fail on a missing control or wrong outcome.

## Validation and limits

The owner subsequently authorized builds and runtime tests. Results, fixes found during execution,
skips and remaining environment prerequisites are recorded in
[native test validation](native-test-validation-2026-11-11.md).

The catalog distinguishes these mock interactions from complete documented journeys. OS file-provider
selection and drag/drop, system share/export, signed installation, USB permissions, real biometrics,
portal transport, desktop lifecycle, and Siri/Shortcuts/Spotlight/Handoff still have their separate
runtime requirements. The mocks exercise application behavior at these service boundaries; they do
not prove the external integrations. Protection crypto/storage integration and existing presentation
suites remain separately listed; this change does not claim complete UI coverage of every documented
journey or completion of every earlier architecture-review item.
