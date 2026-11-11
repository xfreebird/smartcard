# Application service boundaries refactor — 11 November 2026

Follow-up implementation and current test status: [architecture and test review](architecture-and-test-review-2026-11-11.md). The remaining-scope section below records the state at this earlier pass.

The change removes direct fixture construction from several application paths and introduces replaceable
live/demo data providers across Apple, Android, Linux and Windows. It also extracts Apple's document
library behavior and separates combined screen, domain and service files.

## Behavior and contracts

- Apple uses the same signing/verifying ports in live and demo flows. A demo session supplies card fixtures
  and document files through interfaces. Document history, deduplication, clearing, deletion and discovery
  notifications belong to `DocumentLibraryModel`. Switching stores replaces both state and callback.
- Android document bytes come through `DocumentDataProvider`. Live reads still use the supplied
  `DocumentAccess`; demo reads return fixture bytes without opening the supplied URI. Preview names,
  metadata and rendered outputs belong to `PreviewDataProvider`. Existing demo authorization and import
  guards remain in place. Destination screens and shared components have separate files.
- Linux certificate providers own hardware/vault work or delayed preview results. `ReaderSession` retains
  its stale-generation check before applying results. Demo persistence uses a separate memory store from
  initialization, avoiding the previous real-history read/migration before clearing the screen.
- Windows certificate providers supply pending, failed or ready results. The application continues to
  apply them to the selected wallet generation. Demo mode is explicit composition state; replacing a
  reader implementation no longer determines whether the app uses live credentials.

No card protocol, PIN retry, CMS/PDF/XML cryptography, network trust policy or release automation was changed.
Existing unrelated untracked reports and evidence were preserved.

## Verification performed

- Swift syntax-only parsing in normal and Debug/demo configurations passed. This does not type-check,
  build, link, validate Observation expansion or prove application behavior.
- Token inventories of moved Apple/Linux domain definitions and Android screen bodies were compared with
  their originals; code was preserved apart from the intended Kotlin shared-helper visibility changes.
- Project source discovery and explicit source lists were reviewed; Apple policy-package inputs and
  Windows portable test source links were updated.
- `git diff --check` passed.

## Added tests — not executed

- Apple `DocumentLibraryModelTests`: switching persistence keeps live/demo history and discovery isolated;
  clearing history retains saved outputs; deletion ignores files absent from the library.
- Linux `CardDataProviderTests`: a late certificate result cannot overwrite a replacement card; injected
  providers do not trigger vault reads; independent memory stores do not share history.
- Windows `CardDataProviderTests`: selected-reader forwarding, original error propagation, pending reads,
  and distinct blocked/stuck demo states.

The owner runs builds and tests. Run the Apple policy package tests and both app targets; Android app/core
unit tests and app assembly; Linux package tests/build; Windows core tests and native WinUI build. Check
live/demo switching, document-library clear/delete, insertion/removal during certificate reads, signing,
verification, and existing screenshot fixtures on each platform. No runtime, CI or hardware validation
has been performed for this refactor.

## Remaining architecture work

This is a substantial dependency-boundary refactor, not a claim that all code smells are gone. Apple's
`AppModel`, Linux's `AppController` and Android's `MainViewModel` still coordinate several workflows.
Bridge authorization, signing-session lifecycle and screenshot scenario orchestration should become
separate collaborators in subsequent changes with focused lifecycle coverage. Core bridge/format parsers
also remain large; their protocol-sensitive behavior was deliberately kept outside these application
boundary changes. Existing platform adapters and narrow ports should be reused before adding wrappers.

## Subsequent runtime validation

The owner subsequently authorized builds and tests. See [native test validation](native-test-validation-2026-11-11.md)
for executed targets, discovered fixes, passing evidence, skips and the remaining macOS runner blocker.
