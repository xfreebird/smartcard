# Apple carousel and standard iPhone validation — 2026-10-31, revision 2

iOS uses the native page-style `TabView` for identity-card selection, including wide iPad and expanded iPhone Duo workspaces. Finger paging binds directly to the selected reader. The selected card stays complete and centered; native page dots indicate additional cards, with arrows and accessibility adjustment retained. Paging and alternative selection controls are blocked while signing. macOS retains a native horizontal scroll view with symmetric adjacent-card peeks and recenters the selected reader after its measured geometry changes. Programmatic scrolling cannot publish an intermediate visible card as a user selection.

`apple/Tests/InteractionUITests/CardCarouselUITests.swift` runs against the installed Debug product from an isolated UI-test host. It starts on card one, injects a native finger press-and-drag across the card twice, and asserts positions two and three, matching holders, selected accessibility trait, hittability, complete horizontal bounds, and an unchanged card center within two points. It separately launches with the second card selected. It never presses selection arrows, changes a page control, injects a PIN, or connects a hardware transport.

| Simulator | Native tests | Selected transitions | Center X before/after | Card width |
| --- | --- | --- | --- | --- |
| Standard iPhone 17 | 2 passed, 0 failed | 1 → 2 → 3 | 201 pt | 330 pt |
| iPad Pro 13-inch | 2 passed, 0 failed | 1 → 2 → 3 | 197 pt | 338 pt |
| Expanded landscape iPhone Duo | 2 passed, 0 failed | 1 → 2 → 3 | 165.667 pt | 275.333 pt |

Test bundles/logs are `/tmp/esemnbun-native-phone-gesture.xcresult`, `/tmp/esemnbun-native-ipad-gesture.xcresult`, and `/tmp/esemnbun-native-duo-display3.xcresult`, with corresponding `.log` files. The foldable runtime's XCTest screenshot API targets an inactive outer display, so the Duo runner captures active display 3 at stable native-test checkpoints. Those images accompany the native assertions; no programmatic card selection substitutes for a swipe.

Screenshots are under `/Users/nghimbovschi/Desktop/esemnbun-screenshots/ios/2026-10-31/revision2`: 14 standard iPhone presentation states in `iphone-17`, four native gesture checkpoints each in `iphone-17/gesture`, `ipad-gesture`, and `duo/expanded/gesture` (26 PNGs total). Standard iPhone covers signing documents, multiple cards, no reader, PIN with keyboard, card details, browser and verification, each light and dark. `matrix.json` lists the finite presentation coverage; `gesture-validation.json` records actual native selection/frame results. Two refreshed macOS light/dark screenshots are under `macos/2026-10-31/revision2`; the centered Mîndru card agrees with the 2-of-3 position and sidebar holder.

Reusable scripts are `capture-phone-screenshots.sh`, `run-carousel-ui-tests.sh`, and the optional active-display checkpoint wrapper `capture-test-display.py`. Capture uses fictional cards/PDFs and an isolated Debug preferences domain. Public browser portal content may load; hardware and signing remain disconnected.

Validation: current iOS simulator and macOS Debug builds passed; all eight focused batch/insertion policy tests passed; localization export/completeness checks, shell syntax and `git diff --check` passed. This round does not revalidate hardware signing, Store distribution signing, keychain persistence or portal certificate trust. Test-created iPhone/Duo simulators are removed after use; the pre-existing iPad is left shut down and other enrolled simulators are preserved.
