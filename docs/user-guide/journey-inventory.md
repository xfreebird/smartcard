# Illustrated user guide: feature and journey inventory

Source audit: 8 November 2026, current working tree. This is the production plan for end-user documentation, not a claim that every hardware or system integration has been exercised. Screenshots must use isolated fictional data. Do not describe the sample data in public guides and do not display a demo banner inside documentation captures.

## macOS signing refresh — 12 November 2026

Refresh Sign, progress, per-file error and PDF stamp screenshots in EN/RO/RU after moving Sign to the trailing bottom safe area. Capture the production main window and native stamp sheet with isolated fictional data. Check the action stays readable with the complete batch count, the busy state remains disabled, and localized step markers match the new placement. Native XCTest execution is recorded separately from these visual captures.

## Deliverables and languages

Publish English (`en`), Romanian (`ro`) and Russian (`ru`) guides. The website already declares those three locales in `website/docusaurus.config.js`; all three native interfaces are localized. Capture each language natively: translated prose around an English screenshot is insufficient.

| Guide | Devices / presentation | Existing destination |
| --- | --- | --- |
| macOS desktop | Native Mac window; distinguish standalone and Mac App Store | `website/docs/platforms/macos.md` |
| iPhone | Phone portrait plus landscape workflow where it changes layout | `website/docs/platforms/ios.md` or a linked iPhone guide |
| iPad | Tablet portrait/landscape and constrained multitasking | Separate linked iPad guide; do not reuse phone captures |
| Android phone | Native phone compact navigation | `website/docs/platforms/android.md` or linked phone guide |
| Android tablet | Native expanded tablet navigation; constrained window behavior | Separate linked tablet guide |
| Linux desktop | Native GTK/libadwaita; Ubuntu/Fedora package differences | `website/docs/platforms/linux.md` |
| macOS CLI | Terminal commands, installation, MCP/approval configuration | `website/docs/platforms/macos-cli.md` |
| Linux CLI | Terminal commands, reader service, MCP | `website/docs/platforms/linux-cli.md` |
| Windows CLI | Explicit partial CLI coverage and MCP | `website/docs/platforms/windows-cli.md` |

Localized copies belong under `website/i18n/{ro,ru}/docusaurus-plugin-content-docs/current/platforms/`. Windows desktop and CLI are covered in all three languages. Desktop tasks use fresh native numbered captures; CLI tasks use explicitly instructional terminal panels.

Use `GuideScreenshot` with screenshot-native numbered callouts and a matching step list. One goal per journey. Each numbered action must point at an actually visible control, not a hidden action or an inferred gesture. For dialogs, output states or another tab, use a subsequent image. Keep original clean PNGs available as the source for overlays. Every image needs useful localized alternative text.

## Core GUI journey coverage matrix

Each row is required on every applicable GUI form above, in each language. An image may support several tightly related steps; do not attempt to fit every journey into one overview screenshot.

