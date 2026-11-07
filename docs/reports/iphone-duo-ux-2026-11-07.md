# iPhone Duo UX review — 2026-11-07

This review uses the installed iPhone Duo simulator device type rather than a resized conventional iPhone. The existing `iPhone Duo BT Explore` simulator was preserved. An isolated `eSemnBun Duo UX` simulator was created with UDID `FAC452F3-BE0D-4EDF-9E09-974FD33CCC9A`, device type `com.apple.CoreSimulator.SimDeviceType.iPhone-Duo`, and iOS 27.1 runtime.

## Actual display inventory

`simctl io ... enumerate` reports the outer integrated display as screen 1 (`primary`), 1398 × 2034 pixels at 3×, and the inner integrated display as screen 3 (`primary-1`), 2007 × 2853 pixels at 3×. Those correspond to physical viewport sizes of 466 × 678 and 669 × 951 points before safe-area/system reservations. The outer runtime reserves a visible status strip at the side; app usable width must not be inferred directly from physical pixels. The inactive inner display initially returned a black screenshot; this was not counted as inner UI validation.

## Changes

- The iOS target explicitly opts in to the scene lifecycle, retaining a single scene (`UIApplicationSupportsMultipleScenes=false`) and letting SwiftUI supply its scene configuration.
- Sign uses an inline navigation title to free document space on shorter outer displays. The original outer portrait capture put the add-files action partly behind the floating tab bar.
- The two-column signing workspace now considers any window from 560 usable points. This avoids relying on a model name or only landscape height to recognize an expanded foldable window.
- Existing accessibility-size fallback and accessible document rows are preserved. Card selection and queued documents stay in the shared AppModel; layout branches do not reset them.

## Build and fixtures

Final Debug `eSemnBun-iOS` simulator build succeeded with Xcode 27.1 RC / simulator SDK 27.1. Version 0.2.4, current working tree. Preliminary SDK 26.5 builds are retained only as compatibility diagnostics. Build log and screenshots are under `/tmp/esemnbun-duo-2026-11-07/`. Fictional cards, selected card two (Mîndru Ștefan), and synthetic PDFs are used with an isolated preferences suite and `MSIGN_QA_NO_HARDWARE=1`. No physical reader, real identity, PIN or signing service is used. Simulation screenshots do not prove cryptographic signing.

Initial outer before-change captures are `outer-sign/multiple-light.png` and `outer-sign/multiple-dark.png`. The all-black `inner-initial.png` is diagnostic only.

## SDK compatibility finding

