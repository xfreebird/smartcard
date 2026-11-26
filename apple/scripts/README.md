# Mock UI capture

Build Debug first. `capture-screenshots.sh` refuses binaries without the mock scenario marker. Demo mode never starts a reader monitor or signing bridge, never submits a PIN and uses in-memory PIN and activity stores. Capture/startup probes use a dedicated Debug preferences domain and do not reset existing preferences. Captured success is presentation data, not a cryptographic signature.

```sh
apple/scripts/capture-screenshots.sh macos /path/to/eSemnBun.app ~/Desktop/esemnbun-screenshots/macos/YYYY-MM-DD
apple/scripts/capture-screenshots.sh ios /path/to/eSemnBun.app ~/Desktop/esemnbun-screenshots/ios/YYYY-MM-DD SIMULATOR_UDID
```

Captures no-reader, empty-reader, unavailable, reading, ready, multiple cards, error, signing progress, mock success and PIN entry in light and dark. Optional `MSIGN_CAPTURE_SCENARIOS="ready multiple"` restricts the matrix. `MSIGN_CAPTURE_FILES="/path/a.pdf:/path/b.pdf"` supplies a multi-document fixture for batch authorization. `MSIGN_CAPTURE_TAB=card|verify|browser|sign` changes the iOS tab (default sign); macOS supports sign, verify, card and activity. `MSIGN_CAPTURE_SELECTED=1` starts with the second card selected, so centered middle-card geometry can be checked. Browser captures can contact the real portal; signing scenarios remain disconnected.

For iPhone Duo use Xcode 27 Device Hub (`Xcode.app/Contents/Applications/DeviceHub.app`), select the requested device, choose **Open**, wake with **Home**, then activate the app. For its expanded display set `MSIGN_CAPTURE_DISPLAY=3` (inspect `simctl io UDID enumerate` on other runtime versions). Closed display normally uses `1`. Incoming app links can use `esemnbun://show` (the system may ask to open the app); web links can use `esemnbun://browser?url=<percent-encoded-http-or-https-url>`.

On iPad or iPhone Duo, rotate or resize the window to exercise compact and wide layouts. Signing uses two columns from 560 usable points; accessibility text sizes retain one column. The threshold uses the current window width, independently of device model. For native Duo full-display and vertical-toolbar coverage build with the iOS 27.1 SDK: an SDK 26 build runs in a system compatibility window even when captured on the inner display.

macOS capture needs the invoking process's existing Screen Recording permission. The script does not change permissions. It selects only windows belonging to the process it launched and terminates that process afterwards. iOS capture installs the specified Debug app and changes that simulator's appearance; use a dedicated simulator and retain any enrolled wallet sessions.

These matrices cover presentation scenarios. They do not prove hardware signing, PIN keychain access, App Store sandbox behavior, browser TLS trust, or every interactive file chooser/verification/consent state.

`capture-phone-screenshots.sh DEBUG_SIMULATOR_APP SIMULATOR_UDID OUTPUT_DIR` captures a finite standard-iPhone matrix: signing with documents, multiple cards, empty reader, PIN with keyboard, card details, browser and verification, each in light and dark. It writes `matrix.json` beside the 14 PNGs and supplies only fictional PDF fixtures.

`run-carousel-ui-tests.sh DEBUG_SIMULATOR_APP BOOTED_SIMULATOR_UUID OUTPUT_DIR` builds an isolated test host with `xcodegen` and runs `Tests/InteractionUITests/CardCarouselUITests.swift` against the product app. Choose the desired device orientation/window size first. The tests inject actual finger press-and-drag gestures across the card, assert one-page selection changes and centered complete card frames, and retain screenshots plus an xcresult. They also check launching with card two already selected. Arrow presses and accessibility increments are not used as swipe evidence.

For expanded Duo set `MSIGN_CAPTURE_DISPLAY=3` when running the native tests. `capture-test-display.py` captures that display at each stable test checkpoint, writing `active-display/*.png`; XCTest's own screenshot API on this runtime can instead capture the inactive outer display. The active-display images retain the real finger-test selection, without selecting a card from the host.

## Batch authorization policy tests

```sh
swift test --package-path apple --scratch-path /tmp/esemnbun-app-policy-tests
```

The package also tests the exact insertion transition policy compiled into the separate reader watcher: initial state/removals are silent, reader/card insertions each emit once. `ReaderInsertionDeliveryTests` and `MainWindowPresentationPolicyTests` cover how an insertion reaches a running app (URL without activation) and when the macOS main window may come forward (never while it is already showing).

`test-macos-insertion-window.sh DEBUG_APP FRESH_OUTPUT_DIR` checks that path in the real Debug macOS app on an otherwise idle desktop: the bundled helper reads fake snapshots and targets an isolated QA instance; Finder must stay frontmost while the main window is showing, an explicit reopen still brings it forward, and an insertion presents a closed window. No reader, card, PIN or background item is involved.

The Python automation scripts in this folder have unit tests that run on any OS with fake native tools:

```sh
python3 -m unittest discover -s apple/Tests/Scripts -p 'test_*.py'
```

The app uses the same `SigningBatchRunner.swift` tested by this small package. Tests suspend authorization and mutate the queue/card selection, attempt a concurrent batch, cancel and reauthorize, and inject a rejected credential/disconnection. They assert one authorization per immutable batch, no automatic retries, and preservation of pending/new documents after partial failure. No card transport, keychain or production PIN is used.

`FloatingActionUITests.swift` uses the same runner and isolated mock services. It checks the Sign
action above bottom navigation on phone/tablet, fixed placement while scrolling, portrait/landscape,
accessibility text, light/dark appearance and disabled states. It also checks minimum browser touch targets. Commit CI requires all four methods.
Run the suite on iOS 26+ for Liquid Glass and an older supported runtime for the native fallback.