| ID | User goal and numbered actions | Screenshot sequence / required visible evidence | Applies |
| --- | --- | --- | --- |
| G01 | Install and open: choose correct app package/channel, install, open, locate primary navigation | Download/install illustration where practicable, first native window/screen; link canonical Downloads rather than private GitHub assets | All |
| G02 | Connect reader: attach compatible USB/adapter, grant access if asked, insert card, wait, confirm holder/expiry | No reader → empty reader → loaded card; Android USB access state | All; Android permission is specific |
| G03 | Select correct identity: switch carousel/card selector, confirm holder, inspect/re-read card and certificate details | Multiple cards; Card tab with certificate fields and re-read control | All |
| G04 | Add signing documents: open Sign, choose/drop/import files, inspect names, remove unintended inputs | Empty Sign; populated PDF and mixed batch; file controls visible | All; mobile picker/share integration; desktop drop |
| G05 | Choose signature format: inspect default PDF PAdES-T / other-file XAdES-T, choose requested format, understand detached originals | File format chooser and selected format | All; document only formats actually offered |
| G06 | Add visible PDF stamp: choose Add/Edit stamp, enable stamp, position/size, choose page/all pages, optionally apply to queued PDFs, save | Stamp control; PDF stamp editor; saved stamp summary | All GUI implementations have stamp editor |
| G07 | Sign a document/batch: review selected certificate and whole list, press Sign, enter correct PIN or saved-PIN authorization, wait | Ready queue → authorization/PIN dialog → progress → completed result | All |
| G08 | Save/share/open output: activate completed result, export/save/share to destination, confirm output name | Completion actions and destination picker where useful | All; platform-specific action names/output rules |
| G09 | Handle failed item: inspect item error, keep successful outputs, fix input/connection before a new deliberate attempt | Mixed/failed result and human-readable message | All; do not document a nonexistent Retry button |
| G10 | Verify PDF: open Verify, add signed file, expand signature, inspect integrity/chain/time/certificate | Empty Verify → populated valid result → expanded certificate details | All; no reader/PIN required |
| G11 | Verify detached XML: add XML, supply unchanged original via supported picker/directory mechanism, recheck result | Missing-original state and original selection; completed state | All, tailored to actual UI |
| G12 | Interpret verification: distinguish invalid/modified, unconfirmed chain, unsigned/unrecognized, multiple signatures | Separate invalid, untrusted, unsigned and multi-signature examples where supported | All; explain offline revocation limit |
| G13 | Find saved documents: open Documents/Activity, select document, review signing details modal, open/share/reveal | Populated Documents → details modal; optional unavailable file | All; Linux Activity contains Documents/History modes |
| G14 | Clean history: select History, clear list, confirm; return to Documents | History and clear confirmation; retained Documents list | All; clearing history must not claim to delete output files or signed-document collection |
| G15 | Use a website: open Browser/service/bookmark or enable external bridge, navigate to card login/sign, inspect origin/request, authorize | Browser start/navigation; consent; completion. Use safe local mock website for capture | Apple/Android in-app browser; Linux external system browser |
| G16 | Manage website bookmarks/data: add/edit title+URL+icon, navigate, clear selected cache/cookies/history | Bookmark controls/dialog; clear-data controls | Apple/Android browser; not Linux in-app browser (none) |
| G17 | Manage saved PINs: save only via explicit option, unlock using offered platform mechanism, delete entry/all | PIN Remember option; dedicated saved-PIN settings; delete action | Apple/Linux only; Android rememberAvailable=false (AND-06), so do not claim saved-PIN UI |
| G18 | Set language and appearance: open Settings/Preferences or OS app settings, choose supported options | Native preferences for Apple/Linux/Android | In-app language/theme selectors; Android also offers browser stamps, PIN removal, Demo/About |
| G19 | Demo/help/about/update: enable normal demo only intentionally, access help/version, update through installed channel | Settings/About/help/update where controls exist | All; normal demo is labelled, unlike isolated documentation capture |
| G20 | Recover reader/browser problems: distinguish permission/no reader/empty/read error/port busy, correct cause | Relevant native state plus recovery control | All; never retry incorrect PIN automatically |

## Platform-specific journeys

| ID | Platform | Goal / evidence |
| --- | --- | --- |
| M01 | macOS standalone | Menu-bar reopen/main window, Settings/About/Quit; closing window may leave process active. |
| M02 | macOS standalone | Enable start at login and reader/card insertion helper, approve Login Items when required, configure open-window-on-insertion. App Store capability differs: photograph only available controls. |
| M03 | macOS | Browser Settings: response toggle, PDF stamp preference, recognized MoldSign conflict/reconnect; distinguish legacy desktop access toggle and Store in-app workflow. |
| M04 | macOS | Enable local agent approval broker in Settings; configure helper spool, stage PDF, review native approval, authorize or cancel, retrieve output. Native broker exists on macOS only. |
| A01 | iPhone/iPad | Share extension / Files import; export signed output via system share sheet. Use actual picker path, not just file presence in sandbox. |
| A02 | iPad / iPhone Duo | Card+files in wide/landscape space, compact navigation in narrow split window; distinguish visible adaptation from untested drag/drop. |
| A03 | Apple | Shortcuts: Open Documents, Prepare PDF for Signing, Verify PDF. Prepare stages a PDF and requires foreground signing approval; verification returns offline outcome and opens results. Input capped at 32 MiB. No silent Siri signing. |
| A04 | Apple | Enable document discovery, search/open signed documents through Spotlight, optionally search via system intent. Only readable app-owned signed PDF/XML metadata is discoverable; filenames are indexed, not document bodies/PIN/certificate identity. Latest search-in-app schema is SDK/compiler and iOS/macOS27 gated. |
| A05 | Apple | Handoff resumes Documents navigation; does not transfer document contents, pending signature, selected certificate or PIN. Do not illustrate file continuity that is not implemented. |
| D01 | Android | USB permission, external-browser signing notification/foreground service, return to consent; no Siri/Spotlight/macOS broker claims. |
| D02 | Android tablet | Navigation rail/expanded window and landscape card+files workflow; compact split-window behavior. |
| L01 | Linux | Install GUI DEB/RPM/Flatpak; prepare local PC/SC and CCID, distinguish desktop/session access from SSH. |
| L02 | Linux | Preferences startup and background browser connection; system browser instead of an in-app browser. |
| L03 | Linux | Optional replacement localhost HTTPS identity import; this is bridge identity, not personal signing certificate. Native data/Flatpak location differences; normal package already bundles identity. |
| L04 | Linux | Saved PIN uses Secret Service/keyring; locked/unavailable keyring is distinct from incorrect card PIN. |

