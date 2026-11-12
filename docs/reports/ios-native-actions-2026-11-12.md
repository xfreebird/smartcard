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

The first hosted run on `4c9a006` reported that signed results remained visible after a text-based
Clear results action. The action now has the stable `sign.clearResults` identifier. Identifier-based
clicks wait for that exact node to be clickable and enabled, while text-based lookup stops at a
disabled ancestor. The driver still dispatches each action once and verifies the resulting state.

Both Android APK builds and all 16 app unit tests pass locally. Two complete native batches each
pass all 34 journey completions plus storage, prepare and restart verification. The saved-library
preservation assertion remains intact. Evidence is in `.local/ios-glass-android-native-1/` and
`.local/ios-glass-android-native-2/`.

[Run 43217346170](https://github.com/xfreebird/smartcard/actions/runs/43217346170) then exposed the
remaining scroll-position assumption: the Clear results action was above the visible mixed-result
viewport, while the driver searched only forward. A regression deliberately scrolls to the failed
document before returning to Clear results; it reproduces a results-clearing failure with the old
driver. The driver now searches backward and forward and re-queries controls after accessibility
scroll/layout events settle. It clears the accessibility cache on API 34+ and refreshes nodes on older
versions: a new root alone could still return the previous history-control identifier after the UI
changed. The API availability follows [Android's UiAutomation reference](https://developer.android.com/reference/android/app/UiAutomation#clearCache()).
It still dispatches each click once. The regression checks that the clear action and output disappear
while saved documents remain. Both APK builds, all 16 app unit tests and all 56 guards pass. Two final
local batches each pass all 34 journeys and the three storage/restart phases, including the new scroll
regression and history transitions. Evidence is in `.local/ios-glass-scroll-fresh-native-1/` and
`.local/ios-glass-scroll-fresh-native-2/`. Hosted validation of the final correction is pending.
