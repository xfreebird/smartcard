# Illustrated user documentation

The public entry point is the website's `/docs/platforms/` route, available in English, Romanian and Russian. Canonical authoring sources live in `docs/user-guide/content/<locale>/`. `scripts/docs/organize-user-guides.py` generates short device overviews and focused task pages in `website/docs/platforms/` and the corresponding locale directories. Edit the canonical sources, then regenerate; do not edit generated task pages directly. Documentation images live under `website/static/img/guide/<platform>/<locale>/`.

## Editorial and capture rules

- Start with a user goal, state prerequisites and the expected result, then show the numbered actions on the native screen.
- Use `GuideScreenshot` for both numbered markers and the matching accessible ordered list. Coordinates identify the target in percentages of the original image; never use them as the badge position. Numbers are automatically packed in outside gutters, with thin pointers to the target, so opaque labels never cover app content. Inspect them in the rendered page. Tapping a screenshot opens an enlarged view with its callouts.
- Capture native translated interfaces, including actual phone and tablet layouts. Do not stretch a phone screen to represent a tablet.
- Use only fictional identities, filenames and sample documents. Debug capture mode must isolate hardware and hide the demo banner; ordinary app demo mode remains labelled.
- Record provenance, binary identity, locale, device form and capture limitations in each platform evidence manifest. A mock successful screen does not establish physical-card signing, saved-credential access or system-service behavior.
- Terminal examples are instructional illustrations, labelled in adjacent prose, with copyable commands. Do not imply they show an operation that was not exercised. Never include PIN values in a command, screenshot, guide or log.
- Document current platform and distribution differences explicitly. In particular, Windows normal CLI coverage differs from Windows MCP; desktop approval UI is available in standalone macOS, Windows and Linux builds; the Mac App Store edition retains its separate CLI fallback; Android currently offers no saved-PIN save control.

## Refresh and validation

1. Audit the source and update `journey-inventory.md` before refreshing screenshots.
2. Capture from a recorded build into the correct platform and locale directory.
3. Update the localized goal steps and callout positions together.
4. Run `python3 scripts/docs/organize-user-guides.py`, then `python3 scripts/docs/organize-user-guides.py --check` and `python3 scripts/docs/validate-user-guides.py` to check localized coverage, native-locale asset paths and references.
5. Build all Docusaurus locales and visually inspect representative desktop and phone pages, including enlarged screenshots. The Website workflow runs the coverage validation before publication.

Per-platform evidence files distinguish actual native captures, live read-only CLI evidence and explicitly instructional terminal examples. Keep technical evidence outside the public how-to prose unless it helps a user make a meaningful choice.

Windows desktop captures are recorded in `windows-evidence.json`; `windows-panel-targets.json` maps capture names to public assets. Every Windows desktop and CLI task must contain numbered `GuideScreenshot` instructions. The validator and navigation tests reject legacy unannotated panels and missing visual steps.

Current refresh: 231 focused task pages and 546 numbered panels. The 8 November settings/stamp refresh captured 54 native images in English, Romanian and Russian across all seven app forms; 48 PNG assets changed and six recaptures were pixel-identical. Per-asset evidence identifies current Debug fixtures and their limits. Native images do not establish real MCP signing or credential-provider authorization.

File-protection guides add 138 focused localized pages and 138 numbered panels, bringing totals to 369 pages and 684 panels. All native file-protection screenshots are captured separately in English, Romanian and Russian. See `file-protection-evidence.json` for provenance. Numbered anchors and connecting lines stay entirely in the reserved image gutters, including enlarged views. Never place annotation pixels over application content.
