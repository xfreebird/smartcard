2026-11-17 — CI 44109997704 passed all macOS checks (31 integration and 15 UI), Swift core/CLI and localization; remaining validation was cancelled after local Duo checks exposed two missed synthetic gestures. Swipe the carousel container directly, retaining exactly one native gesture per page and selection/centering assertions. Tap the center of the Demo switch instead of a row-width percentage that reached the thumb edge in the narrow Duo pane. The carousel passed three consecutive Duo runs; all 35 Duo cases passed across focused batches, including protection byte/permission and Documents persistence postchecks. Both updated carousel cases and the full Demo activation/share/relaunch/disable flow also passed on iPad. Hosted follow-up pending.

2026-11-17 — Simplified mobile browser authentication into a left toolbar button and shared options modal. iOS Settings uses a short NFC/Reader summary; the full-width connection strip became an accessible status dot. Added friendly error presentation for page loads, native NFC and mobile bridge responses, with raw-error suppression regression coverage prepared. Final iOS Debug build 7 and Android NFC Test builds compiled, installed and launched on both connected phones; the Android production app was preserved. Physical layout/error acceptance and automated suites remain pending. See docs/reports/browser-nfc-integration-2026-11-17.md.

2026-11-17 — Owner confirmed embedded-browser NFC authentication works on iPhone. Added an explicit saved browser authentication method (NFC / Card reader), exclusive certificate listing with no fallback, matching iOS Browser settings, and Android controls shared by embedded/external browsers. Android external requests retain public NFC identity discovery and use the existing notification → native PIN → foreground NFC flow. Follow-up method persistence and external-browser hardware acceptance pending. See docs/reports/browser-nfc-integration-2026-11-17.md.

2026-11-17 — IOS-06/IOS-09/AND-04/AND-09: implemented on-demand NFC identities in the embedded browsers. Known/read public certificates remain listed without RF; native consent/PIN precedes each NFC signing session, exact DER is bound before authentication/PIN, and NFC ends before network completion. Added reader/NFC selection, RO/EN/RU copy, scoped signing hooks and simulated bridge regressions. iOS Debug build 4 and Android NFC Test APK builds passed; localization exports and strict iOS signatures checked. Automated suites are left for the owner per standing rules; physical portal authentication remains pending. See docs/reports/browser-nfc-integration-2026-11-17.md.

2026-11-17 — CI 44097029073 confirmed the readiness fix on both device families and kept macOS green. iPad later timed out at app launch while the Duo was running a separate iOS runtime. Isolate both families in sequential matrix jobs, retaining all 35 UI cases each and the combined 50-minute job ceiling (25 minutes per family; 23-minute UI steps). Compile the shared test harness once and prepare document fixtures before UI execution, preserving per-suite results and filesystem postchecks. Remove initial polling delays for already-present controls while retaining timeouts and two stable frame observations. Correct the iPad protection toolbar-overflow action, which opens the sheet directly. All 35 iPad cases passed locally across the isolated run and corrected protection/Documents/action-button follow-up; all 80 automation contract checks passed. The optimized Settings and all five verification cases also passed; Settings took 86 seconds instead of 105 and verification methods took 133 seconds instead of 195. Hosted full CI validation is pending.

2026-11-17 — Registered the connected iPhone 13 Pro through Apple API-backed Xcode provisioning. Refreshed the main iOS, share and widget development profiles to include the device; verified NFC access on the main profile and the shared App Group on all three. Xcode 27.1 Debug 0.2.12 build 1 compiled, passed strict bundle signature checks and installed on the phone. Browser NFC authentication remains investigation work; no real-card authentication or signing was performed. Local build evidence: `.local/nfc-browser-20261117/`.

2026-11-17 — Full CI 44091906763 passed macOS (31 integration and 15 UI checks), Android, Windows, Linux, Swift core and localization. iOS exposed a busy-runner readiness timeout: a visible, unchanged button was queried repeatedly until the polling budget expired. Read its frame once per poll, require two stable observations, and omit redundant element debug-description snapshots; retain the 10-second wait and all visibility/enabled/hittability checks. Stop the verification method at its first assertion failure. The focused five-state reader test passed on both Duo and iPad; hosted follow-up pending.

2026-11-17 — Follow-up CI validation targets the named Verify workspace instead of the macOS sidebar and handles paged iPad tabs. Both required iOS device families now run concurrently on one billed runner under the unchanged 40-minute UI / 50-minute job limits. Failure or cancellation stops both process groups and shuts down both simulators; subprocess fixtures verify concurrency, peer cancellation and complete successful coverage. Disable the expensive whole-simulator sysdiagnose while retaining XCTest logs, screenshots, recordings and results. All 75 automation contract checks passed. Local iPad PIN/shared-identity/demo checks and NFC guide passed; the complete Settings journey passed on iPhone Duo and narrow iPad, including sheets and landscape sidebar navigation. Hosted verification pending.

2026-11-17 — Repairing Apple CI interaction coverage after the guided signing/Settings redesign: macOS Verify scrolls disclosure rows clear of the window edge; iOS reader tests select the reader method explicitly, carousel tests use the inline cards, nested sheets dismiss the visible Done action, demo checks assert the banner on Sign, and PIN geometry follows the rotated foldable scene. Continue keeps its simple visible label and now exposes the localized document count as its accessibility value. Local iPhone Duo regressions: 14 unaffected cases passed, followed by all three corrected carousel/accessibility cases; 72 automation contract checks passed. Hosted verification pending.

2026-11-17 — Bounded iOS validation to 50 minutes per job, 40 minutes for the two-device UI batch, and 5 minutes for the build. CI now stops at the first failing suite/result postcheck and shuts down its simulator; local investigations retain full-batch collection. Failure evidence remains uploaded with a three-minute limit. Cancelled CI 44052843584 after its UI step exceeded an hour; its first suite had already failed at 09:25 UTC. The previous healthy UI batch took about 32 minutes. Added simulated failure/success/cleanup checks and workflow budget guards. Existing native UI assertion failures are separate from this budget fix.

2026-11-17 — Prepared larger iOS Header and Search Results artwork in English, Romanian and Russian. Replaced the tiny headline/paragraph layout with a short central message and large native NFC/reader phones. Verified exact dimensions, opaque RGB, text safe bounds and Firefox previews using the crop measured from the owner’s iPhone 11 Pro screenshots. The owner approved publication. All six images are uploaded and waiting for Apple review in standalone submission 2dd22b15-02ec-4e90-bdd9-f8f77d061cb0; live placement replacement awaits asset approval. iOS 0.2.12 remains live. See docs/reports/apple-featured-2026-11-17.md.

2026-11-17 — Corrected the first phone landing frames and Android clock and framing. Aligned mobile store badges and Linux package groups, emphasized direct installers, temporarily hid the Mac store badge and refreshed the repository image with all five platforms.

2026-11-17 — Added separate iOS and Android NFC sequence diagrams and documented platform discovery, certificate reads, protected signing and session cleanup in the public Developer Handbook.

2026-11-17 — Updated the public developer handbook and the repository NFC guides for mobile transports, Settings, test evidence, store review and public downloads.

2026-11-16 — Refreshed all 18 Mac, Linux and Windows landing-animation frames. Updated 168 guide screenshots and aligned their callouts for macOS and Linux in English, Romanian and Russian. The website now serves digest-verified release installers through public links. The Mac App Review attachment now includes both muted physical-device demos.

2026-11-16 — iOS and macOS 0.2.12 build 214 are waiting for App Review with their physical-device hardware recordings. Apple removed the preceding Mac review. Play Alpha and AppGallery are reviewing the Android update with verified localized screenshot order. Microsoft published the Windows update. The notarized Mac installer, Windows MSI and Android APK are available in the GitHub 0.2.12 release. The website guides and mobile scroll sequence cover NFC and USB signing. See docs/reports/nfc-store-submission-2026-11-16.md.

2026-11-16 — Owner approved the four 0.2.12 store releases. App Store Connect currently shows iOS 0.2.11 live and macOS 0.2.11 waiting for review. Google Play Alpha has bundle 1793624694, and the published Windows package is 1.2.213.0. Build and review preparation started with the approved localized assets.

2026-11-16 — NFC store materials: prepared the proposed 0.2.12 listing and reviewer copy for Apple, Google Play and Microsoft, with Romanian, English and Russian coverage and both existing English Mac locales. Captures reuse the prior submission sizes. iPhone, Duo and Android show the NFC and reader choices, with a dedicated reader screenshot in each set. App Store Connect reports iOS 0.2.11 live and macOS 0.2.11 waiting for review. The owner reviews before any store changes. See docs/reports/nfc-store-submission-2026-11-16.md.

2026-11-16 — Settings and NFC readiness: mobile Settings replaces Card, with Demo first and purpose-based groups. Follow-up platform reviews replace focused pushes with modal tasks and use actual reader/card artwork on phones and tablets. Sign keeps stable method/action positions and top-right card info; PIN deletion has a trash icon. Desktop Sign is preserved; Windows uses full-width Settings rows and focused dialogs. Apple Documents exposes protection directly with a shield. NFC store copy and targeted match profiles are prepared; no store submission. All five platform designs are approved. macOS troubleshooting is left-aligned and Documents has adjacent shield/trash actions. iOS build 22 passed final phone/Duo checks; the owner installed the approved Android update and chose to open it directly. Actual Linux/Windows external file drops pass on Sign and Verify; Mac/tablet gesture limits are documented. Evidence: docs/reports/settings-nfc-readiness-2026-11-16.md.

2026-11-16 — IOS-09/AND-09 guided mobile redesign and reader follow-up: replaced the permanent setup strip with document choice, review and Continue to the common PIN path. NFC stays compact; selecting Reader now shows connect/insert guidance and the selected card inline on Sign/Card, with swipe selection for multiple identities. Shared neutral surfaces and Android brand palette; details/PIN management remain secondary. iOS build 8 and Android NFC Test builds passed; 10 phone and 8 tablet interaction checks, 18 Android app checks and four runner checks passed. Final Android NFC Test 1794820010 installed via Files and launched; iPhone build 8 installed and launched after reconnection. No real card authentication performed. Details: docs/reports/guided-mobile-signing-2026-11-16.md.

2026-11-16 — IOS-09/AND-09 mobile UI: made Sign and Card NFC-first on capable phones, with a large NFC symbol, How it works guide and visible Document → PIN → Tap card sequence. Moved certificate and saved-PIN details behind simple rows; reader choice and shared PIN handling remain available. RO/EN/RU copy and accessibility step layout added. iOS device/simulator builds, six focused UI tests on each of phone/tablet, two reader-gesture tests, four runner checks, Android Debug build and 18 app tests passed. iOS build 6 installed/launched; Android final build 1794820005 installed/launched. Details: docs/reports/nfc-ui-simplification-2026-11-16.md.

2026-11-16 — AND-09/AND-06: added Android foreground ISO-DEP signing with PIN-first consent, a single card connection per document, exact certificate binding, shared reader/NFC saved PINs and metadata-only diagnostics. Owner signed a PDF on the connected Android 14 phone; OpenSSL accepted its RSA-4096 CMS, rejected a tampered copy, verified the timestamp CMS and confirmed its imprint binds the card signature. One earlier scan lost connection near PIN verification. Core 154 tests (1 skipped), app 18 tests and Debug/Release builds passed. Separate NFC Test installation preserves the Play app; final build 1794820002 was installed via the phone installer and reopened after USB updates were blocked. Automated device test-helper installation was blocked. Details and remaining acceptance: docs/reports/android-nfc-signing-2026-11-16.md.

2026-11-16 — IOS-09 shared card/PIN follow-up: reader and NFC now share a deduplicated identity list and the existing certificate-keyed PIN account. NFC can select the reader card or a remembered card; saved certificate metadata restores remembered cards after restart, with exact certificate verification before PIN transmission. Card/Settings manage disconnected saved PINs and deletion applies to both methods. Fifty-two app-policy tests, four runner checks, three shared-PIN UI checks, two NFC-choice regressions and device/simulator/macOS builds passed. Signed build 0.2.11 (5) installed on the iPhone; launched successfully after a transient timeout. Physical card/saved-PIN acceptance remains open.

2026-11-16 — IOS-09 PIN-sheet follow-up: fixed missing iOS actions by pinning Cancel/Sign in a bottom safe-area bar instead of relying on a keyboard toolbar. Development build 0.2.11 (4) built, signature/entitlement checked and installed on the iPhone; launched after the owner unlocked it. Core 139 tests (5 skipped), focused single-connection 7 tests and app policy 48 tests passed; NFC choice passed on phone and tablet. Both keyboard-visible portrait/landscape PIN interaction tests passed, including submission; the owner’s instrumented main-app card scan remains open. See docs/reports/nfc-app-integration-2026-11-16.md.

2026-11-16 — IOS-09 follow-up: owner reported intermittent NFC connection failure before PIN in the first app build and requested a single NFC presentation. Reworked authorization to collect PIN through the same coordinator first, then identify/bind the card and sign in one NFC session per document; known NFC identities retain saved-PIN/Face ID support, with explicit Use another card. Added Debug-only metadata diagnostics and identity-binding/privacy tests. Signed build 3 and a fresh owner scan are the next acceptance steps.

2026-11-16 — IOS-09 production NFC integration implemented in the working tree: explicit Card reader / NFC choice remains available with connected readers; public identity scan followed by the existing PIN coordinator/vault, then certificate-bound NFC signing through the shared document pipeline. Added session cancellation/timeout handling, mandatory secure-response validation, fresh authentication randomness and RO/EN/RU copy. Core/policy/UI regression suites are prepared and NFC UI coverage joins the native mock batch. Builds/tests/device acceptance remain pending under the owner-run verification rule. Guide and knowledge: docs/16-ios-nfc.md and AGENTS.md. Probe evidence and its one-attempt lock are preserved.

2026-11-16 — Physical NFC signing VERIFIED on the owner's card/iPhone 11 Pro (iOS 27.2): complete certificate/input reads, mutual authentication with verified proof, secure messaging, one successful PIN verification and one RSA-4096 diagnostic-document signature. OpenSSL independently accepted the detached CMS and rejected a modified document. Eighteen reports plus private artifacts collected with prior hashes preserved; persistent one-attempt lock confirmed and retained. Production NFC integration, PDF/PAdES, timestamping and trust/revocation are not yet validated. Evidence: docs/reports/nfc-first-scans-2026-11-16.md.

2026-11-16 — NFC setup and 16-byte challenge confirmed (all 9000); seventeen reports preserved. Owner requested a full PIN test. Build 11 prepares one-attempt secure-channel authentication, protected PIN verification and signing of a diagnostic text document, with local RSA verification and detached CMS output. PIN only on phone; persistent lock before authentication prevents repeat attempts. Thirteen vector/regression and six simulator tests passed, including RSA-4096 success, independent OpenSSL CMS verification/tamper rejection and failure stops. Device build passed; real-card full test pending.

2026-11-16 — Both complete NFC input reads confirmed (D003 18 bytes, D004 16 bytes, all 9000); sixteen reports preserved with earlier hashes unchanged. Build 10 adds separately initiated authentication setup only: exact MSE after input checks, then one 16-byte challenge, stopping before authentication/PIN/signing. Ten regression and three existing-card-simulator integration tests passed; device build succeeded. Hardware setup acceptance remains untested.

2026-11-16 — Step 7 read D003 successfully (9000, exactly 18 bytes) but build 8 rejected its prefix using an unsupported simulator-derived assumption; D004 was not reached. Fifteen reports collected with all earlier hashes unchanged. Build 9 removes this extra prefix restriction to match the production contact reader, preserving exact-length checks and read-only commands. Authentication remains unattempted.

2026-11-16 — Complete NFC certificate read confirmed on physical iPhone: baseline 128-byte reads returned all 1799 DER bytes, and iOS parsed RSA-4096. Fourteen reports preserved with earlier hashes unchanged. Success after holding the card throughout supports early removal as the earlier failure cause. Build 8 adds a read-only complete authentication-input check (18-byte framed serial and 16-byte seed); actual authentication and signing remain untested. See docs/reports/nfc-first-scans-2026-11-16.md.

2026-11-16 — Build-7 smaller-read NFC scan read 260 bytes before response error 102 / nfcd 29 at offset 260, which succeeded in the prior 128-byte run. Thirteen reports preserved; previous twelve hashes unchanged. Owner reported moving the card after the first vibration/checkmark. Retain build 7 and repeat step 5 with the card held until the final app outcome to test this handling explanation before further protocol changes.

2026-11-16 — Repeated full-certificate scan reached 1028 successfully read bytes, then failed at READ BINARY offset 1028 with NFCError 102 / nfcd 29. This differs from the previous selection-stage failure. Build 7 preserves step 5 and adds separate step 6 with 64-byte chunks, plus certificate byte-count progress in the NFC sheet and incomplete outcome. No transport retries, new command types, authentication or signing added. Device validation recorded in docs/reports/nfc-first-scans-2026-11-16.md.

2026-11-16 — First complete-certificate NFC attempt stopped at Generic ADF SELECT (NFCError 102 / nfcd 29), before certificate-file selection or reading. Eleven reports collected; previous ten hashes unchanged. Same command succeeded earlier, so retain build 6 and request one controlled repeat before modifying protocol or inferring certificate restrictions.

2026-11-16 — NFC prerequisite file reads confirmed: build 5 reused IAS discovery, selected MF/D003/D004 and read both 16-byte prefixes with 9000. Ten reports collected with prior hashes preserved. Build 6 adds a bounded full-certificate read and iOS certificate/public-key parsing without retaining holder data or invoking authentication; seven tests and device build passed, and step 5 was installed, launched and visually confirmed.

2026-11-16 — NFC certificate-path read confirmed: build 5 directly selected Generic ADF (9000, 52 bytes), selected EF 0001 (9000, 36 bytes), and read exactly 16 bytes (9000) over NFC on the physical iPhone. Nine reports collected; prior eight hashes unchanged. Raw bytes discarded; full certificate parsing, authentication and signing not yet tested. Next prepared check is probe 4.

2026-11-16 — NFC breakthrough: build-4 discovery selected Generic ADF (9000, 52 bytes) and IAS (9000) over NFC; ICAO LDS returned 6A82. The MF-first certificate probe failed before certificate selection with NFCError 102 / nfcd 29. Build 5 uses direct Generic ADF selection matching the successful discovery sequence, without adding authentication/PIN/signing. Two new reports collected and six prior report hashes verified unchanged. Six tests and signed device build passed; build 5 installed and launched for the next scan.

2026-11-16 — First real iPhone NFC reports: six build-3 scans collected and hashed. IAS discovery and MF SELECT succeeded; EF.CardAccess selection returned 6A82, two attempts had Core NFC response error 102, and three signing-path attempts never delivered a tag callback. No file read or signing success established. Build 4 separates incomplete outcomes from completion, tests application selection before optional file probes, and reuses the initial IAS selection. Six tests and device build passed; build 4 installed, launched and visually verified on the same iPhone. Findings: docs/reports/nfc-first-scans-2026-11-16.md.

2026-11-16 — NFC probe review and device launch: corrected read-length validation, small DER-file reads and stale-session handling; bounded read-only response continuation and added a command allow-list plus security-status stops. Removed the out-of-sequence challenge request. Six synthetic regression tests passed; Debug build 3 signed with NFC TAG entitlement, installed and visually verified on the physical iPhone 11 Pro running iOS 27.2. Empty Documents transfer succeeded. No NFC scan, authentication or signing performed. Review: docs/reports/nfc-probe-review-2026-11-16.md.

2026-11-15 — iPhone documentation status bars: replaced only the top 40-pixel band in 15 legacy protection screenshots across EN/RO/RU with native modern iPhone strips, showing 09:41 on the left. Preserved every app pixel, canvas and annotation coordinate; recorded donor/crop hashes and bumped the website image cache revision. Published source 6ac86bad8211d4ce9010022fb8ed2165c9661a9f: Website workflow 43697200055 passed 36 tests, guide/build/SEO checks and Pages deployment; repository CI passed. Verified all 15 public image hashes and the corrected status bar in the live guide. Evidence: docs/reports/website-status-bars-2026-11-15.md.

2026-11-15 — Website screenshot refresh: captured all five platforms in disconnected, empty-reader and ready states, light/dark, using existing isolated Debug apps with demo banners hidden. Refreshed animation, overview and legacy images; normalized documentation status clocks to 09:41 using native clock crops; cropped Windows guide windows and transformed their annotations. Added image provenance/hash guards and cache revision. Published source 023edbaad200ebb4e2b459ee91b3aed87aef92cb: Website workflow 43695852792 passed all 36 tests, guide checks, three-locale build, SEO and Pages deployment. Verified every one of the 394 changed public PNG hashes and live desktop/mobile, light/dark and Windows guide presentation. Evidence: docs/reports/website-screenshots-2026-11-15.md.

2026-11-15 — Published and verified mobile downloads navigation from 13ff6b70531946cbd5680a0382c219ff32a1002c. Website workflow 43683664572 passed all 34 tests, guide checks, three-locale build, SEO validation and Pages deployment. Live Chrome checks passed 320/390px layouts, all five links, scroll selection in both directions, long-card tracking, keyboard activation, desktop column selection, dark mode, legacy anchors and EN/RO/RU widths after refresh. Physical iPhone Safari was not exercised. Evidence: docs/reports/downloads-mobile-2026-11-15/README.md.

2026-11-15 — iOS NFC investigation: prepared a separate Core NFC probe and device runbook for a future physical-card session. It records application selection/status and session errors; separately triggered follow-ups inspect limited access parameters, certificate-path and secure-channel prerequisites without retaining raw data or sending PIN/signing commands. Research only; no production NFC support claimed. Static Swift type-check and project/plist checks performed; device provisioning, installation, NFC behavior and signing feasibility remain unverified.

2026-11-15 — Downloads mobile navigation: replace clipped horizontal chips with five visible icon-and-label links, a restrained active highlight and underline, and a flat sticky mobile bar. Track the platform in the reading area below sticky controls during scrolling/resizing, preserve desktop column selection and legacy anchors, and measure the bar for accurate anchor positioning. Add regression cases for long/short cards, gaps, sticky occlusion, desktop rows and direct links. Live 320px review also corrected the Windows label wrapping and translated footer links that widened the document. Local syntax/whitespace review and the authorized Website workflow precede live responsive verification; no native build or release changes.

2026-11-15 — Published developer website handbook from a2bde7e190c568c9bb524b22f9f6a233870a28a9. Website workflow 43678660078 passed site tests, guide checks, the three-locale Docusaurus build, SEO/Markdown export validation and GitHub Pages deployment. Verified 65 live HTTPS URLs: 36 developer HTML pages, 12 English Markdown exports, localized discovery/download routes, both source-matching SVGs and desktop update feeds. Browser UI inspection was unavailable; no native builds, store operations or hardware tests performed. Evidence: docs/reports/developer-handbook-publication-2026-11-15.md.

2026-11-15 — Developer website handbook: added twelve public English chapters covering layered architecture, the card signing sequence, APDU/CCID/T=1 fields, formats and bridge, per-platform design-system implementation, build/run, test automation, release and website workflows, an agent source/verification map and glossary. Added local accessible SVG diagrams, dedicated navigation and English Markdown/text/JSON discovery exports while retaining translated product references. Source reviewed against current implementation and operational scripts; Markdown/MDX parsing, local-link audit, JS/Python/JSON/SVG syntax/accessibility metadata and whitespace checks passed, and diagram renders were visually inspected. Website/native builds, automated suites, browser layout validation and deployment remain for the owner; no release or store action performed.

2026-11-07 — iPhone Duo follow-up: native SDK 27.1 build, single-scene declaration, inline Sign header and width-based split from 560 usable points account for vertical system bars. Eight native light/dark captures cover outer/inner portrait and landscape; one state-assertion UI test passed, actual resizing was exercised separately through Device Hub, and a same-process closed/reopened check retained the selected card and two-file queue. iOS delivery/CI now selects and checks SDK 27.1+ before signing or cleanup; hosted CI/upload remains unrun. iOS 17 deployment minimum preserved. Existing BT Duo preserved; disposable simulator removed. See `docs/reports/iphone-duo-ux-2026-11-07.md`, build report and updated phone-preview PDF; simulator wake/foreground and hardware limits are recorded.

2026-11-07 — Cross-platform UX and security review: adaptive iOS/Android landscape signing, concise Verify guidance, readable compact navigation/accessibility rows, Windows queued-action footer and Linux narrow layouts. Hardened Apple/Android saved PIN handling, bridge origin/result/PIN lifetime controls, native-only filesystem routes and CLI detached-reference containment; Windows CLI help identifies unsupported commands. All five native Debug builds passed; Swift 63 tests (5 opt-in skips), Android 121 (1 live-TSA skip), Android AAD 1, Fedora app 14 and native containment 1 passed with no failures. Representative fictional screenshots and scoped interaction checks cover both Macs and Air VMs. Siri, macOS features and CLI/MCP integration proposals are documented, not implemented. See `docs/reports/ux-security-review-2026-11-07.md` and phone-preview PDF. Real-card signing, live OS authentication, complete accessibility/gesture coverage and release/Store validation remain untested; no release or submission performed.