## CLI and agent integration journeys

Use terminal screenshots with fictional filenames, reader/certificate examples and no real secrets. Commands themselves remain untranslated; translate explanations/annotations and capture locale-specific guide context. Label any composed/mock terminal transcript outside the image; do not imply a physical-card operation was performed. Prefer real read-only `capabilities` and fixture verification output, with signing examples clearly instructional.

| ID | Goal / steps | macOS | Linux | Windows |
| --- | --- | --- | --- | --- |
| C01 | Install from Downloads/platform package manager, locate executable, run help and `capabilities --json` | Homebrew/universal tar.gz | APT/RPM/archive; Arch recipe where appropriate | Scoop/Chocolatey/ZIP |
| C02 | Prepare reader and list `readers`; choose exact `--reader`; inspect `cert --out leaf.der` without PIN | Yes | PC/SC socket + CCID first | Yes |
| C03 | Sign PDF and locate separate output; omit output for `-semnat.pdf` default; no overwrite | Yes | Yes | Not normal CLI document signing |
| C04 | XAdES BES/T/C, detached/enveloping; preserve original; SHA-256 default | Yes | Yes | Not normal CLI |
| C05 | PIN no-echo prompt / `--pin-stdin` / env precedence; stop after wrong PIN | Yes | Yes | Supported card commands only |
| C06 | Verify PDF/XML + original directory; text and `--json`; interpret exit/status | Yes | Yes | Not normal CLI verifier |
| C07 | Start browser `server`, loopback defaults18480/18443, stop Ctrl+C, avoid competing bridge | Yes | Yes | Not normal CLI |
| C08 | Configure local MCP host and explicit trusted roots; discover capabilities; verify fixture | `esemnbun-mcp` | `esemnbun-mcp` | `esemnbun mcp` |
| C09 | macOS foreground approval: enable app broker, private spool, prepare/poll/cancel, collect result | Yes | No GNOME approval UI | No WinUI approval broker |
| C10 | Explicit unattended MCP opt-in: pin exact cert SHA256, private output directory, secret-provider reference, reconcile persistent failure lock | Keychain/env/1Password | env/1Password | Credential Manager/env/1Password |
| C11 | Diagnose code1 usage,2 invalid/incomplete/no recognized signature,3 wrong PIN,4 blocked,5 reader,6 network; never auto retry | Full commands | Full commands | Command coverage and error support differ |
| C12 | Advanced reference: raw `sign-hex`, detached `cms-for-hash`, legacy sign form | Both | Both | `sign-hex`; discover installed support |

`spec/cli.md` explicitly documents Windows partial coverage, while `spec/mcp.md` documents Windows verification/unattended MCP separately. Do not confuse Windows MCP signing with availability of `esemnbun sign`. Capability output is authority for installed binary support. App Store execution aliases/embedded helpers and physical-card unattended credential authorization are not proven by source or package presence.

MCP requires operator-selected physical roots, no symlink/traversal grant, no PIN tool argument, bounded files. Foreground broker directory and child directories must already be private0700; unattended output directory must already be owned/private (Windows restricted ACL). Signatures pin exact certificate before PIN. Wrong PIN/uncertain outcome leaves durable failure lock; inspect outcome before explicit reconciliation. No production unattended success claim without actual signed installed helper, credential provider and card validation.

## Capture hooks for platform agents

### 2026-11-12 signing-action refresh

Refresh G03/G04/G06/G07/G08/G09 signing-flow images for native iPhone and iPad in English,
Romanian and Russian. The primary Sign action now floats above the bottom safe area; updated
callouts must point to that visible action and retain the complete viewport on iPad. Include
card selection, stamp, consent/PIN, progress, completion and failed-item screens that show the
signing workspace or its native actions. Use the validated Debug build, isolated fictional fixtures
and per-asset capture provenance; these images do not establish real-card signing.

