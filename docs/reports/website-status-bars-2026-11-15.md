# iPhone documentation status bars — 15 November 2026

Replaced the legacy status-bar band in 15 iPhone protection screenshots: five screens each in
English, Romanian and Russian. The native replacement has 09:41 on the left and connectivity
and battery on the right, matching the newer iPhone documentation images.

Only the top 40 pixels of each 750×1334 image changed. Native strips came from the existing
English `sign.png` (white background) and `pin.png` (dimmed background), cropped at
`[0, 60, 1206, 124]` and resized to 750×40. This is an image presentation edit, not a recapture.
App content, alpha, dimensions and callout coordinates are unchanged. No pixels below the band changed.

`website/static/img/screenshot-clocks.json` records the donor hashes, source crops, old image hashes
and final hashes. The normalization script supports the recorded replacement step, and the image
cache revision has been bumped. The existing website image checks cover the updated hashes.

Evidence: [before/after strips](website-status-bars-2026-11-15/before-after.png) and
[per-image pixel/hash audit](website-status-bars-2026-11-15/image-audit.json).

Local verification covered pixel boundaries, dimensions, status-bar appearance and all 348 manifest hashes.
OCR confirmed 09:41 on the left in all 15 updated images (`clocks.jsonl`).
No local application or website build/test suite was run. Publication checks are recorded below
after deployment.
