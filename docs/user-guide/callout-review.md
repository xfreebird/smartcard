# External screenshot callout review

Reviewed 2026-11-08 after replacing opaque numbers over native controls with external annotation gutters.

## Design and source assessment

No critical or major issue found in the revised component, layout helper and CSS.

- Each native image occupies the middle grid column, with a real 36 CSS pixel gutter on either side. A 24-pixel badge centred 18 pixels from the frame edge remains outside the native image, with six pixels of clearance before its border.
- Leader paths and three-pixel target circles use no fill and a thin stroke. The native image remains unchanged; controls no longer have an opaque numbered badge placed over them.
- Target positions derive from the measured image rectangle relative to the frame, not from the whole frame. This accounts for the gutters, cropped source images, and extra vertical space around short terminal examples.
- Labels are packed in target-height order separately on each side, with 32-pixel separation. The frame minimum height provides sufficient room for the maximum occupied lane. Original instruction numbers remain associated with their own targets after packing.
- Steps without coordinates remain in the ordered instructions without inventing a visual target.
- Inline, fit-to-screen and actual-size views use the same renderer. Actual-size mode retains fixed CSS-pixel gutters and measures the displayed image again. The original image's aspect ratio is preserved.
- Image load and resize observation update the measured geometry when an image becomes available, a dialog opens, or its size changes.

## Validation boundaries

This review inspected `website/src/components/GuideScreenshot.jsx`, `website/src/components/guideCallouts.mjs` and the appended guide styles in `website/src/css/custom.css`. It did not operate the browser or modify screenshots. The main validation pass owns all-panel geometry checks, live responsive rendering, zoom behavior, production builds and deployment.

In the live check, confirm that the fit-content grid shrinks its middle column to the available page width and retains both gutters. Fixed gutters reduce the native image's available mobile width by 72 pixels, so the existing enlargement and actual-size controls remain important. Source geometry supports the intended layout; it is not a substitute for this rendered sizing check.