2026-11-06 — Published 0.2.4: iOS 204 Waiting for Review; Windows 1.2.204.0 Certification; macOS TestFlight 204 VALID (existing review unchanged); Android 1793624677 uploaded Inactive via Console fallback. Corrected signed/notarized DMG verified and published; download catalog and update feeds refreshed. Full CI passed after the stamp-test decoding correction. See docs/reports/release-0.2.4-2026-11-06.md.
2026-11-06 — Release DMG verification: removed hide_extensions for the signed app; dmgbuild adds FinderInfo after signing, which fails codesign --strict despite accepted container notarization. Rebuild the 0.2.4 DMG without modifying bundle metadata.
2026-11-06 — Release validation: corrected the visible-stamp test to decode ASCIIHexDecode appearance streams before asserting transparent background/border drawing commands; runtime source unchanged.
2026-11-06 — Release 0.2.4 preparation: synchronized app/store translations, localized release notes, Apple/Windows build 204; iOS and Windows store submissions, signed/notarized macOS DMG, macOS TestFlight and Android artifact-only uploads authorized. Existing macOS App Review preserved.
2026-11-06 — Documents verification: signed-file Verify actions route the selected document into the existing verification screen on Apple, Android, Windows and Linux; reuse offline verification without a card or PIN. All five native Debug builds passed; localization/whitespace checks passed. Mobile builds installed; interactive routing and verification of a real signed document not exercised in this revision.
2026-11-06 — Captured three-file completion layouts on mobile; added a guarded Android Debug results fixture with explicitly unsigned sample PDFs, without invoking card/signing services. Android Debug build passed.
2026-11-06 — Mobile signing results: grouped completion presentation, clear-results action that preserves files/history, and direct Documents navigation with persistent-file guidance on iOS and Android. Both native Debug builds and localization/whitespace checks passed; installed on the dedicated simulator/emulator, iOS completion demo visually checked. Android completion appearance and interactive clear/navigation actions remain unverified.
2026-11-06 — macOS Documents header: keep the clear-history action in a reserved content-header slot instead of conditionally changing the window toolbar; switching filters no longer changes toolbar composition. macOS Debug build and whitespace check passed; completed-signing demo captured. Interactive filter-switch verification was unavailable (computer-use timeout).
2026-11-06 — Signed document discovery: Documents destination on every platform (new iPhone tab), signed outputs shown first with separate history, explicit open/share or reveal actions, and immediate results placed above queued inputs. Persist output classification alongside existing history, retain legacy named outputs, explain that website results are downloaded from the requesting site. All five native Debug builds passed; demo layouts captured and checked on each platform. Localization exports and whitespace checks passed; real-card signing, output reopening/sharing, restart persistence and regression suites not exercised in this revision; the document list uses the existing bounded, persisted recent-file history (100 entries), not a separate file storage location.

2026-11-06 — Android file size: resolve local file URI metadata from the filesystem, including demo PDFs and cached imports, rather than relying on document-provider metadata. Unknown provider sizes remain hidden rather than displayed as zero. Android Debug build passed; emulator screenshot confirms the local PDF size appears beside its filename.

2026-11-06 — Compact phone file rows: title, size, file icon and options share one aligned header; selection tags use the full row below it with a consistent leading inset, avoiding the trailing-menu gutter that forced early wrapping. iOS/Android phone-only layout; larger layouts retained. Both Debug builds passed; phone previews checked. Android delete background now appears only during a swipe. No signing or regression suite run.

2026-11-06 — Phone file stacks: group menu includes Remove group; swipe left reveals group removal on iOS and dismisses the group on Android. Queue-only removal is disabled while signing; original files remain on disk. iOS/Android Debug builds and localization/whitespace checks passed; gesture execution not yet verified.

2026-11-06 — Phone signing batches: collapsible visual file stacks on iOS/Android, with group format choices restricted to compatible formats, automatic per-file defaults, and one stamp placement applied to all PDF-signature items. Expansion retains individual settings and swipe removal; failed rows stay visible. iOS and Android Debug builds, localization export check and whitespace check passed; collapsed phone previews captured with fictional documents. Full gesture, batch signing and hardware regression tests not run.

2026-11-06 — macOS file-row corners: apply the fill to each individual row and use the same 12-point rounded shape for fill, clipping and inset border, removing the differently rounded group background. macOS Debug build passed.

2026-11-06 — Windows signing-page alignment: removed extra horizontal document-section and ListView item padding; file-row borders, drop zone and advanced options now share the page content width. Windows Debug build passed and the aligned edges were visually checked in the VM.

2026-11-06 — File options refinement: flat native macOS/Windows menus match mobile choices and include removal without a duplicate row button. Windows tags pair theme-aware foreground/background colors. Human-readable signature names cover localized app copy, settings, consent, verification and history; signing/bridge identifiers remain unchanged. Localization exports and whitespace checks passed; all five native Debug builds passed. macOS flat menu and Windows light-theme tag contrast visually reviewed; macOS desktop distribution/entitlements check passed. No regression suites or hardware signing run.

2026-11-06 — PDF-STAMP-01 local macOS validation: current working source at 61743be plus uncommitted changes builds successfully with Xcode 26.6, Debug arm64, using the installed H86U5Z8HYB development profile. App and reader helper pass strict signature verification, retain the smart-card entitlement and hardened runtime; app also retains its provisioned iCloud key-value entitlement. Desktop distribution boundaries and packaged signature font verified. Launched dist/local-macos/DerivedData/Build/Products/Debug/eSemnBun.app for owner testing. No test suite or actual signing interaction run; other platform builds remain pending.

2026-11-06 — File-row styling: subtle individual row borders; compact colored signature/stamp tags left-aligned below the filename, sharing one line where space permits.

2026-11-06 — File-row clarity: human-readable PDF/XML signature names replace technical format codes in file controls; icon tags summarize selections. iOS swipe-left reveals removal, Android swipe-left dismisses a queued file, and every options menu includes Remove file. Protocol format identifiers are unchanged.

2026-11-06 — Per-file options: signing type and Add/Edit stamp live in a file options menu. Phone rows show the current format and stamp state below the filename; desktop rows show it alongside the filename. Summaries include stamp off, the selected page, or all pages and update with user changes.

2026-11-06 — Mobile stamp navigation: iOS and Android now support vertical swipe/scroll between pages, with bottom-pinned round previous/next controls, page count, compact Off/One page/All pages segmented mode, and batch reuse. iOS separates the preview and navigation with 12-point top padding. Native phone builds/captures checked; hardware signing and regression suites not run.

2026-11-06 — Visible PDF stamp UX refinement: labelled Add/Edit actions, native grouped options, transparent serif MoldSign-style appearance with outlined MOLDOVA EUROPEANĂ and small left-aligned Signed with eSemnBun footer. User-directed corner handles replace size sliders on all platforms, retaining proportions and page bounds; GNOME options use aligned AdwSwitchRow controls with consistent margins. Native Debug builds and captured editors reviewed in `dist/stamp-review/`; latest desktop refinements use a macOS print-style sheet with scrollable pages and grouped settings and print-style Windows and GNOME editors with scrollable page columns and fixed grouped inspectors; Windows expands the preview to show approximately 90% of page height with width-safe scaling on resize; no real-card signing or regression suite executed in this revision.

2026-11-06 — [~] PDF-STAMP-01: added optional visible PDF signature placement for macOS, iOS, Android, Windows and Linux, with native previews, page selection, size/position controls, all-page copies linked to one signature widget, and one-action queue templates. Website signing has a separate default-off preference and reuses placement within an origin/card/batch, reopening it when a later PDF lacks the selected page. Appearance text uses the actual signing certificate, a shared signing time and an embedded multilingual font; original PDF bytes are preserved. Added structural, geometry, document-binding, bridge-reuse and visible-counter-signature regression tests. Swift syntax, localization and source-format checks only; builds, test execution, rendered-output verification, installed packages and live portal behavior remain pending owner validation. Contract and checklist: spec/pdf/visible-signature.md.

2026-11-04 — Temporary self-signed standalone MSI certificate created (expires 2027-11-04), saved under Desktop/eSemnBun-secrets/windows and in GitHub Actions secrets WINDOWS_MSI_CERTIFICATE_PFX_BASE64 / WINDOWS_MSI_CERTIFICATE_PASSWORD. Packaging changes sign MSI only and export the public CER; Store MSIX identity is unaffected. Windows smoke test signed a disposable MSI with matching certificate thumbprint BE0FA968224A201B7BA3CF302EF8FAD6A38C40EC; Authenticode reports UnknownError without public trust, so this is not a publicly trusted signature. No trusted-root installation performed. Signing changes committed and pushed in 9b328d4. Release 0.2.1 MSI was signed on Windows and replaced on GitHub with matching public CER; GitHub asset digest confirms SHA256 42dc03e379c421d1c6b8260110545a12fb40688189433f86486a48377ca49026. Release checksums and signing notes updated. CI signing workflow has not been exercised yet.

2026-11-04 — Released v0.2.1 from e687414, authored as xfreebird@gmail.com. Windows CI run 41782914761 built MSI/MSIX successfully using build 111; Partner Center accepted package 1.2.111.0 and Submission 2 now shows Update in certification (pre-processing), with manual publication after approval. GitHub workflow release creation returned HTTP 403, so release assets were published through the owner's authenticated CLI. Linux and Android builds succeeded. macOS 0.2.1 is blocked by a missing Developer ID iCloud provisioning profile; iOS upload was rejected because 0.2.1 is already approved. Downloads retain the working macOS 0.2.0 installer and update feed. Website tests (15), partial-release fallback checks and EN/RO/RU production builds pass.

2026-11-04 — Preparing release 0.2.1: Windows desktop improvements, distinct Explorer actions and dashed drop zones, Store update-check suppression. Release builds, download metadata refresh and Windows Store submission in progress.

2026-11-04 — Windows single-instance audit: normal launches use a per-user, per-session activation broker; later launches forward open, Sign and Verify actions to the primary instance and exit. Existing Windows broker tests passed in the 199-test VM run. Debug preview scenarios deliberately bypass the broker; Store/MSI cross-edition runtime behavior remains unverified.

2026-11-04 — Windows Store update checks: verified that package identity hides the About update button and prevents both automatic and manual feed checks. The button now starts collapsed before Settings initializes. MSIX runtime validation remains blocked by VM sideloading policy.

2026-11-04 — Windows Explorer Sign and Verify use distinct embedded icons in MSI and MSIX; restored dashed outlines to the shared Sign/Verify drop zone. Native Explorer extension, x64 Debug app and MSI rebuilt successfully on the Windows 11 ARM64 VM. Mock app visually confirms dashed borders on Sign and Verify; installed Explorer icon rendering remains to be verified after installing the rebuilt MSI.

2026-11-04 — Installed the current-source x64 validation MSI on the owner's UTM Windows VM (msiexec exit 0, STARTATLOGIN=0). File Explorer now visibly lists Sign with eSemnBun and Verify with eSemnBun under Show more options. Clicking Sign launches the installed Program Files app and queues the chosen mock PDF. Registry commands point to the installed executable. The Store package is retained; MSIX modern-menu runtime remains unverified. Evidence: Desktop/esemnbun-screenshots/windows/2026-11-04/validation/explorer-installed-commands.jpeg.

# eSemnBun (codename MoldSign) — Cross-Platform Development Plan

2026-11-04 — Windows follow-up validation: implemented native standalone jump lists as well as packaged taskbar actions, with Sign/Verify, existing signed outputs, removal handling and an MSI shortcut AppUserModel ID. The native Shell smoke check passed for both tasks and a recent document. Both Explorer COM commands passed title/state/invocation checks and visibly forwarded a demo document into the running app's Sign/Verify pages. All 199 Core/Desktop tests pass. The app, MSI and unsigned MSIX build on the owner's UTM Windows 11 ARM64 VM (x64 app under emulation). Interactive checks cover signed output links/reveal, retained second-card selection, centered Verify area, live Russian switching with Settings retained, dark appearance and About alignment/icon. Testing found and fixed retained About scroll position, tray footer overflow, a truncated Russian card-status caption and light-only verification-result brushes; final focused checks confirm the About title reset and themed verification card. The final tray check confirms the full Russian caption fits and scrolling exposes the browser toggle, Open and Quit actions without cutoff. Details are in `docs/reports/windows-validation-2026-11-04.md`. MSIX installation/runtime validation is blocked by the VM's developer/sideloading policy (0x80073CFF); the original Store package and system policy are unchanged. Evidence is saved under Desktop/esemnbun-screenshots/windows/2026-11-04/validation.

2026-11-04 — Windows validation resumed after disk cleanup: current source (including the single-scroll Sign-page correction) publishes successfully to `C:\esb-validation\app-checked`. About alignment/icon/author/version/site and keyboard reachability of the queued-document list and Sign button were checked in the running app. The original Store package is unchanged. Build logs, the 199-pass TRX and screenshots are now copied to the main Desktop under `esemnbun-screenshots/windows/2026-11-04/validation`. Further interaction was interrupted when the main Mac locked; signing completion/reveal, final language-navigation retest, dark theme, and installed shell integration remain pending.

2026-11-04 — Windows validation on the UTM Store-test VM: installed the x64 .NET 10 SDK in `C:\esbtools\dotnet`, published the modified Debug app successfully to an isolated folder, and compiled the native Explorer extension successfully. All 199 Core/Desktop tests passed, including Sign/Verify single-instance action forwarding. Interactive checks confirmed centered Verify content, both centered card selections, hover arrows outside the card and live Russian labels. Fixed a language-change navigation reset and clamped initial window dimensions to the display work area. Removed nested Sign-page scrolling while finishing small-screen checks. Remaining validation: signed output interactions, About, final language navigation behavior, packaged taskbar and Explorer installation paths; the MSI jump list remains unimplemented. Latest build/test evidence is preserved on the Air at `~/Desktop/esemnbun-windows-validation/2026-11-04/`; main-Mac disk exhaustion interrupted capture until the owner freed space.

2026-11-04 — Additional Windows test target: owner provided the Windows 11 UTM VM `WIN-V0N3TNSH01F` at `192.168.50.235`, with the Store app already installed. RDP port 3389 is reachable and login succeeded through Windows App after owner-approved acceptance of its matching self-signed certificate (permanent trust left disabled). SSH is unavailable. This connection is not validation of the pending source changes; the VM has not received a build containing them.

2026-11-03 — Windows desktop follow-up (in progress): added Sign-page output links, a full-width Verify drop area, higher-resolution and centered About content, more compact card sizing and additional card-status spacing. Added Verify alongside Sign in packaged and MSI Explorer registrations, including forwarding to an already running instance. Language changes rebuild the windows after updating resource language. Added packaged Windows taskbar actions and recent signed outputs. The unpackaged MSI still needs a native desktop jump-list implementation. Windows build and interactive verification of all changes remain outstanding; do not mark this work complete until both distribution types, language switching, Explorer activation and taskbar behavior have been exercised on Windows.

2026-11-03 — Huawei automation validation: workflow run `41720341322` completed successfully, downloaded the latest successful main Android artifact and authenticated with Huawei. It read back `releaseState=4`, `versionCode=1793624669` and correctly skipped the existing submission. Live upload-authorization endpoint also succeeds. The old project service account `119651321` is visibly Disabled; replacement developer account `119651373` is Enabled and its JSON is in GitHub Actions plus the protected Desktop secrets folder. New-binary upload/submission was not repeated while the same build is reviewing. Same-build drafts can be resubmitted after a partial failure; newer or already submitted/live builds are skipped.

2026-11-03 — Huawei publishing automation: added a separate `huawei-appgallery.yml` workflow with manual dispatch and automatic execution after successful main Android builds. It selects the latest successful APK artifact, validates package/version, uploads and submits the existing listing, and skips builds already submitted or superseded. Active reviews are never cancelled. Created developer-level App administrator service account after owner authorization (Huawei rejected project-level access with HTTP 403); saved the JSON in GitHub Actions and owner-only Desktop/eSemnBun-secrets/huawei. Live app-info authentication succeeds and confirms the currently reviewing build 1793624669. Three focused publishing-boundary tests pass. End-to-end new-binary submission remains to be exercised after the current review; workflow validation result recorded subsequently.

2026-11-03 — Huawei Android submission complete: uploaded the newest successful Android GitHub Actions APK from run `41547950405`, commit `15adce05d40d6b31dda5548616e810adfdc5bd02`, version `0.2.0` (`1793624669`). Saved the English listing, icon, four screenshots, phone/tablet support, privacy links and hardware-free demo review instructions. Owner approved the calculated 16+ browser rating and submission. AppGallery Connect app `119651007`, version `2075889243518969152`, visibly confirms **Reviewing** and “Your app is submitted and pending review”; release is set to immediately once approved. API credentials/CI automation remain unprovisioned; this submission used the portal.

2026-11-03 — Windows Store listing: eSemnBun is now live in Microsoft Store (`9PDPR6RNT42S`). Updated every website Windows Store call to action and the Windows installation guide to use the live Moldova storefront URL; landing and downloads now state that the Store edition is available rather than presenting it as pending review/testing.

2026-11-03 — Windows download calls to action: made the Windows-specific homepage actions a vertical stack in the preferred order (Microsoft Store, download options, source) and aligned the Windows download card to lead with the live Store listing before the MSI installer and source link.

2026-11-03 — IOS-STORE-REFRESH-01 composition revision: replaced the over-shrunk whole-scene layout with independently positioned, larger phone/reader artwork and central localized headlines and summaries. Supporting artwork extends beyond the template safe region over a full-bleed tonal background. Preserved the inserted card geometry and sleeved USB connector. Regenerated RO/EN/RU header and search assets. The six localized Header/Search Results assets were uploaded to App Store Connect and each slot reports `1 of 1`; final App Review submission is pending.

2026-11-03 — IOS-STORE-REFRESH-01 typography: refreshed RO/EN/RU creative copy with a two-line benefit headline, larger supporting sentence, short Connect/Choose/Sign steps and signing-key reassurance. Localized headlines fit their deliberate line breaks.

2026-11-03 — IOS-STORE-REFRESH-01 creative correction: physical card height is 98% of the reader, with its entering edge ending inside the housing. Extension cable follows the phone perimeter with a 90 px margin and rounded bends; its female socket fully sleeves the exposed male connector. Regenerated all six localized placements.

