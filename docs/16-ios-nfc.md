# iOS NFC document signing

Status on 2026-11-16: signing a diagnostic document with the owner's Moldovan identity card over NFC is **verified** on iPhone 11 Pro / iOS 27.2. Core, app-policy and simulator UI checks passed. iOS 0.2.12 build 214 was submitted to App Review with physical NFC and reader recordings. The review submission and the independent diagnostic verification are recorded separately in [the release report](reports/nfc-store-submission-2026-11-16.md).

## Physical evidence and readable information

The separate `md.esemnbun.nfcprobe` app read the complete 1,799-byte signing certificate, established IAS/ECC mutual authentication and secure messaging, verified the owner's PIN once, and obtained one 512-byte RSA-4096 signature. The phone verified the signature. Independently, OpenSSL verified the detached CMS against the original diagnostic document and rejected altered content.

Observed certificate fields include holder name, subject identifier, country/state, issuer, validity, public key and certificate extensions (including content-commitment key usage). Do not assume identical fields on every card. The private signing key stays inside the card. Photo, fingerprints, travel-document data, PACE access and other card generations remain unverified. No CAN or MRZ was needed for the tested signing route.

See the [physical probe report](reports/nfc-first-scans-2026-11-16.md) and [probe runbook](../probes/ios-nfc/README.md). Original reports, certificate-bearing CMS and verification artifacts remain in ignored `.local/nfc-fulltest-2026-11-16-D6iLgA/`. The probe's persistent one-attempt authentication lock remains in place. Never copy these personal artifacts into git.

This diagnostic proof does not establish application PDF/PAdES signing, timestamp availability, certificate trust/revocation or legal qualification. Those require separate acceptance checks.

