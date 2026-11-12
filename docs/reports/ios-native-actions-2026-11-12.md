# iOS native actions and floating signing control

The signing workspace has one floating action at its trailing bottom safe area in compact, wide and
landscape layouts. Queued documents retain the action while reader/busy state controls whether it is
enabled. The same prominent native style renders enabled and disabled states.

Standalone actions use SwiftUI Liquid Glass on iOS 26 and later. Earlier iOS versions and macOS keep
their native fallback styles. Menus, alerts and toolbars retain system context; interactive rows keep
full-row hit targets. Custom fills were removed from stamp-page and swipe-removal controls. The share extension uses
UIKit's native prominent-glass configuration on supported versions. The
shared style accepts only UI choices and introduces no signing-core dependency.

At accessibility text sizes, the floating action uses the short visible Sign label while its
accessibility label retains the complete document count. Obsolete form layouts were removed from
the signing screen.

Icon labels retain at least 44-point targets on older iOS. The compatibility test caught reduced
browser targets before delivery; a reusable frame helper restores them without duplicating glass
padding. Landscape evidence uses a complete display capture to avoid cropped window screenshots.

## Validation

The local gate passed before pushing. Hosted Apple, Linux, Windows and Swift validation also passes
on `4c9a006`; the Android follow-up is recorded below.

- iOS Simulator (app and extensions) and macOS Debug builds pass.
- The independent Apple design-system target and all 42 application tests pass.
- All 56 workflow/architecture guard tests, publishing guard tests, localization consistency,
  actionlint, journey mapping, metadata consistency and shell syntax checks pass.
- All 22 required UI methods pass on iPhone Duo / iOS 27.1 and iPad Pro / iPadOS 27.0, without skips.
  The four action tests also pass on iPhone 16 Pro with iOS 18.6 and iOS 26.5: 52 required method
  results across the four targets.
- Both protection round trips preserve the source, produce the exact restored bytes and retain
  private file permissions. Both Documents postchecks preserve every generated fixture byte.
- Retained screenshots were inspected for light/dark appearance, portrait/landscape, accessibility
  text and disabled states. The first visual review caught an oversized accessibility label;
  compatibility testing caught reduced legacy browser targets. Both were fixed before delivery.

The local phone batch encountered one simulator app-launch timeout before process creation.
The unchanged five-method verification suite then passed in isolation. An earlier attempt also
correctly refused existing fixture profiles; complete fixture runs used reset task-created devices.
No assertions were removed and no tests were skipped. The evidence summary retains the recovery.
Local macOS UI automation was unavailable on the developer hosts; macOS builds and application tests
passed, and all 11 hosted native UI methods pass. Its existing control appearance is preserved.

Evidence is retained in `.local/ios-glass-local/` and the developer-host test directory. The final
phone/tablet app binary SHA-256 is
`48b4e9c4f5d7098ec48108b2991cddb0581f3a8ee4fda535e25fe448819eb473`.

All UI inputs and identities are fictional. These checks do not exercise a physical card or live PKI.
Existing broader hardware/OS journey limits remain in the testing plan. Ordinary commits run
validation and do not publish application versions.

## Hosted native evidence

[Run 43211044835](https://github.com/xfreebird/smartcard/actions/runs/43211044835) validates the Apple,
Linux, Windows and Swift source in `4c9a006`. All those jobs pass. Its aggregate failed only because
of the Android automation issue described below.

- iPhone and iPad: all 44 expected methods pass with zero failures or skips. Both retained protection
  proofs show two outputs, unchanged originals, private permissions and the exact restored-byte hash.
  Both Documents migration/history/original-selection postchecks preserve every fixture byte.
- macOS: all 42 application tests and 11 native UI methods pass, including the existing control flows.
- Linux: all 38 application tests and 21 native UI journeys pass, alongside the isolated design-system
  compilation and package builds.
- Windows: all 257 core/integration tests, eight workflow and four verification scenarios pass;
  first-launch, demo, card scrolling, browser helper and package checks also pass.
- Swift Apple/portable backends and shared localization pass.

Downloaded evidence is retained in `.local/ios-glass-ci-43211044835/`. The strict iOS result readback
is `ios/verified-results.json`; it checks the complete suite counts without counting duplicate bundle paths.

## Android automation follow-up

The native driver now waits for an enabled action owner, refreshes accessibility state after layout
changes, and searches above and below the current viewport. Clear results has a stable identifier.
Each click is dispatched once; the resulting UI and saved-document state are asserted separately.

The driver identifies vertical panes by their advertised scroll actions, then makes short overlapping
touch drags. This avoids moving the horizontal card carousel or jumping past a control between the
fixed toolbar, snackbar and bottom navigation. A separate `NativeVerticalScroller` owns the gesture.
The mixed-signing regression scrolls to the failed document, preserves the selected reader, returns
to Clear results and verifies that hiding results leaves the saved library intact.

Three-button navigation reproduced the hosted failure locally; the prior gesture-navigation setup
had a different usable viewport. The strengthened regression also reproduced unintended card
selection with generic forward/backward scrolling. Both failures were fixed before the next push.
Failure screenshots are now captured before Activity cleanup so retained evidence shows the failing
app state. Diagnostics include advertised actions and dispatched input acknowledgements.

Accessibility cache invalidation uses API 34+ `clearCache`, with node refresh on older versions,
following [Android's UiAutomation reference](https://developer.android.com/reference/android/app/UiAutomation#clearCache()).
This prevents a new root from returning a previous Compose control identifier through cached children.

Both APK builds, all 16 app unit tests, all 56 guards and shell syntax checks pass. Complete batches
in both three-button and gesture navigation each pass all 34 journeys and the three storage/restart
phases. Evidence is in `.local/ios-glass-drag-threebutton-1/` and `.local/ios-glass-drag-gestural/`.
Hosted validation is pending.

Earlier failed hosted runs are retained for the investigation:
[43217346170](https://github.com/xfreebird/smartcard/actions/runs/43217346170) and
[43219827912](https://github.com/xfreebird/smartcard/actions/runs/43219827912).
