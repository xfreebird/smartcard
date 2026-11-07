# macOS integration investigation — 2026-11-07

The most useful next step is to improve document handoff around the existing signing flow: native preview/share first, then a separate Verify Finder service. Keep explicit consent in the foreground. A new token extension, background signing daemon, or document indexing scheme has substantially greater cost and risk.

This is a source inventory and feasibility assessment, not a claim that proposed integrations ship or have passed runtime validation. Sources were checked on 2026-11-07. The installed `/Applications/eSemnBun.app` reports macOS 15.0 minimum; the app targets' Release settings also specify 15.0. Nothing here establishes macOS 14 support.

## Already implemented

| Integration | Evidence in current source | Boundary |
| --- | --- | --- |
| Finder Open With / Dock file opening | `apple/Apps/macOS/Info.plist`: Viewer, Alternate rank, PDF/XML/public.data; `AppDelegate.application(_:open:)` | Queues documents and opens Sign; does not sign on receipt. Broad public.data is intentional for detached signatures. Signed PDF/XML is not routed automatically to Verify. |
| Finder Services | `NSServices` → `signDocuments`; `NSApp.servicesProvider` | Reads file URLs and uses the same queue. This is a Service, not a dedicated Finder Action extension or Finder Sync extension. English default service name merits localization work. OS registration and actual Finder invocation were not tested here. |
| Menu-bar and Dock behavior | `MenuBarPopover.swift`, `WindowPresentation.swift`, `MoldSignMacApp.swift` | Main/settings windows become regular app windows; menu-only mode is accessory. Show/open/about/settings/quit commands exist. |
| Login and insertion startup | `SettingsView.swift`, `OnboardingView.swift`, `Startup/ReaderActivationService.swift` | `SMAppService.mainApp` plus non-Store launch agent; approval affordance exists for watcher. Store intentionally omits standalone watcher. |
| Finder reveal | Shared `SignScreen.swift`, `ActivityScreen.swift`, macOS popover | Success/recent rows reveal output in Finder. |
| Browser integration | `BrowserScreen.swift`, shared bridge and bookmarks | Existing WKWebView, external portal bridge, bookmarks and cloud key-value bookmark capability. This is not a Safari extension. |
| Preview/share | Shared `SignScreen.swift` | Quick Look and ShareLink success-row UI is guarded for iOS; there is no corresponding macOS success-row preview/share action. |
| Shortcuts / App Intents / Spotlight / Handoff | Source search across Apple targets | No macOS AppIntent, NSUserActivity or Core Spotlight implementation found. The existing share extension is iOS-only. See the separate Siri/Shortcuts investigation for that proposal. |

## Recommended sequence

### 1. Native preview and output sharing — high value, small/medium scope

Add a macOS preview action for queued/signed PDFs and a native share action for completed outputs, keeping the entire existing success row as Finder reveal. Apple provides Quick Look UI for previewing common document types and SwiftUI ShareLink for invoking the system sharing interface. No custom PDF preview extension is needed just to preview a standard PDF. [Quick Look UI](https://developer.apple.com/documentation/QuickLookUI), [ShareLink](https://developer.apple.com/documentation/swiftui/sharelink).

Implementation candidate: macOS-specific row action menu or adjacent labeled buttons; use system preview presentation and scope file access for the full preview/share lifetime. Keep outputs immutable: Quick Look appearance is not cryptographic validation, and a preview must never mark a signature valid. For detached XML, share the XML and original intentionally together or explain the pairing; do not silently expose a containing directory. Validate Desktop and sandboxed Store builds separately, canceled share/preview, removed files, provider URLs, and multiple output selection. Reuse existing localized preview/share labels where applicable.

### 2. Explicit Verify service and localized Finder actions — high value, small/medium scope

Keep current Open With behavior stable, but add a separate “Verify with eSemnBun” Service so signed documents can reach Verify directly. Route through one application-level import function with explicit operation intent. Apple distinguishes Services from Finder Action extensions; Quick Actions extensions can appear in Finder's preview pane/menu. A dedicated extension is justified only if visibility/discoverability testing shows the existing Services path is insufficient. [AppKit app extensions](https://developer.apple.com/documentation/appkit/app-extensions).

First prove cold-launch file delivery, multiple files, unsupported inputs, sandbox access, localized service names and cancellation on the current Services mechanism. Never automatically sign files from Finder, URL schemes, or a script. Cost grows to medium/high if a new extension target, app-group handoff, bundle signing and extension lifecycle become necessary.

### 3. Refresh startup state when System Settings changes — medium value, small scope

Startup controls are already modern integrations; don't replace them. Refresh `SMAppService` status when the app/Settings becomes active, including main-app approval state, so external changes are reflected without reopening the process. This is a code-inspection candidate: watcher status currently initializes in `@State` and refreshes on its own toggle; a stale external change has not been reproduced. Apple documents registration/status for login items, launch agents and daemons, and emphasizes visible user control over background work. [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice), [Background process guidance](https://developer.apple.com/documentation/appkit/managing-ongoing-background-processes-in-your-mac).

Validation should change approval in System Settings on a dedicated test profile, return to the app, and confirm status without re-registering a disabled service. Preserve the Store/non-Store split and the helper's no-PIN/no-signing responsibility.

### 4. Searchable history — optional, medium scope with privacy design

Core Spotlight can make app records discoverable through a private on-device index; deletion and updates must keep the index in sync. This could expose an intentionally selected signed document and open its existing history record. It should be opt-in and index minimal filename/date metadata, not document content, IDNP, certificate subject, PIN, or browser request data. Clearing history must remove index entries too. [Core Spotlight](https://developer.apple.com/documentation/CoreSpotlight), [Adding content to indexes](https://developer.apple.com/documentation/CoreSpotlight/adding-your-app-s-content-to-spotlight-indexes).

First decide whether Finder already provides enough filename search. Do not add indexing only for platform completeness. Test missing/replaced files, stale index cleanup, sandbox bookmarks, and privacy when search suggestions are visible. Newer intelligence/search APIs are not a requirement for this baseline.

### 5. Handoff / Quick Note — exploratory, lower priority

NSUserActivity supports continuing an activity and linking back to app content. A safe first candidate is reopening a public portal/bookmark or a local verification view, not transferring card authorization. Files and security-scoped access are not automatically transferred merely by advertising an activity. Never include a PIN, certificate identity or private document bytes in activity metadata. [NSUserActivity](https://developer.apple.com/documentation/foundation/nsuseractivity).

Defer until there is a concrete cross-device workflow and an explicit file-transfer/privacy design. A card attached to one device does not make remote signing available.

## Defer as separate projects

A CryptoTokenKit token extension would expose an identity to other apps, changing authorization and attack surfaces substantially; this investigation has not established that the reverse-engineered card flow can safely satisfy all token-extension contracts. Finder Sync overlays are unnecessary for a signing app without a managed synchronization domain. A custom Quick Look XML signature summary could be useful later, but requires safe parsing of untrusted data and must distinguish structure from verified trust. No such capability was implemented in this change.

For every future entry point, preserve the existing shared signing gate, selected-certificate match before VERIFY, foreground consent, cancellation, explicit output destination and no unattended PIN retrieval. Preview, metadata discovery and import must remain non-signing operations.
