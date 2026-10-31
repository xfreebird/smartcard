# Keyboard, carousel and control access — revision2, 31 October 2026

## Android

The PIN bottom sheet was replaced with an IME-aware native Compose dialog. Its viewport consumes the union
of safe-drawing and keyboard insets; the explanation/field can scroll, while Cancel/Sign stay outside that
scroll area. A focused-field bring-into-view request follows keyboard size changes. Short viewports use
smaller padding. The eight PIN cells retain 56dp height; accessible text uses password transformation.
The unavailable remember-PIN option is hidden instead of occupying space with a disabled control.

Reference: [Android window-inset handling](https://developer.android.com/develop/ui/compose/system/insets-ui).

Carousel viewports now span the available Sign/Card/Browser content width, with native gutters. Individual
card faces keep their bounded proportions; document/details panels keep a 680dp reading width. The selected
card remains centered. Screenshot capture waits for navigation transitions to finish, preventing faded
previous-page content from appearing behind current controls.

Validation:

- Debug APK, Release APK, Release AAB and lint pass: /tmp/esemnbun-revision2-android-final-build.log.
- Eight real-IME checks: phone/tablet, portrait/landscape, light/dark. Accessibility bounds prove full 56dp
  input and 48dp action heights, with both actions and the entire field above the visible IME frame.
- A focused empty PIN request survives portrait-to-landscape resize with the same bounds checks; tapping
  its visible Cancel button dismisses the dialog. No PIN was typed.
- A native horizontal drag changes 1 of 2 → 2 of 2 and preserves the selected card's center coordinates.
- 20 scenario PNGs plus four interaction images accompany the JSON proofs under
  Desktop/esemnbun-screenshots/android/2026-10-31/revision2.
- Persistent check: android/scripts/verify-pin-visibility.py is invoked by the capture driver for every
  PIN scenario and rejects a covered or clipped field/button. The interaction harness is available at
  android/scripts/check-mock-interactions.py (English mock emulator).

Core cryptographic policy is unchanged. No hardware, real-card PIN, credential vault or signing operation
was invoked. Apple native gesture/iPhone validation is recorded below.


## Windows

Card faces are capped at 320px on Card and 280px on Sign/tray. The Card page has a bounded native vertical
scroll viewer. Vertical wheel input over the horizontal carousel now scrolls the page without selecting
another card. Native Home/End/Page navigation reaches the same content. No lower control was removed.

All four light/dark × 1100 × 720 / 900 × 580 checks passed using actual wheel input over the card and native
Ctrl+Home/End. The final saved-PIN action and help text are fully within the viewport after scrolling;
the selected second card is still fully visible and centered at the top. Ten final images and machine
proofs are under windows/2026-10-31/revision2. The empty-state foreground/stroke now track ActualTheme.

Native Debug: zero warnings/errors. Unsigned Release MSIX: zero errors, existing optional symbols warning.
Artifact: dist/windows/validation-2026-10-31/revision2/eSemnBun-0.2.0-x64-unsigned.msix.
The capture task was restored and Windows guest stopped. No physical card or PIN was used.

See [Windows validation](windows-platform-corrections-2026-10-31.md) for hashes and reproduction commands.


## iPhone, iPad and expanded Duo

The iOS carousel now uses system page-style TabView touch paging with native page indicators, while
arrows and accessibility adjustment remain available. macOS keeps its native horizontal scroll view.
The final mobile implementation avoids publishing transient scrolling geometry into shared selection.
Touch input is blocked while a signing step is active; the model's signing guard remains in force.

Six actual XCUITest finger tests passed: two each on standard iPhone, iPad and expanded Duo. They include
initial selection of card 2 and press 0.05s/drag selection 1→2→3. Tests verify holder, selected trait, hittability,
full bounds and a stable center (201pt phone, 197pt iPad, 165.667pt Duo). The test does not use arrow taps,
page-control taps or programmatic selection to prove swiping. Eight existing policy tests also pass.

The Duo runtime returns the inactive outer display from app.screenshot. Final Duo PNGs instead come from
synchronized simctl display 3 captures at actual test checkpoints; the final set contains no black images.
The disposable Duo completed app/UI testing after an initial PreferencesMigrator boot-status failure.
This simulator behavior was not represented as a product gesture failure.

Twenty-six new iOS images include 14 standard-iPhone light/dark states and four native gesture checkpoints
for each device. Two macOS images verify the shared component still centers the selected middle card.
Builds, localization and script checks pass. Disposable phone/Duo devices were deleted, the existing test
iPad was shut down, and no test simulators remain booted. No physical card or PIN input was used.

Reproduce with apple/scripts/run-carousel-ui-tests.sh (generated isolated runner; the product project is
unchanged). MSIGN_CAPTURE_DISPLAY=3 captures the active Duo display at test checkpoints. The standard phone
matrix uses apple/scripts/capture-phone-screenshots.sh. All files are in the dated revision2 folders.

See [Apple validation](apple-carousel-and-phone-validation-2026-10-31.md) for xcresult paths and JSON proof.

## Artifacts and final checks

Android Debug/Release APKs, Release AAB, lint reports and hashes were preserved under
`dist/android/validation-2026-10-31/revision2` before cleaning only the task-owned app build outputs to
recover simulator space. Windows unsigned MSIX is under its matching revision2 validation folder.
All relevant native builds, localization/store drift checks, script syntax and diff whitespace checks pass.
Earlier screenshot folders remain before-change evidence; latest reviewed images are under revision2.