See the [iOS NFC sequence diagram](https://esemnbun.md/img/developers/nfc-ios-sequence.svg) in the Developer Handbook.

## Signing experience

Sign starts with **NFC** on capable iPhones and keep **Card reader** one tap away. Connecting or disconnecting a reader never changes the choice. NFC remains selectable while another card is connected through a reader. Devices without Core NFC default to the reader option.

The mobile flow starts with one **Choose a document** action. After import, the illustration
collapses into a compact method/card choice and the screen asks the user to review the
file and **Continue**. The existing PIN sheet is next, followed by one NFC session. A short
hint beside Continue explains that order. The numbered instructions live in **How it works**,
not as a permanent configuration strip.

Sign uses neutral surfaces and compact native menus. NFC has a blue card illustration;
selecting Reader reveals the live reader card inline: connect the reader, insert the card,
reading/error state, or the connected identity. Multiple cards retain the swipe carousel and
an explicit selection hint. Reader help opens the connection guide. The default method remains
NFC. Card details and Saved PINs open from secondary rows. Large text remains scrollable and
the primary Sign action stays above the tab bar. RO/EN/RU copy is included.

1. With **NFC** selected, choose documents and tap **Continue**. Choose **Card reader** instead when using a connected reader.
2. Confirm the PIN through the existing `PINCoordinator` and PIN sheet **before the NFC prompt opens**. On first use or after **Use another card**, enter the PIN for the card you intend to scan. No stored PIN is looked up without a known certificate. The iOS sheet keeps Cancel and Sign in a bottom safe-area bar, above the software keyboard; it does not depend on a keyboard toolbar appearing.
3. Bring the card to the top of the iPhone once and keep it there until final confirmation. Public certificate reading, secure-channel authentication, protected PIN verification and signing all use that one connection. There is no separate identification prompt asking you to remove and present the card again.
4. Cards are identified by the same signing-certificate fingerprint through both transports. At startup NFC selects the only remembered card, if present. On first explicitly switching from Reader to NFC, the app selects the current reader card, or the only remembered card when none is connected. The compact card menu also offers other known identities. Its exact certificate must match the NFC scan before any PIN command. **Use another card** clears that selection and asks for a new PIN; this explicit choice survives switching methods.
5. After receiving the card's signature, the app releases the NFC sheet and finishes ordinary document processing. Results use the existing Documents flow. A batch collects the PIN once and uses one NFC session per document; every document must use the certificate bound by the first scan.

The method, documents, credential and signer are frozen for a batch. A new NFC card's certificate is bound inside its first signing session; a known card is bound before it starts. Saved PINs are stored only after a successful document output, under that actual certificate. Reader updates are deferred during signing, and NFC never silently falls back to a reader.

Cancellation, connection loss, authentication error, incorrect/blocked PIN or card mismatch stops the NFC batch. Neither authentication nor PIN verification is retried automatically. Completed files remain available; unfinished files remain queued. A wrong saved PIN is removed through the existing error path. PIN retry hints are scoped to the certificate that produced them.

The info button on Sign opens the selected identity’s details. **Cards and readers** and **Saved PINs** in Settings open focused sheets, including management for disconnected cards. Deleting a saved PIN removes the shared account for both methods. File-protection workflows retain their existing reader selection. The embedded browser now has a separate on-demand NFC identity selection; see [browser NFC integration](reports/browser-nfc-integration-2026-11-17.md).

`PinVault` retains its existing account namespace: lowercase SHA-1 of the signing certificate DER, with no NFC/reader suffix. No PIN migration or duplicate credential is needed. `SavedCardIdentityStore` retains public certificate bytes in local app preferences only for remembered PIN accounts, validates each fingerprint on restoration and discards malformed certificate data. This enables selection and Face ID before the single NFC prompt after restarting the app. PIN values remain in the existing Keychain store; viewing/deleting card metadata never reads them. Deleting a PIN removes its persisted certificate metadata too. Older saved PINs without certificate metadata remain available in Saved PINs and gain a name when the card is read again; an unidentified NFC card still needs manual PIN entry. Demo identities and PINs stay separate and are cleared from selection when switching modes.

## Implementation and protocol

- `SigningCardChoice` provides the source and known-card choices in Sign. `AppModel` deduplicates known certificates by their existing PIN account ID, while keeping NFC and reader transport selections separate. Stamp previews use the selected signing identity.
- `NFCSigningSession` owns one foreground `NFCTagReaderSession`. `NFCISO7816Transport` adapts asynchronous commands to the blocking `CardTransport` core. Signing runs off the main thread; callbacks run on the main queue. Pending commands have a 20-second bound and are released on invalidation/cancellation. Late callbacks cannot replace a failure.
- `ContactlessCertificateReader` performs only SELECT, READ BINARY and bounded GET RESPONSE. It selects Generic ADF directly, then EF `0001` with P2=`04`, validates DER length and reads at most 4,096 bytes in chunks of at most 128. It never authenticates or sends a PIN.
- `NFCDocumentSigner` creates a dedicated `SigningService` bound to that NFC session, reusing `CoreDocumentSigner`, PAdES/XAdES writers, trust services, security-scoped file access and output naming. It never changes the shared reader/bridge transport factory.
- Declare IAS `A000000077030C60000000FE00000500` first, then Generic ADF `E828BD080FD25047656E65726963` in Info.plist, with NFC `TAG` entitlement and localized usage description. The main app **md.esemnbun.ios** needs an NFC-enabled provisioning profile; the separate probe profile does not authorize it.
- Serial EF `D003` returns **18 bytes: skip 2, take 16**. Do not require the simulator's `04 10` prefix: the real card differed. Seed EF `D004` returns 16 bytes. MSE setup is `0022C1A4098004FF40108C830104`, then a 16-byte challenge.
- The shared core validates setup statuses/exact lengths, generates fresh terminal random/key material, and verifies response MAC plus challenge/terminal binding before accepting the channel. Protected responses require authenticated status/MAC and valid encryption padding. Bare `9000` is not secure-channel proof. Session keys and raw APDU payloads are not logged.
- Signing uses protected PIN ref `03`, MF/Generic ADF reselection, MSE `800102840181`, then INTERNAL AUTHENTICATE. `61xx` is response continuation, never a retry of authentication/PIN/signing. The real RSA response continued as 256 + 256 + 35 protected bytes, unwrapping to 512 signature bytes.
- Early movement produced Core NFC error 102 / nfcd 29 in research. Timeout/SELECT failure is inconclusive about general NFC capability or PACE support.

Apple documents entitlement, usage text and AID requirements in [NFCTagReaderSession](https://developer.apple.com/documentation/corenfc/nfctagreadersession), and initial AID selection order in [NFCISO7816Tag](https://developer.apple.com/documentation/corenfc/nfciso7816tag).

## Verification handoff

The owner explicitly authorized local builds, tests and installation for this change. Completed verification is recorded in [the integration report](reports/nfc-app-integration-2026-11-16.md). The relevant suites are:

- Core: `ContactlessCertificateReaderTests`, `SecureResponseValidationTests`, `ContactlessSigningTests`. Coverage includes bounded public reads, malformed inputs, mandatory MAC/padding, fresh terminal values, binding, setup failures, card swaps before PIN, one wrong-PIN attempt, and production XAdES signing with a simulated RSA-4096 card/chained responses. Existing core suites must also pass because physical readers share authentication/secure messaging.
- App policy: `BlockingCardCommandTests`, `NFCSigningIdentityTests`, `NFCSessionDiagnosticsTests`, `SavedCardIdentityStoreTests` and `NFCBrowserTransportTests` (the browser's Core NFC transport closes its session exactly once with the first error; bridge workers wait for main-actor results), plus existing batch policies. Coverage includes metadata restoration/deduplication, deletion isolation, account/certificate mismatch and legacy entries. Cancellation, timeout and late callbacks must not turn failure into success.
- iOS UI: `NFCSigningChoiceUITests`, included in the native mock batch, exercises both choices with two synthetic reader cards, NFC without a reader and hardware-free demo signing. `PINActionsUITests` requires the software keyboard and checks the PIN action bar and submission in portrait and landscape, using synthetic digits in the isolated fixture. `SharedCardPINUITests` checks common reader/NFC PIN deletion, an explicit other-card choice and disconnected account management. These suites do not prove RF or real PIN behavior.

```sh
swift test --package-path swift/MoldSignKit
swift test --package-path apple
python3 -m unittest scripts.ci.test_apple_ui_batch scripts.ci.test_workflow_contracts
xcodebuild -project apple/eSemnBun.xcodeproj -scheme eSemnBun-iOS \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .local/nfc-app-integration/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Use the project's supported Xcode. Run `apple/scripts/run-mock-ui-tests.sh ios APP_PATH SIMULATOR_UUID FRESH_OUTPUT_DIRECTORY` on an explicitly selected, booted phone simulator, then a tablet. For a focused NFC UI run, set `MSIGN_UI_TEST_SOURCE` to the absolute path of `apple/Tests/InteractionUITests/NFCSigningChoiceUITests.swift` and use `apple/scripts/run-carousel-ui-tests.sh APP_PATH SIMULATOR_UUID FRESH_OUTPUT_DIRECTORY`. Review RO/EN/RU, large text, portrait/landscape and light/dark.

For device installation, build with an explicit device destination, verify main-app NFC entitlement/profile, and upgrade-install without removing app data. The owner enters the real PIN only on the phone. Automatic signing needs an Xcode account for team H86U5Z8HYB (or its development profiles for `md.esemnbun.ios`, `.share` and `.widgets`) on the building Mac; without them `xcodebuild -destination id=UDID DEVELOPMENT_TEAM=H86U5Z8HYB` stops with "No profiles for 'md.esemnbun.ios'" before compiling. Check `xcrun devicectl device info apps --device UDID --bundle-id md.esemnbun.ios` first: a Store/TestFlight install of the same identifier would be replaced.

Physical acceptance remains: PDF/PAdES-T through the new app with independent content/signature and timestamp/trust checks; XAdES; both choices with a reader connected; another NFC card with its own PIN; card swap before PIN (must stop before VERIFY); cancellation/card removal; batch prompts and saved-PIN/Face ID. Do not deliberately submit a wrong PIN to a real card or reset the research probe's lock.

## Development diagnostics

Debug builds record bounded, per-session JSON in `Library/Caches/NFCDiagnostics`. Each report includes build/version, a random session ID, workflow steps, APDU instruction number, secure/plain indicator, response byte count, status word and NFC/underlying error domains/codes. It excludes command/response bodies, PINs, keys, certificate contents, card identifiers, document names/content and error descriptions. Release builds do not enable this recording.

Use `bash apple/scripts/collect-nfc-diagnostics.sh DEVICE_UDID FRESH_OUTPUT_DIRECTORY` to collect only this directory into a fresh ignored `.local/` evidence directory after the owner tests. Keep previous copies and hashes. The original uninstrumented app failure cannot be reconstructed from a later screenshot; a fresh instrumented scan is required. Distinguish `identityRead`, `step.verifyingPIN`, `step.signing`, `cardStepComplete` and `documentWritten`: obtaining a card signature does not prove the timestamp or output-file write succeeded.
