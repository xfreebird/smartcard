# Architecture review — second pass

Current build, native test and delivery evidence is tracked in [commit CI validation](commit-ci-validation-2026-11-11.md). The unrun/pending statements below describe the earlier review checkpoint.

Follow-up implementation and current test status: [architecture and test review](architecture-and-test-review-2026-11-11.md). The remaining-scope section below records the state at this earlier pass.

## Findings fixed

1. **Linux verification result/filename mismatch.** Starting a batch selected its last file, but every
   completion unconditionally replaced the detail reports. An earlier file's report could appear under
   the last filename. `VerificationWorkspace` now records every accepted result while updating the
   detail reports only for the selected file. Reset invalidates pending completions and clears selection.
2. **Apple verification request lifetime embedded in the app coordinator.** Extracted an observable
   feature model with generation and cancellation guards before and after each asynchronous read.
   Cancelled work cannot add history after the verifier returns; mode changes invalidate the workspace.
3. **Android batch policy in presentation.** Extracted `SignDocuments`: one scoped batch consent,
   frozen reader/certificate identity, output naming and saving, recoverable per-file failures and fatal
   cancellation/security failures. Presentation receives typed Started/Saved/Failed events. Output storage
   implements a narrow port. Errors in a UI event consumer are no longer caught as signing errors.
   Fatal VM errors are not treated as recoverable document failures.
4. **Windows verification policy coupled to WinUI and localized outcomes.** Extracted `VerifyDocument`
   into the Desktop assembly. It rejects disallowed source/companion files before invoking the verifier
   and distinguishes completed verification, unreadable input, unsupported behavior and unexpected
   failure. AppServices handles localized presentation and operation accounting.

## Architecture decision

Use platform-native presentation patterns: observable feature models for SwiftUI, ViewModel/StateFlow
and events for Compose, passive GTK views with main-loop presentation state, and thin WinUI views with
observable state and Desktop workflows. Share the dependency direction, not framework boilerplate.
Reuse core signing/verifying contracts; add ports only at actual I/O substitution points. Details are
in section 6 of `docs/09-architecture.md`.

## Validation

- Swift syntax parsing passed in normal and Debug/demo configurations for the changed Swift sources.
- `git diff --check` passed.
- Added Linux tests for batch filename/result association and reset rejecting late results.
- Added Windows tests for companion-file rejection before verifier invocation, unsigned reports and
  unreadable-input classification.
- Builds, type checking, all tests and native UI checks remain **unrun**, following the owner's rule.
  Syntax checks do not prove type correctness or runtime behavior.

Required validation: Apple app builds plus overlapping/cancelled Verify requests and demo switching;
Android build/tests plus a mixed-success batch, revoked output access, cancellation and wrong-PIN stop;
Linux package tests plus multi-file verification/reset; Windows core tests/native build plus saved-file
inspection and demo companion rejection. Use simulated cards for signing flow regression checks.

## Remaining review scope

App-level bridge, PIN/consent and screenshot orchestration remain in the larger coordinators. This pass
extracts cohesive workflows and fixes observable defects; it does not claim that every UI class or core
parser is now fully decomposed. No cryptographic protocol or release automation was changed.

## Subsequent runtime validation

The owner subsequently authorized builds and tests. See [native test validation](native-test-validation-2026-11-11.md)
for executed targets, discovered fixes, passing evidence, skips and the remaining macOS runner blocker.
