# Illustrated guide design review

Review date: 2026-11-08. This is a focused source and image review of the guides available at review time, not exhaustive validation of every frame or a rendered-browser/mobile acceptance test. Changes were still arriving during review.

## Findings resolved on recheck

1. **Resolved — iPad marker positions.** The original phone-coordinate reuse has been removed. Rechecked `website/docs/platforms/ipad.md:31` against the newly cropped native English signing image: the card, Choose files, row menu and Sign markers now identify their actual targets. The PIN coordinates at `ipad.md:44` independently match the tablet input, Remember toggle and Sign control. Native-image cropping is explicitly described in the captions. The reported phone/tablet remapping is consistent with these sampled final files; this review does not claim every localized marker was independently inspected.

2. **Resolved — Android recovery and verification coverage.** All six phone/tablet guides now contain the five added progress, failed signing, invalid, unconfirmed and unsigned panels. Confirmed those references in EN/RO/RU. Viewed the English phone failure frame and Russian tablet unconfirmed frame: their native error/status content matches the recovery and trust interpretation prose. The guides preserve completed outputs and explain current revocation limitations. Multiple signatures are described as a reader action without inventing a multiple-signature fixture.

3. **Resolved — CLI marker gutter and blank-space targets.** Rechecked all 63 SVGs: every command/output text line starts at x=120 and is at most 68 characters. At a 320-pixel image width this puts command text at 40 pixels, clear of the 24-pixel marker centred at 16 pixels. The Windows MCP figure now leaves its follow-up discovery/verification step unpositioned because no corresponding command is shown. Root separately verified responsive and actual-size viewer behavior in the browser; this recheck verifies source geometry and content.

Final CLI follow-up: verified the generator and all nine localized reader SVGs. Each now has three command rows at y=80/170/260 in a 960×303 panel, preserving the x=120 gutter. The corresponding markers are 90 source pixels apart, or 27 CSS pixels at a 288-pixel image width, so the 24-pixel circles remain separated. All nine guides include the correct platform command to hash the exported DER certificate with SHA-256 (`shasum -a 256`, `sha256sum`, or `Get-FileHash -Algorithm SHA256`), and distinguish its 64 hexadecimal digits from the certificate command’s SHA-1 display. This addresses both narrow-screen row overlap and unattended fingerprint selection.

No new critical or major issue was found in this focused recheck.

## Reviewed samples and useful distinctions

- macOS English detached-original verification: native image and coordinates identify the file chooser and original-selection control correctly.
- Android phone English stamp editor: callouts align with stamp, page mode and Apply. Android tablet Russian PIN approval uses native localized UI and contains no demo banner.
- iPhone English PIN approval: coordinates align with the protected input, Remember toggle and Sign action.
- iPad English signing queue and PIN approval: independent native tablet captures are present; final sample coordinates now align with the actual tablet controls.
- macOS CLI broker, Linux CLI Romanian verification, and Windows CLI MCP examples: source SVGs contain legible full command strings at native size, with copyable commands in the adjacent page. They are labelled as instructional examples rather than real-card operations.
- Windows normal CLI coverage is clearly distinguished from its MCP verification/unattended capabilities. Android guides correctly avoid claiming new PIN saving; macOS broker guidance distinguishes standalone and Store editions. History cleanup correctly preserves signed files and the separate document collection.
- Romanian and Russian Android copy and Romanian macOS copy were sampled. No major translation ambiguity was found in those samples.

Linux desktop capture completion was still in progress at final recheck and is outside this focused resolution review. This report is not an exhaustive release sign-off. No builds, application tests, card operations, live website signing or OS integration checks were performed for this review; the final recheck included static SVG and guide-reference checks.
