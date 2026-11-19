# Mobile document controls and browser authentication

## Changes

- iOS document details measure the full localized Preview/Decrypt and Share labels before choosing a horizontal or vertical layout. A common minimum label height aligns the native capsules despite different SF Symbol metrics. Accessibility text sizes retain the vertical layout.
- iOS Settings displays the selected browser authentication method in a contrasting brand badge, with a clearer disclosure arrow. An explicit Debug screenshot fixture exposes that row without enabling a physical NFC signer.
- Android Verify keeps its document-picker action above navigation while results scroll independently. Clear results is a navigation-bar trash action, also present during pending verification, and disappears after clearing. iOS retains its existing navigation-bar action.
- Android browser authentication uses a full-row entry and a scrollable bottom sheet. Method choices, known cards and public NFC identification are separate. The active certificate and remembered metadata are deduplicated by fingerprint; a selected radio row and serial number distinguish identities.
- New Android text is exported from the shared catalog in Romanian, English and Russian.

## Regression coverage

The native iOS suites now assert navigation-bar placement of Clear results, Romanian document-action bounds and capsule heights, and selection/dismissal of the Settings authentication sheet.

Android verification journeys assert the clear action's position beside the navigation title and retain the document picker after clearing. A required emulator-only browser-authentication phase injects one fictional active certificate and duplicate remembered metadata, acknowledges the first-launch notice through its real Continue control when present and preserves the prior acknowledgement, checks one visible identity row and its serial number, then switches to the reader and closes the sheet without opening NFC or requesting a PIN. Its completion marker is checked separately from the other instrumentation phases.

Prepared XCTest reruns now install the supplied app unless their caller explicitly sets `MSIGN_UI_APP_INSTALLED=1`. Install failures stop before XCTest. This fixes a stale-app rerun encountered while validating the capsule-height correction. The outer batch continues installing once for the complete session.

## Local validation

| Target/check | Result |
| --- | --- |
| iPhone 17 Pro, iOS 27.0 | 35/35 cases passed in one session, zero skips; protection and Documents filesystem postchecks passed |
| iPad mini, iOS 27.0 | 35/35 cases passed in one session, zero skips; protection and Documents filesystem postchecks passed |
| Android API 36 emulator | 34/34 journeys plus all five required integration phases passed, including browser authentication |
| CI helper tests | 85 passed |
| Native iOS and Android Debug builds | Passed |
| Shell syntax, localization exports and whitespace | Passed |

The iPhone and iPad protection postchecks restored the exact original bytes, preserved the input and checked private output permissions. The Documents postchecks confirmed history migration/clear behavior and preservation of every fixture file. A cold-simulator XCTest registration failure was resolved before running the successful full session; it was not counted as a test pass.

Detailed logs, native result bundles, source fixtures and postchecks are retained in ignored `.local/mobile-ui-tests-20261119/`. The successful iPhone bundle is `iphone-registered/GestureProof.xcresult`; its fixture postchecks are under `iphone-final/`. The complete iPad batch and postchecks are under `ipad/`. The final Android journeys and all five integration markers are under `android-final/`.

These checks use fictional identities and synthetic documents. Physical readers/NFC, real PINs/signatures, live PKI and store distribution are outside this validation. No release, tag or store operation was requested or performed.
