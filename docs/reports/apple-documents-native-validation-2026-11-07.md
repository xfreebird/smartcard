# Apple Documents native validation — 7 November 2026

Native XCTest exercised the Debug iOS application from the working tree based on `d0f4f13`, version 0.2.4/build 1. The app used its real `PreferencesActivityStore` with isolated QA suites, `MSIGN_QA_NO_HARDWARE=1`, demo mode disabled and the browser bridge disabled. All inputs were synthetic. The XML was genuinely signed by the test card simulator, whose certificate is deliberately untrusted by the production trust chain. No physical card or real-card PIN was used.

## Observed results

On a dedicated iPhone 17e / iOS 26.3.1 simulator, the History-to-Documents migration displayed two files. Opening a saved PDF inspected its current unsigned content and reported an unconfirmed result instead of trusting the old signing-success history entry. Clearing History left Documents populated. Terminating and relaunching the app retained both saved files and the empty History.

An upgrade-install exposed an actual persistence defect: iOS changed the data-container UUID, leaving saved absolute file URLs stale. The fix stores app-owned Documents references relative to the current Documents root. Legacy paths are migrated only from recognized iOS/device/simulator container layouts with valid UUIDs. External URLs are preserved. Invalid relative references do not resolve to an external fallback, and resolving a stored location grants no security scope. Six focused Foundation policy tests passed, covering migration, unsafe paths, external preservation, history clearing and another container change.

The corrected app was upgrade-installed again, changing the container from `4DB7…` to `057D…`. No preferences or files were re-seeded after that install. The existing saved XML remained readable, and the separately prepared legacy History suite migrated, cleared and survived relaunch successfully. This provides runtime evidence for the container-change migration, in addition to the policy tests.

The phone XML test opened the native Files picker, cancelled it without losing the report, reopened it, navigated to the synthetic original and selected the `.txt` file. After Open, the missing-original explanation disappeared; the expanded report showed green document-integrity and cryptographic-signature checks. The test certificate remained untrusted, as expected. The final focused picker test passed with zero failures. Earlier failed attempts were harness errors: a broad selector selected an outgoing XML cell, and a folder tap raced the Files navigation animation. The final harness matches `.txt` and waits until the folder is visibly on-screen.

On a separate iPhone Duo / iOS 27.1 simulator, the native modal smoke test passed with zero failures. It opened Documents, opened the saved XML details and asserted the unconfirmed verdict and original-document picker. The captured default active display is 1398 × 2034. The other display, Closed/Flat transition and true rotation were **not re-exercised in this phase**. An attempted Device Hub startup did not return; further control exploration was stopped. This limited Documents smoke does not replace the earlier full Sign-screen Duo matrix in `iphone-duo-ux-2026-11-07.md`.

## Source and evidence limits

The phone and Duo runtime evidence includes relative document persistence, the Preview-label correction and detached-original selection. It predates the final copy/severity adjustment that separates “no recognized signature” from “unconfirmed trust” and gives demonstrated cryptographic failures priority over missing originals. Those final source changes were compiled and checked in the enclosing validation pass; this report does not claim they were rerun on these devices. The UI test's unsigned-caption expectation was aligned to the final text after capture.

Phone evidence is English, light appearance, portrait, 1170 × 2532. Duo evidence is English, light appearance, default active display only. Native Files-provider selection was exercised for local app Documents; third-party cloud-provider revocation, external sandbox grants, dark mode, landscape and physical hardware are not established by these tests.

The two task-created simulators were shut down and deleted after their attachments were exported: phone `DBB4363A-8D1F-4FDB-984B-BDB6F607261F`, Duo `A31FB17C-E017-4771-B575-087A7B0A4E01`. No existing user simulator was erased or modified.

## Artifacts

- Screenshots and machine-readable provenance: `evidence/apple-documents-2026-11-07/`.
- Phone migration/history result: `/tmp/esemnbun-documents-ui-upgraded.xcresult` (History test passed; earlier picker harness attempt in the same bundle failed).
- Final phone companion result: `/tmp/esemnbun-documents-ui-companion.xcresult` (1 test passed, zero failures).
- Duo default-display result: `/tmp/esemnbun-documents-ui-duo.xcresult` (1 test passed, zero failures).
- Focused location/library tests: `/tmp/esemnbun-document-policy-tests.log` (6 tests passed, zero failures).
- Native test source: `apple/Tests/InteractionUITests/DocumentsUITests.swift`; temporary external-app harness: `/tmp/esemnbun-documents-ui/DocumentsQA.xcodeproj`.
