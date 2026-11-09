# Assistant shortcuts

Implementation status (2026-11-09): iOS simulator and Android debug builds pass; Android app unit tests pass (8 tests). Simulator/emulator file-selection and unsigned-PDF verification smoke checks pass; widget coverage is partial (details below). Physical-device voice validation and store delivery remain pending. Existing store versions do not include these changes.

## Android

Long-press the eSemnBun launcher icon and choose **Verify PDF**, **Prepare Signing**, or **Documents**. On launchers that support it, drag a shortcut onto the home screen. Labels are localized in English, Romanian and Russian.

Verify and Prepare Signing open the Android document picker, restricted to one PDF. Select from Downloads or an installed document provider. Verify displays the existing verification results. Prepare Signing adds the file to the signing queue; review it and explicitly sign in the app. Cancelling keeps existing documents unchanged. Documents opens the library.

The same features are declared for Google Assistant through `actions.intent.OPEN_APP_FEATURE`, with an inline inventory and explicit activity fulfillment. Example English commands for device testing after creating an App Actions preview:

- “Hey Google, open Verify PDF in eSemnBun.”
- “Hey Google, open Prepare Signing in eSemnBun.”
- “Hey Google, open Documents in eSemnBun.”

Voice availability depends on Google's supported Assistant locale, preview/review and deployment. Romanian/Russian launcher labels do not imply Assistant support in those languages. [Google's supported locales](https://developer.android.com/reference/app-actions/built-in-intents/common/open-app-feature) and [review requirements](https://developer.android.com/develop/devices/assistant/get-started).

Gemini AppFunctions are not included: Google's current [AppFunctions documentation](https://developer.android.com/ai/appfunctions) describes an experimental API and Gemini private preview. Launcher shortcuts and Assistant declarations do not establish Gemini compatibility.

Public entry points accept only three feature identifiers. They do not accept a PIN, arbitrary file path, or authorization to sign. Requests wait for active signing/consent to finish. A second shortcut waits for the open picker to close, then replaces the earlier selection; stale results are discarded. Rotation retains the picker purpose.

## iPhone, iPad and Mac

On iPhone and iPad, open eSemnBun once, then touch and hold its Home Screen or App Library icon. Choose **Verify PDF**, **Prepare Signing**, or **Open Documents**. These quick actions use the same navigation and PDF picker as Siri. They work when the app is already running or launches from a closed state. Menu labels refresh when opening/leaving the app to follow the selected language. Android's three launcher shortcuts above are its matching quick-action entries.

Say one of these phrases with Siri configured in English:

- “Open documents in eSemnBun.”
- “Verify PDF with eSemnBun.”
- “Prepare PDF for signing in eSemnBun.”

The two PDF App Shortcuts have no spoken filename parameter: they open the app and its native file picker. Select a PDF from Files/iCloud Drive on iPhone/iPad or the Mac file chooser. Signing still requires foreground review and approval.

For personal Shortcuts workflows, **Verify PDF** and **Prepare PDF for Signing** retain optional file inputs. Connect a previous action's file output to avoid choosing again; leave the input empty to select a file in eSemnBun. Verification returns its actual offline result only after selection and verification. Cancellation, superseding requests and the five-minute selection timeout end the waiting action without fabricating a verification result.

PDF imports enforce a 32 MiB limit, PDF header validation and security-scoped access. Preparation protects its copy from a newer request overtaking it. App Shortcut phrases are shared by both Apple targets and localized in English/Romanian/Russian, subject to Siri's language availability. Saved-document entity actions remain restricted to the app's opt-in, accessible library; they do not search arbitrary Downloads paths.

## Validation before release

The owner runs native builds/tests. Static XML/resource checks, localization parity and Swift syntax parsing are separate from this required runtime matrix:

1. Android: run `cd android && ./gradlew :app:testDebugUnitTest :app:assembleDebug`. The new `AppShortcutsTest` checks allowed IDs, missing-parameter fallback, unsupported actions and path-like inputs.
2. Install on phone and tablet. Exercise all three launcher shortcuts cold and warm; pin one. Repeat in all app languages, rotate during the picker, cancel, and choose from Downloads and a cloud provider.
3. While a picker is open, invoke another shortcut; only the latest selection may run. Repeat during signing/PIN/stamp consent. Check sharing files still works.
4. Create an App Actions preview with Google's Android Studio plugin; use the same test account on device and Play Console. Verify the three English voice commands and missing-feature fallback. Request App Actions review before claiming public voice availability.
5. Apple: build both targets with the repository-required Xcode 27 SDK and inspect extracted App Intents metadata for all five App Shortcuts and shared phrase localizations.
6. On iPhone/iPad also test all three Home Screen quick actions after first launch, after force-quitting, and after changing app language. On iPhone, iPad and Mac test Siri cold/warm launch, native/cloud file selection, cancellation and repeated requests. Test custom Shortcuts with supplied input and empty input, timeout, malformed/oversized PDFs and verification output. Confirm an older slow import cannot replace a newer action.

Direct Android routing smoke check (not proof of Assistant recognition):

```sh
adb shell am start -n md.esemnbun.app/md.moldsign.app.MainActivity -a md.esemnbun.app.OPEN_FEATURE --es esemnbun_feature verify_pdf
```

Use `prepare_signing` or `documents` for the other destinations. Unknown IDs must leave navigation unchanged. These commands select a feature only; they cannot select a private document or sign it.

## Verification and recent-document widgets (iOS and Android)

Both widget implementations build successfully. Android launcher installation and rendering have been exercised; the iOS system successfully registered and generated small/medium widget placeholders. See the validation record below for runtime coverage and remaining checks.

On iPhone/iPad, open the app, then add **eSemnBun — Verify & Recent Documents** from the Home Screen widget gallery. The small widget opens the PDF picker for verification. The medium widget also opens Documents and shows up to two recent signed documents when document discovery is enabled. Turn on document discovery in the app's settings to show filenames; leave it off for a verification-only widget. Locked/redacted widget contexts mark filenames as sensitive.

On Android, add the eSemnBun widget from the launcher's widget gallery. Tap **Verify PDF** to choose a file, **Documents** to open the library, or a recent filename to open its signing details. To display filenames, enable **Show recent documents in widget** in Settings. This is off by default. The widget is a Home Screen widget, with light/dark system colors and a minimum height that accommodates two accessible document rows.

Both widgets show metadata only. They do not contain document bytes, private paths, certificate details or PINs. Recent entries are based on the signed-document library, not clearable activity history. Apple rechecks library membership and readability at each document tap; Android rechecks library membership and the privacy preference, then lets the existing details view report a missing file or revoked permission. Cancelling PDF selection does not sign or remove anything. Widget refresh timing is controlled by the OS; disabling filenames clears the app's widget data and requests a refresh, but an already-rendered system snapshot may persist until the OS redraws it.

Apple Shortcuts now also includes:

- **Open Latest Signed Document**: opens the newest accessible, opted-in signed document; opens Documents if none is available.
- **Verify Latest Signed PDF**: verifies the newest eligible PDF offline and returns the existing verification result. If discovery is off or no recent PDF is accessible, it opens the file picker.

English Siri phrases: “Open latest signed document in eSemnBun” and “Verify latest signed PDF with eSemnBun”. The phrases and labels are translated into Romanian and Russian, subject to Siri's supported languages. These App Intents are shared with macOS; this change adds widgets only for iOS/iPadOS and Android.

### Additional validation and signing requirements

- Build the iOS app with its embedded `eSemnBunWidgets` extension (`md.esemnbun.ios.widgets`). Before signed packaging, register that ID, enable App Groups, assign `group.md.esemnbun.shared`, and create its development/App Store/ad hoc profiles through the existing match process. The release lane includes the widget in its target signing and both export profile maps. Provisioning completed on 2026-11-09: the widget identifier has the shared App Group, and development/App Store/ad hoc profiles were pushed to match and their entitlements verified.
- Validate small/medium iOS widgets and the Android widget with no documents, discovery off/on, two recent signed outputs, long filenames, language changes, dark/light mode, deleted files and revoked provider access.
- Validate cold/warm Verify and document taps, system lock/redaction, cancellation, and a widget tap while a signing consent sheet is active. Confirm clearing history preserves the recent signed library and disabling discovery removes filenames after the system refresh.
- Check both new App Intents with an empty library, a newest XML output plus an older PDF, inaccessible files, malformed PDFs and multiple simultaneous requests. Confirm verification returns an offline result and never requests a signing PIN.

## Integration validation record — 2026-11-09

Tested the current working source in an isolated copy on the MacBook Air. No physical card or personal document was used. These are debug/simulator checks, not signed-store archive validation.

| Area | Evidence and outcome |
| --- | --- |
| iOS build | Xcode 27.1 RC simulator build succeeded for the app and embedded widget; five App Shortcuts and EN/RO/RU metadata extraction/training succeeded. |
| Android build/tests | Debug APK built; all 8 app unit tests passed, including two shortcut routing tests. |
| iPhone 18 Pro, iOS 27.0 | Home Screen menu showed all three quick actions. Verify PDF opened Files; selecting the unsigned repository PDF returned the expected unsupported/no-signature result. |
| iOS widget route | Opening `esemnbun://widget/verify` opened Files. Cancelling preserved the earlier verification result. This tests the URL route, not a Home Screen widget tap. |
| iOS widget extension | Registered with the system; logs showed successful small/medium placeholder generation. Home Screen installation could not be completed reliably through remote UI control, so installed-widget rendering/taps remain unverified. |
| Android API 36, foldable/tablet emulator | Explicit Verify feature intent opened the native picker; selecting a fictional unsigned PDF returned No signature. No application crash was observed. This does not prove Assistant voice recognition. |
| Android widget | Selected in the launcher gallery, added to Home Screen, and rendered with filenames hidden by default. AppWidgetService confirmed the bound provider and RemoteViews. Widget tap navigation and populated recent-document rows remain unverified. |
| Signing | Registered the widget App ID and shared App Group; generated, decoded and checked Development, Ad Hoc and App Store profiles, and pushed them to the match repository. Existing certificates were reused. |

Screenshots are retained locally in `.local/widget-validation-20261109/`: iOS quick actions, Files picker, verification result and cancellation; Android picker, verification result and widget gallery preview. The app itself was not running in demo mode; PDFs were safe test fixtures.

Remaining release checks include actual Siri/Assistant speech, physical-card signing, iPad/phone and theme/language matrix, cloud providers, concurrent requests, signed recent-document navigation, privacy toggles/deleted-file cases, installed iOS widget interactions and signed archive/export. The emulator checks above must not be treated as completion of that broader matrix.

### Widget visual refresh — 2026-11-09

Replaced the plain action labels with a blue verification panel. iOS small widgets focus on Verify; medium widgets use separate action/document columns, a privacy/empty-state icon and two-line filename rows. Android uses a gradient Verify button, neutral light/dark surfaces, contrasting recent-document rows and a three-cell-height preference (launcher minimum sizing still applies). Gallery layouts hide absent document rows. Existing privacy preferences and routing are unchanged.

Both updated native builds succeeded (iOS app plus extension, Android debug APK) and were installed on the existing validation devices. Swift parsing, resource XML parsing and whitespace checks passed. Fresh Home Screen screenshots, long-font/localization cases and dark-mode runtime appearance remain pending: remote UI input did not reliably activate the widget gallery during this pass.

Screenshot follow-up: captured the redesigned Android widget installed on the API 36 emulator Home Screen. Captured an iOS simulator preview harness rendering the current widget view in small, medium/private and medium/sample-document states. The harness substitutes the WidgetKit host background/family and English labels; it is not evidence of installed iOS Home Screen rendering. iOS Home Screen size selection returned to editing without placing a widget. Images and the preview harness are retained under `.local/widget-redesign-20261109/`. Android capture used temporary 260 dpi; restored the emulator density afterward.
