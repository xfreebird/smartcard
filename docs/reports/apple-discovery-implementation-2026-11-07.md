# Apple discovery implementation — 7 November 2026

Shared Apple App Intents now provide Open Documents, offline Verify PDF and Prepare PDF for Signing on iOS and macOS. Prepare imports a bounded 32 MiB PDF into Documents/eSemnBun Imports in a unique directory, then opens the signing queue. It neither invokes signing nor accepts a PIN. The input copy remains available for review; users can remove imported files from storage. Standalone macOS writes signatures beside those imports; sandboxed apps use their existing Documents output policy.

The custom intents require device authentication and foreground execution. The Files open schema additionally requires local-device authentication, enforced by Xcode metadata extraction. `supportedModes = .foreground` is used on OS 26+, retaining `openAppWhenRun` for older deployment targets. Existing offline verification verdicts and temporary-copy cleanup remain unchanged. Detached XML verification is not added by this change.

## Schemas and discovery

`SignedDocumentEntity` adopts the current `@AppEntity(schema: .files.file)` API and `FileEntityIdentifier`. `OpenSignedDocumentIntent` adopts the OS 27 `@AppIntent(schema: .system.open)` when built with Xcode 27, and opens the selected signed document's existing details view. Older toolchains use the Files open schema. The latest schema action is available on OS 27; earlier OS versions retain Open Documents, Verify PDF and Prepare PDF custom actions. Entity string queries support filename matching, suggestions and identifier resolution. Every query and execution rechecks the opt-in preference, library membership, resolved containment, regular-file status and readability. The query never resolves an arbitrary identifier to a permission-granting URL.

Discovery is disabled by default. Enabling the Siri/Spotlight setting exposes signed-output filenames and dates. Sandbox apps allow only their Documents directory; standalone macOS allows only the managed eSemnBun Imports directory. Beside-input outputs elsewhere and verification history are excluded. Core Spotlight indexes only filename, date and file type using an opaque local library UUID. No contentURL, text content, thumbnail, certificate data, identity number or PIN is supplied. The searchable attributes associate the `IndexedEntity` with its file-schema identity, so Siri can resolve results through the guarded entity query. File schema entities necessarily identify files to the OS, but no Transferable file representation or document body is donated.

Index reconciliation serializes domain deletion and rebuilding, rechecks the setting after awaited deletion, and runs at app/window activation, Documents appearance and signing-library updates. Turning the setting off schedules index deletion and immediately makes entity resolution return no documents. Files removed while the app is not running are purged on the next reconciliation; already indexed stale results can briefly remain, but opening them rechecks membership/access.

Handoff advertises only the Documents screen with a generic localized title. It has no document identifier, filename, URL, certificate, PIN, queued operation or approval state. Both platform shells receive the same activity type. Spotlight result activation is separate and resolves only a local library UUID. Handoff never transfers a signing request.

## API evidence and limits

Checked official Apple documentation and installed Xcode 26.6 / Xcode 27.1 RC AppIntents interfaces. Both SDKs expose the schema macros used here; 27.1 uses the newer AppSchema declarations internally. The basic integration compiles with either SDK. OS 27 system search/open schemas are compiled only with Swift 6.4/Xcode 27, using explicit runtime availability gates.

