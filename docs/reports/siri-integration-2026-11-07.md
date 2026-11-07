# eSemnBun Siri integration — 7 November 2026

Research and proposed design, not implemented or runtime-tested. Start with iOS 17-compatible App Intents for verification and foreground navigation; add Siri AI schema integration only where its semantics fit. No signing authorization should move into Siri.

## Verified project baseline

The iOS target supports iOS 17 (`apple/eSemnBun.xcodeproj/project.pbxproj`). No App Intent, App Entity or App Shortcuts implementation exists under `apple/`. The selected toolchain is Xcode 26.6, so newer schema work needs a compatible SDK and separate device validation.

`apple/Apps/iOS/MoldSigniOSApp.swift` imports files into the signing queue, owns Sign/Verify/Documents navigation, and explicitly stops the bridge in the background. `AppModel.signAll` freezes the documents and selected certificate, obtains authorization through the existing PIN flow, and passes the expected certificate identity into signing. Preserve those checks, including before each card VERIFY.

`Services/Documents/DocumentWorkflows.swift` provides `DocumentVerifying`/`CoreDocumentVerifier`, scoped file access and detached-XAdES sibling loading. iOS signed outputs go into app Documents. `ActivityItem` persists a URL, not a security-scoped bookmark; history is not continuing permission to external files. The Documents screen filters signed outputs, including a legacy filename fallback. Do not treat all successful verification history as owned signed documents.

## Public integration surface and availability

App Intents describe actions; App Shortcuts publish discoverable entry points in Siri, Shortcuts and Spotlight. They remain useful independently of Apple Intelligence. Apple's current guidance specifically recommends custom App Shortcuts for capabilities outside schemas. This report targets iPhone/iPad; Apple's HIG distinguishes macOS support. [App Shortcuts](https://developer.apple.com/design/human-interface-guidelines/app-shortcuts)

The installed SDK confirms `AppIntent` and `IntentFile` start at iOS 16, `IndexedEntity` at iOS 18, and `supportedModes` at iOS 26. Keep `openAppWhenRun` for iOS 17–25, with availability-gated foreground modes on 26+. The latter replaces the deprecated foreground flag. [IntentFile](https://developer.apple.com/documentation/appintents/intentfile), [execution modes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes), [WWDC25](https://developer.apple.com/videos/play/wwdc2025/275/)

Siri AI is now a shipping **beta**, not just an announced future feature. Apple's 26 October update lists iOS 27.2 and English, French, Japanese, Korean, Portuguese and Spanish on supported Apple Intelligence devices; iOS/iPadOS availability excludes the EU. Older English-only support pages lag this announcement. This was not tested with our tooling. [Apple availability announcement](https://www.apple.com/newsroom/2026/10/siri-ai-is-available-in-more-languages-starting-today/)

Current App Schemas use `@AppIntent(schema:)`/`@AppEntity(schema:)`; older assistant-schema examples are not a substitute for checking the target SDK. Siri AI integration requires an appropriate schema, while custom intents still serve Shortcuts. Files and system/in-app search are primary Siri domains; Reader and Word Processor schemas are explicitly Shortcuts-only. No documented cryptographic signing schema was established by this research: never misrepresent signing as editing or sending. [Schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains), [Apple's integration guidance](https://developer.apple.com/videos/play/wwdc2026/8011/)

## Recommended delivery order

1. **Verify document.** Accept `IntentFile` PDF/XML input from Shortcuts or a file-selection action. Materialize a bounded, app-owned temporary copy; reuse `CoreDocumentVerifier`, not the UI model. Return a concise structured verdict and a route to full results. Distinguish invalid, unsigned, unreadable and incomplete verification. Detached XAdES needs explicitly supplied companion files or a foreground picker; a lone temporary XML loses sibling access. Never collapse missing companions or read failures into “valid.” Begin with foreground execution if duration, input size or companion access is uncertain.

2. **Prepare document for signing.** Accept a file, require device authentication, foreground the app and open Sign with the queued document. The user reviews format/stamp, selected identity and documents, then explicitly starts the existing signing flow. Returning “Ready for review” must never imply a signature exists. No PIN parameter, voice PIN, credential donation, model tool or silent signing. Device unlock is additional protection, not signing consent. [Intent authentication policy](https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy)

3. **Open Documents / choose signed document.** Add a simple foreground navigation shortcut first. Then introduce `SignedDocumentEntity` with stable ID, filename, type and date, resolving only accessible app-owned outputs. Recheck existence/access on every execution. External history entries require re-selection or deliberately managed bookmarks. Entity queries must not bypass file-provider permissions.

4. **Optional indexing and Siri AI.** On iOS 18+, opt-in `IndexedEntity` integration can expose selected document metadata to Spotlight. Delete indexed entries when history/access is cleared or files disappear. Exclude PINs, IDNP, certificate subject details and document bodies by default. Separately evaluate a genuinely matching Files/open or search schema with the newer SDK; do not promise natural-language signing/verification recognition. Add content transfer or onscreen context only for deliberately shared content. [Apple Intelligence integration](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai)

## Implementation and validation boundary

Proposed files: `Shared/AppIntents/VerifyDocumentIntent.swift`, `PrepareSigningIntent.swift`, `OpenDocumentsIntent.swift`, `SignedDocumentEntity.swift`, and an intent file-access adapter; iOS-only `ESemnBunShortcuts.swift` and foreground route handling. Keep initial intents in the app target, excluding the Share Extension; a separate extension adds unnecessary execution/storage coordination. Never start the bridge or require a reader for verification. Reader connection, PIN interaction and signing remain foreground operations.

Localize titles, parameters, dialogs and shortcut phrases in RO/EN/RU through the catalog pipeline and extraction-compatible resources. UI localization does not imply Siri voice support: the cited Siri AI list includes neither Romanian nor Russian. Retain selectable Shortcuts actions and app navigation regardless of spoken-language availability.

Validate on iOS 17 and newer supported OS/device combinations: clean install discovery, locked-device rejection, cold launch routing, file-provider revocation, duplicate filenames, malformed/large input, detached XML, cancellation, removed history and index deletion. Confirm prepare-sign never invokes signing and preserves queued work. Use simulated-card tests for identity changes/authorization, then owner-run hardware checks. Test Siri AI separately with eligible locale/account/region and compatible SDK. No builds, tests, live authentication or card operations were run for this report.