### Apple

Authoritative capture driver: `apple/scripts/capture-screenshots.sh macos|ios APP_PATH OUTPUT_DIR [SIMULATOR_UDID]`. It requires Debug binary. Set `MSIGN_CAPTURE_LANGUAGE=en|ro|ru` and optionally `MSIGN_CAPTURE_THEMES=light` for localized documentation captures. Keep dedicated simulator IDs/preferences suites.

Required isolation flags: `MSIGN_DEMO_CARDS=1` (3 for multiple), `MSIGN_SCREENSHOT_CAPTURE=1`, `MSIGN_QA_NO_HARDWARE=1`, `MSIGN_DEMO_PREFERENCES_SUITE=md.esemnbun.qa.<run>`. Set `MSIGN_DEMO_SCENARIO`, `MSIGN_DEMO_FILES`, `MSIGN_DEMO_SELECTED`, theme and `-appLanguage en|ro|ru -AppleLanguages '(en)'`. iOS environment uses `SIMCTL_CHILD_` prefixes and `MSIGN_DEMO_TAB=sign|verify|documents|browser|card`. Mac uses `-mainSection sign|verify|browser|card|activity`. Ready marker: `MSIGN_DEMO_READY`.

Baseline scenarios: `no-reader`, `empty-reader`, `unavailable`, `reading`, `ready`, `multiple`, `error`, `signing`, `success`, `pin`, `sign-failure`. `AppModel.applyDemoScenario` additionally supports prefix fixtures: `verify-empty`, `verify-loading`, `verify-valid`, `verify-invalid`, `verify-untrusted`, `verify-unsigned`, `verify-incomplete`, `verify-multiple`; `documents-empty`, `documents-populated`, `documents-unavailable`, `documents-details-valid`, `documents-details-incomplete`, `history-populated`. Reports derive meaning from substring; verify exact visible state after launch. `MSIGN_CAPTURE_SHEET=settings` autoopens Card settings on Apple; macOS also has `MSIGN_DEMO_SETTINGS=1`. Stamp editor, bookmark dialogs, certificate expansion and OS Shortcuts/Spotlight/Handoff may need UI interaction rather than a scenario hook.

Sources: `apple/Apps/Shared/Model/AppModel.swift`, `Services/Demo/ScreenshotFixtures.swift`, `Screens/{SignScreen,VerifyScreen,PDFStampEditor,SavedDocumentDetails,AuthSheets}.swift`, `AppIntents/{ESemnBunShortcuts,DocumentDiscovery}.swift`, platform shells/settings.

### Android

Use Debug APK and explicit emulator serial only. Existing driver `android/scripts/capture-screenshots.sh APK OUTPUT_DIR SERIAL` loops theme/pages/scenarios but omits `store_capture`; add `--ez store_capture true` on the isolated capture launch to suppress banner. Launch component is `md.esemnbun.app/md.moldsign.app.MainActivity`. Intent extras: `--es demo SCENARIO --es demo_page sign|verify|browser|activity|card --ez store_capture true`; optional `--ez stamp_preview true`. Ready log tag `MoldSignDemo`, message `ready:PAGE`. Each new screenshot intent resets navigation/scroll/dialog state.

Exact Debug scenarios in `android/app/src/debug/kotlin/md/moldsign/app/DemoMode.kt`: `one`, `cards`, `reading`, `error`, `empty`, `permission`, `noreader`, `documents`, `batch`, `results`, `sign-failure`, `pin`, `pin-warning`, `activity-empty`, `verify-valid`, `verify-invalid`, `verify-unconfirmed`, `verify-none`, `verify-xml-missing`, `verify-xml-complete`. Activity is seeded by default. Documents detail modal, format picker, settings, browser and certificates may require interaction. Set native app locale/preferences before capture and verify the visible labels.

Sources: `ui/screens/SignScreen.kt`, `VerifyScreen.kt`, `ActivityScreen.kt`, `ui/components/Documents.kt`, `presentation/MainViewModel.kt`, `MainActivity.kt` and Debug DemoMode. Do not use release APK fake extras or a physical device for the isolated scenario workflow.

### Linux

Read environment/VM skills before remote work. Existing owner drivers: `linux/scripts/capture-{mocks,scenarios,desktop,ubuntu}-air.sh`. Scenarios in `Presentation/Preview/DemoScenario.swift`: `documents`, `signing`, `pin`, `pin-error`, `success`, `signing-error`, `verify-checking`, `verify-valid`, `verify-invalid`, `verify-unknown`, `verify-unsigned`, `activity`, `settings`.