> **Living document.** Update it in the same change as the work it describes: tick the box,
> add a line to the [Progress log](#progress-log), and move decisions from *Open* to *Decided*.
> Item IDs (`MAC-04`, `SEC-02`…) are referenced from code as `TODO(MAC-04)`. Use them when
> committing (`git log --grep MAC-04` should tell the story).

Status legend: `[x]` done · `[~]` in progress / partial (implemented, not yet verified on device) · `[ ]` todo · `[-]` dropped (say why)

Last updated: **2026-11-02**

Custom domain deployment (2026-11-02, complete): enabled GitHub Pages with the existing Actions publishing workflow for the private smartcard repository. Website CI builds https://esemnbun.md at /, including canonical URLs and language alternates; standalone update feeds point to /downloads/. Cloudflare has four apex A records, four AAAA records and the www CNAME, all DNS only. GitHub account ownership is TXT-verified; retain the challenge record. GitHub issued the certificate for both names and Enforce HTTPS is enabled. Website run 41415337721 passed build and deployment. Root-domain production build, 13 website tests and SEO checks passed. Independent HTTPS checks from the MacBook Air returned 200 for EN/RO/RU, downloads, support, privacy, terms, sitemap and the macOS update feed; www redirects to the apex. This Mac's company filter returns a separate high-risk block page for the new domain. Repository visibility remains private; published website content is public. Anonymous GitHub installer requests still return 404 and need a separate public distribution decision.

Platform-aware landing downloads (2026-11-02): the landing page now detects the visitor OS without depending on viewport width. iPhone/iPad renders only the App Store badge followed by download options; Android renders only Google Play followed by options; Windows opens the Microsoft Store before the chooser; macOS presents the Mac App Store badge and a separate notarized standalone-download action; Linux presents only its generic Linux download action. Desktop-mode iPad is recognized as iOS. The selector still gives every visitor access to all other platform downloads. Platform detection tests and EN/RO/RU production builds pass.

macOS landing download order (2026-11-02): stack the standalone notarized app, Mac App Store edition and the cross-platform chooser vertically, in that order. The Mac App Store choice now explicitly explains its in-app-browser-only workflow and absence of the reader-insertion helper and MoldSign process controls.

Android landing phone artwork (2026-11-02): replaced the six Android landing states that incorrectly used 2560×1600 tablet captures with native 1080×2400 phone captures for disconnected, reader-connected and card-ready scenes in light and dark appearances. The Android browser path retains the Android handset frame and 9:20 source ratio. Platform-selection tests and all three locale production builds pass.

Linux mascot (2026-11-02): replaced the generic Linux monitor icon with the locally hosted Tux SVG in the shared platform icon component, covering the selector, download menu and desktop-download heading. Preserved mascot proportions and added dark-theme edge contrast. CLI retains its separate terminal icon. Included Larry Ewing/The GIMP attribution, vector source credit and license notice with the asset. All three locale production builds and SEO checks pass; SVG presence and original viewBox verified in each locale. Browser confirms all three Linux images load from the local asset with object-fit contain. Screenshot: Desktop/esemnbun-screenshots/website/2026-11-02/linux-tux.jpg.

Linux download editions (2026-11-02): clarified Linux downloads with separate Desktop app and Command-line app groups in EN/RO/RU. Desktop links select the GNOME DEB/RPM and Flatpak; CLI links select the separate esemnbun-cli DEB/RPM and terminal TAR.GZ archive. Each group has its own setup guide. Replaced the shared Linux terminal icon with a desktop icon and reserved the terminal icon for CLI; filenames are available on hover and architecture labels derive from asset names. Confirmed the published release contains all six packages and packaging manifests distinguish esemnbun-gnome from esemnbun. All three locale builds and SEO checks pass; rendered HTML confirms exactly three correct desktop and three correct CLI assets per locale. Desktop 1280px and mobile 390px layouts verified, including scrolling to CLI downloads with the sticky selector retained and no horizontal overflow. Screenshot: Desktop/esemnbun-screenshots/website/2026-11-02/linux-desktop-cli.jpg.

Sticky downloads selector (2026-11-02): moved the platform navigation outside the introductory header so it remains sticky throughout the downloads content. It sits below the main navbar with a theme-aware surface, keeps every platform visible through wrapping, and measures its height so platform anchor targets remain clear on mobile and in every locale. The main navbar stays visible on this route to avoid overlap when it reappears during upward scrolling. EN/RO/RU production builds and SEO checks pass. Browser verification at 1280px and Russian 390px confirms selector top stays at 80px after choosing Android, section headings remain below it and no horizontal overflow occurs; English Linux selection also verified. Screenshots saved under Desktop/esemnbun-screenshots/website/2026-11-02/downloads-sticky-{desktop,phone}.jpg.

Terms and conditions (2026-11-02): expanded the existing /terms page in English, Romanian and Russian with prominent as-is/as-available and own-risk notices, warranty disclaimers, broad liability exclusions, signing/PIN/file risks and third-party service limits. Preserved MIT permissions and non-excludable statutory rights; renamed the localized footer links to Terms & conditions. Existing /terms URLs remain valid for store listings. All three locale production builds and SEO checks pass; rendered titles, disclaimers and license/support/privacy links verified in each language.

Downloads refresh (2026-11-02): added a shared icon-based split download button and keyboard/touch-accessible platform menu, plus a dedicated /downloads page in Romanian, English and Russian. Platform sections link to actual DMG, MSI, APK, DEB, RPM and Flatpak release assets, store listings and setup/CLI guides. A generated release snapshot supplies installer sizes and links; the Website workflow refreshes it from GitHub's latest published release. Navigation and footer now link to the downloads page. All three locale builds, SEO checks and 13 existing website tests pass; six installer URLs per locale match the current release. Desktop light/dark and Russian phone-width rendering checked without horizontal overflow.

Search visibility (2026-11-02): localized homepage titles, descriptions, visible electronic-ID/MoldSign context and signing questions; an English/Romanian/Russian MoldSign alternative guide linked from home and the docs sidebar; factual SoftwareApplication metadata and social image; generated sitemap discovery and CI verification of rendered SEO fields. All three locale builds and SEO checks pass for both GitHub project Pages and the future esemnbun.md root configuration; 13 existing website tests pass. Public indexing remains blocked by the current GitHub Pages 404 and disabled deployment gate; deployment/Search Console steps are documented in website/README.md.

Documentation refinement (2026-11-02): expanded all five 0.2.0 platform guides with installation, reader setup, signing/output, verification, settings, browser integration, updates, and recovery. Added separate macOS/Linux/Windows CLI guides with reader selection, PIN input, format examples, exit codes, and service setup. Documentation now renders one native screenshot that changes immediately with the site's theme, rather than displaying both themes together. Verified the rendered macOS guide has one image and changes its source light→dark using the appearance control. Production builds for en/ro/ru pass without broken links or anchors; diff whitespace checks pass.

---

## Screenshot/carousel corrective pass — 1 November 2026

The owner rejected earlier clipped carousel/presentation and old-iOS captures. Previous image counts are historical; acceptance requires new current-source evidence.

- [x] SHOT-FIX-01 Desktop carousel uses available content width with margins, selected card centered, no narrow clipped neighbor fragments on macOS/Windows; native wide/narrow interaction checks.
- [x] SHOT-FIX-02 Recapture actual modern iOS Liquid Glass tab bar with current SDK/runtime; add localized compact/expanded iPhone Duo captures with runtime provenance.
- [x] SHOT-FIX-03 Consistent rounded inset UI/logo promotional presentation across Apple/Android/Windows while retaining store-compliant native upload sets and opaque canvases.
- [~] SHOT-FIX-04 Automated capture/build/render/validate entry point, fixtures isolated/no banners, manifests and Desktop delivery regenerated. Windows/Android end-to-end and Apple capture stages pass; unattended Duo Device Hub orientation remains unproven and requires native manual controls. Incorrect orientation is rejected. See docs/reports/store-screenshot-corrections-2026-11-01.md. 2026-11-02: current 0.2.0 platform guides were added under `website/docs/platforms/` for macOS (App Store, GitHub desktop, CLI), iOS, Android, Linux (desktop, CLI), and Windows (desktop, CLI). Banner-free light/dark mock captures were verified for macOS and iOS (Apple Debug driver), Android emulator, Fedora VM, and a fresh Windows x64 Debug build in the active Air VM. The landing sequence now chooses each platform's native light/dark state capture rather than recolouring a single image; source captures are retained in `Desktop/esemnbun-screenshots/docs/2026-11-02`.

Native carousel validation: macOS Sign/Card with the second card selected at requested widths 860/1280 (actual maximum 1126 on the test display) is fully visible and exactly centered in four cases. Windows Sign/Card at widths 900/1382 centers within 0.5 px in four cases, with zero neighboring-card intersection; the viewport grows with window width. Builds pass. Both remote Windows and Android capture drivers completed end-to-end with 48 current-source native images, isolated mock sessions, task cleanup and SHA provenance. The 48 rounded cross-platform promotional images remain separate from native store-upload sets.

Apple sources were recaptured using SDK 27.1: standard iPhone/iPad run iOS 26.5 with actual system Liquid Glass; Duo compact/expanded run iOS 27.1 through the native Device Hub compositor. The revised Apple pack contains 48 official-sized compositions plus 30 supplemental Duo compositions. Rounded inset UI/icons and a three-document Mac batch story replace the rejected artwork. Duo is kept outside official upload slots. Evidence and delivery: Desktop/esemnbun-store-submission/2026-11-01/revision2; desktop geometry evidence: Desktop/esemnbun-screenshots/{macos,windows}/2026-11-01/carousel-width.


## Store submission preparation — 1 November 2026

- [x] STORE-01 Localized RO/EN/RU store metadata, accurate platform features and esemnbun.md support/privacy/terms paths, validated against store field limits.
- [x] STORE-02 Localized store-specific screenshots/promotional packs from fictional actual UI, capture-only demo-banner suppression, validated sizes and source provenance. Normal user demo notices remain.
- [x] STORE-03 Read-only Firefox portal inspection and local submission guide; no agreement acceptance, listing publication or store submission.
- [x] CI-BUILD-01 CI build identity is a positive integer workflow run number; Apple CFBundleVersion and Android versionCode consume it. Marketing version remains x.y.z; MSIX retains mandatory four-part package format. Retries reuse the build number; use a new workflow run before uploading another build.

Delivery: Desktop/esemnbun-store-submission/2026-11-01 includes 96 submission screenshots (48 Apple,12Windows,36Android), localized promotional art/icons, raw provenance and listing metadata. Screenshot dimensions/formats/hash validation, Apple48 slot validation, metadata/localization export checks pass. App Debug builds and Android Release compile pass with capture-only notice suppression; ordinary demo notices retained. Android APK BUILD_NUMBER=731 reported versionCode731; Apple integer validator accepts731/rejects731.2; workflow YAML and shell/Ruby syntax pass. No store upload or agreement acceptance. esemnbun.md paths remain unpublished per owner; Google first-app setup, owner declarations and Microsoft nonzero-first-component package version remain pre-submission gates. See distribution/SUBMISSION-PACK.md and SUBMISSION-METADATA.md.

## Browser usability — 1 November 2026

- [x] WEB-UX-01 Shared official service shortcuts including EVO, per-service icons, compact native navigation controls.
- [x] WEB-UX-02 Confirmed browsing-data reset for cache, cookies and history on macOS, iOS and Android; warn about signout and reset back/forward state.
- [x] WEB-UX-03 Fix real MSign download callback gap with explicit WebKit download API, native attached Save panel and download lifetime management. Live saved PDF matches independently verified portal output.

Validation: official website artwork is bundled locally from recorded source URLs/hashes. Store, Desktop, iOS Simulator and Android Debug builds pass. Native macOS toolbar/service navigation and intrinsic icon sizing passed. Isolated macOS/iOS/Android reset tests confirm Cancel preserves history, history-only preserves cookies/site storage and clears Back/Forward, and full reset removes cookies/site data without reopening MSign. Android cookie counts were 10→10→0. Actual portal Download opened the attached Save sheet; saved PDF matched the independently verified portal output. Final signed Store package and boundary checks passed. Evidence is under Desktop/esemnbun-screenshots/{macos,ios,android}/2026-11-01 and docs/reports/macos-store-live-card-2026-11-01.md.

## Live Store signing acceptance — 1 November 2026

- [x] MAC-LIVE-01 Owner authorized connected-card and known session PIN testing. One worker owns all physical card operations; identify holder before choosing PIN, use stdin/UI only, never retry a failed PIN. Use synthetic documents and validate output; record exact direct/browser and authentication coverage without PINs.

Live results: sandboxed CTK signing with explicitly selected certificate and native consent produced VALID PAdES-B-T with trusted chain. A fresh isolated MSign session uploaded the harmless PDF, signed through the real card and saved the valid result through the app UI. eVMS SAML redirect, MPass ID-card choice and authentication return passed; testing stopped at login and signed out. No PIN errors occurred. No PIN or personal account details are recorded in source or evidence reports.

## macOS Store embedded browser — 1 November 2026

- [x] MAC-WEB-01 Native WKWebView browser with address/history/reload, native uploads/downloads and normal TLS, available in both macOS distributions.
- [x] MAC-WEB-02 Store loopback HTTPS with bundled identity and network server entitlement; data-only route policy preserves origin/consent/PIN checks and rejects filesystem endpoints. Vendor process control and reader helper remain excluded.
- [x] MAC-WEB-03 Sandbox runtime, live portal/localhost WebView requests, both builds and signed Store package validation.

This revision supersedes MAC-DIST-02's initial bridge disablement below: the Store build now intentionally includes the TLS identity and server entitlement, while omitting external helper/process control. Six core tests pass, including simulated data signing, blocked path routes before card/consent IO and denied foreign origins without CORS. Subsequent serialized live-card validation passed as documented under MAC-LIVE-01.

Validation: both Desktop and Store Debug builds pass. The actual sandboxed Store Browser screen loads live MSign and reports bridge enabled. A sandboxed WKWebView loaded the live site and fetched localhost certificates using default TLS/CORS (200); unknown Origin and filesystem signing routes returned 403. Six core tests include simulated authorized data signing and route/origin denials before card IO. The updated universal signed Store package at `dist/macos-app-store/eSemnBun-AppStore.pkg` passes strict codesign, installer signature and revised distribution audit (TLS identity/server entitlement included, watcher absent). Screenshot: Desktop/esemnbun-screenshots/macos/2026-11-01/store-browser/browser.png. Installed app and keychain state restored. Subsequent physical-card MSign signing/download and full eVMS→MPass→authenticated eVMS return passed, followed by signout. Only a synthetic document was signed; no financial action or store upload occurred. See the live-card report.

## macOS distribution variants — 1 November 2026

- [x] MAC-DIST-01 Explicit Desktop and App Store schemes/configurations, preserving the original desktop scheme and its full functionality.
- [x] MAC-DIST-02 Store capability policy retains a data-only browser bridge and CTK signing/verification, PIN management and native export; disables vendor process control and external watcher. See MAC-WEB for the browser revision.
- [x] MAC-DIST-03 Read-only match signing and local Store archive/package export, separate manual CI artifact workflow; no store upload.
- [x] MAC-DIST-04 Validate both variants, Store bundle contents/entitlements and isolated runtime; document supported features and commands.

Validation: both explicit Debug schemes build. The Desktop payload retains localhost.p12 and the reader watcher; Store omits both and the launch agent. An isolated sandboxed Store launch showed only supported settings and no TCP listeners. A universal Apple Distribution archive and signed App Store installer were exported to `dist/macos-app-store/eSemnBun-AppStore.pkg`; strict codesign, sandbox/payload audit and pkg installer-signature checks passed. Match master `eddbafe5f551611b8f039b9c7ee869fa421e1d68` contains the required Store profile and installer signing assets; read-only retrieval passed. New manual workflow packages without upload. No store submission occurred. Physical-card signing and installed Store receipt behavior remain separate device/review acceptance checks.

## Priority: vendor conflicts and sharing — 1 November 2026

- [x] PRIORITY-01 Offer to quit the identified MoldSign vendor application when it occupies the browser bridge ports on macOS, Windows and Linux; retry the bridge after it exits. Do not terminate unrelated port owners.
- [x] PRIORITY-02 Add a Finder Quick Action and Windows Explorer context-menu entry for sending selected documents to eSemnBun for signing.
- [x] PRIORITY-03 Add an iOS/iPadOS share extension for sending documents to eSemnBun. Android already declares SEND and SEND_MULTIPLE; confirm its existing share target and document any remaining gaps.
- [x] Device clarification: USB-C and Lightning adapter use has been tested by the owner. Released apps do not yet support NFC. Physical probe signing is verified; production iOS integration is implemented in the working tree with app acceptance pending (IOS-09).

Completion pass: the iOS extension and App Group are registered and associated. All six development/App Store/ad hoc profiles for app and extension were regenerated and pushed encrypted to match master `61d16296cd9ac4c4d37f7d17ef14cee0c849f6de`; read-only match retrieval passed. `ios_release upload:false` produced signed App Store and ad hoc IPAs in dist/ios. Both app and embedded extension pass strict signature verification and contain the shared group in signed entitlements and embedded profiles. No upload occurred. MSIX Explorer is implemented: x64/ARM64 DLL builds, native COM, registered loose MSIX activation, actual modern menu visibility/invocation, manifest/payload inclusion and packaging-script syntax pass. The command and MSI label use the shared three-language catalog. Full release packaging was not repeated. Windows installer/UI validation passed: a test MSI built from production WiX sources installed its payload, localized MUIVerb and file command, then uninstalled cleanly. The test used separate product/upgrade/install/registry identities and disabled app-closing/PATH actions to preserve the existing installation. Actual Settings Cancel preserved a disposable listener; Close and reconnect stopped it and restored bridge HTTP 200 on isolated test ports. Existing app and VM state were preserved.

These priorities supersede the older NFC research tasks and the untested-adapter statements below. Implementation and verification details will be recorded here as the work progresses.

Current implementation and validation: macOS offers a confirmed quit/retry for port listeners under the installed MoldSign directory. With the real vendor server and an isolated Debug app, Cancel preserved the vendor listener, while confirmation stopped it and restored HTTPS bridge access; an unrelated listener was ignored. The Finder Services action queued a sample file. Sandboxed distribution remains to be tested. Linux identifies the same-user Java vendor server by JAR name and actual socket ownership; Fedora build, unit tests and GTK mock checks verified cancellation, termination/retry and unknown-listener safety. Real Linux vendor installations and Flatpak process visibility need checks. Windows shows port-owner paths and PIDs for explicit user confirmation and revalidates identity before closing. The final WinUI Debug x64 build passed on Windows ARM; a runtime harness detected the existing eSemnBun listener without stopping it, and the same helper on alternate test ports identified and terminated a disposable listener. Same-session activation IPC passed for two paths including spaces and Unicode. Windows confirmation/reconnect UI passed with isolated ports as recorded above. Windows MSI registers a classic Explorer verb; Windows 11 places it under Show more options. A temporary per-user verb and isolated self-contained publish queued one document on launch and a second in the running instance, confirmed in the UI Automation tree. MSIX support and shared-catalog localization are implemented and runtime-verified above; MSI installation/removal validation passed with an isolated package identity as recorded above. Android's system Files share sheet sent one and two sample PDFs to the signing queue on an emulator; a current-source Debug build passed. No physical card or PIN was used in these checks.

iOS/iPadOS share-extension code copies shared files into an App Group inbox for the main app to add to its signing queue. It asks the user to open eSemnBun after sharing. The simulator Debug build passed; an iPhone Files share delivered a byte-identical document into Sign, and an iPad Files share delivered two distinct byte-identical documents into Sign. Signed archive and both distribution exports are verified as recorded above; physical-device installation remains a separate check. See fastlane/SIGNING.md.

## Mobile browser and MPass — 1 November 2026

- [~] MOB-01 Preserve external-browser signing for split-screen use and offer an in-app browser on
  Android and iOS with address and history controls. Request the desktop MPass login so the identity
  card option is available, while retaining the bridge's origin checks and TLS validation. Both
  in-app browsers send a desktop user agent from their first request to preserve SAML POSTs; Android
  signed-in downloads currently direct users to an external browser.
- [~] IOS-06 Bundle the existing localhost TLS identity in iOS and require the HTTPS listener before
  reporting the bridge as ready. iOS Simulator build includes the identity; real-reader signing
  and localhost requests from the embedded WebView remain unverified.
- [~] MOB-02 iPhone simulator redirect to the live MPass login showed the ID-card choice; Android
  core tests and Debug build pass on the Air. Android WebView interaction, actual eVMS SAML return,
  browser signing and physical reader/PIN tests remain unverified.

## Settings, verification and card selection — 1 November 2026

- [~] UI-23 Apply Apple language and theme changes immediately, remove the restart message and the
  redundant General PIN action, and provide a dedicated About surface. The macOS and iOS Debug
  builds pass on the MacBook Air. Known card and signing errors retain localization keys and update
  when displayed; historic activity entries and unexpected system error descriptions remain verbatim.
  Recreating the SwiftUI presentation on language changes needs additional interaction testing.
- [~] UI-24 Show app identity, author, version and website in platform About surfaces; ensure Verify
  offers a document drop target where the platform supports it. Linux About was visually checked;
  Android core tests and Debug app build pass on the Air; tablet drag/drop and the remaining About
  surfaces still need native interaction checks.
- [~] UI-25 Preserve the preferred reader through transient disappearance and place desktop carousel
  arrows outside the selected card at large sizes. Apple policy tests pass on the Air; native UI,
  Windows VM: 193 core tests and WinUI Debug build passed; mock selection and scrolling passed at
  two window sizes in both themes. Fedora: 9 app tests and release build passed; 38 core tests ran
  with 7 network/reference skips. Real-card signing remains to be verified.

## Desktop carousel, browser and insertion helper — 31 October 2026

- [~] MAC-17 Investigate first browser-session crash. The available crash reports are from the
  older installed app and show the previously fixed carousel array-bounds failure. A no-hardware
  browser request from msign.gov.md displayed the macOS consent panel on the Air without a new
  crash; actual card selection, approval and browser signing still need device verification.
- [~] MAC-18 Fix the registered reader watcher exiting with code 2: launchd provides a relative
  executable name, so the helper now locates its process executable using proc_pidpath. An isolated
  mock helper started with relative argv[0] and launched the app on insertion; the updated installed
  launch agent and real physical insertion have not yet been verified.
- [~] UI-22 Add bounded hover arrows on desktop cards and tighter dot indicators, while preserving
  selection and keyboard navigation. Use Linux's portrait geometry on all four platform UIs. Native
  mock hover and next-card interaction were verified on macOS, Windows and Fedora; Debug builds
  passed for macOS, iOS Simulator, Windows, Fedora, Ubuntu and Android. Native hover and next-card
  interaction also passed on Ubuntu; iOS and Android avatar appearance has not been visually checked.

## macOS signing crash — 31 October 2026

- [~] MAC-16 Fix a SwiftUI carousel array-bounds crash when reader/card state changes while signing.
  Pagination now captures stable card values rather than indices into a changing array. Document
  rows also use identity-based format bindings so completed or removed files cannot leave stale
  collection-index bindings in the view hierarchy.
- Mock regression on the MacBook Air reproduced the old crash (`Index out of range`) as the card
  list shrank. The fixed app survived 3→2→1→0→3 transitions, and native demo signing succeeded
  for one document and a two-document batch. The reusable Debug-only regression is
  `apple/scripts/test-macos-card-transitions.sh`. A local universal Release DMG was built and its
  signature and image checksum verified; the archive retains matching debug symbols. Physical-card
  signing has not yet been revalidated.

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
  persistence and exit passed with 28 focused tests. Apple policy tests passed.

## Screenshot review and diagnostics removal — 31 October 2026

- [x] UI-21 Reviewed the latest available screenshots and corrected the demo banner overlap,
  clipped card neighbors, truncated issuer and document names, and inaccessible PIN content.
  Apple, Android, Windows and Linux selectors show a complete centered card with selectable dots.
  Fresh Ubuntu and Fedora builds and mock screenshot matrices (28 each, RO/EN/RU and light/dark)
  passed; selecting another card using the pagination dots was verified on both desktops. macOS
  build and native demo-banner/card-dot interaction passed. Windows UI build and 24 mock screenshots
  passed; wheel, keyboard and pagination-dot card selection and lower controls were checked at two window heights.
  Android phone PIN rotation/cancel, tablet card swipe and 12 tablet keyboard-visible PIN cases
  passed. Added localized accessibility labels and selection state to the Android carousel dots;
  the rebuilt app exposes these in the accessibility tree. On the MacBook Air, the dot tap,
  tablet swipe and focused phone resize with the keyboard visible and Cancel interaction passed.
  An earlier concurrent-startup attempt produced an Android emulator ANR; the isolated retry passed.
  On the MacBook Air, macOS dot selection passed and iPhone, iPad and expanded Duo each passed
  both native carousel tests, including actual swipe gestures and centered-card assertions.
  The expanded Duo PIN field and actions were visible above the keyboard. Air screenshots and
  test results are saved in the Desktop screenshot folders under `2026-10-31/air-review`.
- [x] MON-08 Removed desktop Sentry SDKs, telemetry consent, instrumentation, localization,
  packaging, CI symbol uploads and the GitHub Actions upload secret. Previously submitted reports
  may remain with the provider; the previously created token still needs to be revoked in Sentry.
  Localization export, static project checks and native macOS, Linux and Android builds passed.

- [x] CI-21 Fix the Xcode 16 SDK compilation failure by using the supported scroll behavior on
  older compilers. Local macOS, iOS Simulator and CLI builds pass with Xcode 26; the Xcode 16
  GitHub CI job passed for commit 98885a3.
- [x] CI-22 Fix the Windows activation-pipe startup race by creating the first server before
  returning from Listen. The formerly failing test and all 193 portable tests pass on Windows ARM;
  hosted CI passed all jobs for commit 57e36f6.

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
| Reader I/O | PC/SC via `CPCSC` (proven); TKSmartCard alt | CryptoTokenKit `TKSmartCard`; Core NFC (implemented; app acceptance pending) | USB Host API + own CCID driver; NFC `IsoDep` (research) | WinSCard P/Invoke | pcsc-lite via `CPCSC` (+ `pcscd`, `libccid`) |
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
- [~] MAC-17 First-run onboarding (docs/10 §4.7): localized welcome and aligned startup switches implemented and visually checked; real login-item permission and card-insertion paths remain to be validated.
- [~] MAC-20 **Several cards at once**: per-reader cards with a picker (popover, Sign, Card screens); `/certificates` lists all; the bridge signs with the portal-chosen card; consent for that card. Simulator-tested + live `/certificates` with 2 real cards (both listed, names decoded). GNOME too: `CardSelector` (AdwComboRow / GtkDropDown) on Card + Sign pages, run against both real readers
- [~] MAC-21 **Card removed / reinserted / swapped**: per-reader card generation (TK slot state + `TKSmartCard.valid`), cached certificate dropped and re-read, "Recitește cardul" action; identity guard before every VERIFY (`cardChanged`, PIN never sent to another card). Needs a real swap test on device
- [x] MAC-22 Names with diacritics: decoded `X509Name` for UI, verify reports and `/certificates` ("Ștefan Mîndru", not `M\C3\AEndru`); XAdES issuer keeps the vendor escapes
- [~] MAC-19 Multi-document portal batches: `use_pin_session` / `keep_pin_session=1` honoured in the core bridge (same origin only, memory only, 5 min idle TTL), so one consent + PIN covers the batch; the card still verifies per document. Simulator e2e-tested; live batch retest with 0.1.2 pending
- [ ] MAC-18 App icon + menu-bar template icon artwork

### Phase 2: iOS / iPadOS

Exit criteria: sign a PDF on iPhone over USB-C **and** Lightning adapters; msign.gov.md works in the in-app browser.

- [x] IOS-01 Owner confirms the reader has been tested with USB-C and Lightning adapters; power-budget measurements are not recorded here.
- [ ] IOS-02 `TKSmartCardTransport` on device: full mutual auth + sign; does TK need an explicit reset?
- [~] IOS-03 Connection guide with adapter tiles + live status banner
- [~] IOS-04 Document flow: Files picker, "Open in" (`onOpenURL`), results in Documents (visible in Files) + Share
- [~] IOS-05 Keychain PIN + Face ID (`NSFaceIDUsageDescription` set)
- [~] IOS-06 In-app browser (WKWebView) and bundled HTTPS bridge for MPass and msign.gov.md; device and real-reader verification pending
- [ ] IOS-07 Bridge in Split View / Stage Manager (both apps foreground), documented limits (R-01)
- [ ] IOS-08 Share extension "Semnează" (memory cap, R-06)
- [~] IOS-09 Reopened by owner after verified physical NFC signing (2026-11-16). Reader/NFC choice, shared PIN flow and document-pipeline integration implemented; builds, regression suites and main-app device acceptance pending. See docs/16-ios-nfc.md.
- [~] IOS-10 Packaging: `fastlane ios_release` → one archive, App Store IPA uploaded to TestFlight (no waiting for processing) + ad hoc IPA (match AdHoc), in the `release` workflow; App Store Connect app 6826865290; `scripts/package-ios.sh` stays for unsigned archives. Export compliance: `ITSAppUsesNonExemptEncryption = NO` (owner's call, exempt encryption only). App Store review strategy (vendor TLS key R-02, private API audit) todo

### Phase 3: Android

Exit criteria: sign on a USB-C Android phone; Chrome on the same phone signs through msign.gov.md.

- [x] AND-01 Kotlin port of PAdES, XAdES BES/T/C, TSA/OCSP/CRL (note: plain HTTP, no HSTS), validator, chain certs: `PadesCmsSigner`, `XadesDocumentSigner`, `MdTrustServices`, `Revocation`, `OfflineValidator`, `ChainCerts`. PAdES-T signed with the real card on a phone; XAdES verified with the JDK XML-DSig engine, `Probe3` and the Swift validator, live OCSP/CRL/TSA parsing checked, still to be signed with the real card
- [~] AND-02 CCID driver: IccPowerOn/XfrBlock/GetSlotStatus done; **T=1 block layer for TPDU readers + SetParameters done and verified on the miniLector POCKET EVO** (certificate read on a phone, 2026-10-25); slot-change interrupt, PPS to a faster rate, reset confirmation, PIN + signature on device pending
- [~] AND-03 USB permission flow + `device_filter.xml` (class 11 + VID 0x25DD), VID/PID to verify on hardware
- [~] AND-04 Foreground service bridge: HTTPS :18443 (vendor `localhost.cts.md` identity, loaded from the core jar) + HTTP 127.0.0.1:18480, origin policy + PNA, `GET /certificates` from the wallet, async `POST /sign/data` + long-poll + PIN sessions for PAdES-T (`SigningBridgeRoutes`), verified on a phone with curl and **signed from msign.gov.md in Chrome on the phone (2026-10-25)**. Pending: XAdES for non-PDF content, auto start/stop with the reader. Check `CHANGE_NETWORK_STATE` Play policy
- [x] AND-05 Consent from the background: heads-up notification (full-screen intent where allowed) opens the PIN sheet; unanswered requests are cancelled after 2 min (R-04). Verified on a phone
- [~] AND-06 PinVault wired into local reader/NFC signing, shared certificate accounts, post-success save, biometric reuse and disconnected-card deletion; cross-transport saved-PIN hardware acceptance remains.
- [x] AND-07 Save and share on Android: signed files go to Downloads/eSemnBun through MediaStore (never overwriting; D-06 "next to the original" is impossible with picker URIs); Activity rows have Open / Share / Save as… (system save dialog); share target "Semnează" accepts PDFs and other files from other apps (copied to the cache, cleared at start). Verified on a phone
- [~] AND-08 Chrome Local Network Access prompt (R-05): signing from msign.gov.md in Chrome on the phone works (2026-10-25); `localhost.cts.md` resolves to 127.0.0.1 and the preflight answers `Access-Control-Allow-Private-Network`. Still to document what Chrome shows the first time
- [~] AND-09 Reopened at owner request: Android NFC signing implemented. Physical single-session PAdES-T succeeded; independent signature, tamper-rejection and timestamp-binding checks passed. Additional card/device generations, XAdES over NFC and saved-PIN cross-transport acceptance remain. See docs/17-android-nfc.md.
- [~] AND-10 Packaging: `scripts/package-android.sh` → APK + AAB signed with the upload key (`md.esemnbun.app`, keystore kept by the owner, CI secret `ANDROID_KEYSTORE_BASE64`). R8 shrinking (14 MB APK today), Play App Signing enrolment and listing todo

### Phase 4: Windows

Exit criteria: tray app replaces the vendor suite on Windows 10/11; portal flow works in Edge and Chrome.

- [~] WIN-01 C# PAdES-T/counter-signing, XAdES BES/T/C (SHA-256/SHA-1), TSA/OCSP/CRL and offline validator implemented; vectors and simulated RSA signing tests pass. Windows app built and installed on the owner's PC. **Real-card signing and manual normal-privilege startup deferred by owner; see the Windows device checklist in windows/README.md.** TSA signature/revocation authentication and encrypted/object-stream PDF editing remain unsupported
- [ ] WIN-02 WinSCard transport on hardware (`SCardReconnect` reset, T=1), Microsoft CCID class driver with the miniLector
- [~] WIN-03 Reader hot-plug: WinSCard reader/card events + 2 s poll, per-insertion generations, late reads dropped (Core, unit-tested). TODO: toast notifications, hardware check
- [~] WIN-04 Tray icon + flyout (H.NotifyIcon.WinUI), Mica main window, start at sign-in (MSIX startup task / MSI registry). Windows 10 startup/card-render crash fixed and deployed on the owner's machine (2026-10-25): separate rosette paths instead of transformed ellipses in a GeometryGroup. Single-instance Sign/Verify forwarding, immediate language override, packaged/native taskbar actions and recent signed outputs are implemented (2026-11-04); 199 Core/Desktop tests pass. Final tray caption/footer scrolling and live Russian switching were checked on Windows 11. TODO: first-run TeachingTip; packaged taskbar runtime validation
- [ ] WIN-05 PIN in Credential Locker, gated by Windows Hello
- [~] WIN-06 Kestrel HTTPS 18443 + HTTP 18480, vendor PKCS#12 identity/import, wallet certificate list, queued sign/data, absolute empty 201, long-poll, consent and origin/card-bound batch PIN sessions implemented. TLS/origin/PNA/signing/swap tests pass on Windows; live portal test deferred by owner. Windows Schannel requires UserKeySet rather than EphemeralKeySet
- [~] WIN-07 Explorer Sign/Verify quick actions implemented for MSI classic verbs and MSIX COM commands. Native x64 DLL builds; both COM title/state/invocation checks and forwarding into the running app pass (2026-11-04). MSI installation and classic-menu visibility are verified, and clicking Sign queues the selected file in the installed app (2026-11-04). MSIX modern-menu runtime remains blocked by guest sideloading policy
- [~] WIN-08 MSIX packaging + code signing (thumbprint or Azure Trusted Signing from env; unsigned otherwise) + winget manifest: see WIN-09

- [x] WIN-10 Microsoft Store CI credentials and submission wiring: associated the dedicated `esemnbun.onmicrosoft.com` tenant, created **eSemnBun GitHub Store Publisher** with the approved Manager role, and stored all four `MSSTORE_*` repository secrets. Read-only token/app lookup passed. Release submissions are enabled for version tags, or explicit manual `submit_windows_store=true`, when all credentials exist; build numbers must exceed the last Store package version. Added an independently dispatchable read-only credential check. No new package submission was created during setup; the first automated upload remains unexercised.
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
- [~] WIN-09 Installers (`windows/scripts/package-windows.ps1`, CI job `windows`): `eSemnBun-0.2.0-x64.msi` (WiX v5, per machine, `Program Files\eSemnBun`, CLI at `bin\esemnbun.exe` with only `bin\` on PATH because `esemnbun.exe`/`eSemnBun.exe` collide case-insensitively, optional start at sign-in, in-place upgrades), `eSemnBun-0.2.0-x64.msix` (startup task, identity from env), winget manifests, `SHA256SUMS.txt`. `Package.wxs` compiles and links with WiX on macOS. Current-source x64 Debug MSI and unsigned MSIX builds also pass on Windows 11 ARM64 (2026-11-04); installed package validation remains incomplete because the test MSIX is rejected by guest sideloading policy. TODO: arm64 in CI, LICENSE/homepage in winget
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
| R-03 | NFC is not supported | Out of scope per owner; use a supported reader and adapter. |
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

- 2026-11-05 release delivery: pushed d60d945 as xfreebird <xfreebird@gmail.com> and published v0.2.2 with signed packages. iOS 0.2.2 (200) is WAITING_FOR_REVIEW; macOS 0.2.2 (200) is VALID in TestFlight (existing macOS review unchanged). Windows 1.2.200.0 submission 3 is in certification, with manual publication retained. Play 1793624674 was uploaded through the bundle library only and is inactive; release tracks remain on 1793624673. The initial API artifact commit rejected changesNotSentForReview, so the lane now blocks cancellation of active reviews and recognizes already-uploaded bundles by SHA-256. Huawei 0.2.0 is reviewing; owner explicitly chose to preserve that review and leave the 0.2.2 draft pending. Website EN/RO/RU builds passed; deployed downloads and all three update feeds return 0.2.2. Details: docs/reports/2026-11-05-release-0.2.2.md.

- 2026-11-05 simulator Safari preview: added an opt-in, Debug/simulator-only fixture that shows two DEMO certificate identities and starts a real HTTPS bridge without physical reader monitoring. Server certificate-preview mode permits enumeration/hello/refresh only and rejects all signing routes before consent or hardware access. Preview test passed; iPad HTTPS certificates returned both demo identities with normal TLS verification. iPhone stopped to avoid host-port conflicts; iPad remains in its multitasking layout for Safari checks.

- 2026-11-05 clear/drop follow-up: added clear-results controls on verification screens with stale-work invalidation. Android removal now removes its stored verification result and cancels pending work. Apple Sign/Verify accept file URL and concrete document drag representations, copying provider files before temporary URLs expire. Added Android signing drag reception. Apple policy suite: 24 passed, including two provider-lifetime/multiple-file drag tests. macOS clear verified live; all app builds passed. Launched Pixel Tablet API 36 emulator (esemnbun-tablet, emulator-5556) with current app and 24 files in Downloads/Mac Downloads; updated iPad app installed. Actual inter-app drag gestures remain to be checked.

- 2026-11-05: Extended reader instructions to iPadOS 17+ alongside iOS 17+, with Lightning/USB-C adapter guidance and external power generally unnecessary, in Romanian, English and Russian. Prepared an iPad simulator with the app and Downloads sample documents.

- 2026-11-05: Updated iOS reader guidance in Romanian, English and Russian: any iPhone running iOS 17+, Lightning-to-USB-A or USB-C-to-USB-A adapters, external power generally unnecessary. Removed the iPhone 15+ restriction and powered-camera-adapter recommendation.

- 2026-11-05: Apple verification document headers place the validation icon beside the filename in one row, retaining the readable verdict and signature count underneath the filename.

- 2026-11-05 signature author display: verification headings expose author, signature label, subject IDNP and formatted signing time. Distinguished-name attributes render individually rather than as an opaque issuer string; the issuer organization identifier is never used as personal IDNP. Apple disclosure headings are full-width buttons. Corrected metadata fingerprints to hash only the leaf DER and parsed extension URLs from ASN.1 boundaries. About is fixed-size with Close as its only enabled window control; Help opens https://esemnbun.md/docs/start/. Live macOS UI checks passed; signed macOS/iOS, Android, Windows and Fedora builds passed. Certificate metadata regression tests: 3 passed locally; Windows: 200 passed; Fedora: 41 executed, 7 skipped, no failures.

- 2026-11-05 signed-result actions: successful signing rows are whole-row native actions. macOS groups filename and Show in Finder under one hoverable button (App Store export retained in the context menu); iOS shares from the whole row; Linux action rows reveal their file; Windows stretches filename and Show in Explorer across a single button; Android retains every completed output and opens it from a full-width card.

- 2026-11-05 follow-up: Apple verification results now group filename, verdict and signatures in one document card; new verification selections replace the prior batch (also Android/Linux). Sign and Verify share the Apple drop-zone implementation and scroll layout, eliminating Form clipping of iOS dashed corners. CardSelector uses a fixed card snapshot throughout local signing. Signed macOS and iOS builds passed; live macOS verification checked two PDFs then replacement with one PDF, and iOS screenshot confirmed rounded dashed corners. Apple policy tests: 22 passed. Real-card multi-document signing has not been repeated.

- 2026-11-05: Implemented certificate detail disclosures in Apple, Android, Windows and Linux verification screens (PDF and XAdES); readable verification dates; multiple-document verification; continuation after document failures with per-file errors and no retry buttons; card state preservation during signing; dashed signing/verification drop zones; content-sized Windows tray flyout. Added batch continuation regression coverage. Card/PIN failures still stop the batch. Validation: Android debug/core tests, Apple app policy tests, iOS/macOS builds, Fedora GNOME build/core tests and Windows build/core tests; real-card signing and full UI workflows remain unverified.

- 2026-11-05 validation: current working tree builds on Windows 11 ARM64 VM (x64 WinUI), Fedora VM (Swift GNOME), local Android debug, and iOS simulator. Windows core: 199 passed; Fedora core: 38 executed, 7 skipped, 0 failures; Android core: 117 executed, 1 skipped, 0 failures. iOS verification view compilation was repaired. iOS and Android launch screenshots show remaining drop-zone inconsistencies; full document workflows and real-card batch signing are not yet validated.

- 2026-11-05: Began cross-platform signing and verification improvements: Apple signing rows no longer offer per-file retry or duplicate their error in the result area; the shared Apple signing drop zone uses a dashed outline. Remaining cross-platform work is pending.


- 2026-11-01: Mobile browser and MPass desktop login follow-up (MOB-01–02, IOS-06).

- 2026-11-01: Settings, About, Verify, reader selection and desktop carousel follow-up (UI-23–25); Apple builds and policy tests passed on the MacBook Air.

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

## Store draft uploads — 1 November 2026

- [~] IOS-STORE-REFRESH-01: Replace the cropped shared Header/Search Results artwork with six placement-specific localized compositions (21:9 Header, 3:2 Search Results), remove recursive reader-help content, and keep queued-document add/drop actions visibly active. Add iCloud key-value bookmark synchronization between the iPhone/iPad and Mac apps, then upload and submit the next iOS Store build after validation. Completed: iOS 0.2.1 build 111 is selected for review; Romanian, English, and Russian iPhone/iPad screenshots and all six Header/Search placements are attached, each reporting `1 of 1`. 2026-11-03: the creative composer now keeps its app, reader and card focal points in the central safe field rather than the lower/right crop boundary; its physical scene keeps the reader's USB-C plug, a short female extension, and the iPhone bottom port visibly joined, with the lead behind the device frame and clear of the display/card. The card's entering edge is layered below the reader so it reads as inserted, not as an unrelated background object. Consent/PIN sheets disclose exact document count and available request size, and compact queued-document actions clip content to continuous rounded corners. App Review submission is the only remaining step.
- [x] AND-UI-PARITY-01: Match the queued-document affordance and reader/card placeholders to the refreshed Apple treatment: an added-document picker stays visibly active, and passive reader/card placeholders use solid rather than erased-looking dashed outlines. Android's reader guide is already non-recursive. Android bookmark records remain private preferences because iCloud key-value synchronization is Apple-only; cross-platform automatic bookmark sync requires an account-backed service and is intentionally not implied.

- [x] STORE-UPLOAD-01 Apple build 100 VALID and attached to iOS/iPadOS and sandboxed macOS 0.2.0 drafts. RO/EN/RU metadata and 30 iPhone/iPad screenshots plus 24 Mac screenshots (including primary en-GB copies) processed COMPLETE. Owner-provided review contact saved; no review submission or release.
- [x] STORE-UPLOAD-02 Updated Windows x64 MSIX 1.2.100.0 marked Validated; marketing 0.2.0 retained. Listing import Complete, saved export verifies three localized descriptions, first-release notes and 12 screenshot URLs. Restricted runFullTrust still requires review approval; no certification submission.
- [x] STORE-UPLOAD-03 Google app 4973211912255144827 created after explicit owner approval of the three required declarations. Signed AAB 100 accepted; internal draft and RO/EN/RU first-release notes saved. All three localized listings saved with icon, localized feature graphics and 36 phone/tablet screenshots. No rollout. Production requires the account’s 12-tester/14-day closed-test gate.

Current source CI passed before dispatch. New iOS and Android Release workflows and the macOS Store package workflow use integer build 100. Reserved esemnbun.md pages remain placeholders until published; actual portal processing and outstanding declarations will be recorded after uploads.

- [x] STORE-NOTES-01 First-release notes authored in the shared RO/EN/RU catalog and exported for every store. Google internal draft uses compact first-release summaries; Apple omits What’s New for initial releases.

Store upload evidence: docs/reports/store-uploads-2026-11-01.md and Desktop/esemnbun-store-submission/2026-11-01/upload. All upload build workflows and the initial upload-tooling CI passed. The package-version upgrade mapping was subsequently corrected for future marketing 1.x releases; CI for that follow-up is checked separately. Submission gates remain: publish reserved website pages, complete privacy/content/review questionnaires, and meet Google closed-testing requirements. No public release or certification submission performed.

- [x] STORE-COPY-01 Every generated store description is validated to mention only its target platform; the iOS listing covers iPhone/iPad together. Windows/Huawei JSON exports omit the shared catalog's other-platform notes. Live Apple descriptions (all seven locale/platform combinations) and the saved Windows export (RO/EN/RU) pass the same platform-name audit. Android's three uploaded descriptions were prepared from the validated Android exports.

- [x] STORE-EXPORT-01 Owner-declared exempt encryption is the default on iOS/iPadOS and macOS: ITSAppUsesNonExemptEncryption=false in both app plists and the share extension; macOS packaging verifies the flag. App Store Connect build 100 read-back confirms usesNonExemptEncryption=false for both apps (iOS already false; macOS changed from unset). All plists lint, shell syntax and the uploaded iOS IPA's flag pass. No replacement upload is required for the existing server-side declaration.

- [x] STORE-DUO-01 Corrected the earlier supplemental-only classification: App Store Connect has a dedicated APP_IPHONE_DUO slot. Rendered five compact (1398×2034) and five expanded (2853×2007) images per locale; all 30 uploaded and read back COMPLETE in story order. The nine iOS/iPadOS screenshot sets contain 60 COMPLETE images in total. Standard iPhone images now include a device bezel and camera cutout; native screen content is retained. All 78 Apple exports pass exact-dimension/RGB validation.
- [x] STORE-CREATIVE-01 Header/Search Results artwork: show the actual slim white bit4id reader/adapter connected to an iPhone signing documents. Owner photos are hardware references only; public artwork must contain only fictional identity details. Universal opaque 5244×2950 exports validated for RO/EN/RU. All three images processed PREPARE_FOR_SUBMISSION and six Header/Search Results placements read back ACTIVE. Artwork corrections hide the physical chip under the reader, straighten the card and correct the USB-C connector/cable. Export/upload automation reuses matching images and stops before replacing different artwork; no review submission performed.

- [x] STORE-FRAME-02 Replace generic iPhone hardware outlines with Apple's original licensed PNG frames for iPhone 17 Pro Max and Duo outer/inner displays. Owner explicitly authorized the Design Resources License. Exact native openings and source PNG checksums are enforced; original Apple hardware is composited without modification. Regenerated all 78 Apple exports; selectively replaced 45 iPhone/Duo images and preserved the 15 iPad images. Final API read-back verifies all nine iOS sets (60 images) COMPLETE, correctly ordered and matching local source-file checksums. No review submission.

- [x] STORE-CREATIVE-02 Header/Search Results now combine keyed RO/EN/RU marketing copy (brand, headline, PDF/XAdES/batch/verification features, three usage steps and key-privacy line) with exact native batch-screen pixels and an IDCardFace crop. The official Apple frame, empty reader cutout and orthographic constant-width cable form the usage illustration; the cable exits straight downward before curving right, and physical chip occlusion is enforced. All three 5244×2950 RGB exports are uploaded; six draft placements read back ACTIVE. The screenshot pipeline regenerates the compositions and provenance. Replacement uploads preserve prior library images and handle unique reference names, pagination, empty DELETE responses and rollback on failed replacement creation. No review submission.

- 2026-11-01: Added MIT project license, updated Linux license metadata and started a public-facing README refresh. macOS demonstration recording and full release artifact refresh remain outstanding.

- 2026-11-01: Captured banner-free native macOS walkthrough from freshly compiled commit 4c77c10 using isolated no-hardware fixtures; embedded it in README. Full release build 101: run 41329713694; Mac App Store package 101: run 41329717584 succeeded. Final asset verification pending.
- 2026-11-01: Release refresh complete. All six platform jobs and publisher passed in run 41329713694 (source 4c77c10, build 101); separate Mac App Store package run 41329717584 passed and its package was added to v0.2.0. All 15 installer hashes match GitHub asset digests and SHA256SUMS.txt. Subsequent source changes contain README/media/progress only. README animation verified as four 980×752 frames at 3 seconds each, captured from freshly compiled source with banner-free isolated fixtures.

- 2026-11-01: Replaced the README animation with a static banner-free macOS screenshot from the same freshly compiled capture; removed the unused GIF.
- 2026-11-01: Replaced README pointer-highlight capture with the cursor-free native macOS store capture (English sign screen), visually checked for no cursor or demo banner.

- 2026-11-01: Fixed tray-only Settings presentation by activating the app before requesting the SwiftUI scene and deferring the request until the activation-policy transition completes. Both desktop Debug and isolated QA builds passed; diff whitespace check passed. Exact tray-only runtime validation remains pending because the UI automation attachment reopens the main window.
- 2026-11-01: Added macOS TestFlight upload to the store packaging lane and a dedicated Apple TestFlight workflow for iOS/macOS/both. Restricted public releases to DMG/APK/MSI and Linux packages; obsolete store-upload assets are removed before checksums. Building macOS Settings fix for store and desktop distribution.
- 2026-11-01: macOS store build 102 uploaded to TestFlight successfully (run 41331692589), processed VALID and selected/read back on the 0.2.0 PREPARE_FOR_SUBMISSION version. Desktop DMG build 102 published (run 41331696079). Release now contains nine installable packages plus SHA256SUMS; all nine hashes verified. IPA/AAB/MSIX/PKG/macOS CLI tarball removed from public assets. No review submission initiated.
- 2026-11-01: Added dedicated Android build/optional Play internal-draft upload and Windows installer build actions with explicit integer build numbers. Existing Windows certification submission is not modified. Play API secret and Partner Center credentials are absent; Windows store upload remains deferred until certification completes and API access is configured. Workflow validation and CI build checks in progress.
- 2026-11-01: Dedicated Android build 103 (41332185728) and Windows build 103 (41332188789) both passed and uploaded nonempty CI artifacts. Workflow YAML parsed, Fastlane syntax and diff whitespace checks passed. Google Play draft upload remains untested until its service-account secret is configured; Windows store mutation is intentionally absent during certification. Added build badges and automation documentation.

- 2026-11-01: Created dedicated Play upload service account in eSemnBun Play Uploads Cloud project, enabled Android Publisher API, saved owner-only JSON in offline secrets/google and configured GOOGLE_PLAY_SERVICE_ACCOUNT_JSON in GitHub Actions. Play account is Active with md.esemnbun.app-only read/testing-track release permissions. API authentication/edit access and track listing verified; temporary edit deleted without committing changes. No production access or rollout.
- 2026-11-02: Android release CI now runs automatically for Android/release changes merged to main and from release builds. It uploads each newly signed AAB to the internal testing track, then stages the exact version code on the configured closed-testing track (default Play alpha). The app is still a Play Console draft, so Google rejects a completed closed-track release; CI therefore defaults that second release to `draft` until `PLAY_CLOSED_RELEASE_STATUS=completed` is explicitly configured after Play permits availability. Both Android workflows serialize on one `android-play-vc-*` tag-backed counter, reserve/increment the next code by exactly one before building, and retain an auditable reservation even when a build fails. The first two timestamp codes were already accepted by Play and cannot be rolled back, so the counter starts above the highest accepted code. CI never targets production. Fastlane/YAML validation remains required before the first live publish.
- 2026-11-01: Created Docusaurus website under website/, compiling to website/pages/. Added setup/signing/browser/troubleshooting docs and public /support, /privacy, /terms pages. Landing copy focuses on notarized macOS installation without workarounds and mobile signing; responsive native screenshots, hover/touch download menu, and shared-coordinate device/cable/reader signing sequence. System fonts, no analytics. Local production build passes. GitHub Pages enable attempt returned HTTP 422 (private repository plan); owner chose to keep repository private and enable after upgrading. Deployment is gated by ENABLE_PAGES_DEPLOYMENT=true; build artifacts remain available meanwhile. Store URLs are prepared, not changed to unreachable Pages routes.
- 2026-11-01: Revised website direction to practical installation/mobile signing benefits; removed decorative arrow copy. Device outlines use fixed, documented proportions and native screenshot ratios, with contained desktop app windows and port-aligned cable paths in one SVG coordinate space. Disconnected captures appear before stage 3; card details only appear after connection. Made four-stage progress prominent and reduced scroll length to 290vh desktop / 260vh mobile. Eight static routes and production build verified, plus desktop/mobile browser checks and download menu interaction. Pages publishing remains gated pending the owner's GitHub plan upgrade.
- 2026-11-01: Enlarged the opening desktop app capture, added a Verify-tab selection/highlight at stage 2, and enlarged the inserted fictional ID while preserving its aspect ratio and hiding its chip behind the reader. Added EN/RO/RU Docusaurus locale builds, 45 complete keyed landing/interaction messages, translated navigation/docs/support/privacy/usage pages, a language menu, and first-visit browser-locale detection respecting explicit localized links. All 24 content routes built; four locale-negotiation cases passed. Romanian landing and tab-switch interaction verified in Firefox after the in-app browser connection became unavailable.
- 2026-11-01: Corrected website output ignore rule to /pages/ so src/pages is tracked. Clean archived-source build passed for EN/RO/RU; GitHub Website build 41338425921 passed and saved its Pages artifact. Deployment correctly skipped pending plan upgrade.
- 2026-11-01: Replaced stepped website scene with requestAnimationFrame-driven continuous scroll geometry. Desktop aperture starts at 100vw, shrinks to 75vw at viewport center, then retains width while frame/reader/card motions overlap without idle timeline intervals. Reader connects before the card inserts; app details reveal only after insertion. Physical card height is exactly 98% of reader insertion height, aspect preserved and chip occluded. Added timeline/reveal/ratio tests to Website CI. EN/RO/RU production builds and tests pass; opening/connection phases checked in Firefox (final capture attempt hit automation timeout).

- 2026-11-01: Refined responsive website story: mobile sequence is shortened to 230svh; both layouts open at 140vw, low in the viewport, then continuously recede into view. The connected iPhone uses matching light-mode native capture. Desktop rig scales to viewport height during reader connection so the screen and hardware remain visible. Increased navigation/body/supporting text to 16–18px, rounded the logo, added official App Store and localized Google Play badges on mobile with availability labels, and fit all four progress labels on narrow phones. Added a distinct native reader-connected/no-card capture for all five platform illustrations, including a fresh isolated iOS 27 capture. Reader connection precedes insertion; on mobile the reader slides right and its cable endpoint follows, keeping the approaching ID within the scene. Four timeline, insertion-proportion, desktop-fit and mobile-card-bounds checks pass; EN/RO/RU production build passes. Desktop and 390px mobile connection/insertion phases checked in Firefox; later preview control was interrupted. The task-owned iOS simulator was shut down.

- 2026-11-01: Mobile story timeline now starts during section entrance, once more than 10% of the enlarged screenshot is visible. Its normalization includes that entrance distance, spreading the zoom-out across scrolling before the section reaches the viewport top. Resize recalculates progress immediately. Added iPhone/Android entrance-threshold and completion coverage across three phone sizes.
- 2026-11-01: Enlarged final portrait mobile screen to 85vw, constrained only by short viewport height. Reader and ID now overlap the lower phone area instead of reducing the whole rig; reduced physical reader geometry retains the 98% card-insertion ratio and keeps the approaching card within side margins. Cable attachment follows the relocated reader. Added final screen-width and projected card-bounds coverage.
- 2026-11-01: Six website animation/geometry checks pass and EN/RO/RU production builds pass. The enlarged mobile scene, reader-only screen and lower hardware overlay were visually checked at 390×650 in Firefox.
- 2026-11-01: Replaced all three macOS website story images with native captures from a fresh build, using one normal window (Sign), identical 2704×1696 dimensions, English/light appearance and Contract.pdf throughout. Removed the mismatched preview-window capture and aligned the card/document column across transitions. Windows ready state now matches its Romanian title and 1100×720 capture geometry. Added a reusable isolated macOS story capture script, provenance manifest and CI asset integrity/alignment check.
- 2026-11-01: Fresh macOS Debug build and isolated native capture completed successfully. Visually checked the disconnected, reader-only and inserted-card website sequence in Firefox: title, sidebar and document column stay aligned. All seven website checks, capture-script syntax and EN/RO/RU production builds pass.
- 2026-11-01: Mobile story now measures the live dynamic viewport, removes the inherited 680px minimum that clipped shorter browsers, and centers the phone in the available height. Reader/adapter stays fixed from connection through insertion, without the previous leftward overshoot/rightward correction. Replaced boxed progress steps with a compact translucent capsule, current-stage icon/label and four continuous segments. Site navigation hides on scroll and stays hidden during the pinned story, with keyboard focus and reduced-motion handling preserved.
- 2026-11-01: Eight geometry/asset checks and all EN/RO/RU builds pass. Visually verified the 390×650 browser view uses the full height, keeps the compact progress capsule inside the viewport and hides the site menu during the story; restored Firefox's normal viewport and prior tab after verification.

- 2026-11-01: Shared the entrance-aware 10%-visible scroll timeline between desktop and mobile, preventing desktop zoom from waiting until the section reaches the viewport top. Hid the redundant Docusaurus desktop docs-sidebar logo while preserving header spacing. Added explicit iPhone/iPad/Android mobile signing copy below the workaround heading in EN/RO/RU, and added desktop entrance regression coverage.
- 2026-11-01: Verified one visible docs brand in Firefox, the desktop screenshot already shrinking before its section reaches the viewport top, and the new Romanian mobile-app paragraph. Nine checks and EN/RO/RU production builds pass. Keyboard-only navbar reveal now uses focus-visible so clicking the home logo does not keep the menu visible during scrolling.

- 2026-11-01: Added a localized debug platform selector on the website landing page for Automatic, macOS, Windows, Linux, iPhone and Android. Overrides switch native screenshots, frame and scroll geometry together, persist per tab and remain available while navigation is hidden. Enabled only in development or on loopback production previews; public production hosts ignore stored overrides. Thirteen checks and EN/RO/RU production builds pass without compiler warnings. Verified Windows and iPhone frame/screenshot switching and reload persistence in Firefox; restored Automatic after testing.

- 2026-11-01: Added website dark mode with first-visit system preference and the native Docusaurus light/dark/system toggle, including persistent choice across routes, reloads and locales. Added shared light/dark palette tokens for landing copy, surfaces, download menu, mobile badges captions, signing progress/result, visible cable/frame and debug controls; documentation uses the same theme. Romanian and Russian theme-control labels are translated. All 13 existing checks and EN/RO/RU production builds pass without warnings. Nine foreground/background text combinations per palette pass WCAG AA (minimum 4.85:1 light, 5.43:1 dark); the download button is 5.79:1. Visually verified dark landing/menu/story/docs, mobile navigation and Romanian landing at 390×650, plus persisted theme after navigation/reload. Restored system preference, normal viewport and prior browser tab.

- 2026-11-01 (in progress): Desktop reliability and parity follow-up: bring existing main/Settings/About windows forward; unify the three About entry points; retain failed signing rows with explicit per-document retry across Apple/Android/Windows/Linux; translate card surname/given-name labels; recover automatically after vendor port conflicts; add weekly/manual standalone-desktop update checks and website JSON channel; opt-in vendor Desktop client compatibility with consent retained. Store binaries exclude the standalone updater. Validation/results recorded below when complete.
- 2026-11-01: Implemented the reliability follow-up. macOS explicit Open/Settings/About requests now unhide and activate the app, restore minimized windows and raise the registered target after the tray closes; the app menu, tray About and Settings About share AboutContent, with a larger resizable standalone About window. Apple and Android card field labels now use keyed translations (certificate identity values remain untouched; Windows/Linux already translated these labels). All four app families keep failed documents in the queue with inline errors and an explicit one-file retry; completed documents are removed, and successful results remain available during retries. Bridge conflict recovery retries automatically on standalone desktop platforms; macOS additionally offers the validated vendor-only quit action directly in the tray during a conflict.
- 2026-11-01: Added manual and seven-day automatic standalone macOS/Windows/Linux update checks, strict stable-version/HTTPS-domain validation and platform JSON manifests under website/static/updates. The Website workflow regenerates feeds from the latest published GitHub release and runs after Release; deployment remains subject to the existing Pages plan/domain setup. macOS Store binaries exclude the updater; Windows packaged apps hide/disable it. Added an opt-in MoldSign Desktop signing-server compatibility setting to standalone desktop hosts, preserving consent, origin restrictions and certificate-bound batch credentials. Protocol evidence/scope: docs/reports/moldsign-desktop-compatibility.md.
- 2026-11-01: Validation: Apple standalone macOS, App Store macOS and generic iOS Simulator builds pass; 15 Apple policy tests pass, including update version/URL validation. Store binary inspection confirms no update-feed URL. Fresh isolated macOS UI shows translated Russian labels, retained failed row and working mock retry; Settings and the app-menu About display the shared author/icon/version/site content. Screenshot: Desktop/esemnbun-screenshots/macos/2026-11-01/reliability/failed-row-ru.jpg. Exact tray activation while covered by another application still needs a manual check (native automation interrupted that path). Android debug build/unit tests/lint pass (2 tests); no attached Android runtime was available. Windows VM ARM64 build passes with 0 warnings/errors and 197 Core tests pass. Native Fedora GTK build and 13 tests pass; live disposable-listener port recovery passed in 2.6 seconds. Swift bridge suites pass 14 tests each on native and portable listeners, including unmodified installed vendor Java client classes signing through the simulated CosmoX card; no physical-card/PIN attempts. Website's 13 checks, EN/RO/RU production builds and localization export check pass. Vendor compatibility covers signing, not encryption/deletion/signature management; Windows filesystem verification and XAdES countersigning remain unsupported as documented.
- 2026-11-01: Linux About and the updater resolve the installed AppStream marketing version; packaging synchronizes the staged metadata with MOLDSIGN_VERSION and validates x.y.z overrides. Script syntax and replacement preserving older release entries pass. A complete package rebuild was not repeated for this metadata-only adjustment.

- 2026-11-02: Replaced Romanian “sursă deschisă” with “codul sursă deschis” throughout the website documentation, terms, landing copy and footer (six occurrences). JSON parsing and whitespace checks pass; no old wording remains in website source.

- 2026-11-01: Removed the MCabinet and Public Services browser shortcuts in the shared portal specification and regenerated Apple/Android defaults (MSign, EVO, eVMS, MPay). Added persistent bookmark management to macOS, iPhone/iPad and Android: add/edit/remove titles, HTTP(S) URLs and six native icon choices, including removal of built-ins. Original website icons remain on built-ins until changed. Explicit empty lists survive restarts; cache/cookie/history reset is independent of bookmarks. Added RO/EN/RU labels and URL validation rejecting non-web schemes and credentials. Apple editor scrolls with compact layouts/keyboard and keeps save controls outside its scrolling content.
- 2026-11-01: Bookmark validation: latest standalone macOS, App Store macOS and iOS Simulator builds pass. Apple policy suite passes 17 tests (including bookmark validation/edit/remove/empty persistence). Android debug build, 5 unit tests and lint pass; Android runtime unavailable (no attached devices). Native macOS QA verified four-item menu, custom add/edit/delete, saved Star icon, restart persistence and unsafe-URL save rejection in an isolated preferences domain with hardware disabled. Editor screenshot: Desktop/esemnbun-screenshots/macos/2026-11-01/bookmarks/editor.jpg. Shared portal exports/localization drift checks and git diff check pass. Test app terminated after verification; installed app and real cards were not used.

- 2026-11-02: Fixed standalone macOS vendor-server quit reliability. Replaced the best-effort GUI quit request with SIGTERM for validated current-user MoldSign port listeners, fingerprinted by executable path and process creation time. The operation waits for listener release, reports failure on timeout, never escalates to SIGKILL and never signals a replacement PID. Tray and Settings use the same background operation, disable duplicate quit requests, show progress and reconnect only after successful shutdown. Added three shutdown-policy tests (20 Apple policy tests pass overall). The old GUI request was observed to stop the installed server from a standalone probe, but the in-app action did not complete reliably; the replacement avoids that GUI/Apple Events dependency. Owner stopped both applications during runtime validation; respected that state and did not restart either afterwards. Full end-to-end retest of the new action against the installed server remains unperformed. Final signed desktop and Store compile results recorded in the build logs under /tmp/esemnbun-{macos,macos-store}-shutdown-build.log.

- 2026-11-03: Created the eSemnBun Android (`119651007`, `md.esemnbun.app`) and iOS (`101653523127320907`, `md.esemnbun.ios`) AppGallery Connect records after owner confirmation. The Android AAB and RO/EN/RU listing material are ready locally; no package upload, release, review submission, API client or CI secret has been created. Huawei’s Connect Publishing API can automate Android package upload and release after an app-scoped API client is created and granted access; iOS registration is for Huawei service integration, not iOS marketplace distribution. Store metadata now lists only the current MSign, EVO, eVMS and MPay default shortcuts.

- 2026-11-04: Refreshed Apple signing profiles in encrypted match storage without revoking certificates: Developer ID for the standalone macOS app, the invalid Mac App Store profile, and App Store/development/ad hoc profiles for both iOS targets. Both main App IDs already had iCloud enabled; the refreshed profiles authorize the shared `H86U5Z8HYB.md.esemnbun.bookmarks` entitlement, and iOS App Groups remain intact. The desktop signing lane now installs its iCloud provisioning profile read-only; packaging selects it only on the macOS app target. Signed universal macOS 0.2.1 build 114 Desktop and Store archives pass signature, distribution-boundary and entitlement/profile checks. The 0.2.1 DMG is notarized (Accepted `5502faa8-7494-4900-bebb-cdd2608b4281`), stapled, Gatekeeper-accepted and attached to the existing v0.2.1 release. Fixed the Mac TestFlight lane to select the macOS bundle identifier explicitly rather than inheriting the iOS Appfile default. No marketing version or App Review submission was changed; iOS's previous upload failure was an already-approved-version rejection, not a signing failure.
- 2026-11-04: Uploaded macOS 0.2.1 build 114 to TestFlight (`md.esemnbun.mac`, App Store Connect build `f52e9850-8400-410b-afff-47c90adb07c2`); Apple processing is `VALID` with `usesNonExemptEncryption=false`. Existing macOS 0.2.0 submission remains `WAITING_FOR_REVIEW` with build 102 selected. No App Review submission or selected-build change was made.
- 2026-11-04: Google Play rejection remediation (non-government route): Android now shows a localized independence disclosure on first launch/upgrade, with permanent Browser/About access and official MSign, MPass, EVO, eVMS and MPay links. RO/EN/RU Android listings lead with the non-affiliation statement and official sources. Play publishing supports opt-in localized metadata upload (current credential lacks store-presence commit permission, so listing updates were saved in Firefox); Russian export uses the live Play locale ru-RU. Validation/build and closed-testing submission tracked below.
- 2026-11-04: Android policy remediation delivered as commit 5edfce2; signed CI build 41884731637 produced 0.2.1 (1793624673). Local debug build, 5 app unit tests, lint (0 errors), localization/metadata checks passed. CI's listing commit hit permission denied; exact signed CI bundle was uploaded with existing testing permissions, and all three descriptions saved in Firefox and verified against repository copy via API. Alpha now contains only the new build with RO/EN/RU policy release notes. Sent 18 pending changes for review; Console confirms Changes in review with quick checks running. Google approval remains pending. Publishing lane keeps metadata opt-in because the current credential cannot commit store-presence changes; no access grants were changed.

- 2026-11-05: Added branded adaptive iPhone/iPad launch storyboard. macOS explicitly presents the main scene on first launch; Windows and Linux already override background startup on first run.
- 2026-11-05: Published rebuilt 0.2.2 macOS DMG (build 201); refreshed website release metadata. iOS 0.2.2 build 201 validated and resubmitted, WAITING_FOR_REVIEW (fe81fcd7-e479-4c10-8b1a-cbabddf24e6b). Apple upload run 42041104516 also builds macOS TestFlight 201.

- 2026-11-05: Added repo skills for developer environment discovery, platform builds/signing, UI automation/screenshots, and release/store/website operations; added developer onboarding and ignored per-developer host/device inventory example. Scoped Air/QEMU recipes to the owner profile and corrected stale Windows Store automation guidance. Documentation/skill validation only; no production operations or application builds required.

- 2026-11-05: Updated iOS launch screen to full-bleed brand-blue gradient with unplated signature mark and white title, removing the rounded icon tile; reproducible assets use the shared brand generator.

- 2026-11-05: Fixed missing launch images by packaging explicit PNG launch resources; recorded simulator cold launch and visually confirmed the signature logo, white title and full-bleed gradient.

- 2026-11-05: Matched Android launch artwork to iOS (blue gradient, white unplated logo/title). Android 12+ retains the required solid system starting window and renders matching artwork in its exit transition; older versions use the gradient launch drawable.

- Android launch validation: `:app:assembleDebug` passed. Runtime visual check not completed: mock AVD lacks config.ini; validation AVD startup fails its host free-disk-space check. Existing emulator data preserved. Launch assets regenerate with `python3 scripts/make-launch-assets.py`.

- 2026-11-05: Preparing iOS 0.2.2 build 202 resubmission and Android artifact-only upload for the corrected gradient/logo launch screens; includes developer onboarding and repo skills.

- 2026-11-05: Pushed launch-screen/onboarding changes as 79d27e5 (xfreebird@gmail.com). iOS 0.2.2 build 202 VALID and resubmitted, WAITING_FOR_REVIEW (daf81477-5574-4798-9054-61821652cfdd), Apple run 42054163277 succeeded. Android run 42054171484 built signed artifacts but API commit failed with HALTED release must have fraction; uploaded its AAB via Play Console, versionCode 1793624675 confirmed Inactive, old 0.2.1 review preserved.

- 2026-11-05: Refactored downloads into a JSON-driven six-card grid with localized platform requirements, official store badges, explicit per-installer versions/architecture/size and guide links. Removed source/release download cards; made Tux monochrome. Release generation preserves platform configuration and missing package/architecture downloads. Static JSON/resource/JSX checks performed; website build and browser visual validation left for developer verification.

- 2026-11-05: Restored the JSON-driven download platform selector with persistent selected/hash highlighting. Platform sections now span the content width, with store badges and installers in horizontal rows that wrap on narrow screens.

- 2026-11-05: Restored two-column download platform grid with equal-width option cells, including store badges. Download-page navigation scrolls away so the platform selector sticks flush to the viewport top without the hidden-navbar gap.

- 2026-11-05: Moved store badges into the platform heading row; standalone installers now stack vertically at full card width, retaining the two-column platform grid and flush-top selector.

- 2026-11-05: Highlighted the selected download platform card with an accent border and subtle theme-aware tint, synchronized with selector clicks and URL hashes.

- 2026-11-05: Added localized recommended-device pages with Apple and Amazon adapter links, connection paths and conditional power guidance. Clarified the incompatible connector direction of Apple USB-C-to-Lightning plus USB-C-to-USB-A adapters; no unverified chain advertised as supported. Linked from navigation, footer, downloads and setup.

- 2026-11-05: Redesigned device recommendations with locally hosted Apple/Anker product photos, responsive product cards, connector paths and a labelled native demo screenshot. Added the requested iPhone/iPad compile-from-source alternative to the JSON download catalog.

- 2026-11-05: Added localized Windows MSI self-signing and installation-permission notice to the JSON-driven downloads card.

- 2026-11-05: Platform card clicks and keyboard activation now synchronize the floating selector, card highlight and URL hash without interrupting nested download/store links.

- 2026-11-05: Added verified Moldovan retailer listings for Apple USB-C adapter and alternative USB-C OTG adapters. No local Lightning camera adapter listing was verified.

- 2026-11-05: Added Romanian retailer links for Apple USB-C and Lightning camera adapters and a UGREEN USB-C OTG option; availability remains subject to retailer stock.

- 2026-11-05: Removed duplicate selected-card border and kept a single accessible focus outline.

- 2026-11-05: Kept selected-card border dimensions stable, expanded badge links across their heading area, and made card text show the selection cursor.

- 2026-11-05: Reconciled shared localization catalog with current native strings, localized remaining Apple verification/help labels, and preserved platform-specific Apple release notes in catalog-backed exports. All three shared-localization CI checks pass locally; application builds not run.

- 2026-11-05: Updated Website actions to Node 24-based releases (checkout/setup-node v6, Pages upload/deploy v5), resolving action-runtime deprecation warnings while retaining website Node 22.

- 2026-11-05: Localized Apple/Microsoft badges with official Romanian/Russian artwork and shared manifest selection on homepage/downloads; Google Play already has localized images. Romanian macOS uses the Romanian App Store badge because the Mac-specific endpoint returns English.

- 2026-11-05: Styled the standalone macOS DMG with a Finder background and app-to-Applications arrow, Finder icon positions, and a mounted-volume icon matching the eSemnBun app icon. Created and mounted `dist/macos/eSemnBun-0.2.2-custom.dmg` from the installed signed 0.2.2 build; the package script syntax and whitespace checks pass. A full archive/release package build was not run.

- 2026-11-05: Matched Firefox installer dimensions (680×425, 128-point icons), reduced the arrow, added the app-label pill and blank Applications shortcut name, and created a branded card-reader volume icon. Mounted the revised local 0.2.2 DMG; confirmed the ICNS file survives compression.

- 2026-11-05: Release CI now installs pinned dmgbuild tooling and writes the branded DMG layout without Finder automation. A local package using the same settings passed mounted-image checks for the volume icon, blank Applications symlink, icon size and positions. Full archive/sign/notarize CI has not been dispatched.

- 2026-11-06: Published branded macOS 0.2.2 build 202 via Release run 42120435210. Developer ID signing, notarization and stapling succeeded; downloaded DMG matches SHA256SUMS (5e942ae70a01eae3ed87c121cb705233a3e2c7478d9015ee18c78a112be0266c), and stapler validation passed. Refreshed download metadata.

- 2026-11-06: Continued first-run onboarding across macOS, Linux and Windows. The localized welcome explains signing, verification and browser services; existing startup and card-detection preferences are presented without resetting them. Linux avoids duplicate dialogs and reflects login permission results; Windows prevents concurrent preference changes while registration is pending. Localization export consistency and diff whitespace checks pass; native builds, first-launch UI and OS permission paths remain to be validated.

- 2026-11-06: Refined desktop first-run onboarding with aligned macOS switches and Windows choice cards, dark appearance, localized wrapping, and clear installer/policy startup status. Fresh MSI installs now default to no machine-wide startup; previous installer settings remain preserved. macOS Desktop and Store Debug, Fedora ARM64 Debug, Windows x64 Debug and a Windows Debug MSI built. Visual checks covered EN/RO/RU across desktop platforms and dark mode; Fedora onboarding persistence test and Windows isolated first/subsequent launch check passed. The MSI startup default was inspected as 0; fresh MSI/MSIX installation and OS login/card-detection permission paths were not exercised.
- 2026-11-06: Moved iOS browser navigation controls above the tab bar and kept WebKit URL/history state synchronized. iPhone simulator Debug build showed the controls unobstructed in portrait and landscape; Back and Forward moved between MSign and eSemnBun, and Share opened the system sheet for the current URL. No card, PIN, or real signing was used.

- 2026-11-06: Prepared 0.2.3 for desktop distribution and store builds, with separate desktop release selection to avoid duplicate mobile uploads.

- 2026-11-06: Released desktop 0.2.3 from 7a02b3a; Windows MSIX 1.2.203.0 entered certification, iOS build 203 was submitted for review, macOS build 203 uploaded to TestFlight, and Android bundle 1793624676 was uploaded to the Play library without changing tracks. Refreshed release downloads and update manifests.

- 2026-11-06: Corrected the macOS installer background bookmark using Foundation. Finder displayed the background and arrow in a mounted test image; release packaging uses the same native bookmark generation.

- 2026-11-06: Android 0.2.4 (1793624677) promoted to closed testing Alpha at owner request, with localized release notes. Play accepted full rollout; Console shows changes in review / quick checks, managed publishing off. Availability awaits Google approval. See `docs/reports/release-0.2.4-2026-11-06.md`.

- 2026-11-07: Exported all twelve UX, Duo, security and integration task reports to individual PDFs and a local ZIP. The 55-page combined volume includes the existing 13-page screenshot review, clickable contents and report bookmarks. Rendered pages were visually reviewed; all 427 source content blocks were verified present, with no out-of-page text, footer overlap or broken report links. This documentation export ran no new application builds/tests and published no release. See `docs/reports/complete-task-reports-2026-11-07.pdf` and `docs/reports/task-reports-2026-11-07.zip`.

- 2026-11-07: Began recommendation implementation: independent migrated signed-document libraries and read-only Verify-style document modals across Apple/Android/Windows/Linux; history clear no longer clears Documents. Added authenticated foreground iOS Open Documents/Verify PDF shortcuts, localized macOS Verify Finder Service, native preview/PDF sharing, startup status refresh, and metadata-only CLI capabilities JSON. Hardened Apple/Linux GUI detached reads. Added focused library/CLI regression sources; localization, syntax, plist/XML/JSON and whitespace checks pass. No native builds/tests/runtime checks were run in this pass. Apple missing-XML-companion presentation, structured CLI verification, MCP/broker and newest Siri schema integration remain follow-up work. See `docs/reports/recommendations-implementation-2026-11-07.md`.

- 2026-11-07: Completed the next native validation pass on the main Mac and Air Fedora/Windows guests. Swift core65 (5 opt-in skips), Apple policy30, Android core123 (1 live-TSA skip) + PIN-binding1, Fedora18 and Windows CLI10 all passed;11 Swift CLI process checks passed. Native iOS Debug/unsigned Release, signed macOS desktop/AppStore Debug, Android, Fedora and Windows builds passed. Exercised independent Documents persistence, fresh modals, native XML original selection, native preview/share cancellation and upgrade migration. Fixed iOS container-relative saved paths, incomplete-original/trust copy, Android modal/error handling, Linux row activation/verdict metadata and Windows modal lifecycle/theme/resource keys. Added Swift offline verify --json with sanitized output and contained reads. Physical-card, live OS-authentication/Siri and other coverage limits are explicit in docs/reports/validation-next-2026-11-07.md; sanitized screenshots and PDF accompany it. No release/push/store action.

- 2026-11-07: Completed the fresh screenshot review matrix on both Macs: 3,572 native PNGs (iOS/iPad/Duo 1,124; Android 1,720; macOS 324; Windows 212; Linux 192), light/dark, phone/tablet/native Android fold surfaces and desktop window forms. Phone/tablet portrait and both landscape directions are covered; Duo is default portrait only because native posture/rotation control could not be validated, and 20 width-inapplicable Android menu combinations are documented. Added guarded Debug capture routes, opt-in screenshot tests, synchronized native keyboard capture and reliable readiness/window framing; no production layout fixes were made during this review pass. Native builds/capture batches passed; accepted-image hashes, geometry, exact manifests, PDF IDs/bookmarks/text bounds, gallery filters and ZIP CRC all pass. Five PDF books, a filterable offline gallery, original PNG ZIP and linked findings are in `docs/reports/screenshots-review-2026-11-07/` and `docs/reports/screenshots-review-2026-11-07.zip`. Task simulators/emulators were cleaned up and existing user devices/VMs preserved. No real PIN, physical signing, push or release action was used; observed layout issues are retained for the owner's review.
- 2026-11-07: Addressed all 14 findings from the screenshot review in a focused UI pass. Apple: compact landscape Sign/Verify/Card layouts, keyboard-accessible PIN entry with wrapping preferences and preserved document-review input, native PDFKit PDF preview on iOS/Duo with independent scoped access and unavailable-file handling, and content-sized macOS details sheets. Android: width-gated panes/readable result headings, full-height landscape stamp preview, wrapping Card actions, and short-window navigation/chooser access. Linux: compact accessible output actions; Windows: theme-bound stamp surfaces and hidden empty certificate properties. Certificate labels now use catalog-backed Romanian/English/Russian presentation mappings on every platform while preserving certificate data and validator keys. Native Debug builds passed on all platforms; Linux 18 tests and Windows six focused tests passed, with Apple UI capture/input-preservation tests and Android picker/navigation/scroll/output-opening interaction evidence. Original screenshot matrix preserved; focused before/after report and PNGs are under docs/reports/ui-fixes-2026-11-07. Duo validation remains default portrait only; Android fold evidence uses equivalent geometry, and one recovered emulator ANR has undetermined cause. No real PIN, physical signing, release, push or publishing was performed.

- 2026-11-07: Android splash uses dedicated 288dp density assets rendered from the brand SVG, avoiding 2.67x enlargement of the adaptive launcher foreground. Debug APK builds and packages all five densities. Android card faces already cap at 420/480dp. Fresh 36-image RO/EN/RU phone/tablet store capture and clean cold-start splash proof passed visual review after reclaiming old task build caches. See `docs/reports/android-splash-store-refresh-2026-11-07.md`.

- 2026-11-07: Bounded Apple empty/populated identity-card faces to natural responsive sizes (400pt large/phone; 288pt compact), and stabilized the macOS title/toolbar with an explicit compact unified style plus an inaccessible, invisible height reservation. iOS Simulator and signed macOS Debug builds passed; native light/dark captures verified identical toolbar height with and without actions and centered bounded card faces. See `docs/reports/store-refresh-2026-11-07/apple-layout.md`.

- 2026-11-07: Captured and audited 30 fresh native Duo store screenshots in Romanian/English/Russian: compact1398×2034 and expanded2853×2007, five stories each. Native Device Hub posture and screenshot controls used; original task simulator name/posture restored and device shut down. Source manifests/hashes and contact sheets are under `docs/reports/store-refresh-2026-11-07/`.

- 2026-11-07: Recreated and visually checked the store review pack after toolbar/card/splash corrections:78 Apple screenshots including30 native folded/expanded Duo,36 Android compositions,12 native Windows screenshots,6 Apple featured assets and133-page PDF. Native captures and five focused validation images accompany the pack; geometry/format/localization/metadata checks pass. Uploaded251 PNGs plus PDF/manifest/readme to xfreebird@gmail.com Drive with336/336 items confirmed. Windows capture driver absent-task handling fixed. Older temporary validation artifacts preserved on Air to recover main-Mac space; repository reports unchanged. No store submission, release, commit or push. See docs/reports/store-refresh-2026-11-07/README.md and drive-upload.json.

- 2026-11-07: Revised six Apple featured artworks: corrected native card crop, doubled card height, aligned reader, preserved original revision; exported RO/EN/RU header/search images and review PDF.

- 2026-11-07: Apple featured artwork v3 scales the physical reader with the enlarged card, restores insertion proportions, and realigns the cable; six localized exports and review PDF.

- 2026-11-07: Apple featured artwork v4 aligns title, supporting copy, and brand block with the card left edge; six localized exports and review PDF.

- 2026-11-07: Apple featured artwork v5 balances phone position and headline weight while preserving card-left alignment and hardware proportions; six localized exports and review PDF.

- 2026-11-07: Preparing 0.2.5 release (Apple/Windows build 205) with adaptive UI, independent Documents history, PIN/bridge hardening, approved store artwork, and accessible scroll transitions. Website tests (15), three-locale build, SEO and metadata/localization checks passed. Store submissions tracked separately from public availability.

- 2026-11-07 release follow-up: CI confirmed the older SDK toolbar fallback. Flatpak packaging now includes pinned Poppler GLib/data dependencies required by the PDF editor; focused packaging rerun pending.
- 2026-11-07 release follow-up: Flatpak retry succeeded and refreshed the 0.2.5 release checksums and website downloads. Apple iOS and macOS build 205, with verified localized screenshots, are waiting for review under manual release. The certified Microsoft 0.2.4 update was published manually in Firefox; its 0.2.5 replacement MSIX and artwork are in certification with manual publication retained. Google Play Alpha 0.2.5 and all nine localized screenshot sets are in review. Huawei still has its older build in active review, so its 0.2.5 draft is pending. See `docs/reports/release-0.2.5-2026-11-07.pdf`.
- 2026-11-07 release and CI follow-up: At the owner's request, canceled Huawei's 0.2.0 review and submitted signed 0.2.5 APK `1793624678`; Huawei API confirms reviewing. Google Play API confirms the same code is completed on the Alpha closed-testing track, subject to Play review. Release and Android push workflows now package by default, with Play and Microsoft submission opt-in; a reserved Android code can be reused only for the same commit. Huawei draft workflow requires an explicit packaged main run, defers during active review, and tolerates Huawei upload receipts without a filename. Latest main CI before these changes was green. See `docs/reports/store-submissions-ci-2026-11-07.md`.

- 2026-11-07 automation implementation: added shared Apple Verify/Open/Prepare Shortcuts, current OS 27 Siri system Open/Search schemas, guarded signed-file entities, opt-in Spotlight/onscreen metadata and navigation-only Handoff. New schemas are confirmed in generated App Intents metadata; desktop macOS, iOS simulator and sandboxed AppStore builds pass. Added native macOS/Linux stdio MCP with current and legacy protocol adapters, bounded root-scoped offline verification, an opt-in macOS foreground PDF approval broker, and explicit unattended signing with certificate SHA-256 pinning and environment/Keychain/1Password credential references. Unattended signing uses exclusive card access and a durable failure marker surviving host restart; no PIN retry/reset tool. Windows CLI MCP and unattended backend pass 24 focused VM tests; managed self-contained publishing passes with Native AOT analyzers, and modern/legacy real-process checks pass with raw UTF-8 filenames. Native AOT linking/MakeAppx remain unvalidated because the VM lacks MSVC/Windows SDK. Standalone macOS/Linux packaging includes MCP; Microsoft Store packaging adds CLI payload/console alias, with standalone CLI fallback for the current Mac App Store sandbox model. Apple CI/release jobs now pin Xcode 27 and preflight schema SDK support. macOS full Swift88 (5 skips), Fedora52 (7 skips), modern/legacy stdio checks, focused credential/gate tests and localization checks pass. No physical PIN/card, store submission or release publication. Details: docs/reports/automation-integration-2026-11-07.md and spec/mcp.md; live Siri/Handoff/Spotlight, credential-provider authorization and installed signed packaging remain explicit validation limits.
- 2026-11-08 release preparation: owner authorized publishing 0.2.6 and replacing pending reviews. Updated platform marketing versions and localized per-platform release notes; preserve prior screenshots/listings. Initial live state: iOS 0.2.5 is available, macOS 0.2.5 waits for review, Huawei 1793624678 is reviewing, Microsoft has no pending submission. Replacement reviews will be canceled only after replacement artifacts are ready. CAPTCHA challenges require a human; API/session paths remain preferred.
- 2026-11-08 packaging follow-up: corrected lipo input ordering for the embedded universal MCP helper after the signed release job exposed its variadic architecture parsing. Apple Store upload jobs succeeded; standalone macOS packaging will be retried with the corrected check.
- 2026-11-08 store packaging follow-up: declare multiple-instance support required by the packaged console alias; reserve Android version tags through the refs API to avoid annotated-tag workflow-permission rejection when main advances during a queued build. iOS and macOS 0.2.6 build 206 are waiting for App Review.
- 2026-11-08 release delivery: 0.2.6 public installers and CLI archives published with all 11 hashes verified. Apple iOS/macOS build 206 replacements are waiting for review; Play Alpha 1793624681 is committed; Microsoft 1.2.206.0 is in certification with no reported errors. Huawei remains on its existing review because browser verification did not complete and a service-account withdrawal route was unavailable. Full seven-job CI passed on e2330c3; signed/notarized macOS packaging passed after selecting Xcode's architecture tool. Updated website download data/feeds and release guidance. See docs/reports/release-0.2.6-2026-11-08.md.
- 2026-11-08 CLI package distribution: reuse the existing homebrew-utils repository for the macOS formula and Windows Scoop bucket; create a standalone Windows CLI ZIP and Chocolatey package; add signed APT/RPM feeds plus an Arch recipe. Package workflows validate artifact digests, signatures and package installation without hardware/PIN access. Dedicated package signing key is stored outside Git and in the repository Actions secret. Published 0.2.6 packages at https://esemnbun.md/packages/. APT and Chocolatey installation checks passed; public Homebrew, Scoop and Fedora/DNF install checks passed. Anonymous artifact digests and APT/RPM signatures verified. Full seven-job CI passed on b73b298. Partial releases retain the last complete package feed and two prior CLI download versions. Chocolatey community publishing and AUR submission remain separate; the Arch recipe has not been runtime-tested. See docs/reports/cli-package-distribution-2026-11-08.md.

- 2026-11-08 landing scroll clarity: replace translucent full-screen crossfades with one decoded native capture at a time, shared fixed screen bounds and aspect-preserving containment. This avoids doubled text/window edges, keeps capture origins aligned, and stops desktop screenshots being cropped to the monitor ratio. Reader/card movement remains continuous; reduced-motion still shows the final state. Desktop and iPhone preview states reviewed in Edge, including reverse scrolling and light/dark appearance. Added a capture-canvas regression check for all five platforms and both themes. Website tests, production build, SEO checks and Pages deployment passed (run 42455716763). Public landing HTML verified to render one contained screenshot with no crossfade layers.

- 2026-11-08 package download navigation: moved Homebrew, Scoop, Chocolatey, signed APT/RPM and Arch/archive instructions into the main Downloads page with the shared navigation, localized copy and collapsible copyable commands. Legacy /packages/ links redirect to /downloads/#cli; package-feed and binary URLs remain stable. Package version comes from the last complete package release, independently of app releases.

- 2026-11-08 download artifact clarity: label macOS TAR.GZ and Windows CLI ZIP as command-line/MCP tools for terminal and agent integrations, explicitly distinguishing them from the desktop app. Label DMG and MSI as desktop app installation options with short installation guidance in English, Romanian and Russian.

- 2026-11-08 platform-first downloads: group every installation method under macOS, Windows, iPhone/iPad, Android or Linux. Move Homebrew/Scoop/Chocolatey/APT/RPM/Arch instructions into their platform cards, merge Linux CLI artifacts into Linux, and remove separate CLI/package-manager navigation. Preserve artifact-purpose labels and map legacy CLI anchors to platform sections.

- 2026-11-08 illustrated user documentation: audited current features and journeys before parallel platform authoring; expanding Mac, iPhone, iPad, Android phone/tablet, Linux desktop and macOS/Linux/Windows CLI guides in English, Romanian and Russian. Native localized captures use isolated fictional data without the demo banner. Added numbered screenshot overlays, matching accessible steps, enlarged/actual-size image viewing and automated guide/asset coverage checks. Documentation explicitly separates platform capabilities and unverified hardware/system integrations. Completed 27 localized guides with 483 numbered panels, 411 native PNGs and 63 labelled terminal illustrations. All guide/asset checks, 16 website tests, the three-locale production build and SEO checks passed; desktop/400px browser review verified image enlargement and corrected tablet callouts. Three design findings were corrected and rechecked. Publication uses the Website workflow.

- 2026-11-08 documentation publication follow-up: all 27 live guide pages and 27 sample image hashes verified after deployment. Windows CI passed 228 tests and native CLI compilation, then a transient GitHub compiler-archive timeout failed packaging. Added three bounded download attempts with incremental backoff; the pinned SHA-256 check remains mandatory before extraction. Windows PowerShell parsing passed; the download remains subject to the existing package checks in CI.

- 2026-11-08 CI follow-up: Windows packaging passes with bounded compiler-download retries. A subsequent Android job hit an upstream Kotlin compiler download timeout. Added Gradle dependency caching and a three-attempt wrapper that retries only dependency-resolution transport/HTTP failures, immediately preserving compiler/test failures and checking pipeline logging errors. Release APK/AAB packaging uses the same wrapper; its Play upload remains outside retries. Five focused retry probes and shell/workflow syntax checks passed. CLI guides now show the exact SHA-256 calculation for certificate pinning and space short terminal rows to keep phone callouts separate.

- 2026-11-08 documentation callout correction: replaced opaque badges over app controls with reserved outside gutters and thin outline pointers across all 483 illustrated panels, all platforms and languages. Label packing preserves original step numbers, separates clustered labels, and follows the measured image geometry in fit and actual-size views. Geometry checks cover every panel at phone/desktop/native widths; desktop and 320px browser review confirmed unobstructed controls and CLI commands. No native screenshot pixels changed.

- 2026-11-08: Reorganized illustrated guides into 30 localized device/interface overviews and 222 focused task pages. Added searchable task directories, device-scoped sidebar/pagination, localized navigation and redirects for existing section bookmarks. Preserved all 483 illustrated panels and capture provenance; Windows desktop remains an explicitly historical reference.

- 2026-11-08: Replaced the legacy Windows desktop illustration with 42 native localized 0.2.6 captures, 45 numbered desktop panels and 3 new MCP-verification panels. Added a dedicated saved-documents task and enforced numbered illustrations on every Windows desktop/CLI task. Captures use isolated fictional data; no real signing/PIN/Windows Hello authorization was exercised.


- 2026-11-08: Localized visible PDF stamp wording and native previews in Romanian, English and Russian across Apple, Android, Windows and Linux; placement preserves the chosen app language. Android General settings now offer persisted per-app language (including pre-Android-13 support), System/Light/Dark theme, browser stamps and selected-card PIN removal. Added opt-in Windows/Linux MCP foreground approval spools with immutable PDF review, selected-certificate checks, fresh consent/PIN, cancellation, five-minute expiry and private output handling. Windows stdio now reads cancellation concurrently with serial work, bounds pending requests and terminates timed-out operations safely. Linux unattended configuration additionally accepts an operator-provisioned Secret Service reference. Added focused core/spool/session/request tests and updated localized guide text plus MCP/stamp contracts. Localization generation/check, Swift syntax parsing, XML parsing and whitespace review passed. Per owner instructions, builds, tests, device UI, installed/store/Flatpak packaging, secret-provider unlock and real-card validation were not run; these are implementation changes, not a released build. Windows broker retention cleanup currently requires the broker to remain enabled.


- 2026-11-08 screenshot refresh: captured and visually reviewed 54 fresh native screenshots across macOS, iPhone, iPad, Android phone/tablet, Windows and Linux in English/Romanian/Russian, with fictional data and no demo banner. Updated numbered targets and split Windows/Linux foreground MCP setup into dedicated task pages; documentation now has 231 task pages and 546 panels. Current iOS simulator, macOS, Android, Fedora GNOME and Windows Debug builds passed; the refresh fixed a Linux Swift type-check timeout and a Windows unpackaged stamp-editor locale API crash. All 19 website tests, guide/asset checks, localization checks, three-language production build and SEO checks passed. Native captures illustrate settings/stamp UI only; real signing, credential unlock and MCP approval are not exercised. Preserved an older task cache on Air with checksum verification before removing its local copy; removed only reversible project build/dependency caches to recover space.

- 2026-11-08 Windows MCP CI follow-up: corrected child-file atomic publication sharing while retaining directory delete/rename denial, and assigned current-user ownership plus a protected owner-only ACL when creating new files under elevated Windows tokens. All 18 WindowsMcp tests passed on the native Windows VM, including ACL rejection, junction/root-rename confinement, immutable requests and atomic replacement. Website deployment passed and all 264 published guide routes plus 54 screenshot hashes matched local assets.

- 2026-11-08 Android closed testing: submitted signed 0.2.6 build 1793624684 from successful Android CI to Alpha with EN/RO/RU feature notes. Upload key and exact AAB SHA-256 matched; Play validation/commit and independent post-commit track/hash verification passed. Production/beta/internal tracks remained unchanged. Play Console shows Changes in review with quick checks running and Start full rollout for the new Alpha release; approval/tester availability pending. See `docs/reports/android-closed-release-2026-11-08.md`.

- 2026-11-08 Actions optimization: added conservative changed-platform CI routing, a stable aggregate, cancellation of superseded validation and secret-free unsigned Windows CI; consolidated Android version reservation; added exact-artifact Play upload/closed-track publication with review preservation, idempotence and result checkpoints; selected-only Apple runner matrix, explicit macOS build numbers, opt-in Release TestFlight, dependency caches and bounded timeouts. Added canonical workflow/recovery/credential inventory, CI skill, and synchronized project/release/build guidance. Validation and hosted-CI evidence are recorded after checks; no store mutation is part of this automation change.
- Local automation validation: 26 routing/version-reservation/workflow-contract/publisher tests passed, official actionlint 1.7.12 passed with the declared Xcode runner label, Ruby and shell syntax passed, generated localization/store metadata remained current, and new guide/skill links resolved. Publishing tests use fake APIs and do not contact stores.
- Hosted validation for `a7d4fc9`: full changed-platform CI run 42514123629 passed all native/localization jobs and `CI result`; signed Android build 42514123650 and Website 42514123661 passed. New store publishing workflows were not dispatched. The following documentation-only change exercises the no-native-build route.

- 2026-11-08 agent integrations: added a discoverable MCP setup guide for ten widely used products/surfaces (Claude Code/Desktop, Codex, Cursor, Copilot in VS Code, Gemini CLI, Windsurf/Cascade, Cline, Roo Code, OpenCode), with current official sources and explicit protocol/local-device limits. Added a portable document verification/signing skill, Claude Code local plugin and client-native skill/rule/workflow/instruction adapters, exported for macOS/Linux/Windows in a deterministic public ZIP. The path-customization exporter requires a new directory, preserves personal configuration and never enables unattended signing or embeds PINs. Linked from Downloads, protocol/docs indexes and all nine localized CLI guides. Seven focused exporter tests, skill validation, all 19 existing website tests, guide generation/asset checks (231 tasks, 546 panels), MDX compilation on Air and whitespace checks passed. Full website/native builds, live connections to all ten clients, marketplace publication, credential access and physical-card signing were not run; this is an integration/documentation pack, not proof of released client compatibility.

- Agent-doc publishing follow-up: the production build caught Docusaurus rewriting a root-relative static Markdown link as a docs route. Changed both MCP reference links to their absolute public download URL; deployment is revalidated before reporting publication.

- 2026-11-08 MCP setup configurator: added interactive agent/platform/signing-mode selection to the agent guide, editable executable/input/broker paths, certificate-pinned unattended provider references, client-specific JSON/TOML and tailored numbered setup steps. Users can copy/download the configuration, installation guide and native skill/rule/workflow; processing stays in page memory and never accepts a PIN. The browser client catalog/skill is generated from the existing export source. Added six focused checks including all 30 exporter/browser configurations and 90 guide combinations; all 25 website tests passed. Native Edge interaction confirmed Windows approval/unattended generation, incomplete-certificate validation and a 320px responsive layout. No native card operation or credential provider was exercised.

- 2026-11-09 appearance/About fixes: Android now observes explicit language/theme state at the Compose root, supplies locale-scoped resources to the visible destination, resolves activities through wrapped dialog contexts and refreshes locale-dependent date formatting. Settings/About uses a bounded scrollable body so long government notices and legal links remain reachable. Added localized Legal information, Terms & Conditions, Privacy Policy, disclaimer summary and website links to Android, iPhone/iPad, macOS, Windows and Linux About surfaces. Native exports are catalog-first and matched before editing. Static localization/XML/Swift syntax and whitespace checks are recorded below; native builds, tests and device interaction remain for the owner under the standing build rule. These changes are not submitted to stores.

- 2026-11-09 Siri/Shortcuts investigation: inspected the exact App Store-uploaded 0.2.6 (206) IPA from Actions artifact 13605239258. Its autoShortcuts metadata includes the provider and all three Open Documents / Prepare Signing / Verify PDF definitions. The shipped EN/RO/RU AppShortcuts tables omit Prepare Signing; the catalog lived only in the iOS target. Completed that phrase in all three languages, moved the catalog into shared Apple resources and added macOS startup parameter refresh. Static phrase coverage, catalog drift, Swift parsing and whitespace checks passed. Missing App Shortcuts UI on the user’s phone remains unconfirmed at runtime; the package metadata rules out a missing provider, and the localization defect is not proven to be the sole cause. Changes remain local, with no new build/store submission.

- 2026-11-09 Siri PDF selection: built-in Verify PDF and Prepare Signing App Shortcuts now use separate foreground intents without file parameters. They retain cold-launch navigation, select the matching screen and present a single-PDF native file importer rather than asking Siri to resolve an IntentFile from a spoken filename. Selection uses the existing verification/import workflow; dismissal does not start work and preparation does not sign. Existing file-taking intents and typed verification results remain unchanged for custom Shortcuts pipelines. Added localized picker-action names/descriptions. Swift syntax parsing, complete catalog export checks, phrase coverage and whitespace checks passed; native builds, generated metadata extraction and Siri/file-provider UI validation are not run under the owner build rule.

- 2026-11-09 complete Siri file-input audit: both reusable file-taking actions now accept an optional IntentFile. Without supplied input they await the same single-PDF native picker; with input they preserve direct processing and the verification outcome type. A single-owner selection continuation handles cancellation, replacement and five-minute expiry; late picker results after cancellation/expiry cannot start verification/import. Generation tracking prevents superseded verification results replacing a newer request. Open Signed Document remains a constrained saved-library entity selection, while search/open-library actions require no external file. Added descriptions explaining the picker fallback. Static Swift parsing/catalog checks passed; native metadata extraction, runtime cancellation, cold launch and provider UI remain unvalidated.

- 2026-11-09: Android assistant entry points: localized static Verify PDF / Prepare Signing / Documents launcher shortcuts, OPEN_APP_FEATURE inline inventory and allow-listed explicit routing. File actions use single-PDF SAF selection, retain purpose across recreation, defer during signing/consent and discard superseded picker results. No PIN/file-path authority is accepted. Added routing unit tests (not run). Gemini AppFunctions remain outside the implementation pending public integration availability.
- 2026-11-09: Siri follow-up review: prevent an already-presented picker from being relabeled by a new request; ignore stale voice picker results, protect slow preparation with an operation generation and cancel a resumed selection superseded by newer navigation. Shared phrase localization and optional-file picker flows retained. Documented usage and release-validation matrix in docs/15-assistant-shortcuts.md. Static localization/XML/Swift parse checks pass; native builds, tests, Siri/Assistant device validation and release remain pending (owner runs builds/tests).

- 2026-11-09: Added iPhone/iPad Home Screen and App Library quick actions (Verify PDF, Prepare Signing, Open Documents), with localized dynamic labels refreshed on launch/activation/background and scene callbacks for cold/warm launches. Routes reuse the Siri picker flow and retain signing approval. Android already has the matching three static launcher quick actions from this change set; verified declarations and localized labels rather than creating duplicate entries. Swift syntax/XML/localization checks only; native builds and device checks remain pending.

- 2026-11-09: Added iOS/iPadOS verification widget (small/medium) and Android Home Screen verification/recent-documents widget. Verify routes to native PDF selection; two recent signed filenames open existing details. Apple uses opt-in discovery, a metadata-only App Group snapshot and membership/readability revalidation. Android adds an off-by-default widget-filenames setting, immutable PendingIntents carrying library IDs only, and current-library validation. Widget updates follow signed-library changes and app activation; OS rendering may lag. Shared Apple App Intents and localized Siri phrases now open the latest signed document or verify the latest eligible PDF (picker fallback). Added iOS extension target, embedding, entitlements and release profile mappings. New widget App ID/App Group provisioning is required before signed packaging; no portal changes made. Static checks only; native builds/tests/device widget and voice validation remain pending under owner policy.

- 2026-11-09 integration validation (explicitly authorized): Xcode 27.1 RC iOS app/widget simulator build and Android debug build passed on the Air; 8 Android app tests passed. On iPhone 18 Pro/iOS 27, quick-action Verify opened Files, selected unsigned PDF returned expected result, widget URL opened Files and cancellation preserved the result. On API 36 foldable/tablet emulator, explicit Verify routing opened SAF and returned expected No signature; widget installed/rendered with filenames hidden. iOS extension registration/placeholder generation passed, but Home Screen installation was not completed through remote UI; widget taps/recent documents and voice remain pending. Registered widget App ID with shared App Group and pushed verified Development/App Store/Ad Hoc profiles to match (2a97517, 79e4f46, 5624615). Detailed evidence and limits: docs/15-assistant-shortcuts.md. No app release or main-repository commit performed.

- 2026-11-09 widget design refresh: iOS uses a blue gradient verification panel with a shield icon; medium widgets separate Verify and document content into two columns. Android uses a prominent 64dp verification button, compact document rows, theme-aware neutral surfaces and a three-row launcher size preference. Empty rows are hidden in gallery previews; default filename privacy and existing action routing remain intact. Native build validation recorded in docs/15-assistant-shortcuts.md.

- 2026-11-09 release 0.2.7: preparing authorized publication of settings/About fixes, Siri file selection, quick actions and mobile widgets. Store notes are separate per platform in EN/RO/RU; metadata export now rejects missing platform notes and mentions of another platform. Previous iOS 0.2.6 is live; macOS 0.2.6 awaits review and will be replaced only after the new build processes. Windows has no pending submission at preflight. Simulator/widget runtime limitations remain documented in docs/15.
- 2026-11-09 release validation: added the widget extension display name required by App Store upload validation. Android packaging encountered an upstream Kotlin compiler download HTTP 504; retrying the same source artifact build. macOS Store build 207 uploaded successfully.

- 2026-11-09 release 0.2.7 delivered: source e79fe76 and iOS upload-metadata fix 0907561 pushed. GitHub v0.2.7 published by Release 42584057334; CLI repositories 42585391969 succeeded. iOS build 208 and replacement macOS build 207 are WAITING_FOR_REVIEW; macOS is an initial Store release, so Apple disallows What's New and its field remains empty. Google Play run 42585317377 submitted Android 1793624687 to alpha only. Huawei's previous review was cancelled, the same verified signed APK attached, Android-only English notes updated, and releaseState 4 confirmed. Windows submission 1152921505702351127 reached Certification with Windows-only EN/RO/RU notes. App Store review is not public availability. Desktop artifacts retain their existing packaging/signing policy, including the self-signed direct Windows MSI. The final website refresh runs separately. Upstream Android dependency HTTP 504 recovered on retry; the initial iOS widget-display-name upload rejection was fixed and build 208 uploaded successfully.

- 2026-11-09 FILE-01…07: file-protection feature authorized for password and certificate/card encryption/decryption plus safe removal where supported. Plan and acceptance gates: spec/encryption/README.md. Vendor AES format uses PKCS#12 SHA-256 derivation and unauthenticated CBC; CMS certificate encryption uses RSA key transport/AES-128. Original preservation, bounded parsing, explicit destructive confirmation and accurate storage-erasure limits are required. Implementation/interoperability/UI evidence pending.
- 2026-11-09 FILE implementation: added MoldSign-compatible AES password and RSA/AES CMS certificate encryption/decryption across Swift, Kotlin and C#, legacy password decryption, PKCS#15 encryption identity discovery and simulated-card extended secure-message unwrap. Added localized Documents tools and desktop CLI commands, exclusive output creation and confirmed best-effort local removal. Swift/macOS 83 tests (8 skipped), Linux 63 (7 skipped), Kotlin core and Android runtime fixtures passed; native Apple/Android/Linux/Windows builds passed. Reverse vendor-library interoperability and screenshots are recorded in docs/reports/file-protection-2026-11-09.md. Physical-card and final cross-platform UI gates remain explicit; not released.
- FILE validation follow-up: Android native runtime confirmed legacy RC2 after adding RFC-vector-tested read-only fallback; vendor password/CMS libraries accepted Swift/Kotlin/C# outputs. Windows focused encryption/capability/file-I/O checks passed, with earlier MCP/bridge timing failures passing isolated reruns. Added owner-only Windows output ACLs and fixed Linux action-footer visibility and Apple dark-mode password prompts. Native fictional-data light/dark previews cover eight device/platform groups; physical-card decryption remains a release gate.

### 2026-11-09 — Public encryption certificate export

- Added Export encryption certificate for selected card identities in Apple (macOS/iPhone/iPad), Android, Windows and Linux. No document or PIN required. Saves exact public DER bytes with a fingerprint-based .cer filename.
- Swift and Windows CLI: encryption-certs --card SHA256 --out NEW.cer, explicit identity selection and exclusive output creation. Updated help and specification. EN/RO/RU localized labels.
- Localization consistency, Swift syntax parsing and diff checks pass. Native builds, interactive picker checks and physical-card export have not been rerun for this follow-up; owner runs batched build/test verification under the standing repository rule.

### 2026-11-09 — File protection UX simplification

- Reorganized encryption/decryption into File and Access method sections with contextual requirements and expandable help in EN/RO/RU. Explained password acquisition, recipient public-certificate export, compatible card/reader/PIN requirements and signing-only certificate limits.
- Apple uses a grouped native Form and DisclosureGroup; Android uses Material single-choice segmented controls, expandable help, keyboard insets and a fixed action footer; Windows uses ContentDialog primary actions and Expander; Linux uses GTK expanders and linked native controls. Certificate identity summaries stay visible while fingerprints/export sit in details. Password mismatch feedback is inline; PIN appears after identity discovery. Certificate export still requires neither document nor PIN.
- Preserved crypto, output handling and destructive-removal confirmation. Removed repeated compatibility paragraphs from the main flow and the irrelevant unavailable-removal footer on Android; format limitations remain in help.
- Swift syntax parsing, localization consistency and whitespace checks passed. Native builds, UI/runtime/accessibility checks and refreshed screenshots have not run for this revision under the owner-run build/test rule. Prior screenshots do not represent this revision.
- Screenshot refresh explicitly authorized: native Apple/Android/Linux/Windows builds passed. Visual inspection prompted a fixed Apple action footer and native macOS password-field label correction. Delivered 54 fictional-data light/dark PNGs in eight platform/device folders to the owner's [Drive](https://drive.google.com/drive/u/0/folders/1DUgpL_zEnuWyPUakXwfcs8GCnUcTGnwz); upload completion verified; physical-card operations remain untested.

- Added illustrated file-protection documentation in EN/RO/RU: 138 focused pages across seven app forms and three CLI platforms, linked from platform directories. Includes password and certificate/card methods, certificate acquisition/export, saving results and desktop removal limits. Reused v2 fictional native screenshots with external numbered markers and explicit capture-language captions; terminal panels are labelled instructional examples. No documentation publication requested.

- 2026-11-09 release 0.2.8: owner authorized publication and replacement of pending reviews. Includes file protection, public certificate export, desktop/CLI removal and localized illustrated guides. Live preflight: iOS maximum 208 and macOS 207 both awaiting review; Play alpha 1793624687; Windows has no pending submission; Huawei version code 1793624687 in review. New Apple/Windows build 209 selected. Website tests: 25 passed; refreshed panel-count assertion for new guides. Signed builds and store submission status tracked separately.

- Release 0.2.8 delivered from cbbfff7; fdd6d2a corrects the Linux removal test to use supported tmpfs rather than container overlayfs without weakening production guards. Release 42615342586 succeeded, all 12 initial asset hashes matched GitHub digests, CLI feeds 42616965333 succeeded, full CI 42616177821 passed. iOS/macOS 209 replaced 0.2.7 and await review; Windows 1.2.209.0 submission 1152921505702353222 is in Certification; Huawei 1793624688 is in review after authorized CAPTCHA and withdrawal; Play alpha 1793624688 submitted with EN/RO/RU Android-only notes. First Play attempt stopped before commit with HTTP 400; verified retry succeeded and workflow rerun passed. Guides deployed; final downloads/feed refresh follows package publication. Physical-card decryption remains unverified.

### 2026-11-09 — Localized illustrated guide correction

- Recaptured file-protection screens natively in English, Romanian and Russian for macOS, iPhone, iPad, Android phone/tablet, Linux and Windows; replaced the prior shared-locale image exception. Linux images show only the application window.
- Moved all numbered callout graphics, including pointer endpoints, outside screenshot pixels across the 684 guide panels and enlarged views. Kept numbered accessible text steps alongside the images.
- Added regression coverage rejecting identical cross-locale protection images and checking annotation geometry at phone, desktop and original image sizes. Regenerated all task pages and validated the multilingual website before publication.

### 2026-11-09 — Remove screenshot notices from public guides

- Removed fictional-data notices from guide introductions, screenshot captions and generated task pages in English, Romanian and Russian. Retained actual Demo mode instructions and safe support-reporting guidance.
- Regenerated the public guides for website publication; screenshot provenance remains in engineering evidence files.

### 2026-11-09 — Clear stale Apple signing errors after queue edits

- Reset the screen-level signing error when queued document identities change, covering individual removal, grouped removal, additions and replacement on iOS/iPadOS and the shared macOS model.
- Preserve per-document errors on remaining items; changes to signing progress or an item's error do not reset the banner. Cancelled imports and duplicate-only additions leave the unchanged queue alone.
- Reviewed all queue mutation paths and checked patch whitespace. Native build and simulator tests have not been run; verification remains with the owner per project guidance.

### 2026-11-09 — Clearer iOS share-extension handoff

- Replaced the centered text-only share result with native UIKit status imagery, preparation progress, readable saved filenames, localized next steps and a full-width Done button. Content scrolls for long lists and Dynamic Type; semantic colors support light/dark appearances.
- Kept atomic delivery: success appears only after all files and the ready marker are saved; failed deliveries still clean up. Prevent interactive dismissal while saving.
- Reviewed Apple extension documentation: launching the containing app is not a supported Share extension operation. The UI explains the manual handoff; the existing app inbox imports shared files and selects Sign when activated.
- Localization generation/check and whitespace checks passed. Native build and device/simulator visual validation have not been run, per owner-managed build/test guidance.


### 2026-11-09 — Signed-document deletion and XML original selection

- Added confirmed individual and all-document deletion to Signed documents on iOS/iPadOS/macOS, Android, Windows and Linux. Successful deletions remove the saved file and library entry; failed deletions retain their entries and show a localized error. History clearing remains independent and does not delete files. Windows individual deletion is in the document details dialog; Apple uses swipe/context actions, Android the row menu, and Linux a row action.
- Fixed Apple detached XML verification to open the exact security-scoped original selected in Files, without first requiring access to its parent directory. Selected files remain limited to expected names, no-follow final opens and regular files. Added a regression case for an unreadable parent with a readable selected original.
- Added Linux original-document pickers to Verify and saved-document details using the same bounded reference resolver. Android now rechecks a repeated original selection and replaces earlier same-name attachments in Verify. Windows clears the previous rendered report before displaying the refreshed result.
- Generated English, Romanian and Russian strings. Localization consistency, patch whitespace and Swift syntax parsing passed. Native builds, regression-test execution and device/VM interaction validation have not run, per owner-managed build/test guidance. These changes are not released.

- 2026-11-09 release 0.2.9 preparation: owner authorized new releases and replacement of pending reviews. Updated shared marketing version and EN/RO/RU platform-specific notes for saved-document deletion, XML verification, stale signing errors and the iOS share handoff. Apple live maximum is 209; replacement Apple/Windows build 210 selected. Existing Apple 0.2.8 and Huawei 1793624688 reviews remain until replacement packages are ready. CI and signed release builds will validate the source before store replacement.

- Release validation found Windows MCP stdio tests blocking an xUnit worker while waiting for a queued thread-pool session. Changed the test harness to a dedicated session task and asynchronous entry signal; cancellation and EOF assertions remain unchanged. Production binaries are unchanged by this harness correction.

- Release 0.2.9: `b125964` production source, `6243d63` test-only harness correction. Full CI `42649315944` and Release `42648572389` passed. All 12 public asset digests match release checksums; downloaded macOS notarization/distribution checks and Windows artifact checksums passed. iOS/macOS build 210 replaced 0.2.8 and await review. Windows MSIX 1.2.210.0 replaced the older certified submission and entered Certification (`1152921505702354441`). Play Alpha 1793624690 submitted successfully (`42652851179`), with Console confirming Changes in review and other tracks preserved. CLI signed repositories/Chocolatey workflow `42652831633` passed. Huawei 1793624688 remains in review because new browser CAPTCHA confirmation is pending. Updated download metadata and desktop feeds. See `docs/reports/release-0.2.9-2026-11-09.md`.

- 0.2.9 distribution follow-up: Pages `42653376230` succeeded after a file-sync timeout and deployment-only retry. Live desktop update manifests and signed package feed report 0.2.9; all 15 final GitHub asset checksums match. Published hash-verified Homebrew/Scoop definitions to the existing tap (`5f94530`). Huawei still awaits per-action CAPTCHA confirmation; previous review preserved.

- Windows 0.2.9 certification passed during final checks. Manually published replacement submission `1152921505702354441` in Firefox; Partner Center confirms Update in publishing. Store propagation remains pending.

## 2026-11-10 — File protection UX and 0.2.10

- Moved protection entry points into native navigation/header menus; removed unsupported ID-card/certificate choices from app forms while retaining CLI format compatibility.
- Apple password fields now have explicit labels/borders; mobile success automatically stores separate encrypted/decrypted outputs with Done/Close and optional export. Desktop Save records the result in Documents. Protected outputs retain their type, survive history clearing, and are excluded from signed-document discovery/widgets.
- Validated Apple iOS/macOS Debug builds and seven document-library tests; Android core suite (137 tests, one opt-in skip), emulator vendor compatibility, save/reload/delete checks and cross-process library relaunch passed; Windows native build and Linux build/23 tests passed. Localized guide screenshot refresh and store delivery are in progress.

- Final source `7bb81e6` passed full platform CI `42784306555`. Native iOS picker/encrypt/Document-details/decrypt/relaunch UI round trip passed (`.local/protection-runtime-ios-4`); decrypted bytes match the original and saved-file mode is 0600. Fedora six storage tests and Windows seven isolated storage/crypto probe checks passed; complete Windows/Linux UI picker-to-save remains unverified because remote input was unreliable. Documentation commit `adcb235` refreshes 96 native images in EN/RO/RU, 327 task guides and 702 outside-image numbered panels. macOS 0.2.10 build 212 replaced the old review and was submitted; remaining delivery is in progress.

- Added an explicit temporary-runner choice for Website manual recovery when hosted Actions budget prevents jobs starting; automatic triggers retain hosted runners. Recovery uses repository-scoped ephemeral owner-machine runners and the existing Pages/OIDC environment, without Store credentials.

- Recovery found 65.82GB of Actions artifacts. Removed only obsolete reproducible CI Linux/Windows packages created before 9 November (release/store artifacts preserved), and reduced CI package retention from seven days to one; Release retention is unchanged. Website publishing also encountered the separate artifact-storage quota.

- 0.2.10 delivery: iOS/macOS212 waiting for review; Play Alpha1793624693 confirmed In review; Windows1.2.212.0 certified and manually published in Firefox (Update in publishing). GitHub release assets verified (12digests), Linux metadata corrected with executable-preserving repack. Repository is private; GitHub assets are not anonymous public downloads. Updated localized docs are committed/built but final Pages upload42789721944 attempt3 remains blocked by storage accounting after53.47GB cleanup; GitHub reports6–12h recalculation. Huawei retains its older review pending required displayed-CAPTCHA confirmation. See docs/reports/release-0.2.10-2026-11-10.md.

- Budget recovery completed: CLI package repositories42818811932 passed and published0.2.10 feeds/Chocolatey; hosted Website42819453689 passed and deployed the refreshed docs/download metadata. Verified96 public image hashes,21 EN/RO/RU protection-guide pages and0.2.10 update/package feeds. Enlarged iPhone guide callouts inspected outside the screenshot UI. All15 release asset hashes match. Huawei remains the only pending release replacement action, awaiting displayed-CAPTCHA confirmation.

- Owner-requested preproduction GitHub cleanup: removed 152 older Actions artifacts (9.64 GB) and 122 downloads from ten older releases (3.18 GB). Retained all 16 v0.2.10 release files with unchanged IDs, sizes and digests, plus nine current release/store/package/Pages Actions artifacts. Release notes, tags, workflow logs and store submissions are preserved.

## 2026-11-11 — Replaceable app providers and responsibility separation

- Apple (iOS/macOS): route demo signing, verification, card fixtures and fixture files through injected provider contracts; extract observable document-library state, persistence and deletion policy from `AppModel`. Separate domain models, core adapters and memory/live stores into named files.
- Android: introduce live/demo `DocumentDataProvider` implementations and an injectable `PreviewDataProvider`; remove fixture bytes and preview-document construction from `MainViewModel`. Split combined screens by destination/shared component and split demo adapters from fixture data.
- Linux: inject certificate/credential reads through `CardDataProviding`, preserving generation checks in `ReaderSession`; inject JSON/in-memory history through `ActivityStoring`. Demo initialization no longer loads or migrates real document history. Split domain types into named files.
- Windows: use `ICardDataProvider` for both live and demo certificate results; make demo selection explicit in composition instead of inferring it from a reader's concrete type. Separate operation models, reader interface and demo providers.
- Added regression coverage for document-store switching, deletion boundaries, stale card completions, independent memory stores and Windows certificate-provider failures/scenarios. Tests and native builds are intentionally unrun under the owner's standing rule. Swift syntax parsing, source-move token inventories and `git diff --check` passed; these do not establish type correctness or runtime behavior.
- Remaining scope and validation handoff: `docs/reports/service-boundaries-refactor-2026-11-11.md`. The larger application/bridge controllers still warrant further coordinator extraction; this change does not claim repository-wide SOLID compliance.

### 2026-11-11 — Second architecture review

- Extracted Apple verification state/request lifetime into an observable feature model with cancellation and generation guards.
- Fixed Linux verification results appearing under another file's name using a toolkit-independent workspace reducer; reset rejects stale completions.
- Extracted Android batch consent/sign/save/retry policy into `SignDocuments`, with typed presentation events and a replaceable output store. Presentation failures no longer masquerade as signing failures.
- Extracted Windows verification/file-admission policy into the Desktop assembly; localization and UI operation accounting remain in the app adapter.
- Documented consistent platform-native presentation patterns and dependency direction in docs/09. Added Linux/Windows regression cases. Swift syntax and diff whitespace checks passed; builds/tests/runtime validation remain unrun under the owner's rule. Review: `docs/reports/architecture-review-second-pass-2026-11-11.md`.

### 2026-11-11 — Remaining review areas and cross-platform test harnesses

- Extracted Apple PIN/bridge consent, cancellable request lifetime and Apple/Linux demo scenario assembly; added Linux duplicate/stale-consent guards, Android exclusive consent/stamp admission and unused-PIN cleanup, and Windows cancellation independent of UI queue execution. Fixed bridge rejection cleanup to target the requested certificate.
- Separated shared bridge wire encoding, XML signature parsing, DER and certificate fields. Fixed content-length overflow, empty query-key indexing, control-character JSON escaping, malformed DER slicing/fixed certificate header assumptions, and reversed XML closing-tag ranges. Added regression cases; signing protocol output expectations remain protected by the existing core suites.
- Added native UI automation runners for macOS/iOS, Android, Linux and Windows, plus integration batches and lifecycle/storage/failure tests. Added a traceability catalog for all 47 documented journeys and three current protection/removal journeys; missing platform/OS automation is explicit, and the strict coverage gate deliberately fails until it is complete.
- Static syntax/metadata/whitespace checks only. Builds, type checking, all tests and native runtime checks remain unrun under the owner's instruction. Full UI automation coverage is not complete: actual installers, hardware/OS services, file providers/drag-drop/share, Shortcuts/Spotlight/Handoff and live portal flows still require their catalogued checks. No release or push.
- Review findings, implementation and exact outstanding validation: `docs/reports/architecture-and-test-review-2026-11-11.md`. Execution commands: `docs/testing/README.md`.


### 2026-11-11 — Interactive mock UI workflows

- Added injected signing scenarios for success, recoverable document failure and fatal stop across all native platforms. Apple, Android and Linux demo execution now reuses the production batch workflow; mock providers own fictional outputs and do not access credentials or transports.
- Added native queue/format/stamp/history interactions, verification detail expansion/collapse and cancellation checks. Fixed Apple consent fixture dismissal and Linux history-button accessibility labels exposed by source review.
- Apple wrapper covers both XCTest suites; Android expects 28 completion records; Linux has 20 scenarios; Windows has 12 across verification/workflow runners. These are authored paths, not passing execution results.
- Updated journey catalog with eight shared mock scenario groups and linked suites. Static parsing/metadata/whitespace validation only; native builds and tests remain unrun as instructed. Runbook: docs/testing/README.md; implementation and remaining external-integration limits: docs/reports/mock-ui-workflows-2026-11-11.md.


### 2026-11-11 — Owner-authorized native build and test execution

- Built macOS/iOS Debug apps, Android Debug/instrumentation and Release APKs, Fedora native GTK/CLI/MCP and Windows WinUI x64 Debug. All builds passed after correcting extracted Swift bridge calls, Android BuildConfig generation and an orphan annotation.
- Integration batches passed: Apple core/application/MCP plus CLI processes, Android core/USB/application, Fedora core/application/MCP plus CLI processes, and Windows 254 tests. Opt-in live PKI and absent vendor-reference checks remain explicitly skipped; the Linux application suite passed all 31 without skips after resolving an occupied-port prerequisite.
- Native UI passed on iPhone and iPad (24 paths each), Android (28 completion records plus protection/persistence), Linux (20 scenarios on isolated Xvfb), and Windows (12 cases). Existing iPhone carousel and demo/share/persistence tests also passed. Fixed Android startup navigation before NavHost graph readiness, compact sign identifiers, Apple confirmation/popover test behavior, Windows runner environment encoding, and Linux native menu/disclosure drivers.
- macOS UI remains blocked before the first test: XCTest times out enabling automation mode. Developer Tools permission is off and logs show denials. Temporary activation/retry/restoration requires the owner's pending confirmation under the computer-use permission policy; no permission has been changed. Do not claim all platform UI tests passed.
- Evidence and exclusions: docs/reports/native-test-validation-2026-11-11.md; local logs/results in `.local/validation-20261111/`. No commit, push, publishing, real-card attempt or distribution-signing validation.

- Final Android repetition exposed a replaced Compose accessibility node during format selection. The driver now re-queries rejected actions and requires menu dismissal before validating the selected format; failure reports retain stack traces. Both subsequent complete 28-case runs passed. Debug/Release builds and unit tests remain passing.

- macOS authorization follow-up: owner granted full permission. Enabled Terminal Developer Tools through System Settings; retry `mac-ui-r5` still times out before tests. Apple's automation-mode tool reports authentication required, and noninteractive sudo requires an administrator password. A local Terminal authentication prompt is pending; no credential was accessed or stored. Temporary Terminal permission must be restored after the handoff/test session.

- Owner is away from the machine. Cancelled the Terminal administrator prompt and the unresolved System Settings authentication sheet. Terminal Developer Tools is confirmed off; automation mode remains disabled/authentication required. The earlier toggle-on observation was provisional, not a completed permission grant. No temporary security change remains active. macOS UI execution remains pending local administrator authentication; other platform evidence is preserved.

### 2026-11-11 — Commit validation and publishing boundaries

- Connected the native mock UI suites to each selected CI platform job: macOS XCTest, iPhone and iPad simulators, Android emulator instrumentation, Linux GTK under isolated Xvfb/D-Bus, and Windows UIAutomation. Added Apple/Linux application integration tests and Android application unit tests. UI failures remain required by `CI result`; evidence uploads run even after failure.
- Added a CI Apple launcher that discovers simulator targets, checks the existing macOS XCTest authorization without changing security settings, and ad-hoc signs the Debug mock app without distribution credentials. XCTest result checks reject empty, incomplete, skipped and failed runs.
- Removed the branch-push trigger from the signed Android builder. Branch pushes now validate without reserving Android versions, signing distribution artifacts or uploading Store versions. Release remains explicit manual dispatch or version-tag push; documentation deployment is unchanged.
- Local validation: 18 CI/routing/result-contract tests and 12 publisher tests passed; journey traceability, shell syntax, Ruby syntax, whitespace checks and pinned actionlint validation passed. XCTest result checks also passed against the saved iPad verification/workflow bundles. Hosted results are recorded separately after push; prior native validation remains in `docs/reports/native-test-validation-2026-11-11.md`.
- First push `be108ab` started CI43016084788 only; no signed Android builder or publishing workflow ran. Hosted Swift/localization checks passed. The first native run exposed test-environment assumptions: a thread-pool-delayed Windows worker, a disappearing GTK accessibility node, and macOS tests opening overlapping design preview windows. Follow-up uses a dedicated Windows test worker, tolerates removed GTK nodes, and drives the single production macOS window with native mouse clicks. Also corrected the card accessibility label to announce certificate-read errors before the missing-certificate loading state. The full Windows254-test suite and Linux20-scenario UI suite passed on the native VMs after these changes; hosted follow-up remains required.
- Android's hosted SDK rejected the existing `pixel_8` AVD profile before boot. Both CI and the manual runtime workflow now use the standard `pixel_2` device profile with the same API36 x86-64 image; application unit/build checks had already passed.
- Hosted iPhone verification passed all5methods; the workflow suite passed5/6. The captured iOS27.2 accessibility hierarchy showed native menu buttons exposing their localized labels but dropping SwiftUI identifiers. XML format selection now accepts the exact English menu label as well as the identifier and still asserts the resulting selected format. No scenario was removed or marked optional.
- Hosted follow-up passed macOS disclosure, loading clear, PIN cancellation and verification clear tests. macOS native text exposes some reader states as accessibility values rather than labels, so state matching now checks both. Apple batch runners collect both suites and both iOS device families even if an earlier suite fails, while preserving a nonzero final result. Windows verification UI passed, and teardown now waits for its own process to exit before the workflow suite starts.
- The second mobile run completed with iPhone11/11 methods passing and iPad verification5/5 plus workflows5/6. The iPad mini native toolbar moved Clear list into `TopOverflowBarButtonItem`; the test now opens that real overflow menu before clearing history and still verifies cancellation and saved-file preservation. Android's emulator process failed before boot because its default7.4GB userdata allocation exceeded the runner's6GB free space. The test AVD now requests2GB and has a5-minute startup deadline. No application test failure is attributed to that boot failure.
- Follow-up local CI contract checks now include20tests, including failure propagation across both Apple suites.
- macOS verification now passes all5methods; history and website refusal also pass. Captured native AX trees identify file options as `MenuButton`, so workflow queries now match the stable identifier across native control types. Linux's intermittent clear assertion now waits for both the verdict and clear control to disappear, instead of treating the always-present chooser as completion. Windows teardown additionally disposes process handles and preflight excludes exited processes while retaining a live-process guard with PID diagnostics. A native VM process probe passed; a fresh VM UI reproduction could not locate its first verification view, so no additional Windows UI pass is claimed from that attempt. The temporary validation task was removed.
- The API36 system image still demanded7.4GB userdata despite the2GB AVD setting. Android-only hosted jobs now remove their unused preinstalled .NET SDK and verify at least8GiB free before launching the emulator; insufficient space fails immediately rather than waiting for a missing device. The updated Linux state-wait suite passed20/20 scenarios again on the native VM.
- Windows CI now starts each native suite in its own PowerShell process so UIAutomation objects and native handles from verification cannot remain rooted during workflow-suite preflight. Both steps remain required and share the final evidence upload.
- Hosted run43020707005 completed iPhone and iPad verification5/5 and workflows6/6 each, with zero failures. All20local CI contract tests, pinned actionlint, Python compilation, Swift test parsing and whitespace checks passed before the next runner-fix commit.
- Hosted run43023660566 passed both Windows native UI suites after process isolation. macOS passed10/11methods; the remaining native menu exposes XML format as an AppKit title with a replaced identifier, so selection now uses the native menu-item title. Linux history cancellation now waits for dialog dismissal before reopening; its full20-scenario VM rerun and three focused history repetitions passed. Failure evidence now includes the GTK accessibility tree.
- Android's disk prerequisite is resolved (11.6GiB free and successful API36 boot). The first UI scenario was obscured by a System UI ANR; CI now stops the still-running4GiB Gradle daemon before emulator startup and records host memory/CPU plus logcat, ANR, guest memory and screenshot evidence on failures. No scenario or assertion is skipped.
- Hosted run43026465773 passed macOS (both native suites5+6methods, application integration, Debug/App Store/CLI builds) and Linux (20native UI scenarios and packages). Windows exposed an MCP test-owned5second handler timeout racing the test continuation under load; handler gates now release in finally and reply/EOF waits are asynchronous. The focused2tests and complete254-test VM suite passed after the fix. Production MCP behavior is unchanged.
- Android's follow-up still had only1.9GiB host RAM available after Gradle shutdown, and the failure screenshot confirms the System UI dialog. Hosted builds now use a temporary Gradle process with Kotlin compilation in-process, avoiding a separate resident compiler daemon; the emulator preflight also requires3GiB available RAM. The API36 image and all28required scenario completions remain unchanged.
- The next hosted Windows run passed MCP cancellation but exposed the same independent5second timer in the bridge long-poll fake transport. Replaced it with a finally-released test gate and asynchronous readiness while retaining201/absolute-Location/one-long-poll/400/consumption assertions. All254native VM integration tests passed again; no production protocol behavior changed.
- Android now has6.8GiB available RAM, confirming compiler cleanup, but the Google API36 image still presents a System UI startup ANR on the2-core hosted runner. Verified the official SDK repository offers `system-images;android-36;default;x86_64`; native mock CI/runtime now use that AOSP image, retaining API36 and every scenario while removing unrelated Google-service startup.
- AOSP API36 still shows the first-boot System UI dialog after a74second cold boot. Added a pre-install readiness gate: acknowledge only that exact System UI dialog once, require three healthy launcher observations, and reject recurrence/other app errors without starting instrumentation. Readiness XML/screenshots/boot logs are retained separately. Six regression tests cover healthy boot, one recovery, recurrence, app-error rejection, missing native action and physical-device rejection; all26CI helper tests pass. No app scenario is retried or skipped.
- The readiness gate exposed that Android's boot-completed property precedes its first accessible window: UiAutomator returned a null root and created no dump. Setup now waits within its existing deadline for valid XML, removes stale dumps before every observation, and dismisses the unsecured emulator keyguard. A regression test ensures a missing hierarchy never counts as healthy; all27CI helper tests pass. This supersedes the failed validation run. Its Linux dependency setup also encountered a transient Ubuntu DNS-resolution failure before any test; no Linux source change was indicated.
- Linux dependency setup encountered the same hosted-container DNS failure on a second fresh runner, while both Ubuntu endpoints resolve from the developer host. The disposable Linux CI container now specifies public DNS resolvers; apt index updates fail on any incomplete download and dependency downloads have a bounded retry count. No build/test error is retried or ignored.
- Android boot readiness now succeeded: one initial System UI dialog was acknowledged before app installation, followed by three healthy launcher snapshots. Instrumentation then exposed a genuine fresh-install prerequisite absent on the reused local emulator: the independence disclosure. Added an explicit native first-launch case that resets only its acknowledgement, accepts through Continue, verifies retention across activity relaunch, and restores the original flag after the suite. Required completions increase from28 to29; existing scenarios remain required.
- The expanded Android instrumentation APK and Debug app built successfully. All29completion records passed on an isolated read-only API36 ARM64 emulator, including disclosure acceptance and activity relaunch; the emulator was then stopped. G01 traceability now includes the Android journey runner while retaining partial status for installer/clean-OS acceptance.
- Final hosted CI run [43040752719](https://github.com/xfreebird/smartcard/actions/runs/43040752719) passed all nine jobs at source `8244e5f42d3327630fa78ec4549c53e213e917c9`: macOS 11 UI methods; iPhone and iPad 11 each; Android 29 journey completions; Linux 20 UI scenarios; Windows 254 integration tests and 12 UI scenarios. Required builds, packages, shared tests and aggregate `CI result` passed. Only validation CI was triggered; no release/store workflow ran. Full evidence and remaining acceptance limits are recorded in [commit CI validation](docs/reports/commit-ci-validation-2026-11-11.md). The 50 catalog scenarios remain partial rather than claiming complete hardware/OS acceptance coverage.

### 2026-11-11 — Remaining automation and import review

- Required commit CI now includes iPhone/iPad native card gestures and user-controlled demo activation/share/restart checks, Android runtime crypto/storage plus separate-process persistence, and Windows first launch, demo persistence/isolation, card scrolling and synthetic reader-helper lifecycle.
- Windows demo automation now uses an isolated Debug profile instead of backing up and rewriting the developer's live preferences/history. Android instrumentation is separated into dispatch, legacy fixture data, storage integration and persistence integration; invalid phase combinations fail and coroutine/password cleanup runs after failures.
- Review found duplicate input selections could enqueue the same document twice in one import on Apple/Linux/Android. Shared Swift import policy deduplicates standardized local file identities across existing and incoming queues, preserves order and rejects directories/remote URLs; Android deduplicates incoming provider URIs before acquiring grants and describing inputs. Added Swift regression cases. Validation is pending this batch's exact source and hosted native tests.
- Follow-up review found file-protection I/O/crypto inside native views. Apple now injects `FileProtectionProcessing`; the service owns private output storage and cancellation. Android injects `DocumentProtection`, with bounded provider reads, output-buffer cleanup, and sample bytes supplied by the preview provider. Added four Swift service regressions and four Android workflow cases; the Android journey gate now requires 33 completions plus storage/restart phases.
- Promoted the earlier successful iOS protection round-trip probe into a maintained native suite for both phone and tablet. Its runner seeds one synthetic PDF, drives Files/password/Documents/relaunch controls, then compares restored bytes and owner-only permissions. Hosted execution remains pending.
- Expanded CI passed Windows first-launch and isolated demo persistence. Card-scroll exposed a stale 330-pixel assertion: current large-card geometry is bounded at 360 DIPs, so the test now checks the documented layout in window-DPI units while preserving centering/wheel/keyboard assertions. Android disclosure navigation now waits for the verification verdict before scrolling, avoiding the previous activity's accessibility window; failure text captures the active tree.
- Linux password transformation/removal now uses the same `PasswordFileProcessing` port as Apple's storage service; Windows delegates to an injected Desktop `IPasswordFileProcessor` instead of implementing password policy inside WinUI. Added Windows round-trip, invalid-operation and malformed-input regressions. Native save destination selection remains in the UI adapters.
- The hosted iPhone Duo accessibility tree exposes native navigation as buttons in a side rail, with no TabBar ancestor. Demo/protection navigation now finds the actual named buttons and waits for them; native Files navigation accepts its adaptive Browse button. The earlier gesture suite passed on that target. This corrects test assumptions without changing app navigation.
- The import follow-up also deduplicates source URIs before shared/drop documents are copied into cache: deduplicating only the generated copy URLs was too late. `ImportDocuments` now owns grant/metadata/copy policy, with an Android integration fixture proving one grant/copy per source, stable order and empty-selection behavior. Android completion gate increases to 34.
- Removed the remaining fictional protection names/paths from native views into preview providers/value objects, retaining screenshot authorization guards. Interactive Android disclosure tests now use stable control IDs and assert localized expanded/collapsed accessibility state; their fixture disables screenshot-only auto-scroll so it cannot compete with native user actions.
- The Windows keyboard driver omitted the extended-key flag for Home/End. Corrected scan codes and flags rather than changing the scroll result assertion; Microsoft's keyboard-manager documentation confirms the unflagged form can generate keypad input under NumLock.
- Continued readability review: independent Apple signing rows, verification details, Documents/Card screens and card presentation components now have their own files; Linux card items and empty-state rendering are separate from wallet interaction. Component token inventories verify unchanged bodies apart from required cross-file visibility/imports. Current macOS Debug build and Android build/unit tests pass; all 34 Android native/integration completions plus storage and two-process persistence pass on the isolated API 36 ARM64 emulator.
- Added a repeatable iOS Documents runner to commit CI: it generates genuine synthetic detached-signature fixtures with the simulated card, seeds fresh isolated history domains, and drives migration/details/history-clear/relaunch plus the native original-file picker on phone/tablet. It refuses existing fixture/profile paths and verifies original bytes and persisted library/history afterward. Native execution is pending; this is not a hardware or Store-installation test.
- Hosted follow-up passed all 14 existing iOS methods on both iPhone/iPad. The new protection test exposed two automation assumptions: iPad moves Protect files into the toolbar overflow, and the Files picker can still be transitioning while the underlying Cancel/Choose controls exist. The driver now opens overflow actions, waits for the actual Files view and dismissal, and taps only stable hittable controls. The macOS job was never acquired by the hosted runner; Apple jobs now serialize through the shared Xcode 27 pool while retaining iOS execution after a macOS failure.

- Native provider follow-up: iOS Files cancellation targets its own phone/sidebar toolbar and checks actual dismissal. The protection round trip and all three Documents methods pass on the local iPhone and iPad; byte preservation, private output modes, migrated library entries and history persistence were checked afterward. Simulator post-checks now resolve the current data container after installation, and protection baselines use relative paths so container relocation cannot hide or invent outputs.
- Android readiness now recognizes the framework process cold-boot ANR as well as System UI, permits one native Wait before app installation, and requires three healthy launcher observations. Repeated or different framework failures and all app ANRs still fail. All 38 CI-helper regression tests pass.
- The corrected iPad Documents runner also passes its final fixture and persistence checks. Both native Files layouts are now exercised locally; hosted validation remains required on the final pushed revision.
- Added a Linux protection journey that starts the real dialog from an isolated preview fixture, then drives native source/save controls and the production processor. It checks empty/mismatched input, cancellation, exact restored bytes, private output modes and explicit removal confirmation. The full 21-scenario GTK regression batch passed, including save cancellation retaining the pending result; no physical-card or portal claim is implied.
- Hosted Files evidence exposed taps landing in folder metadata instead of the icon; folder navigation now taps the observed icon. Both corrected iPad runner wrappers pass from fresh app data, including their final byte/persistence checks. The demo activation test now waits for the asynchronously applied switch value and passes locally.
- Hosted follow-up exposed two environment prerequisites rather than app regressions: Docker `/tmp` uses overlayfs, which explicit removal correctly refuses, so the protection fixture now uses `/dev/shm` like the core removal tests. Android boot can precede UiAutomation service readiness; failed pre-install hierarchy dumps reset the healthy count and fail after three attempts, retaining diagnostics. No app failure or unsupported-filesystem guard is bypassed.
- The tmpfs protection rerun passed locally and all 41 CI-helper tests passed. Windows and shared checks passed on the preceding hosted commit. Canceled that failed validation run while Apple remained queued so the corrected commit can run; no publishing workflow was canceled or dispatched.

- Hosted run43071414969 passed macOS, Android (34 journeys plus storage/restart), Windows (257 integration tests plus native suites), Linux (21 native scenarios), Swift and localization. iOS passed16/18methods per family; its remaining Files failures exposed remote accessibility controls changing identity between queries. The shared native picker driver now uses one public snapshot per action and observed frames, handles empty folders and sibling toolbars, and retains dismissal/file-result assertions. Protection and all3Documents methods pass on local iPhone Duo/iOS27.1, including post-checks; tablet and final hosted validation remain pending. Local iPad/iOS27.0 omitted Files accessibility names entirely and correctly failed the test.

- Follow-up isolated the iPad failure to missing attributes in whole-application XCTest snapshots: the named Files subtree exposes the real controls. Added a targeted snapshot fallback, retaining the phone toolbar path. The iPad/iOS26.5 protection runner now passes end to end, including original/restored bytes and private permissions; All3iPadDocuments methods and fixture/persistence post-checks also pass. Hosted final-source checks remain required.

- Final picker source b61890f passes protection and all3Documents methods locally on iPad/iOS27.0 as well as26.5, with fixture/persistence checks. Full hosted run43088408745 passed macOS, Android, Windows, Linux, Swift and localization, but the iOS native step failed; its evidence upload is still in progress. Added immediate named-suite GitHub error annotations to retain failure identity even when result-bundle upload stalls, without suppressing later suites or changing failure status. Hosted failure diagnosis and a passing final run remain required.

- Run43088408745's iOS evidence upload also failed after ten minutes. Its job/log APIs then returned repeated HTTP502 responses and inconsistent queued/in-progress metadata; cancellation returned409. No iOS pass is claimed. Native failure reporting now emits the failed XCTest method and escaped assertion before artifact upload, including nested protection/Documents bundles. All43CI-helper tests pass, and extraction was checked against a saved failed bundle. A fresh hosted reproduction is required to recover the unresolved failure details.

### 2026-11-12 — Native test lifecycle and CI follow-up

Baseline source `af30422` passed every platform and the aggregate in
[full CI 43171823518](https://github.com/xfreebird/smartcard/actions/runs/43171823518).
The deletion/evidence follow-up `d9383ec` also passed every platform and the aggregate in
[full CI 43176745714](https://github.com/xfreebird/smartcard/actions/runs/43176745714).
The authoritative results and coverage limits are in [commit CI validation](docs/reports/commit-ci-validation-2026-11-11.md).

- iOS installs once before fixture seeding and preserves that container across nested runners. Picker
  presentation and control interaction use bounded readiness waits. The shared Files driver honors
  restored locations and anchors thumbnail taps to uniquely identified native cells. Snapshot checks
  compare identity/frame and read application bounds once. All eight targeted protection/Documents
  methods pass locally on iPhone 27.1 and iPad 27.0, including exact restored bytes, private output modes,
  migration, history clearing, relaunch persistence and detached-original selection.
- Hosted runs `43098447037`, `43160305562` and diagnostic `43165580460` exposed Files navigation failures.
  Native-activation diagnostic `43168869669` also failed on the newer hosted 27.2 combination. The
  unchanged driver passed all eight methods on hosted iPhone 27.1/iPad 27.0 in `43168468861`.
  **The iOS 27.2 Files automation failure remains unresolved.** Runtime selection is not a claimed fix for it.
- Commit CI now selects each device family within the active SDK's major/minor release line, using
  runtime and hardware metadata. It retains inventories/targets, handles renamed devices and patch
  releases, prefers iPhone Duo at the selected version, and fails if either family is missing. All
  18 native methods remain required per family. Nine selector regressions bring the helper suite to
  52 passing tests; 12 publishing guards, actionlint 1.7.12, syntax checks and journey traceability pass.
- Windows scrolling waits for native focus before Home/End and for visible control geometry as well as
  scroll percentage. All four light/dark and 1100×720/900×580 cases pass on the Windows 11 ARM64 VM and
  hosted CI, including selected-card centering, wheel/keyboard end and full PIN/help visibility.
- Android runs `43166922439` and `43168937646` exposed ambiguous accessibility acknowledgements during
  disclosure and result clearing. The driver now retries lookup only, dispatches actions once, waits
  for the UI thread and checks the resulting UI/domain state. Verification uses the shared driver;
  returning to the library must reveal a saved document. All 34 local journeys, storage integration
  and process-restart checks pass. Commit `215df80` is green in hosted run `43170798943`; the same
  Android source also passes the current full CI run.
- Temporary diagnostic branches/worktree and the Windows test task were removed. Task-owned simulators
  and the disposable Android emulator were stopped; unrelated devices, VM state and untracked reports
  were preserved. No release, Store submission, tag or real-card operation was performed.

### 2026-11-12 — Bind deletion confirmation to the saved file

- Final review found that Apple, Android and Linux checked library membership by identifier but used
  the caller-provided file location for deletion. They now require the confirmed location to match the
  stored entry. Foreign identifiers remain ignored; altered locations fail without deleting either file.
- Android and Linux deletion policy now has its own application workflow, separate from presentation
  and persistence. Android uses the existing document-access adapter for I/O. Windows already checks
  the complete immutable activity record, including its path, and needed no behavior change.
- Local Apple application tests pass (42 cases). Android application tests pass (14 cases, including
  three deletion regressions), and Debug app/instrumentation builds pass with incremental compilation
  disabled after a stale local Kotlin symbol-cache error. Fedora application build and all 35 tests pass,
  including deletion, missing-file and symlink checks. The Mac Linux probe lacked Poppler headers; it
  does not replace the successful Fedora execution. Full hosted CI `43176745714` passes on final source
  `d9383ec`, including 42 Apple, 14 Android and 35 Linux application cases and every native platform suite.
- Baseline full CI `43171823518` passed every job and all 18 XCTest methods on each selected iPhone/iPad.
  Artifact inspection verified every required count with no skips. The protection postchecks passed but
  their nested JSON proof was omitted from upload patterns; CI now retains `roundtrip.json` alongside
  XCTest bundles, logs and simulator inventories for direct byte/permission evidence.

- Final evidence readback confirms all nine jobs passed on `d9383ec`, including `CI result`. The 12 iOS
  result bundles contain all 36 expected methods with zero failures/skips. Both retained protection
  proofs confirm two outputs, unchanged originals, private permissions and exact restored-byte hashes;
  Documents migration/history/original-selection postchecks pass on both families. iOS 27.2 Files
  automation and full hardware/OS catalog acceptance remain explicit open limits.

### 2026-11-12 — Decouple native design systems from signing models

- Apple card/empty-state/progress/verdict/activity/drop controls now receive display values. Domain
  mappings live in `Shared/Presentation`; feature settings, bookmarks and wallet coordination live
  under screens. A dependency-free SwiftPM target compiles the reusable source boundary.
- Android card wallet/art, status tones and PIN prompts now use presentation data. Core status and
  notification mapping moved out of the theme; settings and document orchestration are explicit
  features, while generic document picker tiles remain reusable components.
- Windows controls receive wallet/status data through bindings and emit selection callbacks. File
  selection uses an injected UI interface; core certificate mapping and live/demo behavior stay in
  presentation adapters. Linux card/placeholder widgets accept display content mapped by features.
- Android consent lifetime is keyed by the pending request at the feature host, so identical display
  text from a new request cannot retain a previous prompt's input after removing core models from UI.
- Added cross-platform boundary guards, an isolated GTK compilation check and Android/Linux mapper
  regressions. Full CI `43192144735` passes on `a3ce7d7`, including all native jobs and the aggregate.
  The 36 iPhone/iPad methods pass without skips; retained protection and Documents postchecks pass.
  Commit triggers remain validation-only; no release publishing changed.

- Android history automation now targets explicit accessibility identifiers and waits for tab/dialog
  transitions. The updated native suite passes all 34 journeys and storage/restart checks locally;
  timeout diagnostics also report visibility, clickability and enabled state.

### 2026-11-12 — Native iOS actions and floating Sign control

- Keep one floating Sign action above the bottom safe area in compact, wide and landscape layouts.
  Its enabled and disabled states use the same native prominent style.
- Reusable action styling uses system Liquid Glass on iOS 26 and later with native fallback styles.
  Standalone actions, file menus, stamp paging and swipe removal use these styles; toolbars, alerts,
  menu items and interactive content rows retain their system context. The design system stays core-free.
- Added native phone/tablet checks for scrolling, rotation, large accessibility text, light/dark
  appearance, unavailable/busy reader states and legacy browser touch targets. Local builds, 42 app
  tests, 56 guards and all 44 phone/tablet UI methods pass, plus eight iOS 18/26 compatibility checks.
  The phone verification suite passed an isolated rerun after a simulator launch timeout.
  Local validation completed before push. Hosted run `43211044835` passes all 44 iPhone/iPad methods
  with zero skips, both protection/Documents postchecks, macOS, Linux, Windows and Swift checks.

- The first hosted run exposed an Android result-clearing automation failure. Give that action an
  explicit identifier and require identifier-based clicks to target the enabled action owner;
  disabled controls never redirect clicks to an ancestor. Both APK builds, 16 app tests and two
  complete 34-journey native batches (including storage/restart checks) pass locally. The fix is
  pushed as `15b7d5d` after Apple evidence readback. Hosted Android validation exposed an additional
  one-way scrolling assumption. Add a regression that returns from the failed document to Clear
  results; search in both directions and wait for accessibility layout stability before clicking.
  Invalidate cached accessibility children before lookup so changed Compose identifiers are current.
  Both APK builds, 16 app unit tests, 56 guards and two complete 34-journey local batches plus storage/
  restart checks pass with the regression. Hosted run `43219827912` then exposed generic scroll
  actions moving the horizontal card carousel. A strengthened local regression reproduces the
  identity change. CI's three-button navigation also reproduced the missing control locally: page
  scrolling jumped past it between fixed chrome and a snackbar. Use short vertical touch drags in
  advertised vertical panes and assert that scrolling preserves the selected reader and saved library.
  Capture failure screenshots before Activity cleanup. Both navigation modes pass all 34 journeys
  and storage/restart checks; APK builds, 16 app tests, 56 guards and shell checks pass before push.
  Final hosted run `43223891446` passes on `ea6ac0b`, including the aggregate. Artifact readback
  confirms all 34 native journeys, three storage/restart phases, 16 app and 21 USB tests pass;
  the 137-case core suite has no failures/errors and one existing opt-in live-TSA skip. Unchanged platforms
  retain the successful `43211044835` evidence. Commit validation publishes no application version.

### 2026-11-12 — Localized iOS signing documentation

- Refreshed 48 native signing-flow screenshots across iPhone/iPad and English, Romanian and Russian,
  including card selection, the floating Sign action, stamp, consent, PIN, progress, completion and
  document errors. iPad assets retain the complete viewport so the bottom action stays visible.
- Updated the six canonical guides and 12 generated setup/signing pages with matching localized
  instructions and reviewed callout positions. Retained all other canonical guide content.
- Recorded binary identity, source equivalence, image hashes, dimensions and mock limitations in
  `docs/user-guide/ios-signing-refresh-evidence.json`; updated existing per-asset evidence. Dedicated
  guide simulators are shut down. No real reader, PIN or signing operation was used for these images.
- Added targeted panel regeneration and removed import-time guide rewriting. Capture waits for the
  first rendered frame after fixture readiness; the initial blank phone image was rejected and retaken.
- Local validation: 48 image hashes/dimensions, 327 task pages/702 panels, 26 website tests, 56 CI guards,
  all three production-configured locale builds and SEO checks pass before push. Enlarged guide images
  were checked in Safari in each locale; the action remains visible and labels stay outside the UI. This documentation
  change uses the existing Website deployment and validation CI; it does not publish an app version.

### 2026-11-12 — Floating macOS signing action

- Moved Sign from the compact toolbar to a large native bottom-right capsule, reserving space outside
  the scrolling documents. Preserved batch count, Command-Return, readiness checks and empty-queue hiding.
  The same native style now handles enabled and disabled appearance.
- Added four macOS floating-action XCTest methods and required them in the commit batch (15 macOS
  methods total). They cover actual document scrolling, resizing, EN/RO/RU, light/dark appearance,
  unavailable/busy states, click/keyboard mock signing and an empty queue.
- Refreshed 12 native macOS guide images and localized steps in EN/RO/RU, including the stamp sheet.
  Recorded source/binary/image hashes and capture boundaries; reviewed the generated guides in a browser.
- Local macOS/iOS Debug builds, 42 application tests, 56 CI guards, all macOS UI suite compilation,
  26 website tests, guide checks, three locale builds and SEO checks pass. Native mock clicking produced
  two sample outputs and removed the action. XCTest execution remains blocked by administrator
  authentication for Automation Mode on both Macs. The owner subsequently requested push after this
  limitation was disclosed; `1cb9067` is delivered. Website deployment passed and all 12 live image
  hashes plus all three localized instructions match. No app version was published.
- First hosted CI passed Linux, Android, Swift and localization, but found two test-driver assumptions:
  macOS resize growth exceeded the hosted display, and Windows Home checked transient UIA state.
  The follow-up shrinks within the display and waits for stable top offset plus full card visibility.
  All 56 guards and macOS UI suite compilation pass; the native Windows scroll driver passes locally
  in four size/theme combinations. Hosted CI `43243483172` passed for `7629f8e`: all 15 macOS
  UI methods, 22 iPhone plus 22 iPad methods, Windows native UI/helper/packaging, localization and
  the aggregate result. Linux, Android and Swift had already passed in the preceding full selection.
  Local macOS XCTest still requires administrator authentication; hosted success is separate evidence.
  See `docs/reports/macos-floating-sign-2026-11-12.md`.


### 2026-11-12 — Remove the iOS Sign navigation title

- Made the shared Sign navigation title macOS-only. iPhone and iPad keep the Sign tab and floating
  signing action, with no duplicate navigation-bar title.
- Local iOS Simulator Debug build passed. Native captures confirm the title-free phone/tablet
  workspace. The existing floating-action suite passed all four methods on iPhone iOS 26.3 and
  iPadOS 26.5, with complete result bundles and no failures or skips.
- The iOS 27.1 simulator logged four passing methods, but Xcode produced an empty result summary;
  that run is not counted as a validated suite pass. Logs, captures and results are retained under
  `.local/ios-sign-title-*`.

### 2026-11-13 — Website search and agent discovery

- Strengthened Romanian, English and Russian homepage metadata and visible links for electronic
  signatures, MoldSign alternatives on Windows/Mac/Linux and local MCP integrations. Platform
  overview copy is maintained in the guide generator's metadata source; nine generated indexes
  were refreshed without changing the illustrated tasks.
- Added a localized MoldSign MCP overview with actual platform commands, tool capabilities,
  approval requirements and the distinction between local stdio and the browser bridge.
- Production canonicals now default to esemnbun.md. Removed automatic language redirects;
  visitors choose a translation explicitly. Added stable WebSite/SoftwareApplication identities.
  Confirmed the source repository is private and removed it from public sameAs metadata.
- Extended the discovery plugin to generate localized llms.txt, llms-full.txt, a site-specific
  JSON catalog and 24 Markdown references from the same public documentation. HTML links expose
  the alternative formats; wildcard crawler access and three locale sitemaps remain enabled.
- Expanded the existing SEO checker for 18 entry pages, exact language/canonical links,
  structured data, homepage navigation and generated discovery files. JavaScript/JSX/Python
  syntax, seven JSON sources, relative Markdown links in 24 localized references and whitespace
  checks passed. All 26 website tests, guide organization (327 tasks/702 panels), the three-language
  production build and SEO checks passed. Build validation corrected an inherited translated-page
  Markdown link and aligned discovery URLs with the HTML canonical trailing-slash policy.
- Desktop browser review confirmed the new homepage section, Windows guide link, MCP navigation
  and Romanian language switch. Direct HTTPS access to the production domain succeeded.
  Publication uses the existing Website workflow. Indexing, ranking and search-console submission
  remain separate from deployment; see website/README.md for the operational steps.

### 2026-11-13 — Store screenshot refresh and Mac listing name

- Prepare the separate Mac listing as `eSemnBun Desktop`; retain the iOS listing name.
- Capture fresh Apple, Windows and Android store screenshots from current source.
- Upload the review pack to the owner's Google Drive; store screenshot replacement and release submission are pending explicit screenshot approval.
- Captured and visually reviewed 96 images in EN/RO/RU: iPhone 15, iPad 15, Mac 18, Windows 12, Android 36. Heavy Apple/Android work ran on the Air and Windows captures in its VM. Android captures now acknowledge the first-launch disclosure and reject wrong-language or still-obscured frames. Corrected all Android images before Drive upload; verified all uploaded names and byte sizes. Approval remains pending.
- Owner accepted the initial images and requested the missing Duo and iOS Header/Search Results assets. Prepare 30 compact/expanded Duo screenshots and six creative images for the same Drive review folder. Corrected the creative card crop for the removed iOS navigation title and the Device Hub capture helper's selected-row lookup. Store submission remains on hold for review of these additions.
- Completed and visually reviewed all 36 additions on the Air, uploaded them and their overview sheets, and verified Drive filenames/byte sizes plus native source hashes. The review folder now contains 132 images. Removed the task-owned Duo simulator after capture; original 96 accepted, additions awaiting approval.

- Owner approved all 132 images and authorized replacing the pending Mac review. Prepare 0.2.11 with Apple/Windows build 213 and Android version code 1793624694; submit approved assets with automatic publishing where supported. Preserve Android internal testing and use the existing Alpha track.

- 2026-11-13: Corrected Linux AppStream release metadata to 0.2.11 before rebuilding Linux packages and Flatpak for the shared release; Apple, Android and Windows build identities remain 213 / 1793624694.

### 2026-11-14 — Website downloads, browser locale and Huawei refresh

- Prioritize stores, standalone apps, CLI packages, then MCP setup. Add the released Huawei listing beside Google Play, deduplicate package/architecture entries, and remove the repeated Linux archive link.
- Smooth the landing animation with frame-rate-independent easing while preserving reduced-motion behavior.
- Refresh the light ready-state documentation captures for macOS, Windows, iPhone and Android from the approved 13 November native pack, retaining source hashes. The landing animation retains its matched native canvas set; replacing only ready frames with store captures would break alignment. Other states, dark captures and Linux still need a fresh capture batch.
- Initialize MSign's persisted browser locale from the app language, supply Accept-Language on opened URLs, and add vertical spacing between the iOS browser controls and app tab bar. Locale build/runtime validation is recorded below; no app release was requested.
- Verify Android 0.2.11 / 1793624694 and its upload certificate; replace four Huawei English screenshots using the current OBS upload API. See docs/reports/website-huawei-2026-11-14 for actual submission status.
- Google Play alpha was published manually by the owner and was left unchanged.
- Website source published on main as 972d2695f0ff24ad7ce5af460e445736d488a7b0. Website workflow 43634978947 passed automated tests, guide validation, build and SEO checks, and deployed successfully. Verified the live download page exposes Huawei AppGallery and grouped downloads. GitHub CLI authentication remains unavailable; repository access is available through the connected GitHub integration. Native builds and runtime verification remain owner-run.

- 2026-11-14: Replace the Huawei text link with the official AppGallery badge on the landing and download pages. Bundle Huawei's original English SVG with English fallback for RO/RU; preserve the existing app listing URL.

### 2026-11-14 — Embedded browser follows app locale

- Share one document-start locale policy across iOS, macOS and Android: browser language preferences and MSign persisted culture follow the effective app language. Preserve unrelated portal state, cookies and navigation request bodies.
- Resolve System mode through supported app locales; replace scripts safely after browser-data resets. Android recreates its WebView when the selected language changes and supports a bounded MSign reload on older providers.
- Windows and Linux keep their external-browser behavior by owner decision; their browser/site language remains controlled externally.
- The owner authorized the validation batch; results and remaining coverage limits are recorded below.

- Validation 14 November: 17 shared policy tests and 16 Android app tests passed; iOS/macOS/Android builds passed. Real WKWebView/WebView fixture checks passed EN/RO/RU; Apple System-mode resolution passed. Corrected blocked-storage handling and exact-origin isolation. Windows/Linux source remains unchanged. Live authentication and full settings-screen journeys remain untested; see docs/reports/browser-locale-2026-11-14.md.

- Delivery: commit and push the validated browser-locale changes only. No version changes, release tags, release workflows or store submissions.

### 2026-11-15 — Compact picker controls and iOS landscape cards

- Give the short Sign/Verify picker one full-width action and one outline on Apple platforms, retaining drag highlighting without a nested glass button.
- Let empty card placeholders grow with their text and help action instead of overflowing the fixed ID-card aspect ratio in narrow landscape panes. Existing signing pane padding now surrounds the complete placeholder.
- Show the iOS Card tab in two columns at the same usable width as Sign, with the card visible beside certificate/PIN/help sections. Keep a single column for narrow windows and accessibility text sizes.
- Move Clear Results to the iOS Verify navigation bar in both orientations, preserving its accessibility identifier and localized label.
- Source review found no equivalent overlapping picker chrome in Android, Windows or Linux. Native builds, tests and device/simulator visual checks remain owner-run.

- Validation 15 November: iOS Debug simulator build and unsigned macOS compilation passed. Visually checked Romanian iPhone landscape Sign/Card and portrait Verify, plus dark iPad Card. Verified picker opening/cancellation and navigation-bar clear-results behavior with isolated fictional fixtures. macOS runtime and real-card flows remain untested. Evidence: `docs/reports/ui-layout-2026-11-15/`.

- Follow-up: restore native glass styling for the short picker. The standalone capsule now owns its outline and shadow; only roomy drop areas retain an outer dashed border. Keep drag highlighting without overlapping idle borders.
- Glass follow-up validation: iOS Debug rebuild passed; recaptured and visually checked portrait Verify on the fresh iPhone simulator. Native capsule glass/shadow is restored without the surrounding drop-zone border (`docs/reports/ui-layout-2026-11-15/glass/verify-valid-light.png`).
