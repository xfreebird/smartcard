# Android tablet desktop-layout amendment — 31 October 2026

Tablets use the desktop vertical signing hierarchy: centered card/carousel, documents and picker below,
then a compact centered signing action. Native navigation remains a rail. All destination pages use a
bounded 680dp reading column; tablet Sign has 24dp gutters and a bounded card viewport. Tablet signing uses
one scroll container, so the card and document list scroll together. Compact windows retain their phone UI.

The layout begins at 600dp window width, including smaller portrait tablets; narrow split-screen windows
switch to the compact layout. Device model names and physical orientation do not select the layout.

Validation:

- Debug APK, unsigned Release APK, Release AAB and lint passed. Final log: /tmp/esemnbun-tablet-desktop-final.log.
- 32 final-source ARM64 emulator captures: 600dp portrait and 1707dp landscape, light/dark; Sign with cards,
  no reader, batch and blank PIN, plus Card/Verify/Browser/Activity destinations.
- Visually inspected the portrait and landscape batch screens: card, documents and action are centered in
  the same column and fit the test viewport. The other destinations retain nonzero gutters.
- Every capture's APK hash matches the final Debug APK. No hardware or actual PIN input was used.
- Release APK and AAB native ELF audits pass for ARM32/ARM64/x86/x86-64.
- Shared localization and diff whitespace checks pass. Cryptographic policy code was unchanged; core suites
  were not rerun for this UI amendment.

Evidence: Desktop/esemnbun-screenshots/android/2026-10-31/{tablet,tablet-landscape}.