- [Files entity schema](https://developer.apple.com/documentation/appintents/appschema/filesentity/file) documents Siri and Shortcuts experiences.
- [Files open schema](https://developer.apple.com/documentation/appintents/appschema/filesintent/openfile) currently lists **Shortcuts** in its supported experiences, despite its Siri-oriented explanatory text. This implementation does not establish that Siri AI will invoke file opening in natural language.
- [App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains) defines domain matching. Cryptographic signing has no adopted matching schema here; preparation and verification remain custom App Intents.

New settings, action labels/descriptions and broker approval text are in the RO/EN/RU catalog. Existing App Shortcut invocation phrases are English. This does not claim Romanian/Russian Siri voice availability or live Siri AI support in any region/account.

## Validation

Focused compiler typechecks passed for the schema/entity/query/index/settings implementation on Xcode 26.6 and 27.1 RC, with small stubs for existing application dependencies. Shared shortcut implementations typechecked with Xcode 27.1 RC against the existing MoldSignKit module. Its old `supportedTypeIdentifiers` parameter initializer emits a deprecation warning but preserves iOS 17 support. Plist lint, localization export consistency and whitespace checks passed. The full macOS Debug application build and App Intents metadata extraction passed with Xcode 27.1 RC after fixing schema property initialization ordering and the Files schema authentication policy. No device Siri conversation, Spotlight click, Handoff transfer, provider permission revocation or real signing was performed. Further platform build results follow below.

Final integration builds all passed using Xcode 27.1 RC and `/tmp/esemnbun-integrations-dd`, with code signing disabled:

- `eSemnBun-macOS`, Debug, macOS: compile/link and App Intents metadata extraction passed (`/tmp/esemnbun-integrations-mac-build.log`).
- `eSemnBun-iOS`, Debug, generic iOS Simulator: arm64 and x86_64 compile/link and App Intents metadata extraction passed (`/tmp/esemnbun-integrations-ios-build.log`).
- `eSemnBun-macOS-AppStore`, **AppStore Debug**, macOS: sandbox configuration and metadata extraction passed (`/tmp/esemnbun-integrations-appstore-build.log`). A scheme invocation with plain Debug would test the desktop configuration; the final command explicitly used AppStore Debug.

These are unsigned build results, not installed/runtime, store submission or live Siri AI validation. Existing unrelated compiler concurrency/deprecation warnings remain. Available disk after the builds was approximately 2.1 GiB; no unrelated caches or artifacts were removed.


## OS 27 Siri AI additions

The latest implementation adds the genuinely Siri-supported [system.searchInApp schema](https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp) and [system.open schema](https://developer.apple.com/documentation/appintents/appschema/systemintent/open), introduced in OS 27. Apple lists Siri and Shortcuts for both. Search authenticates locally, requires discovery opt-in, forwards `StringSearchCriteria.term` to the Documents screen and shows filename-filtered results in the actual app. Search does not transfer results or file bodies to another app. The Documents search field also works manually. Open revalidates library membership and access before presenting document details.

One OpenIntent is generated per entity type: metadata extraction rejects two separate open intents targeting the same entity even when their schemas differ. Therefore the stable intent selects the OS 27 system schema at compile time on Xcode 27, retaining the old Files schema on older toolchains. This is a capability availability distinction, not a claim that the old Files schema becomes Siri-supported.

Opt-in row-level `.appEntityIdentifier` annotations attach only `EntityIdentifier` references to readable app-owned signed documents. This modifier is available from iOS 18.4/macOS 15.4 (it is discussed prominently in [WWDC26 advanced App Intents](https://developer.apple.com/videos/play/wwdc2026/343/), but is not itself newly introduced in OS 27). Annotation resolution uses the same guarded query. No Transferable file representation, document-body donation, selected certificate or approval state is added. Handoff remains generic navigation-only.

The schemas make the actions eligible for Siri AI dispatch; actual dispatch, linguistic matching and onscreen reference resolution still require eligible OS/device/account/region settings and have not been exercised live. The final platform build logs above are rerun after these additions, including metadata validation.

Final generated metadata was inspected in `Debug/eSemnBun.app/Contents/Resources/Metadata.appintents/extract.actionsdata`: `OpenSignedDocumentIntent` contains `assistantDefinedSchemas = system/OpenIntent`; `SearchSignedDocumentsIntent` contains `system/SystemSearchInAppIntent`. Both are discoverable, introduced on OS 27, foreground and locally authenticated. `SignedDocumentEntity` contains the Files/FileEntity schema and Indexed entity protocol. The macOS, iOS simulator and AppStore configuration builds all passed again after these final additions. This confirms registration in the generated artifact, not live Siri dispatch.
