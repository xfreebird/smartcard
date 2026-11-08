# Illustrated user documentation

The public entry point is the website's `/docs/platforms/` route, available in English, Romanian and Russian. Guides live in `website/docs/platforms/` and the corresponding Docusaurus locale directories. Documentation images live under `website/static/img/guide/<platform>/<locale>/`.

## Editorial and capture rules

- Start with a user goal, state prerequisites and the expected result, then show the numbered actions on the native screen.
- Use `GuideScreenshot` for both numbered markers and the matching accessible ordered list. Coordinates are percentages of the original image; inspect them in the rendered page. Tapping a screenshot opens an enlarged view with its callouts.
- Capture native translated interfaces, including actual phone and tablet layouts. Do not stretch a phone screen to represent a tablet.
- Use only fictional identities, filenames and sample documents. Debug capture mode must isolate hardware and hide the demo banner; ordinary app demo mode remains labelled.
- Record provenance, binary identity, locale, device form and capture limitations in each platform evidence manifest. A mock successful screen does not establish physical-card signing, saved-credential access or system-service behavior.
- Terminal examples are instructional illustrations, labelled in adjacent prose, with copyable commands. Do not imply they show an operation that was not exercised. Never include PIN values in a command, screenshot, guide or log.
- Document current platform and distribution differences explicitly. In particular, Windows normal CLI coverage differs from Windows MCP; desktop approval UI is macOS-only; Android currently offers no saved-PIN save control.

## Refresh and validation

1. Audit the source and update `journey-inventory.md` before refreshing screenshots.
2. Capture from a recorded build into the correct platform and locale directory.
3. Update the localized goal steps and callout positions together.
4. Run `python3 scripts/docs/validate-user-guides.py` to check localized coverage, native-locale asset paths and references.
5. Build all Docusaurus locales and visually inspect representative desktop and phone pages, including enlarged screenshots. The Website workflow runs the coverage validation before publication.

Per-platform evidence files distinguish actual native captures, live read-only CLI evidence and explicitly instructional terminal examples. Keep technical evidence outside the public how-to prose unless it helps a user make a meaningful choice.