Flags: Debug `MOLDSIGN_DEMO` binary, `MSIGN_SCREENSHOT_CAPTURE=1`, `MSIGN_DEMO_LANGUAGE=en|ro|ru`, `MSIGN_DEMO_DARK=0|1`, `MSIGN_DEMO_CARDS`, `MSIGN_DEMO_SELECTED`, `MSIGN_DEMO_PAGE=sign|verify|card|activity`, `MSIGN_DEMO_SCENARIO`, isolated `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `MSIGN_DEMO_WORK_DIR`, `MSIGN_DEMO_RUN_ID` and `MSIGN_DEMO_READY_FILE`. Validate ready JSON fields for scenario/run/page/language before taking screenshot. Set desktop session variables for local Wayland/DBus as the environment requires. Normal demo data may contain explicit sample-document text; the screenshot-specific naming/visual path suppresses app banner. Inspect actual visible contents.

## Accuracy and completeness gates

- Current published docs say0.2.0; replace with verified current release context or version-neutral wording. Verify per-target deployment settings before changing compatibility claims (Xcode project has mixed target values; Android minSdk26).
- Do not present generated signing fixtures as cryptographically signed outputs. A native UI scenario confirms appearance only. Reader transport, PIN correctness, live portal, drag/drop and OS integrations each need their own runtime evidence.
- Current common signing page mentions a Retry action; recent app UX deliberately has no retry button. Describe correction and starting a new deliberate request.
- Always explain: physical card required, USB/adapter prerequisites, NFC unsupported, PIN never shared, incorrect PIN not guessed repeatedly, private key remains on card, detached originals unchanged, offline verification is not a current revocation check.
- Record asset provenance (commit/build or binary hash, form/size, locale/theme, mock scenario, readiness marker). Never reuse one device screenshot as another device or add localized labels to an untranslated native screen.
- All journey callouts must remain legible on a phone, avoid obscuring filenames/status/primary buttons and retain matching step order. Publish functional screenshot links and inspect rendered pages in every language.
- Coverage is complete only when every applicable matrix row has illustrated steps or an explicit reason it cannot be illustrated. A screenshot gallery without goal-based action steps is insufficient.

## Source corrections for platform authors

Android source specifically sets `rememberAvailable = false` in `ui/MoldSignRoot.kt` with TODO(AND-06): a platform vault abstraction is not a shipped saved-PIN UI. Android General now includes per-app language/theme, browser stamps and selected-card PIN removal, alongside Demo/About. New PIN retention is still unavailable.

Windows source verification: `CliApp.Run` explicitly dispatches `mcp` to `McpHost`; normal command dispatch remains partial. `CliApp` capability writer advertises `mcpServerAvailable:true`, so the older JSON example in `spec/cli.md` saying false is stale. `McpServer` now exposes `prepare_signing`, `get_job` and `cancel_job` when a private desktop broker is configured, plus verification and explicit unattended signing. Native approval is separate from ordinary CLI sign command support.

## File protection — 9 November 2026

Added five discoverable goals: password encryption, encryption for a certificate holder, password/card decryption, public encryption-certificate sharing, and local file removal. Each has EN/RO/RU numbered guides for Mac, Windows, Linux and their CLI tools. iPhone, iPad and Android phone/tablet cover the first four; removal is unavailable on mobile.

Recaptured the native screens separately in EN/RO/RU. Numbers and pointer lines remain entirely outside the image in reserved gutters. `file-protection-evidence.json` records native locale, source and hashes. Card discovery/export completion and card decryption remain textual instructions from source, not runtime success evidence. CLI panels are explicitly instructional command illustrations.

## File protection revision — 10 November 2026

Native apps expose password encryption/decryption from the Documents navigation menu. The Moldovan ID card has no supported encryption key, so native certificate/card journeys are removed. CLI compatibility commands remain documented with this restriction. Capture the menu entry, clearly bordered password/confirmation fields, completion with Done, and saved encrypted/decrypted entries. Apple and Android save app-managed outputs automatically; Windows and Linux use a save-location step. Captures must reflect the final platform behavior, including each locale.

## Test traceability

The [test catalog](../../tests/journeys/catalog.json) maps every journey above to acceptance criteria, edge cases, existing/new automated suites and explicit native runtime requirements. See [test commands and coverage limits](../testing/README.md). Fixture captures do not establish end-to-end or hardware coverage.
