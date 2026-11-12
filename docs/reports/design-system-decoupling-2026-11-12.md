# Native design-system decoupling

The reusable UI on macOS, iOS, Android, Windows and Linux no longer accepts signing-core models.
Domain mapping belongs to presentation adapters; components receive display values and callbacks.

Apple's shared components compile in a `DesignSystem` target with no target dependencies. Feature
settings, bookmarks and card selection are outside that target. Android uses display models for card
wallets and PIN prompts, and UI-owned status tones. Its feature host retains consent request identity
so a replacement request resets PIN input even when its display text is identical.

Windows wallet and status controls use bound display values and selection events. File selection
uses an injected `IFileSelectionProvider`; live/demo behavior remains in the application adapter.
Linux card and placeholder widgets accept presentation content and compile independently with GTK,
Foundation and localization support.

The architecture tests reject core/application dependencies in all reusable UI folders. The Apple
and Linux compilation checks additionally catch undeclared/transitive source dependencies. Native
mock UI suites continue to exercise the adapters through the actual apps.

## Validation

Final code source: `a3ce7d7e5504bd7a6afae072bad645e60f7ca29c`.

[Full CI run](https://github.com/xfreebird/smartcard/actions/runs/43192144735): all nine jobs passed, including `CI result`.

Verified CI results:

| Platform | Build and test evidence |
| --- | --- |
| iOS | App and extension build; all 36 expected UI methods on iPhone/iPad passed without skips. Both protection round trips and Documents postchecks passed. |
| macOS | Debug, App Store variant and CLI builds; 42 application tests; 11 native UI tests with no failures or skips. |
| Android | Debug and instrumentation builds; 16 application tests; 34 native journey completions plus protection storage and restart checks. |
| Windows | 257 core/integration tests; all native UI suites, including 8 workflow and 4 verification scenarios; MSI/MSIX packaging. |
| Linux | 38 application tests; standalone GTK design-system build; 21 native UI scenarios; CLI/app packaging. |

Swift core and CLI checks passed on Apple and portable backends. Shared localization, routing,
publishing and architecture guards passed. Native UI evidence was inspected from this run's retained
artifacts. Core suites retain their existing opt-in/platform skips; no hardware or live-PKI claim is
made from those results.

Local checks passed:

- macOS and iOS Simulator Debug app builds; standalone Apple design-system build.
- 42 Apple application tests.
- Android app and instrumentation APK builds; 16 application unit tests.
- Android native suite: 34 journey completions plus storage, prepare and restart verification.
  History actions use explicit control identifiers and awaited tab/dialog transitions; cancellation
  and saved-document preservation checks remain enforced.
- Fedora native application build and 38 tests; isolated GTK design-system build.
- Native Windows x64 Debug build of the corrected control sources.
- 56 workflow/architecture guard tests, localization export check and actionlint.

Validation uses fictional cards and mock scenarios. It does not establish real-card, live-PKI or
store-delivery acceptance. Existing iOS 27.2 Files automation and full hardware/OS journey-catalog
coverage limits remain documented in the [cross-platform validation report](commit-ci-validation-2026-11-11.md)
and [living plan](../../PLAN.md).

Ordinary commits continue to run validation without publishing application versions. No release
workflow, tag, store upload or hardware operation was performed for this refactor.
