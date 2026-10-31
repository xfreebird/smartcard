# eSemnBun (codename MoldSign) — Cross-Platform Development Plan

> **Living document.** Update it in the same change as the work it describes: tick the box,
> add a line to the [Progress log](#progress-log), and move decisions from *Open* to *Decided*.
> Item IDs (`MAC-04`, `SEC-02`…) are referenced from code as `TODO(MAC-04)`. Use them when
> committing (`git log --grep MAC-04` should tell the story).

Status legend: `[x]` done · `[~]` in progress / partial (implemented, not yet verified on device) · `[ ]` todo · `[-]` dropped (say why)

Last updated: **2026-10-31**

---

## User-facing demo mode — 31 October 2026

- [x] ABOUT-01 List Nicolae Ghimbovschi and the esemnbun.md website in the native About or settings
  surfaces on macOS, iOS, Android, Windows and Linux; the website is a link. Localization export,
  Swift parsing, XAML well-formedness and whitespace checks passed; native builds and UI checks remain.

- [x] DEMO-01 Add a persisted, user-controlled demo mode to macOS, iOS, Android and Windows settings.
  Switching uses isolated mock services and safe simulated outputs, with a visible demo disclaimer.
- [x] DEMO-02 Linux automated screenshot fixtures suppress demo disclaimers only when explicitly capturing;
  ordinary interactive mock runs remain labelled. Debug/Release builds, 13 policy tests and native Fedora
  screenshots verified both modes without real card/PIN operations.
- [x] DEMO-03 Center the empty saved-PIN message in macOS settings and separate Open/Quit tray actions.
- [x] DEMO-04 Validate switching, persistence, isolation and screenshots using mock data; keep evidence on Desktop.

  Android Debug and non-debuggable Release native flows passed enable/confirmation, cold relaunch,
  per-document unsigned sample generation, native sharing and disable; four-ABI audit and focused
  safety tests passed. Fedora screenshot scripts capture without the demo notice and exit GNOME's
  overview before capturing (34 scenario and 28 layout images). macOS native mode switching, sample
  signing and empty-PIN layout passed; the insertion helper was checked with mock insertion events.
  iOS native confirmation, simulated batch, persistence and exit passed; share-sheet presentation
  and a dedicated macOS tray screenshot need separate visual confirmation. Windows Release native confirmation, signing, verification,
  persistence, telemetry suspension and exit passed with 28 focused tests. Apple policy tests passed.

## Optional desktop Sentry — 31 October 2026

- [x] MON-01 Sentry is included ONLY in macOS, Windows and Linux desktop apps. Remove SDKs,
  instrumentation and upload configuration from iOS/Android and CLI tools. Historical mobile/CLI
  test events and the unused Android project remain untouched in the organization.
- [x] MON-02 Native first-launch prompt with separate crash-report and application-metric switches,
  both OFF; no SDK/network reporting before explicit opt-in. Persist decline, do not ask again on
  restart; allow both choices to change immediately in Settings. Cancel sessions and purge unsent
  queues on changes/opt-out. Stable RO/EN/RU keys live in the shared localization catalog.
- [x] MON-03 Actual SDK application metrics (fixed counters and duration distributions), sanitized
  crash reports and optional sampled fixed-operation timings, each gated by its own consent.
  Linux in-process backend records sanitized JSON crash reports for the next opted-in launch,
  without raw minidumps. Windows captures managed unhandled failures; raw native dumps stay disabled.
- [x] MON-04 Native macOS/Windows/Fedora consent flows verified: unknown and persisted decline,
  independent choices, opt-out/cache removal, no repeated prompt. Hosted metrics confirmed in all
  three desktop projects; real controlled SIGABRT received as ESEMNBUN-LINUX-4 after opt-in/relaunch.
  Android clean builds/lint/dependency+APK audits show no Sentry; iOS build/symbol/DSN audit shows no SDK.
- [~] MON-05 Native production symbol uploads are wired for macOS dSYMs, Windows PDBs and Linux DWARF.
  GitHub Actions secret SENTRY_AUTH_TOKEN is configured and Sentry CLI authentication verified; actual upload/full native file-line symbolication remains unverified.
  No production release or store upload was dispatched.
- [x] MON-06 Local privacy policy, macOS manifest and desktop store-disclosure checklist updated;
  mobile remains SDK-free. Public privacy URL and portal forms remain submission prerequisites.
- [x] MON-07 Ubuntu24.04 bundled SDK/app build, thirteen policy tests in a clean scratch directory and
  actual desktop prompt/metrics-only opt-in/default SDK path/opt-out runtime validation passed. Native
  layout compatibility was fixed for libadwaita1.5. Fedora final Debug/Release +13tests also passed.
  Fifteen native consent screenshots across desktop platforms are saved on Desktop, with proof files.

## Card pagination simplification — 31 October 2026

- [x] UI-20 Remove visible previous/next arrows and numeric position rows from Apple and Windows card
  carousels; replace Android's numeric row with dots. Keep native iOS dots, add matching macOS,
  Android, Windows and Linux indicators, and preserve swipe/scroll, keyboard and accessibility navigation.
  Update interaction scripts to observe card selection instead of removed counter text.
- Validation: source and syntax checks only for this small presentation change; native builds and
  refreshed screenshots have not been run. Existing revision2 screenshots predate UI-20.

## Keyboard, carousel and capture corrections — 31 October 2026

- [x] UI-15 Android PIN dialog: actual IME-visible tests must prove the entire field and cancel/sign actions
  remain above the keyboard on phones and tablets, portrait/landscape, including resize while focused.
- [x] UI-16 Android carousel: viewport spans available window content width with native gutters; document
  and detail panels retain bounded reading widths. Keep the selected card centered and fully visible.
- [x] UI-17 iPad/Duo: prove actual touch swipes change selected cards, not only arrows/programmatic scrolling.
  Use a visible native paging affordance and retain one-card snap/centering.
- [x] UI-18 Windows: reduce card imagery, bound/scroll Card page so bottom actions are reachable at ordinary
  and shorter window heights; test wheel and keyboard scrolling.
- [x] UI-19 Standard iPhone: add missing light/dark key-screen screenshots alongside iPad/Duo evidence.

Validation complete: Android has 24 fresh images, eight keyboard-visible matrix cases plus two focused-resize
bounds proofs and a native swipe/cancel check. Windows has 10 fresh images with all four size/theme scroll
checks passing. Apple has 26 iOS + 2 macOS images, including 14 standard iPhone states; six native finger tests
passed across phone/iPad/expanded Duo, selecting 1→2→3 with matching visible holders, selected traits,
full bounds and unchanged center coordinates. Builds, localization and script checks pass.

Evidence goes under each platform's `2026-10-31/revision2` folder. Previous screenshots are before-change
references. Mock-only; no PIN or physical-card operations. Root owns shared tracking/Android, platform agents
own Apple/Windows. Screenshot readiness must include completed navigation/keyboard layout, not just composition.

## Android tablet desktop-layout amendment — 31 October 2026

- [x] AND-14: Tablet Sign uses the desktop vertical hierarchy: centered bounded card, document list/picker
  underneath, compact centered signing action below. Remove independent side-by-side signing panes.
  Keep native navigation rail and nonzero 24dp gutters; other destinations use the same 680dp reading width.
  Apply from 600dp window width so smaller portrait tablets also receive it; narrow split-screen stays compact.
- Validation passed: Debug/Release APK/Release AAB/lint; 32 final-APK-matched portrait/landscape light/dark
  mock captures cover Sign/Card/Verify/Browser/Activity, including multi-document, no-reader and PIN states.
  Portrait runs at 600dp window width; landscape at 1707dp. Compact windows below 600dp retain the phone layout.

## 2026-10-31 corrective acceptance pass

The owner rejected the prior completion assessment after reviewing screenshots. Reopen the following
items until current-source runtime evidence exists. Earlier screenshot counts are historical evidence,
not acceptance of layout or architecture. Preserve existing source changes and unrelated scheme edits.

| ID | Status | Acceptance requirement |
|---|---|---|
| FIX-01 | [x] | Stable semantic localization identifiers in every platform; typed Apple/Linux API, no display-text lookups; three-language exports checked |
| FIX-02 | [x] | Platform code grouped by responsibility, meaningful feature/infrastructure ports and small coordinators; document dependency directions |
| FIX-03 | [x] | Windows carousel centers selection without tiny clipped adjacent-card slivers; reader/drop placeholders match vertical macOS hierarchy |
| FIX-04 | [x] | macOS empty reader is one dotted rectangle; iPad/Duo symmetric pane gutters and centered signing CTA |
| FIX-05 | [x] | Natural portrait bust inside 3:5 frame, proper chip contacts, larger centered PIN entry across platforms |
| FIX-06 | [x] | Configurable non-store macOS and Windows helper detects reader/card insertion while main app is closed; helper lifecycle packaged |
| FIX-07 | [x] | First launch always presents desktop main window on macOS, Windows and Linux, including background-launch edge case |
| FIX-08 | [x] | Rebuild affected targets, targeted current-source screenshot evidence under Desktop/2026-10-31 and validation report; keep runtime gates explicit |

Parallel ownership: Apple platform, Windows platform, Linux platform; root owns Android and shared catalog,
generators and integration. Physical cards remain unused during mock verification; no PIN retries.

---

## 2026-10-30 product adjustment work

**Current layout constraints (owner amendments):** Windows Sign always stacks centered card → selected documents →
drop zone, including wide windows. Maintain native nonzero gutters and spacing; avatar frame3:5, uniformly scaled
person; card golden ratio, right-center chip. iPad/iPhoneDuo wide CTA is one compact native button without a nested
container; selected-document bottom spacing matches the rest of the file pane. Android tablets need adaptive
navigation/workspace; Android builds include ARM and x86-64. Batch authorization/PIN is once for the frozen list,
with no reuse across unrelated batches and no automatic wrong-PIN retry.

These items supersede the earlier expandable vertical wallet design. Implemented items remain `[~]`
until their platform build and runtime evidence is recorded. No physical-card PIN attempts may run concurrently;
mock scenarios must never invoke real transports or credential stores.

| ID | Status | Requested outcome |
|---|---|---|
| ADJ-01 | [x] | Golden-ratio card,3:5 avatar with uniform human scaling, chip at right center; fix Windows stretching |
| ADJ-02 | [x] | Horizontal multi-card carousel on every platform; native controls and common hierarchy |
| ADJ-03 | [x] | Desktop language, system/light/dark theme, saved-PIN deletion preferences |
| ADJ-04 | [x] | Configurable card-insertion activation plus desktop startup/background utility |
| ADJ-05 | [x] | iOS custom URL in-app browsing, mobile-only guidance, compact signing and document sharing |
| ADJ-06 | [x] | Platform sources remain grouped; shared Apple/Linux core retained without duplication; ownership documented |
| ADJ-07 | [x] | One localization catalog, individual platform exports, Romanian/English/Russian |
| ADJ-08 | [x] | Injectable services and isolated mock scenario entry points on every platform |
| ADJ-09 | [x] | Repeatable mock screenshot matrix and Desktop delivery for all platforms |
| ADJ-10 | [x] | VM runtime verification on Air; serialized real-card access; Ubuntu coverage |
| ADJ-11 | [~] | Sandboxed macOS App Store configuration and packaging |
| ADJ-12 | [x] | Repository store metadata/configuration for Apple, Google, Microsoft and Huawei |
| ADJ-13 | [x] | Android tablet adaptive workspace/navigation and explicit ARM/x86-64 package verification |
| ADJ-14 | [x] | One authorization/PIN per frozen document batch; isolate scope and stop on first error |

Validation ledger: initial working tree had an unrelated macOS scheme change; preserve it. Air reachable;
Fedora and Windows initially stopped. Fedora started without reader for mock-only checks. Existing QEMU/HVF
VMs are used because documented UTM 4.7/5.0 versions crash on macOS 27. No new sudo wrapper created.
No PINs or signing credentials belong in this plan, source, fixtures, screenshots or command arguments.

Implementation and verification (31 October, corrective pass):

- FIX-01/02 replace display-text localization lookups with typed stable identifiers and group code by
  responsibility, with narrow signing/verification, reader, document, activity, settings and activation ports.
  Catalog/native export/source usage checks pass for all three languages. See docs/12-platform-adjustments.md.
- FIX-03/04/05 correct Windows selected-second-card centering and vertical empty-reader/drop-zone layout;
  Apple wide pane 24pt gutters, centered CTA, standalone dotted empty state; compact natural bust, explicit
  eight-pad chip, and larger centered PIN content. Current-source targeted captures are dated 31 October.
- Apple native macOS Debug, iOS simulator and unsigned Store-candidate Release builds pass; eight policy tests
  pass. Separate-helper reader/card cold-start and first-launch visible-window checks pass with isolated data.
- Windows native build passes with zero warnings/errors; nineteen focused tests pass, including scoped
  batches, separate signer/verifier interfaces, insertion preferences/muted-card insertion and real IPC.
  Separate-helper reader/card cold starts and first/subsequent ordinary manual visible-window launches pass.
- Fedora and Ubuntu native application builds and nine policy tests per distribution pass. Installed release
  first-background→visible, subsequent-background→hidden and explicit activation→visible checks pass on both.
  Trusted HTTPS works without an insecure bypass. Ubuntu GUI/CLI packages rebuilt and reinstalled.
- Android Debug/unsigned Release APK/Release AAB/lint pass after package/port changes. Core:117 tests, zero failures, one opt-in skip; USB:21 tests, zero failures. Four-ABI ELF audits pass. Final 24 ARM64 runtime captures cover phone and
  both tablet orientations; normal lifecycle factory launch works with injectable ViewModel dependencies.
- Frozen batch authorization and PIN scope are preserved; saved-PIN persistence is attempted once per batch,
  even if storage fails. First failure/cancellation ends the batch without a wrong-PIN retry.
- No physical-card PIN/signature attempts in this pass. The earlier serialized PIN-free certificate read is
  the only real-card probe. No new privileged wrapper, credential change, commit/push, store upload or
  agreement acceptance. Support/privacy URLs deliberately remain placeholders.

Remaining execution/release gates are explicit: owner login-keychain authorization for the distribution
private key and signed Store export/installed acceptance (isolated ad-hoc sandbox launch passed); real OS background permission acceptance;
Flatpak Background portal permission UI; Android x86-64 runtime workflow; physical-card batch/biometric and
insertion acceptance. These are not represented as completed hardware or store-certification tests.

Final evidence ledger and platform reports: docs/reports/platform-corrections-2026-10-31.md.

See `docs/12-platform-adjustments.md` for source ownership, capture commands and evidence limits.

---

## 1. Goal

Replace the STISC **MoldSign Desktop Suite** (Java, `/Applications/STISC/MoldSign`) with native apps on
**macOS, iOS/iPadOS, Android, Windows and Linux (GNOME)**, and a native **CLI on macOS, Linux and Windows**. They sign and
verify with the Moldovan eID card (IDEMIA CosmoX ID-A, IAS/ECC) through a USB reader (bit4id miniLector
POCKET EVO), produce documents that **msign.gov.md** accepts, and act as the local "MoldSign Server" that
government web portals call.

Reader connectivity to support:

| Host port | Adapter | Platforms |
|---|---|---|
| USB-A | none (reader plugs in directly) | macOS, Windows, Linux |
| USB-C | USB-C → USB-A adapter / OTG cable | macOS, Windows, Linux, iPhone 15+ / iPad (USB-C), Android |
| Lightning | Lightning → USB 3 Camera Adapter (powered recommended) or Lightning → USB Camera Adapter | iPhone ≤ 14, older iPads |

## 2. Product principles: easy and seamless

1. **Zero-config.** Plug in the reader and the app notices. Insert the card and the holder's name shows up. No PIN is needed until a signature is made.
2. **One primary action per screen.** Drop files and press *Semnează*. The format is picked automatically (PDF → PAdES-T, anything else → XAdES-T detached). Advanced options stay behind a disclosure.
3. **Always a consent step.** Every signature, including one a browser requests, shows *what*, *who asks* and *which format*, then confirms with Touch ID / Face ID / Windows Hello / biometrics (or the PIN).
4. **Protect the PIN retry counter.** Never retry a PIN automatically. After a wrong-PIN response, delete the stored PIN. Show the remaining attempts.
5. **Native everywhere.** Each platform uses its own UI toolkit, credential store, background model and smart-card stack (Linux: GTK4 + libadwaita, libsecret, pcsc-lite). CLIs are native binaries too (no .NET on macOS/Linux).
6. **Byte-exact interop.** Output must keep passing the msign.gov.md / iText / BouncyCastle checks. Shared golden vectors gate every port.

Design system and screen specs: [docs/10-design-system.md](docs/10-design-system.md).
Mock-ups (all platforms, light and dark): [eSemn UI concepts](https://claude.ai/artifact/5LZRjfVTDrQ9TKnscfWTyi) (private artifact).

## 3. Architecture (summary)

Full detail: [docs/09-architecture.md](docs/09-architecture.md). CLI contract: [spec/cli.md](spec/cli.md).

```
UI (SwiftUI | GTK4/libadwaita | Jetpack Compose | WinUI 3)     CLI (Swift: macOS + Linux | .NET: Windows)
  └─ App services: SigningService · ReaderMonitor · PinVault · BridgeHost · ActivityLog
       └─ Core (per language, same layout): CosmoXCard · SecureChannel · PAdES · XAdES · TrustServices · Validator · BridgeProtocol
            └─ CardTransport: PC/SC (mac, Linux) · CryptoTokenKit (iOS, mac alt) · USB-CCID (Android) · WinSCard (Windows)
```

| | macOS | iOS / iPadOS | Android | Windows | Linux |
|---|---|---|---|---|---|
| Desktop/mobile UI | SwiftUI `MenuBarExtra` + `Window` | SwiftUI | Kotlin + Jetpack Compose (Material 3) | WinUI 3 + tray icon | GNOME: GTK4 + libadwaita, Swift calling the C API (D-10) |
| CLI | Swift `moldsign` | — | — | .NET `moldsign.exe` (Native AOT) | Swift `moldsign` |
| Core | `MoldSignKit` (Swift, **the original core**) | `MoldSignKit` (shared) | `core` (Kotlin port) | `MoldSign.Core` (C# port) | `MoldSignKit` with `MOLDSIGN_PORTABLE` backends (OpenSSL, POSIX) |
| Reader I/O | PC/SC via `CPCSC` (proven); TKSmartCard alt | CryptoTokenKit `TKSmartCard`; NFC slot on iOS 26 (research) | USB Host API + own CCID driver; NFC `IsoDep` (research) | WinSCard P/Invoke | pcsc-lite via `CPCSC` (+ `pcscd`, `libccid`) |
| Hot-plug | `TKSmartCardSlotManager` KVO | same | USB attach/detach + CCID slot status | `DeviceWatcher` | PC/SC polling (`PCSCTransport.readerStates()`) |
| Background | Menu-bar agent (`LSUIElement`), launch at login (`SMAppService`) | Foreground only (R-01) | Foreground service `connectedDevice` | Tray app, start at login | `GApplication` hold + Background portal; `moldsign server` systemd user unit |
| PIN store | Keychain + `LAContext` | Keychain + Face ID | Keystore AES-GCM + `BiometricPrompt` | Credential Locker + Windows Hello | libsecret (GNOME Keyring / Secret Service) |
| Browser bridge | `NWListener` 18480/18443 | `NWListener` while foreground | loopback server in the FGS | Kestrel | POSIX sockets + OpenSSL TLS |
| Min OS | app macOS 15 · CLI macOS 14 | iOS 17 | Android 8.0 (API 26) | Windows 10 1809 | GNOME 46+ (libadwaita ≥ 1.5), e.g. Ubuntu 24.04, Fedora 40 |

### Repository layout

```
PLAN.md · AGENTS.md · .github/workflows/ci.yml
spec/                 vectors/card-crypto.json · bridge/allowed-origins.properties · cli.md
swift/MoldSignKit/    Swift package: the reverse-engineered core + `moldsign` CLI + tests (moved from MoldSignMac/,
                      history preserved); used by the Apple apps and by Linux
apple/
  MoldSign.xcodeproj  Xcode project (source of truth): MoldSign-macOS · MoldSign-iOS · moldsign-cli
  Apps/{Shared,macOS,iOS}/   SwiftUI apps (synchronized folders)
linux/                GNOME app: GTK4 + libadwaita C API from Swift · data/ (.desktop, metainfo, icon) · flatpak/
android/              Gradle: core (Kotlin port) · transport-usb (CCID) · app (Compose)
windows/              .NET: MoldSign.Core · MoldSign.Cli · MoldSign.App (WinUI 3) · tests
scripts/              package-{macos,ios,android}.sh · test-portable-macos.sh   → dist/ (git-ignored)
docs/                 01–08 RE docs · 09 architecture · 10 design system · 11 build & release
re/                   Reverse-engineering workspace (unchanged)
```

---

## 4. Phases and tasks

### Phase 0: Foundation (restructure, contracts, skeletons)

Exit criteria: the core builds as a library for macOS **and** iOS, the CLI behaves as before, all
skeletons exist with TODOs pointing back to this plan, and golden vectors are shared.

- [x] F-01 `MoldSignMac/` → `swift/MoldSignKit/` SwiftPM package (`MoldSignKit` library, `CPCSC`, `moldsign` CLI) via `git mv`
- [x] F-02 `.gitignore`; stopped tracking `.build/` (2,519 committed build files)
- [x] F-03 Removed the hard-coded card PIN from the CLI (`sign-hex`, `cms-for-hash`): `--pin-stdin` / `MSIGN_PIN` / no-echo prompt
- [x] F-04 `CardTransport`: `PCSCTransport` (macOS) + `TKSmartCardTransport` (iOS/macOS). TK on device = IOS-02
- [x] F-05 Core is iOS-safe: no `Process` (curl/openssl). TSA/CRL/OCSP via `TrustServices` (plain HTTP over `NWConnection` + native OCSP request); `osascript` PIN prompt only in the macOS CLI fallback
- [x] F-06 `MSLog` facade: the CLI keeps verbose traces, apps silence them
- [x] F-07 Bridge server embeddable: `start()`/`stop()`/`run()`, `authorize` (consent + PIN), `onEvent`, `onListenerError`, TLS identity lookup
- [x] F-08 Hermetic tests: fixtures in the repo; network tests gated by `MSIGN_NETWORK_TESTS=1` (live TSA, CRL, OCSP pass)
- [x] F-09 `spec/vectors/card-crypto.json`: Swift, Kotlin (and C#, F-13) suites pass it
- [x] F-10 `spec/bridge/allowed-origins.properties` (73 vendor patterns) + drift test against the Swift copy
- [x] F-11 Xcode project `apple/MoldSign.xcodeproj`: macOS menu-bar app, iOS app, CLI target. All build (macOS, iOS simulator + device); package tests run from the scheme
- [x] F-12 Android skeleton (`android/`): `core` port (38 tests, all vectors pass), `transport-usb` CCID (7 tests), `app` Compose (debug APK builds)
- [x] F-13 Windows skeleton (`windows/`): C# core port (108 tests incl. all vectors), Windows-only `MoldSign.Cli`, WinUI 3 tray app (C# compiles against WinAppSDK 1.8; XAML compile and runtime need Windows)
- [x] F-14 Docs: 09 architecture, 10 design system, AGENTS.md + docs 01–08 paths, spec/cli.md
- [x] F-15 Design mock-ups (all platforms, light and dark), contrast fixes folded into the tokens

### Phase 1: macOS MVP (replaces the vendor suite on Mac)

Exit criteria: daily use on Mac without the Java suite. Sign/verify PDF + XAdES from the UI,
msign.gov.md works through the bridge with consent, PIN in Keychain, starts at login, notarized build.

- [~] MAC-01 Menu-bar agent with status icon (no reader dimmed · ready · busy · error); explicit menu actions wait for the target window, restore/raise it and activate the agent, including reused windows behind other apps
- [~] MAC-02 `ReaderMonitor` (TK KVO): reader plug-in and card insert drive the status; PIN-less certificate read greets the holder. Needs device run
- [~] MAC-03 Sign flow: drop zone (popover, window), Dock / "Open With" → queue, auto format, step progress, `<name>-semnat.<ext>` without overwrite
- [~] MAC-04 PIN panel: 4–8 digits, attempts line, "remember"; stored PIN gated by `LAContext`; saved only after the card accepted it
- [~] MAC-05 Wrong PIN deletes the stored PIN and never retries (`63Cx` → `wrongPIN`, `6983` → `pinBlocked`); also for browser requests via `MoldSignServer.onSignResult` (live-tested deny path)
- [~] MAC-06 Verify view: verdict badge + signature cards + technical details
- [x] MAC-07 Bridge host in the app: consent panel per request, "trust site 10 minutes", PIN via Keychain/Touch ID. **Live msign.gov.md signing confirmed with 0.1.1 (2026-10-25)**
- [ ] MAC-08 Detect the vendor Java server on 18480/18443 (state `portBusy` already shown) and offer to quit it
- [~] MAC-09 Settings: launch at login (`SMAppService`), bridge toggle, allowed sites. Formats/output policy still read-only
- [x] MAC-10 Activity log (last 100, persisted; reveal in Finder); bridge entries record the outcome, format, SHA-1, document and batch (`onSignResult`), replacing the misleading "request received = ok" entry (also in the GNOME app)
- [x] MAC-11 Card session serialization (`SigningService` lock, used by UI and bridge)
- [ ] MAC-12 Verify on device: `SCardReconnect(RESET)` on connect (docs say "always"; code doesn't)
- [~] MAC-13 Entitlements + hardened runtime: `com.apple.security.smartcard` set; sandbox decision D-04 open
- [ ] MAC-14 Finder Quick Action / Share extension "Semnează cu MoldSign"
- [~] MAC-15 Packaging: `scripts/package-macos.sh` → universal DMG + archive + universal CLI tarball; Developer ID signing + notarization (DMG stapled, CLI notarized) with the App Store Connect API key, in the `release` workflow. Developer ID Application `4N85G38A26` (portal, from our CSR; the API can't create it) imported into match; local run: DMG and CLI notarized (Accepted), DMG stapled, Gatekeeper `accepted / Notarized Developer ID`. Sparkle (D-05) todo
- [ ] MAC-16 Localization: String Catalog ro (default), ru, en
- [ ] MAC-17 First-run onboarding (docs/10 §4.7)
- [~] MAC-20 **Several cards at once**: per-reader cards with a picker (popover, Sign, Card screens); `/certificates` lists all; the bridge signs with the portal-chosen card; consent for that card. Simulator-tested + live `/certificates` with 2 real cards (both listed, names decoded). GNOME too: `CardSelector` (AdwComboRow / GtkDropDown) on Card + Sign pages, run against both real readers
- [~] MAC-21 **Card removed / reinserted / swapped**: per-reader card generation (TK slot state + `TKSmartCard.valid`), cached certificate dropped and re-read, "Recitește cardul" action; identity guard before every VERIFY (`cardChanged`, PIN never sent to another card). Needs a real swap test on device
- [x] MAC-22 Names with diacritics: decoded `X509Name` for UI, verify reports and `/certificates` ("Ștefan Mîndru", not `M\C3\AEndru`); XAdES issuer keeps the vendor escapes
- [~] MAC-19 Multi-document portal batches: `use_pin_session` / `keep_pin_session=1` honoured in the core bridge (same origin only, memory only, 5 min idle TTL), so one consent + PIN covers the batch; the card still verifies per document. Simulator e2e-tested; live batch retest with 0.1.2 pending
- [ ] MAC-18 App icon + menu-bar template icon artwork

### Phase 2: iOS / iPadOS

Exit criteria: sign a PDF on iPhone over USB-C **and** Lightning adapters; msign.gov.md works in the in-app browser.

- [ ] IOS-01 Spike: miniLector EVO as a `TKSmartCardSlot` over USB-C adapter and Lightning → USB 3 Camera Adapter (power draw)
- [ ] IOS-02 `TKSmartCardTransport` on device: full mutual auth + sign; does TK need an explicit reset?
- [~] IOS-03 Connection guide with adapter tiles + live status banner
- [~] IOS-04 Document flow: Files picker, "Open in" (`onOpenURL`), results in Documents (visible in Files) + Share
- [~] IOS-05 Keychain PIN + Face ID (`NSFaceIDUsageDescription` set)
- [~] IOS-06 In-app browser (WKWebView) on msign.gov.md with the bridge in-process. http :18480 only until the TLS identity question (D-03) is settled
- [ ] IOS-07 Bridge in Split View / Stage Manager (both apps foreground), documented limits (R-01)
- [ ] IOS-08 Share extension "Semnează" (memory cap, R-06)
- [ ] IOS-09 NFC research: CosmoX IAS/ECC over contactless? iOS 26 `createNFCSlot` + `iso7816.select-identifiers` (R-03)
- [~] IOS-10 Packaging: `fastlane ios_release` → one archive, App Store IPA uploaded to TestFlight (no waiting for processing) + ad hoc IPA (match AdHoc), in the `release` workflow; App Store Connect app 6826865290; `scripts/package-ios.sh` stays for unsigned archives. Export compliance: `ITSAppUsesNonExemptEncryption = NO` (owner's call, exempt encryption only). App Store review strategy (vendor TLS key R-02, private API audit) todo

### Phase 3: Android

Exit criteria: sign on a USB-C Android phone; Chrome on the same phone signs through msign.gov.md.

- [x] AND-01 Kotlin port of PAdES, XAdES BES/T/C, TSA/OCSP/CRL (note: plain HTTP, no HSTS), validator, chain certs: `PadesCmsSigner`, `XadesDocumentSigner`, `MdTrustServices`, `Revocation`, `OfflineValidator`, `ChainCerts`. PAdES-T signed with the real card on a phone; XAdES verified with the JDK XML-DSig engine, `Probe3` and the Swift validator, live OCSP/CRL/TSA parsing checked, still to be signed with the real card
- [~] AND-02 CCID driver: IccPowerOn/XfrBlock/GetSlotStatus done; **T=1 block layer for TPDU readers + SetParameters done and verified on the miniLector POCKET EVO** (certificate read on a phone, 2026-10-25); slot-change interrupt, PPS to a faster rate, reset confirmation, PIN + signature on device pending
- [~] AND-03 USB permission flow + `device_filter.xml` (class 11 + VID 0x25DD), VID/PID to verify on hardware
- [~] AND-04 Foreground service bridge: HTTPS :18443 (vendor `localhost.cts.md` identity, loaded from the core jar) + HTTP 127.0.0.1:18480, origin policy + PNA, `GET /certificates` from the wallet, async `POST /sign/data` + long-poll + PIN sessions for PAdES-T (`SigningBridgeRoutes`), verified on a phone with curl and **signed from msign.gov.md in Chrome on the phone (2026-10-25)**. Pending: XAdES for non-PDF content, auto start/stop with the reader. Check `CHANGE_NETWORK_STATE` Play policy
- [x] AND-05 Consent from the background: heads-up notification (full-screen intent where allowed) opens the PIN sheet; unanswered requests are cancelled after 2 min (R-04). Verified on a phone
- [~] AND-06 PinVault (Keystore AES-GCM + BiometricPrompt + DataStore) written, not yet wired into the sign flow
- [x] AND-07 Save and share on Android: signed files go to Downloads/eSemnBun through MediaStore (never overwriting; D-06 "next to the original" is impossible with picker URIs); Activity rows have Open / Share / Save as… (system save dialog); share target "Semnează" accepts PDFs and other files from other apps (copied to the cache, cleared at start). Verified on a phone
- [~] AND-08 Chrome Local Network Access prompt (R-05): signing from msign.gov.md in Chrome on the phone works (2026-10-25); `localhost.cts.md` resolves to 127.0.0.1 and the preflight answers `Access-Control-Allow-Private-Network`. Still to document what Chrome shows the first time
- [ ] AND-09 NFC `IsoDep` path, if R-03 is positive
- [~] AND-10 Packaging: `scripts/package-android.sh` → APK + AAB signed with the upload key (`md.esemnbun.app`, keystore kept by the owner, CI secret `ANDROID_KEYSTORE_BASE64`). R8 shrinking (14 MB APK today), Play App Signing enrolment and listing todo

### Phase 4: Windows

Exit criteria: tray app replaces the vendor suite on Windows 10/11; portal flow works in Edge and Chrome.

- [~] WIN-01 C# PAdES-T/counter-signing, XAdES BES/T/C (SHA-256/SHA-1), TSA/OCSP/CRL and offline validator implemented; vectors and simulated RSA signing tests pass. Windows app built and installed on the owner's PC. **Real-card signing and manual normal-privilege startup deferred by owner; see the Windows device checklist in windows/README.md.** TSA signature/revocation authentication and encrypted/object-stream PDF editing remain unsupported
- [ ] WIN-02 WinSCard transport on hardware (`SCardReconnect` reset, T=1), Microsoft CCID class driver with the miniLector
- [~] WIN-03 Reader hot-plug: WinSCard reader/card events + 2 s poll, per-insertion generations, late reads dropped (Core, unit-tested). TODO: toast notifications, hardware check
- [~] WIN-04 Tray icon + flyout (H.NotifyIcon.WinUI), Mica main window, start at sign-in (MSIX startup task / MSI registry). Windows 10 startup/card-render crash fixed and deployed on the owner's machine (2026-10-25): separate rosette paths instead of transformed ellipses in a GeometryGroup. TODO: single instance, first-run TeachingTip, language override
- [ ] WIN-05 PIN in Credential Locker, gated by Windows Hello
- [~] WIN-06 Kestrel HTTPS 18443 + HTTP 18480, vendor PKCS#12 identity/import, wallet certificate list, queued sign/data, absolute empty 201, long-poll, consent and origin/card-bound batch PIN sessions implemented. TLS/origin/PNA/signing/swap tests pass on Windows; live portal test deferred by owner. Windows Schannel requires UserKeySet rather than EphemeralKeySet
- [ ] WIN-07 Explorer context menu "Semnează cu MoldSign"
- [~] WIN-08 MSIX packaging + code signing (thumbprint or Azure Trusted Signing from env; unsigned otherwise) + winget manifest: see WIN-09

- [ ] WIN-10 Microsoft Store uploads from CI (step in `release.yml`, disabled with `if: false`). To enable: (1) complete the first submission of 9PDPR6RNT42S by hand (listings ro/en, screenshots, privacy policy URL, age rating, runFullTrust justification); (2) Partner Center → Microsoft Entra application (Manager) → secrets `MSSTORE_TENANT_ID`, `MSSTORE_SELLER_ID`, `MSSTORE_CLIENT_ID`, `MSSTORE_CLIENT_SECRET`; (3) restore the `if:` to tags-only + secrets present; (4) bump the version for each tag
- [ ] WIN-11 Windows code signing for GitHub downloads (MSI/MSIX outside the Store): paid OV certificate with cloud signing (e.g. SSL.com eSigner → eSigner CKA on the runner + thumbprint mode); Azure Artifact Signing is not available to individuals in Moldova
- [ ] AND-11 Google Play: finish developer-account verification, create the app (eSemnBun, Romanian, free), Play App Signing enrolment, service-account key for CI uploads
- [ ] X-12 Publish `docs/privacy-policy.txt` at a public URL (e.g. GitHub Pages) for the store listings
- [ ] X-13 Store screenshots per platform (Windows needs a real Windows run)

### Phase CLI: command line on every desktop OS

The contract is [spec/cli.md](spec/cli.md). macOS and Linux use the native Swift CLI; Windows uses the .NET CLI (D-09).

- [x] CLI-01 Contract: commands, PIN rules (`--pin-stdin` → `MSIGN_PIN` → no-echo prompt), exit codes 0–6
- [x] CLI-02 macOS: Swift `moldsign` implements the contract (`readers`, `cert`, `sign`, `xades --enveloping`, `verify`, `server [port [https_port]]`, `sign-hex`, `cms-for-hash`, legacy form). SwiftPM product + Xcode target `moldsign-cli`
- [~] CLI-03 Windows: `MoldSign.Cli` (.NET, Native AOT): `readers`/`cert`/`sign-hex` real, the rest wait on WIN-01; exit codes + PIN rules done. Contract change to follow: `xades --digest SHA-1|SHA-256`
- [~] CLI-04 Release packaging: macOS universal tarball done (ad-hoc); notarized + Homebrew tap, Windows winget, Linux (LNX-07) todo
- [ ] CLI-05 Shell completions (zsh/bash/fish/PowerShell) + man page
- [~] CLI-06 CI matrix: `.github/workflows/ci.yml` (macOS Apple + portable, Xcode, Linux container, Android, Windows); remote `github.com/xfreebird/smartcard` (private) exists; runs on push once Actions are enabled

### Phase Linux: native CLI + GNOME app (no .NET)

Exit criteria: `moldsign` CLI and the GNOME app sign/verify on Ubuntu 24.04 / Fedora with pcscd + libccid;
msign.gov.md works in Firefox/Chrome through the bridge; Flatpak builds.

Core portability. All of it is verified on macOS through `scripts/test-portable-macos.sh` (30/30 tests,
live PKI, live TLS bridge); a real Linux build waits on CI (R-09):

- [~] LNX-01 Crypto without CommonCrypto/CryptoKit: OpenSSL EVP AES-256 ECB/CBC, CMAC on top, SHA-256/SHA-1 (`MOLDSIGN_PORTABLE`, automatic on Linux)
- [~] LNX-02 pcsc-lite transport: `cpcsc.c` includes the real `<PCSC/winscard.h>` (no redeclared types), links `pcsclite`; reader-state polling API
- [~] LNX-03 RSA verify without Security.framework: `RSAVerifier` → OpenSSL (`EVP_PKEY_verify`), proven on a real middleware CMS
- [~] LNX-04 `PlainHTTP` POSIX-socket client (live TSA/CRL/OCSP pass)
- [~] LNX-05 Bridge on POSIX sockets + OpenSSL TLS with the vendor p12 (loads the legacy provider if needed); live: TLS 1.3, allow-list, 403, PNA, loopback, port-busy
- [~] LNX-06 `systemd --user` unit (`esemnbun-server.service`, shipped not enabled) + udev/pcscd notes in linux/README.md. Gap: on Linux `MoldSignServer.fallbackPIN()` returns nil, so the headless server only serves pages that send the PIN (TODO: `systemd-ask-password` hook)
- [~] LNX-07 CLI packaging: static-stdlib tarball, `esemnbun-cli` `.deb`/`.rpm` (see LNX-15); CI `linux` job builds and uploads them

GNOME app (`linux/`, Swift + GTK4/libadwaita C API; compiles and runs on macOS with Homebrew GTK for UI work):

- [~] LNX-08 Reader/card hot-plug via PC/SC polling (1 s, `readerStates()`), every reader with a per-reader generation (presence + pcsc-lite `eventCount` → reinsert/swap between polls), PIN-less certificate greeting, "pcscd not running" state (`isServiceAvailable()`), "Recitește cardul". TODO: event-driven wait (`\\?PnP?\Notification` + `SCardCancel`) instead of polling
- [~] LNX-09 App shell: `AdwApplicationWindow`, header bar + view switcher (bottom bar when narrow), banner, toasts; pages Semnează · Verifică · Activitate · Card; Preferences. Runs on macOS (Homebrew GTK); a real card signature through it verified valid. TODO: detached-XAdES file picker, translations
- [~] LNX-10 PIN in libsecret (schema `md.moldsign.pin`, keyed by cert SHA-1): save after success, delete on wrong/blocked PIN, also for browser requests (`onSignResult`). The Secret Service has no per-read biometric gate, so using a stored PIN always asks for confirmation. Untested against a real keyring
- [~] LNX-11 Bridge hosting + consent dialog (`AdwAlertDialog`), "trust site 10 minutes", port-busy state, rejected-PIN cleanup via `onSignResult`. HTTPS is now required for the GUI bridge: missing/unreadable identity gets a banner and a validated PKCS#12 import action (Preferences too); HTTP-only CLI use stays available. Owner's Linux "no available IDs" report awaits machine access to confirm the cause
- [~] LNX-12 Background running: `GApplication` hold when the window closes. TODO: Background portal + autostart
- [~] LNX-13 Flatpak manifest (`--socket=pcsc`, network, Secret Service). TODO: Swift SDK extension name, pcsc-lite module checksum, bridge TLS identity delivery (core looks in `$XDG_DATA_HOME/moldsign`, `/app/share/moldsign`, `/usr/share/moldsign`)
- [~] LNX-14 `.desktop`, AppStream metainfo, placeholder icons. TODO: final icon, screenshots, project LICENSE

### Phase UX: v2 redesign (docs/10 §0)

- [~] UX-01 Status light: green = card ready, amber = reader only / reading, blue = busy, red = error, none = idle, always with text. Inside the apps (Apple sidebar + bridge row, Android status chip). The tray/menu-bar dot is now two-state (UX-11). TODO: Android Quick Settings tile
- [x] UX-02 Card wallet: card illustrations as the selector, empty/error states as cards, re-read from the context menu. Superseded by UX-09/UX-10 (one card + in-card switcher instead of a carousel with dots)
- [x] UX-03 macOS per HIG: system button styles, `Form`/`List`, toolbar, materials; card selector in popover + Card/Sign pages (demo-mode screenshots, light + dark)
- [x] UX-04 iOS per HIG: large titles, inset-grouped lists, paging card selector, bottom prominent action, haptics (simulator screenshots)
- [x] UX-05 Android per Material 3: pager card selector, ExtendedFAB, bottom sheets, status in the foreground notification (emulator, light + dark)
- [~] UX-06 Windows per Fluent 2: NavigationView + Mica, InfoBar, accent Sign button, card selector, tray dot (4 icons: green/gray × light/dark taskbar). C# compiles against Windows App SDK 1.8 on macOS; XAML compile and runtime need Windows
- [x] UX-07 GNOME per GNOME HIG: AdwCarousel (one card wide) card selector, AdwStatusPage empty states, AdwToast, Background portal status (`BackgroundPortal.swift`, GDBus), debug demo mode (`MSIGN_DEMO_CARDS=1…4|empty|noreader|error|pcscd`). Verified with Homebrew GTK screenshots; the portal itself needs a real GNOME session
- [ ] UX-08 Refresh the design mock-ups artifact
- [~] UX-09 Card face = stylized Moldovan identity card (docs/10 §0.2b): pastel guilloche paper, bilingual headings, neutral shield (never the coat of arms), portrait silhouette, Surname / Given names (certificate SN/GN, else CN split "Surname Given"), valid-until, issuer, status strip. No photo, document number or IDNP. Apple, Android, GNOME done; Windows written (unverified on Windows)
- [~] UX-10 Card and selector are ONE component: the selected card with a **disclosure button at its right-centre** that expands, in place, into a list of every card at the same size; pick one → it collapses to it (user revision, docs/10 §0.2b). Plus ←/→, context menu, accessibility adjust. (First version: "1/2" capsule menu + paging.) Apple, Android, GNOME done; Windows written (unverified on Windows). TODO: keyboard (←/→, Escape) and screen-reader checks on Android/GNOME hardware
- [~] UX-11 Tray / menu-bar dot is two-state: green while a card is inserted (reading, ready, signing), gray otherwise; tooltip "eSemnBun · Card conectat · {holder}" / "Niciun card conectat". macOS, Android notification, GNOME Background-portal text done; Windows tray icons written and checked as images
- [x] UX-13 App icon on every platform = the tray motif (disc with the signature cut out) on the brand plate; one generator `scripts/make-app-icons.py` (iOS opaque 1024, macOS grid sizes, Android adaptive + monochrome + Play 512, Windows ico/MSIX, GNOME). macOS and iOS had no icon before
- [~] UX-12 Public name **eSemnBun** on every platform (apps, windows, tray, installers, file names); CLI command `esemnbun`; codename `MoldSign` stays in code and IDs (D-07). Apple, Android, GNOME (`esemnbun-gnome`, deb/rpm/flatpak names), core CLI, scripts, CI done; Windows (`eSemnBun.exe`, `bin\esemnbun.exe`, installer names) written. Version 0.2.0 everywhere
- [~] WIN-09 Installers (`windows/scripts/package-windows.ps1`, CI job `windows`): `eSemnBun-0.2.0-x64.msi` (WiX v5, per machine, `Program Files\eSemnBun`, CLI at `bin\esemnbun.exe` with only `bin\` on PATH because `esemnbun.exe`/`eSemnBun.exe` collide case-insensitively, optional start at sign-in, in-place upgrades), `eSemnBun-0.2.0-x64.msix` (startup task, identity from env), winget manifests, `SHA256SUMS.txt`. `Package.wxs` compiles and links with WiX on macOS; the MSI/MSIX builds and installs need Windows. TODO: arm64 in CI, LICENSE/homepage in winget
- [~] LNX-15 Installers: `scripts/package-linux.sh` → `esemnbun_0.2.0-1_<arch>.deb` + `esemnbun-cli_…deb`, `esemnbun-0.2.0-1.<arch>.rpm` + `esemnbun-cli-…rpm` (`linux/packaging/{debian,rpm}`, shared `install.sh`), `eSemnBun-0.2.0.flatpak` (GNOME 51 runtime, swift6 SDK extension, pcsc-lite 2.5.2 with verified checksum), CLI tarball + `esemnbun-server.service` user unit (not enabled). Dry-run on macOS only; real deb/rpm/flatpak builds, `desktop-file-validate`/`appstreamcli` and installs need CI or a Linux box. TODO: licence, maintainer address, metainfo screenshots, signed repos

### Phase 5: Parity and beyond

- [ ] X-01 Encrypt/decrypt (vendor "Criptare / Decriptare"): reverse-engineer the vendor format first (CMS EnvelopedData?)
- [-] X-02 "Ștergere securizată" (secure delete): **dropped**. Overwrite-based deletion is meaningless on SSD/APFS/flash, so the app would promise something it can't deliver. Document why in the FAQ
- [ ] X-03 ASiC-E container support (if portals require it)
- [ ] X-04 Async core APIs (`async`/`await`, coroutines, `Task`) replacing semaphore-bridged calls; Swift 6 language mode for the apps
- [~] X-05 CI: `ci.yml` (tests + builds on every push) and `release.yml` (all installation artifacts; tag `v*` → GitHub Release). The first CI run found a Linux-only Foundation error (`Range(NSRange, in: Substring)`) and a WiX ICE03 failure, both fixed. Vectors job todo
- [ ] X-06 Crash-safe card handling: `6985`/`6988` recovery playbook surfaced in the UI ("re-insert the card")
- [ ] X-07 Telemetry: none by default; opt-in local diagnostics export with secrets redacted
- [ ] X-08 Explicit HTTP proxy setting for PKI calls (they deliberately bypass the system proxy today)
- [x] X-10 Card simulator for tests (`Tests/…/Support/SimulatedCosmoXCard.swift`): full mutual auth + SM, PIN retry counter, real RSA signatures with a generated test key/cert; drives SigningService and bridge end-to-end
- [ ] X-09 Clean the pre-existing compiler warnings in the core (unused variables in Signing/Validation/XAdES/SecureChannel), with byte-identical output checks

### Cross-cutting security (P0: must ship before any public build)

- [x] SEC-01 Bridge origin enforcement: vendor allow-list; `moldSign: DesktopSuiteClient` only without `Origin`; denied → 403 without CORS (verified live)
- [x] SEC-02 Per-request user consent in the apps (consent panel/sheet/dialog, temporary trust); loopback test proves a denial never reaches the card; exercised against the live portal (macOS 0.1.1)
- [~] SEC-03 Bound to 127.0.0.1 (verified: LAN refused); 64 MB body cap. TODO: rate limit
- [x] SEC-04 PIN never logged; apps set `MSLog.sink = nil` (SM traces contain session keys)
- [~] SEC-05 PIN storage gated by device-owner auth on Apple (LAContext); Android Keystore written; Windows pending
- [x] SEC-06 **Purge the PIN that the first commit hard-coded** from git history before the repo gets any remote. Done 2026-10-25 before the first push: `filter-branch` on a mirror redacted the literal in the first commit's `main.swift` and dropped the committed `MoldSignMac/.build/` (its binaries embedded it too); verified absent from every tree, blob and message of the pushed history. Old objects still sit in the local reflog until `git gc --prune`
- [~] SEC-08 Identity guard before VERIFY in **every** port (docs/09 §3.1b): Swift (app, bridge, batch PIN sessions), Kotlin (`IdentityGuardTest`) and C# (`CardErrorKind.CardChanged`, `IdentityGuardTests` incl. full mutual auth on the simulator) all compare the certificate SHA-1 before VERIFY. TODO: hardware check on Android/Windows
- [x] SEC-07 Vendor TLS key (`localhost.p12`): shipped in the macOS, Windows, Linux and Android apps (D-03); user import / `MSIGN_TLS_P12` override it

---

## 5. Decisions

### Decided

| ID | Decision | Why |
|---|---|---|
| D-01 | Native UI per platform; core reimplemented per language (Swift, Kotlin, C#), gated by shared golden vectors | Matches "native solutions"; no FFI or bridging runtimes |
| D-02 | Swift core stays the reference implementation | It is the one proven on the live portal |
| D-06 | Output naming `<name>-semnat.<ext>` next to the original, never overwrite (iOS: app Documents) | Predictable |
| D-08 | Min iOS 17 | TK USB readers need 16+; 17 gives `@Observable` |
| D-09 | CLI: native Swift `esemnbun` (was `moldsign`) on **macOS and Linux**; .NET only on **Windows** | User requirement: "for cli macos and linux, use native solution, not dot.net" |
| D-11 | Apple apps live in a committed **Xcode project** (`apple/eSemnBun.xcodeproj`, was `MoldSign.xcodeproj`; synchronized folders); the core is a local SwiftPM package linked by it. No XcodeGen spec is kept | User requirement: iOS must be an Xcode project, not package-only; one source of truth |
| D-12 | macOS app minimum macOS 15 (`defaultLaunchBehavior(.suppressed)` keeps the main window closed at launch); CLI stays macOS 14 | Menu-bar agent UX |
| D-13 | PKI HTTP (TSA/OCSP/CRL) uses a minimal plain-HTTP client (`NWConnection` on Apple, POSIX on Linux), bypassing the system proxy | URLSession applies HSTS (`tsp.pki.gov.md` → https fails); matches the proven `curl` behavior. Proxy setting = X-08 |
| D-10 | Linux gets a **GNOME app** (GTK4 + libadwaita) as well as the CLI, written in Swift against the GTK C API (no third-party Swift GTK wrappers), reusing MoldSignKit | User requirement: "add linux port too, use native solution, no dotnet. gnome gtk solution" |
| D-14 | The Swift core lives at `swift/MoldSignKit/` (not under `apple/`) | Shared by the Apple apps and Linux |
| D-07 | Public product name **eSemnBun** (user decision, 2026-10-25); CLI `esemnbun`. Store identifiers follow it: Apple `md.esemnbun.ios` / `.mac` / `.cli`, Android `md.esemnbun.app` (user decision when signing was set up). `MoldSign` stays the codename in code (modules, namespaces, Kotlin package), Linux/Windows IDs, storage and keychain names, `MSIGN_PIN`; "MoldSign" in UI text only where it means the vendor suite | Distinct from the vendor trademark. The ID change resets saved PIN/settings of existing dev installs once |
| D-15 | Signing uses the owner's own accounts only: Apple team H86U5Z8HYB (fastlane match in `github.com/xfreebird/fastlanecerts`), an Android upload key generated for the project; never the employer identities on the dev Mac (nor the employer GitHub Enterprise host `gh` defaults to: pass `GH_HOST=github.com`) | Personal project; the owner provided the Apple account and asked for match |

### Open (recommendation first)

| ID | Question | Recommendation |
|---|---|---|
| D-03 | Ship the vendor `localhost.p12` inside our apps? | Yes (owner, 2026-10-27): bundled in the macOS, Windows, Linux and Android apps; the vendor suite has only a JKS, so loading it from there never worked. iOS stays HTTP-only (R-02). Long term, ask STISC for an official partner channel |
| D-04 | macOS App Sandbox on or off? | Off during Phase 1 (bridge `/sign/pdf` takes arbitrary file paths). Re-evaluate for the Mac App Store with security-scoped bookmarks. Note (nice to have, no action planned): a Mac App Store build is feasible: smart card, network client/server, Keychain and menu bar work sandboxed; it would need a Save dialog or folder bookmark for `<name>-semnat` output, security-scoped bookmarks for recents/Activity, and loses the bridge's `/sign/pdf` (arbitrary paths) and the vendor TLS key (D-03). The notarized Developer ID DMG stays the Mac distribution |
| D-05 | macOS distribution | Developer ID + notarized DMG + Sparkle; Mac App Store later |

## 6. Risks and research spikes

| ID | Risk | Mitigation / spike |
|---|---|---|
| R-01 | iOS suspends background apps, so a localhost bridge can't serve Safari while our app is backgrounded | In-app browser (IOS-06), Split View (IOS-07); research a Safari Web Extension relaying to the app |
| R-02 | App Store review of a bundled third-party TLS private key | D-03; the in-app browser could avoid TLS (custom scheme bridge) |
| R-03 | Unknown whether the card supports contactless IAS/ECC (PACE may be required) | IOS-09 spike with the Android `IsoDep` + iOS 26 NFC slot |
| R-04 | Android blocks activity starts from the background (consent UI) | Notification-driven consent (AND-05) |
| R-05 | Chrome/Edge Local Network Access permission for public → localhost requests | `Access-Control-Allow-Private-Network: true` (done); document the one-time browser prompt |
| R-06 | iOS share-extension memory (~120 MB) vs large PDFs | Stream hashing; hand large files to the main app |
| R-07 | PIN retry counter burn during development (already happened once) | MAC-05 rules; no auto-retry; `6985` → stop and ask to re-insert |
| R-08 | Lightning camera adapter power budget for the reader | IOS-01 measures; recommend the USB 3 adapter with power pass-through |
| R-09 | No Linux toolchain on the dev Mac (no Docker, no Swift Linux SDK) | Linux code paths run on macOS via `MOLDSIGN_PORTABLE` (30/30 tests); the CI `linux` job (`swift:6.2-noble`) does the real build once the repo has a remote |
| R-11 | The portal requests XAdES with `algorithm:"SHA-1"` (vendor honours it) | **Mitigated (0.1.2):** the bridge honours the requested digest for XAdES (vendor-faithful); SHA-256 stays the default elsewhere. Open: confirm on a live Xml/Text document; SHA-1 DigestInfo on the real card unproven (INTERNAL AUTHENTICATE pads whatever DigestInfo it gets, so it should work) |
| R-10 | The vendor Java suite holds 18480/18443 while running (seen 2026-10-25) | MAC-08: detect and offer to quit; `portBusy` state already surfaced |

---

## Progress log

Newest first. One line per meaningful step; link IDs.

- 2026-10-31: **Demo mode and screenshots (DEMO-01–04)**: introduced opt-in, persisted mock sessions
  with explicit consent and a visible disclaimer on Apple, Android and Windows; mock exports are
  marked unsigned. Linux screenshot-only mock fixtures suppress the notice. Native verification and
  evidence collection are tracked above; no physical card, real PIN or user document was used.

- 2026-10-26: **PIN entry and centering (MAC-04, WIN-05, LNX-11)**: on macOS the PIN boxes were overlaid by the system focus ring of the hidden `SecureField` (opacity only dims the text, not AppKit's ring). The key catcher is now a 1 pt plain field with `focusEffectDisabled()`, clear text and tint, so only the boxes show focus; the whole box row is tappable. The auth panel sizes itself to the SwiftUI content and centers on the visible frame of the screen under the pointer for both consent and PIN (`NSWindow.center()` sits above center). Release build installed on the dev Mac. Windows: the PIN moves from a `ContentDialog` inside the main window to its own code-only `PinWindow` (always on top, centered in the work area of the display under the cursor, Enter signs, Escape/close cancels, no paste); the Windows Hello path still brings the main window forward because it owns the prompt; the `dialogRoot` plumbing is gone. **Not yet built on Windows** (the test PC was offline): CI is the first compile. Linux unchanged: the `AdwAlertDialog` is centered over the app window, and GTK 4 on Wayland gives window placement to the compositor.
- 2026-10-26: **macOS dropdown window activation (MAC-01, MAC-04, MAC-09)**: menu actions previously called `openWindow`/`openSettings` followed by activation before SwiftUI necessarily had a target window; a reused window also was not explicitly raised. Added a main-actor presentation coordinator with weak Main/Settings window registration and a one-shot pending request. After popover dismissal, it orders the selected window in, explicitly activates the agent and makes that window key; minimized windows are restored, and background SwiftUI updates never request activation. The Dock-policy observer does not demote the app while a requested window is being created. Auth panels share the same foreground ordering without changing their floating level or agent policy. macOS Debug build passes; a real AppKit accessory-app probe passes new/reused Main, minimized Main, new/reused Settings and no-focus-stealing background registration against foreground Finder windows. Release build installed in /Applications on the dev Mac for the owner to test.

- 2026-10-26: **Windows card-removal crash (WIN-03, WIN-04)**: reproduced with the reader still connected. Native `0xc000027b` / `RO_E_CLOSED` hid a managed `ObjectDisposedException`: `System.Drawing.Icon.Handle` → H.NotifyIcon `UpdateIcon` → `TrayIconService.Update` during the ready-to-empty state change. H.NotifyIcon disposes a replaced icon, but the app cached that same instance and reused it when returning to gray (also affected revisiting a taskbar-theme variant). The service now gives the library a clone and retains ownership of its cached originals. Added call-site logging before reader UI callback exceptions are rethrown so future dispatcher failures retain their original stack. Windows publish/install succeeded; owner confirmed two insert/remove cycles leave the app running without any PIN/signing operation.

- 2026-10-26: **Windows Verify detail parity (WIN-01)**: owner confirmed the browser name/PIN/signing steps now work and verification reports valid, but the Windows page discarded the individual reports. Verify now keeps every report and renders signer, local signing/TSA times, level, integrity/RSA/trust-chain checks, timestamp-imprint status, selectable technical details and explicit offline TSA/revocation limitations. Added an original-document picker for detached XAdES (replacing a same-name selection and re-verifying), document reveal, progress and stale-result protection; tray verification opens the same detailed page. Mixed unknown-chain results remain indeterminate rather than being flattened to invalid, and unsigned files have a distinct neutral state. Two focused aggregation tests pass; the Windows app publishes and is installed (app/core/PRI hashes match), running normally; owner confirmed the expanded view looks good. The postponed test reminder was cancelled after the owner resumed testing.
- 2026-10-27: **macOS bridge listed no identities on other Macs (SEC-07, D-03)**: reproduced on the MacBook Air (macOS 27.0.1): only `127.0.0.1:18480` listened, so msign.gov.md (which calls `https://localhost.cts.md:18443`) found nothing. The app looked for `localhost.p12` in the vendor suite (which ships only `sslKeyStore2.jks`, a real JKS), the bundle (not packaged) and `~/Projects/smartcard`, so it worked only on the dev Mac; Windows/Linux worked only where the file had been copied by hand. Owner decision: bundle it. macOS: Copy Bundle Resources of `eSemnBun-macOS` (not iOS) and `start(requireHTTPS: true)`, so a missing identity shows as a bridge error instead of HTTP-only. Windows: Content item next to the exe (MSI harvest + MSIX), `BridgeTls.ResolvePath` = env → imported → bundled. Linux: `install.sh` installs `share/moldsign/localhost.p12` for the GUI (deb, rpm, Flatpak). The CLI's `server` still needs `MSIGN_TLS_P12` or a GUI install. Second bug found on the Air: `SecPKCS12Import` put the key in the login keychain with an ACL for the importing build, so the next (ad-hoc or differently signed) build stalled every TLS handshake on a hidden "wants to sign using key" prompt and both ports stopped answering; the import is now memory-only on macOS 15+ (`kSecImportToMemoryOnly`). Verified on the Air: headless Chrome 151 on https://msign.gov.md fetches `/certificates` → 200 with the card once Local Network Access is allowed (denied → "Failed to fetch": users must click Allow in Chrome's prompt). Linux checked on a Fedora 44 aarch64 VM (QEMU on the Air, reader passed through): release build with Swift 6.4.1, `install.sh` puts the identity in `/usr/share/moldsign`, the GNOME app serves `https://localhost.cts.md:18443/certificates` (200, TLS trusted) and the CLI signs PAdES-B-T that verifies VALID. Windows packaging is compiled only by CI so far.
- 2026-10-27: **Test VMs + full screenshot set**: Fedora 44 GNOME (aarch64) and Windows 11 Pro ARM64 VMs on the MacBook Air
  (QEMU+HVF; UTM 4.7/5.0 crash on macOS 27), the bit4id reader passed through on demand, snapshots, documented in
  `.agents/skills/esemnbun-test-vms`. Release v0.2.0 (`faf227c`) verified on real OSes with the real card: Windows x64 MSI
  under ARM64 emulation (bundled identity, bridge 201, PAdES/XAdES signing + verify), Linux release build, macOS notarized
  DMG. 166 screenshots (macOS/Linux/Windows, light + dark, every reachable state + demo cards) kept outside the repo.
  UI issues found (open): Linux + macOS Verify show the raw UTCTime (`261027073256Z`) and English technical details;
  macOS Activity shows `MoldSignKit.MoldSignServer.Denied` for a refused browser request and the no-reader hint names a
  Lightning adapter; Linux keeps the PIN dialog open after the reader is unplugged and logs a GLib `g_value_get_int`
  critical at start; Windows file picker opens in `System32`, the Verify drop zone reuses the Sign hint, the
  no-reader hint has low contrast in dark mode, reader toasts (WIN-03) and first run (WIN-04) are not built.

- 2026-10-25: **Windows live browser follow-up (WIN-06)**: owner resumed testing and launched the installed app normally (tray icon, no startup error). Real HTTPS `/certificates` enumerates one card; label/name fields are populated, but `.NET` rendered the DN as `C=..., CN=...`. The portal splits attributes without trimming, so the key became `" CN"` and the identity appeared nameless. Bridge DNs now come from decoded DER attributes with comma-separated, unpadded keys (regression test with several RDNs). Browser consent now temporarily raises/restores the main window above the browser, restores minimization, attempts foreground activation and focuses the PIN field; previous topmost state is restored on completion/cancel/error. Owner observed the old PIN sheet only after switching into the app; recheck this visibility behavior after installation.

- 2026-10-25: **Windows signing/browser port (WIN-01, WIN-06)**: replaced the app's WIN-01 signing stubs with PAdES-T and counter-signing, XAdES BES/T/C (detached/enveloping, SHA-256/SHA-1), PKI clients and offline validation. Public CA certificates embedded; crypto packages pinned to patched 10.0.14 (10.0.0 was rejected by NuGet vulnerability audit). Implemented real HTTPS, certificate enumeration, async sign/data with one signing worker, long-poll and origin/card-bound PIN sessions; browser-supplied PINs ignored. Consent shows origin/document/holder; unattended browser PIN sheets expire after two minutes. Added a PKCS#12 import action and credential-free exception call-site logs. Windows tests cover 166 cases; all core cases passed and all eight bridge cases pass, including independently verified simulated-card signatures, PIN-session origin separation and swapped-card rejection before VERIFY. Integration fixes: Schannel cannot use ephemeral PKCS#12 private keys, and ASP.NET treats trailing slashes as equivalent (duplicate certificate endpoints caused ambiguity).
- 2026-10-25: **Windows input and deferred device checks (WIN-04, WIN-06, WIN-07)**: moved to the Windows App SDK 1.8 picker with an explicit window owner (also works elevated), brought the main window forward for tray picker actions, and added visible file-open/drop errors. The earlier verification launch was elevated, which prevents Explorer drag-and-drop across the integrity boundary; future runs must be normal/asInvoker. Full published app/runtime copied to the installed location with backups and the private localhost identity installed in user data. Automated normal-privilege launches did not produce a usable window, so installed startup, GUI picking/drop, real-card PDF/XAdES signing and live Chrome/Edge portal signing are **not verified**. Owner explicitly postponed these checks and requested notes plus a reminder (scheduled in 12 hours). Checklist: windows/README.md; do not retry after a PIN error.

- 2026-10-25: **Windows tray crash (WIN-04)**: reproduced on the owner's Windows 10 Pro 19045 desktop over SSH, with CDB launched in the interactive session (a direct SSH launch runs in session 0 and fails differently). Native stack: `UnwrapD2DGeometry` → `CD2DFactory::CreateGeometryGroup` → `CGeometryCollection::GetPrintGeometry` → stroke-mask rasterization. The card rosette was the only GeometryGroup, containing rotated EllipseGeometry children. Replaced it with eight separately rotated Path elements, preserving the illustration. Built on the target with .NET 10, ran the fixed app, then backed up and replaced the installed app's DLL/PDB/PRI. The installed process remained responsive, with no new Application Error/.NET Runtime crash events. No PIN or signing attempt was needed.
- 2026-10-25: **Linux browser setup (LNX-05, LNX-11)**: the GUI previously reported both bridge ports active even when the vendor TLS identity was absent; Linux packages intentionally omit it, and msign.gov.md calls HTTPS 18443, not HTTP 18480. Added required-HTTPS startup with rollback, missing/invalid-identity state and banner, and a Preferences/banner file-picker import (validates the PKCS#12 before replacing the XDG copy, permissions 0600, Flatpak portal-compatible). CLI HTTP-only mode is unchanged. Focused bridge tests pass on Apple and OpenSSL/POSIX backends; GTK app compiles on the Mac. The reported Linux machine is not yet accessible, so the actual certificate-list failure and portal signing remain unverified there.

- 2026-10-25: **Android PAdES-T signing (AND-01, AND-07)**: tapping Sign on the phone failed because the PAdES signer was a stub (`UnportedPadesSigner`, shown as "not available on Android"); it threw after authentication and before the PIN, so no VERIFY was sent. Ported `PAdESSigner` to Kotlin (`PadesCmsSigner`: incremental update + CAdES CMS with signingCertificateV2, chain, RFC 3161 token), an HTTP MDQTSA client (`MdTrustServices`, the TSA's status is checked) and the two CA certificates as jar resources. Fixed on the way: the Swift code derives the update's xref offsets from the last `%%EOF`, which is wrong when the file ends with a newline after it; the port uses the real file size. Verification: 12 unit tests (CMS parsed and its RSA signature, messageDigest and signingCertificateV2 checked independently, counter-signing, xref offsets), `openssl cms -verify` on the one- and two-signature PDFs, the Swift validator, iText 9 + BouncyCastle `verify()=true` on a document with a **real MDQTSA token** (`MSIGN_NETWORK_TESTS=1`). The signed file is written to Downloads/eSemnBun (MediaStore, never overwriting); the activity entry points to it and the "saved" message has an **Open** action. Found on the first real run: `ActivityLog` pruned the entry at once because it required a persisted read permission, which a file the app inserted itself never has (MediaStore URIs are now accepted). **First real card signature (PIN, T=1, TSA) checked: Swift validator "VALID, PAdES-B-T, chain trusted", iText/BouncyCastle `verify()=true`.**
- 2026-10-25: **Android reader works on a phone (AND-02, AND-03)**: the app refused the miniLector POCKET EVO ("reader is not responding"): its CCID descriptor says TPDU level (`dwFeatures` 0x000100B6, 3 V, T=0|T=1), not short-APDU as the code assumed. Added the host T=1 block layer (`T1.kt`: I/R/S blocks, chaining, WTX, IFSD, ATR parsing) and `PC_to_RDR_SetParameters`. The decisive finding, from libccid's source (`IFDHSetProtocolParameters`) after lab trials on the reader: a TPDU reader without `dwFeatures` 0x40 stays in a T=0 default until it gets SetParameters (before that: header-only commands answered with nothing, S/R blocks with an empty OK, I-blocks with `bError 0xFB`). Result on a Xiaomi 22126RN91Y (Android 14, `adb` over Wi-Fi because the reader uses the only USB port): mutual authentication + certificate read, "Card ready". 21 transport tests (T=1 against a simulated card). Open: PIN + signature on device (WTX), PPS for speed (9600 bps now), interrupt endpoint. Logs now carry the failure message (`MoldSignUsb`, `MoldSign`).
- 2026-10-25: mpass.gov.md ID-card login hung on "Introduceți PIN-ul semnăturii" after a successful signature: our `201` carried a JSON body, so mpass's jQuery (`dataType:'json'`, polls only from `.fail`) never polled. The `201` now matches the vendor's `Response.created(uri).header("sessionId", id)`: empty body. Regression test added.

- 2026-10-25: Microsoft Store: free individual registration, product eSemnBun (9PDPR6RNT42S). First upload rejected (PublisherDisplayName "eSemnBun" ≠ account "Nicolae Ghimbovschi"): the Store identity now comes from repository variables (Identity/Name, Publisher CN, display name), MSIX rebuilt by the Release workflow; `runFullTrust` needs a justification in the submission. Windows code signing for GitHub downloads stays open (paid certificate, e.g. SSL.com eSigner).

- 2026-10-25: iOS release job: one archive → App Store IPA uploaded to TestFlight (API key, `skip_waiting_for_build_processing`, `skip_submission`) + ad hoc IPA (new match AdHoc profile, 1 registered device); build number `<run>.<attempt>`; privacy manifest added (UserDefaults CA92.1). Verified locally without upload; CI does the upload.

- 2026-10-25: macOS notarization working: Developer ID Application created in the portal from our CSR (Firefox), fetched via the API, imported into match. Two fixes found on the way: `match import` takes paths only interactively (lane calls `Match::Importer` directly) and the macOS keychain rejects OpenSSL-made empty-password .p12s ("MAC verification failed"), so the lane exports the .p12 with `security`; `package-macos.sh` retries timestamped codesign (one transient timestamp failure). Notarized locally: DMG + CLI Accepted, stapled, Gatekeeper accepted.

- 2026-10-25: Tray/menu-bar glyph restyled like GitHub's (solid disc, signature cut out, dot as badge) on macOS, Windows and the Android notification; then the app icon on every platform from the same motif (UX-13). Release v0.2.0 published by the workflow (11 installers + checksums; macOS pending Developer ID).

- 2026-10-25: App Store Connect record **eSemnBun** created (Apple ID 6826865290, `md.esemnbun.ios`, SKU `esemnbun-ios`, Romanian) through the web UI, since the API key gets 403 on `POST /v1/apps` (checked with a raw JWT call too). `release.yml` now always publishes a GitHub Release (tag or `v<version>`, files replaced on re-runs, failed platforms named in the notes, checksums over all assets).

- 2026-10-25: First `release.yml` runs: iOS IPA (Apple Distribution, App Store profile), Android APK/AAB (upload key), Linux deb/rpm/tarball, Windows MSI/MSIX/winget all built; Flatpak green after three fixes (host `elfutils` for eu-strip, pcsc-lite `--libdir=lib`, host `librsvg2-common` so AppStream compose can read the SVG icon); macOS waits for the Developer ID certificate. Store records: the App Store Connect API refuses to create apps ("'apps' does not allow 'CREATE'"), so the iOS record is a one-time web/`produce` step; Play Console blocks app creation until the personal developer account finishes Google's identity verification.

- 2026-10-25: Signing + release pipeline (user request). Apple: App Store Connect API key, `fastlane match` storage reset (nuked: 6 stale 2020 profiles; the team had no certificates), App IDs `md.esemnbun.ios`/`.mac` registered, Apple Distribution + Development certificates and profiles created; signed App Store IPA built locally (team H86U5Z8HYB). Developer ID: the API refuses ("Account Holder only") → CSR prepared for a portal upload, `import_developer_id` lane. Android: upload keystore generated, signed APK/AAB built. `release.yml` builds every installer (DMG notarized, IPA, APK/AAB, deb/rpm/tarball, Flatpak, MSI/MSIX/winget) and publishes on `v*` tags; 9 Actions secrets set. IDs moved to `md.esemnbun.*` (D-07), D-15 rewritten. The first CI run had failed on Linux (Foundation `Range(NSRange, in: Substring)`) and WiX ICE03; both fixed.

- 2026-10-25: Repo published privately at `github.com/xfreebird/smartcard` (branches `main`, `cross-platform-apps`). History rewritten before the push: all 7 commits authored `xfreebird <xfreebird@gmail.com>` (was the employer address), PIN purged (SEC-06), committed build output dropped (101 MB → 5.5 MB); the final tree is unchanged. Local repo-level git identity set to xfreebird. Then the 0.2.0 work was committed per area on `cross-platform-apps` and `main` fast-forwarded to it (user: "merge all to main").

- 2026-10-25: User feedback round (macOS screenshot): (1) disabled toolbar "Semnează" rendered as an accent fill → hidden until documents exist, accent only while enabled (all platforms); (2) Documents = large drop zone with "Alege fișiere…" + list, compact zone under the list (all); (3) recent documents only while the file exists, "Golește" in the popover/flyout hides recents, Activity page "Golește lista" (confirmed) clears the log; moved/deleted files are pruned (all; Windows now persists the log in `%LOCALAPPDATA%\MoldSign\activity.json`); (4) popover/flyout closes before opening a window/settings/picker/Finder (macOS: closes the MenuBarExtra window; Windows: hides the flyout); (5) macOS app becomes a regular app (Dock, Cmd-Tab) while the main window or Settings is open — verified via System Events: UIElement → Foreground on open, back on close, popover alone stays UIElement; (6) PDF format selectable: PAdES-T or detached XAdES-BES/T/C (all; Windows tests 138/138, signing still WIN-01). Android: new Activitate tab with a persisted log (entries kept while the URI grant + file exist), Sign FAB only when signable; 56 + 7 tests, lint clean; the output file still waits on AND-01/AND-07.

- 2026-10-25: UX-10 revised (user): the "1/2" capsule + paging are replaced by a disclosure button at the card's right-centre that expands, in place, into every card at the same size (selected one ringed, "Folosit pentru semnare"); pick → collapse. Keys: ←/→ collapsed, ↑/↓ expanded, Space/Return, Escape. Done on all platforms: Apple (macOS popover/window + iOS screenshots, `MSIGN_DEMO_EXPANDED=1`), Android (emulator, light/dark; card now also on Browser; 51 + 7 tests, lint clean), GNOME (GtkRevealer, Homebrew GTK screenshots, 0 warnings), Windows (flyout grows/re-anchors, list scrolls past screen height; compiles against Windows App SDK, 130/130, not run on Windows). Selected card in the list: status strip "✓ Folosit pentru semnare" (blue) unless it is reading/signing/in error. Windows issuer field kept full width (only the name rows share the disclosure's band).
- 2026-10-25: Tray popover/flyout tidy-up (user feedback; macOS + Windows): no drop zone (the popover/flyout closes before a drag can reach it), recents without timestamps, browser switch on the trailing edge, "Deschide eSemnBun" and "Ieșire" on separate menu-style rows (docs/10 §4.1).

- 2026-10-25: **0.2.0 rebrand + v3 design** (user request: rename to eSemnBun, ID-card illustration, card and selector merged, green/gray tray). Spec: docs/10 §0.2b. Apple: `CardSelector` (paging `ScrollView`, in-card "1/2" menu, ←/→ with keyboard navigation, VoiceOver adjust) + `IDCardFace` (Canvas guilloche/rosette/shield/silhouette, relative layout); menu-bar dot green/gray; Xcode project/targets renamed (`eSemnBun.xcodeproj`, `eSemnBun-macOS/-iOS`, `esemnbun-cli`); demo switches `MSIGN_DEMO_CARDS=none`, `MSIGN_DEMO_SELECTED`, `MSIGN_DEMO_DARK`. Core: `CertificateSummary.surname/givenNames` (SN/GN, else CN split), CLI product `esemnbun` (43 tests). Android (agent): Canvas ID card, pager + in-card menu, green/gray notification, `eSemnBun-0.2.0` packages; 51 + 7 tests, lint clean. CI YAML never parsed (unquoted `name:` with a colon) → fixed. GNOME (agent): cairo ID card, one-card-wide AdwCarousel + in-card menu, portal text green/gray wording, `esemnbun-gnome`, deb/rpm/flatpak packaging (dry-run only). Windows (agent): C# identity guard (`CardChanged` before VERIFY), multi-card model with generations, Fluent card selector + ID face, green/gray tray, MSI/MSIX/winget pipeline; 130/130 tests on macOS, nothing run on Windows yet. Name fallback unified: CN "Surname Given" on all four ports (Windows had it reversed). During the GNOME run both real cards answered SW 6985 on a PIN-less read (no PIN sent, not retried): re-insert before the next real test (R-07).

- 2026-10-25: GNOME app gets the same multi-card + card-change support (per-reader generations incl. pcsc-lite event counter, card selector, re-read, identity-guarded signing, consent for the portal-chosen card); run against both real readers (PIN-less only), names decoded. Cosmetic: `auth-smartcard-symbolic` missing from the macOS test icon theme.
- 2026-10-25: **0.1.3** — user reports: (1) no card-change detection, (2) "M\C3\AEndru" shown, (3) second card → "no available signatures" in the browser, (4) two cards connected. Root causes: (2) display reused the XAdES `\XX` escaping → new `X509Name` decoder (MAC-22); (3) live-reproduced: `/certificates` returned **invalid JSON** (unescaped `label` with `\C3`), and only one card → JSONSerialization + all cards (MAC-20); (1) single-card monitor and no identity check → per-reader generations + **identity guard before VERIFY** (MAC-21: a swapped card can no longer receive the other card's stored PIN). Live check with both real cards: valid JSON, both holders decoded. 42/42 tests on both backends (multi-card, swap-refused-before-PIN, diacritics). `MoldSign-0.1.3.dmg` packaged.
- 2026-10-25: Open items from the portal work (0.1.2): **MAC-19** batch PIN sessions in the core bridge; **R-11** XAdES honours the requested digest (SHA-1 for the portal's Xml/Text, as the vendor does); the validator now checks enveloped `#FileObject-` content (previously skipped) and SHA-1 signatures on both backends; **MAC-10** activity log records real outcomes. New card simulator (X-10) → 3 end-to-end tests (batch = 1 consent, SHA-1 signature verifies, wrong PIN tried once → 400 + remaining attempts). 36/36 on Apple and OpenSSL backends. CLI `xades --digest`. `MoldSign-0.1.2.dmg` packaged; live batch + XML retest pending.
- 2026-10-25: **Live portal signing works with macOS 0.1.1** (user-confirmed; request 11:30:26 from msign.gov.md). Closes the browser-signing regression; MAC-07 and SEC-02 done. The activity log doesn't record the content type, so R-11 (SHA-1 vs SHA-256 for Xml/Text) stays open until an XML document is signed.
- 2026-10-25: **Browser signing failed (user report) → fixed in 0.1.1.** Cause: the 0.5 s/303 poll introduced in the bridge hardening. The portal (re-read `chunk-4385ef64`) makes ONE GET per document, browsers follow at most 20 redirects, and consent + PIN take longer → "Failed to obtain signature location." The vendor's GET is a long-poll (`Future.get()`; no 303 anywhere in its code). The bridge now long-polls, answers failures `400` + `error` header like the vendor, and honours `signatureType:"Embedded"` (it always produced detached XAdES, unusable for the portal's Xml/Text contents). New tests: long-poll regression (3 s consent → one held response, no 303), enveloping XAdES structure. 33/33 in both modes. `MoldSign-0.1.1.dmg` packaged; needs a live portal retest.
- 2026-10-25: GNOME app (`linux/`, LNX-08…14) built: Swift + GTK4/libadwaita C API, runs on macOS via Homebrew GTK for UI work. First real-card signature through it (`Customs declaration-semnat.pdf`, PAdES-B-T) verifies valid offline; one wrong-PIN attempt beforehand was reported once and not retried. Core gaps it surfaced are closed: `MoldSignServer.onSignResult` (stored PIN dropped when the card rejects it during a browser request, now in all apps), `PCSCTransport.isServiceAvailable()`, Linux TLS identity paths. A loopback test covers consent denial → error to the page, card untouched (both backends). 31/31 tests in Apple and portable mode.
- 2026-10-25: CI workflow for all platforms (`.github/workflows/ci.yml`); docs/11 build & release.
- 2026-10-25: Packaging (MAC-15, IOS-10, AND-10, CLI-04): `scripts/package-*.sh` produced `MoldSign-0.1.0.dmg` (universal, ad-hoc), `moldsign-0.1.0-macos-universal.tar.gz`, an unsigned iOS archive + IPA, a debug-signed release APK + unsigned AAB. Versions come from `MARKETING_VERSION`. The employer signing identities on the Mac are deliberately unused (D-15).
- 2026-10-25: Linux core portability (LNX-01…05) behind `MOLDSIGN_PORTABLE`: OpenSSL AES/CMAC/SHA/RSA/TLS, POSIX HTTP client + bridge listener, pcsc-lite via the real header. On macOS the portable build passes 30/30 tests incl. live PKI and a live TLS 1.3 bridge with the vendor p12. Found: our PC/SC shim declared a 64-bit `DWORD` on macOS (the real ABI is 32-bit); fixed by including the real headers. Added a real-signature RSA test (vendor CMS) + tamper test.
- 2026-10-25: Linux scope decided (D-10): GNOME app in GTK4/libadwaita + CLI, both native Swift. Swift core moved to `swift/MoldSignKit` (D-14). Windows skeleton done (F-13, 108 tests).
- 2026-10-25: Design mock-ups published (F-15); contrast fixes adopted (`onBrand` navy text on dark-mode brand, soft status fills, warning text only on raised surfaces).
- 2026-10-25: Xcode project `apple/MoldSign.xcodeproj` (F-11, D-11): `MoldSign-macOS` menu-bar agent (popover, main window, settings, auth panel, launch at login), `MoldSign-iOS` (tabs, connection guide, in-app msign.gov.md browser with bridge), `moldsign-cli`. All build with no warnings; the macOS app launches as an agent; package tests pass from the scheme.
- 2026-10-25: Android skeleton landed (F-12): Kotlin core passes every vector; CCID transport; Compose app APK builds. The port found a Swift bug: `readBinary` double-unpadded (chunks ending in `00`/`80` truncated). Fixed, with a card-simulator regression test that fails on the old code.
- 2026-10-25: CLI contract (CLI-01) + Swift CLI (CLI-02). User decisions: CLI on macOS, Linux, Windows; macOS/Linux native Swift, not .NET (D-09).
- 2026-10-25: Bridge hardened (SEC-01/03, F-07) and verified live on spare ports: loopback-only, allow-list 403 without CORS, PNA preflight, 0.5 s poll hold → 303. The vendor Java server currently holds 18480/18443 (R-10).
- 2026-10-25: Live PKI tests pass (F-05/F-08): MDQTSA token, CRL, native OCSP (same responder as `openssl ocsp`). Found and fixed: URLSession HSTS-upgrades the TSA URL; NWConnection follows the system proxy (Charles → 503); `URL.path` drops the trailing slash (TSA 301).
- 2026-10-25: Counter-signing went from 42.9 s to 0.06 s: `(\d+) 0 obj` was quadratic over the `/Contents` zero run; anchored with `(?<!\d)`.
- 2026-10-25: Core moved to `swift/MoldSignKit` (F-01) with transport abstraction (F-04), MSLog (F-06), public API; hard-coded PIN removed (F-03); `.build/` untracked (F-02); C CMAC empty-message overflow fixed (NIST vector).
- 2026-10-25: Plan created. Baseline: `swift test` 16 tests, 13 pass, 3 fail on missing `~/Downloads` fixtures. Found: hard-coded PIN in `main.swift` (F-03, SEC-06), committed `.build/` (F-02), bridge accepted any origin (SEC-01).
- 2026-10-25: **Android browser bridge (AND-04, AND-05)**: Chrome on the phone could not sign because the app listened only on HTTP 18480 and `/certificates` was empty; the portal calls `https://localhost.cts.md:18443`. Added the TLS listener (the vendor `localhost.p12`, packaged into the core jar by `processResources`; Android's PKCS12 reader accepts its PBES2/AES-256 encoding, expiry 2027-02-16), the Swift routes ported to `SigningBridgeRoutes` (`201` + absolute `Location` + empty body, long-poll `GET`, PIN sessions for batches, one signing job at a time in arrival order), the real certificate list (`CertificateSummary.der`) and a heads-up consent notification, because Chrome is in front when a request arrives. A PIN typed on the web page is ignored; the PIN is only entered in the app. Verified on a phone with `adb forward` + curl (valid public chain, `201`, notification, PIN, `200` with a PDF that the Swift validator reports VALID, chain trusted, and iText `verify()=true`). Bug found on the way: an empty `certificateBase64` (portal "any card") was read as a certificate hash that matches no card. Then the owner signed from msign.gov.md in Chrome on the phone. Pending: XAdES (non-PDF content answers a clear error). The Mac app holds 18443/18480 while it runs (R-10): forward the phone to other local ports when testing.
- 2026-10-25: **Android share target and save-as (AND-07)**: other apps can share files to "Semnează" (SEND / SEND_MULTIPLE; the file is copied into `cacheDir/shared`, which is emptied at process start, and the Sign tab opens through a one-shot event); every Activity row with a file has a menu with Open, Share (system chooser) and Save as… (`CreateDocument`, one launcher per file type). Checked on a phone: a shared PDF lands on the Sign tab with PAdES-T, the chooser and the save dialog open, and the copy is written.
- 2026-10-25: **Android XAdES, OCSP and validator (AND-01)**: `XadesDocumentSigner` ports the Swift `XAdESSigner` (BES / T / C, detached `file:/` or enveloping, SHA-256 or the portal's SHA-1; the card signs a SHA-1 DigestInfo then; the vendor's duplicate OCSPRef and full-path ObjectReference kept) and the bridge now signs Xml/Text contents through it (`algorithm` honoured). Native OCSP request (`Revocation`, byte-identical to `openssl ocsp -no_nonce`), CRL number / issuer / thisUpdate and OCSP responder / producedAt read from the DER instead of scanning for bytes. Differences from Swift: a failing CRL / OCSP / TSA fails the signature instead of silently dropping the reference, and the self-signed root is filtered out of the XAdES-C certificate list by looking at the certificate, not at what the caller passes. `MdTrustServices` retries once on 502/503/504 or a dropped connection: the OCSP gateway answers the first request after an idle spell with a 13 s 502, then in ~20 ms. `OfflineValidator` replaces the byte-scanning Swift validator: the PDF ByteRange must start at 0, enclose one `/Contents` string and reach the end of the file for the last signature (data appended after signing is a change), the signer certificate is picked by the SignerInfo's issuer + serial, and the time-stamp token must cover the signature (PAdES) or the canonical SignatureValue (XAdES). Same verdicts as the Swift validator on card-signed PDFs (real MDQTSA token, real CA chain). The Verify screen shows the verdict (valid / invalid / cannot be confirmed / no signature), a card per signature with Integritate / Semnătură / Lanț de încredere chips and technical details, and an inline picker for the document a detached XAdES refers to; verifying is automatic on picking. Not done: signing XAdES with the real card (needs the owner's PIN), revocation checks and the time-stamp token's own signature in the validator, and the "Contrasemnează" action on the Verify screen (the signer itself counter-signs).