SDK 26.5 builds run in the system compatibility window on the Duo inner display even after adding a scene manifest. Apple documents that SDK 27 enables inner-display resizing and SDK 27.1 enables full-display content with vertical system bars: [Prepare for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/). The manifest is the documented scene opt-in, not a substitute for linking the new SDK: [Specifying the scenes your app supports](https://developer.apple.com/documentation/uikit/specifying-the-scenes-your-app-supports). The minimum supported OS remains iOS 17.

The compatibility-mode fold probe retained process 33299, card two, two queued PDF files and the Sign tab across the real Closed/Open/Flat Device Hub controls. `fold-before-outer.png`, `fold-after-inner.png`, and corresponding process files record this preliminary check; it does not prove native expanded layout.

## Native SDK 27.1 validation

The final candidate built successfully using `DEVELOPER_DIR=/Applications/Xcode-27.1-rc.app/Contents/Developer`, with separate DerivedData at `/tmp/esemnbun-duo-2026-11-07/build27`. Global Xcode selection was not changed. Its installed bundle reports `DTSDKName=iphonesimulator27.1`, `MinimumOSVersion=17.0`, and a single-scene manifest.

`native-inner/multiple-light.png` and `native-inner/multiple-dark.png` show actual full-width expanded landscape rendering: the selected card and signing action occupy the left column, files and add-files action occupy the right column, and native vertical tabs fit on the right edge. The SDK 26 compatibility-window captures are superseded for native-layout assessment.

`phone27-smoke/ready-light.png` and `phone27-smoke/ready-dark.png` confirm the same SDK 27.1 candidate launches and renders on the standard iPhone 17e iOS 26.3 simulator without clipping the card or file actions. No uninstall or data reset was performed.

The final unsigned **Release simulator build also passed** with SDK 27.1 (`release-build27.log`). Its bundle reports `DTSDKName=iphonesimulator27.1`, `MinimumOSVersion=17.0` and multiple scenes disabled. This checks the production compilation path, including protected PIN-vault code; it is not a signed device archive or an authentication test.

## Native fold continuity

Using the actual Device Hub Closed and Flat controls, the SDK 27.1 fixture kept PID 34890. After reopening and reactivating the app, card two (Mîndru Ștefan), `Cerere.pdf`, `Contract.pdf`, both PDF format selections and the Sign tab remained intact. Evidence: `native-fold-before-inner.png`, `native-fold-reopened.png`, `native-fold-before-process.txt`, `native-fold-closed-process.txt`, and `native-fold-reopened-process.txt`.

The simulator's closed display initially went black; Home woke it to the Home screen, and plain app activation did not bring the running scene to the outer display. Reopening and activation showed the intact workspace. This verifies retained state after the simulated fold/reopen sequence; it does not establish seamless foreground migration on a physical Duo. Fresh native outer-display captures are recorded separately from continuity evidence.

## Native state assertions

The temporary `DuoAdaptiveUITests.swift` ran through the existing isolated native UI-test runner with Xcode 27.1. Its final run passed one test with zero failures, asserting selected card two, `test.pdf` and its PDF format after portrait/landscape/portrait orientation requests. Result: `rotation-final/GestureProof.xcresult`; log: `rotation-final-driver.log`; active-display checkpoints: `rotation-final/active-display/duo-rotation-{0,1,2}.png`.

This runtime did not actually resize the active inner display in response to `XCUIDevice.orientation`: all three screen 3 captures stayed 2853×2007. The test therefore proves those state assertions survived the requests, but does not prove portrait/landscape reflow. XCTest reported an app frame of 669×951 at every checkpoint; the live screen dimensions are recorded separately rather than treating that reported frame as physical display orientation. An earlier temporary harness compile failed because it referenced the wrong orientation enum; the final run imports UIKit and uses `UIDeviceOrientation`.

Actual portrait geometry was subsequently exercised through Device Hub's Controls → Rotate Left, which did resize the inner surface to 2007 × 2853. `native-inner-portrait/multiple-light.png` and `native-inner-portrait/multiple-dark.png` show the 600-point split working: the complete card and signing action remain left, the file format chips wrap vertically, and the add-files action remains entirely visible. These screenshots establish portrait rendering separately from the XCTest orientation requests. The final branch was simplified to available width alone (`>=560`), preserving the accessibility-size single-column fallback; it produces the same branch in the observed Duo portrait and landscape windows.

The native outer landscape display (2034 × 1398) exposed a second boundary case: its vertical system bar left less than 600 usable points, so the 600-point branch still produced a tall stacked card. The final threshold is 560 points, with a minimum left-column width of 240 points to preserve room for the file pane. Outer portrait stays in one column.

The corrected native outer-landscape captures are `native-outer-landscape/multiple-light.png` and `native-outer-landscape/multiple-dark.png`. Both show complete side-by-side card/file panes, a visible choose-files button and the native sidebar signing action. The earlier `native-outer/` files intentionally retain the failing 600-point baseline and must not be presented as the final UI.

The final native outer-portrait captures are `native-outer-portrait/multiple-light.png` and `native-outer-portrait/multiple-dark.png` (1398 × 2034). Both were visually inspected: the complete selected card, document name and format chips, choose-files action, explanatory caption and vertical tabs remain visible. The outer-landscape right file border and drop target also retain their outer gutter; neither format chip is clipped.

## Screenshot matrix

All paths below are relative to `/tmp/esemnbun-duo-2026-11-07/`. Each folder contains `multiple-light.png` and `multiple-dark.png`; `matrix.json` records absolute paths and measured dimensions.

| Native surface | Folder | Pixels |
| --- | --- | --- |
| Inner landscape | `native-inner/` | 2853 × 2007 |
| Inner portrait | `native-inner-portrait/` | 2007 × 2853 |
| Outer landscape | `native-outer-landscape/` | 2034 × 1398 |
| Outer portrait | `native-outer-portrait/` | 1398 × 2034 |

## Coverage limits

The final native screenshot matrix covers Sign on both Duo displays, both physical surface orientations, and both themes. The UI test and fold probe predate the final 560-point/minimum-240-point column adjustment; that final layout was rebuilt and directly checked in the newly failing outer-landscape case. No card-selection/model code changed in that last adjustment.

This focused Duo round did not re-exercise Verify results, Documents, Browser, Card settings, Files drag-and-drop, VoiceOver, Duo accessibility text sizes, long Russian strings, or real-reader signing. No release upload or physical Duo validation was performed. The simulator wake/activation limitation described above remains a validation gap.

## Cleanup

The task-created simulator `FAC452F3-BE0D-4EDF-9E09-974FD33CCC9A` was shut down and deleted after the final captures. The existing BT Explore Duo was not modified. Evidence, the final simulator app and build/test logs remain under `/tmp/esemnbun-duo-2026-11-07/`; no simulator erase, existing-app uninstall, commit or push was performed.
