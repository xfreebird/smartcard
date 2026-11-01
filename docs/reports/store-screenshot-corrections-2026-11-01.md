# Store screenshot correction validation — 1 November 2026

The previous pack was rejected for clipped neighboring cards, inconsistent promotional artwork and old iOS system styling. This pass changes actual macOS/Windows carousel layout and captures current native UI before composing promotional images.

## Application checks

- macOS Desktop Debug builds. Sign and Card pages, second card selected, requested widths 860/1280 (actual maximum 1126 on this display): four native cases, complete selected card, exactly centered.
- Windows Debug builds in the Windows 11 ARM64 VM on the MacBook Air. Sign and Card at widths 900/1382: four native cases, center deviation at most 0.5 px, no neighboring card intersects the viewport. Viewport width grows with the window.
- Windows capture driver completed end-to-end: 12 current-source native captures.
- Android capture driver completed end-to-end: 36 current-source native phone and tablet captures. The task-owned read-only emulator was stopped afterward.
- Apple native capture stages completed: 30 standard phone/tablet captures using iOS 26.5 and SDK 27.1, 30 compact/expanded Duo captures using iOS 27.1 native Device Hub composition, and 18 Mac captures. These are actual system controls, including Liquid Glass; tab bars were not redrawn.

## Delivered pack

Desktop/esemnbun-store-submission/2026-11-01/revision2 contains 48 official-sized Apple compositions, 30 supplemental Duo compositions, 48 Android/Windows promotional compositions and 48 native Android/Windows captures. Listing text and images cover Romanian, English and Russian. Original Apple images and runtime/SDK provenance are retained.

The Mac batch story contains three localized documents. Rounded inset UI, application icons and presentation panels are used consistently. Store canvases remain opaque and rectangular. Native Microsoft and Google images are separate from promotional artwork; Duo is outside official App Store device slots. Capture fixtures suppress the demo notice without changing ordinary interactive demo mode.

The combined render-only pipeline passed: 78 Apple images rendered, all 48 official Apple sizes/formats validated, 48 cross-platform promotional images rendered, metadata and localization export checks passed. The final inventory covers 258 PNGs including originals and supplementary artwork. Native Windows/Android asset validation passed for 54 store PNGs. Python compilation and git whitespace checks passed.

No physical card or PIN was used in this screenshot pass. No store listing was submitted or agreement accepted. Website paths still require content publication before submission.

## Automation boundary

The Windows and Android capture drivers passed end-to-end. Apple build/capture/render stages passed individually, and the combined render-only entry point passed. A fresh unattended Duo compact → expanded → compact Device Hub lifecycle did not pass: native host actions can lose the selected device or leave the display in portrait. Size checks rejected those files rather than accepting incorrect images. The delivered Duo set was captured using the native Device Hub controls and visually verified. Unattended Duo orientation remains open; do not treat it as proven by the standard Apple automation.
