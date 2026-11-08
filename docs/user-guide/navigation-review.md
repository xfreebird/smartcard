# Platform guide navigation review

Review date: 2026-11-08.

## Proposed structure

Replacing each long platform guide with a short overview and focused task pages addresses the difficulty of finding a specific instruction. Preserve the current platform overview URLs and provide localized redirects for former section links.

Use goal-based overview labels: Get started; Sign documents; Check a signature; Find, save and share documents; Sign on a website; Change settings; Get help. Apple automation and command-line automation can be separate advanced topics. Avoid ambiguous sibling destinations named only Results and Documents: either combine them or explicitly distinguish saving a just-completed signature from finding an older saved file.

Group phone and tablet guides visibly under their platform. Keep the device name visible in task titles or breadcrumbs, and constrain next/previous navigation to the same device guide. Label terminal destinations Command line (CLI), subordinate to their operating system, so desktop-app users can distinguish them.

Each task page needs an obvious route back to its device overview and a setup link for users arriving directly from search. The overview's goal links must work without opening the sidebar on a phone. Shared conceptual signing/browser pages should be distinguishable from platform-specific click-by-click instructions.

## Required final checks

- Preserve every illustration and its associated localized instructions across all three languages.
- Inspect representative setup, signing, verification and advanced task pages for coherent boundaries; introductory prerequisites must not be stranded only on the former monolith.
- Verify internal links, device breadcrumbs and next/previous destinations, including CLI boundaries.
- Check old section links against the actual localized heading slugs, including Romanian diacritics and Russian text.
- Ensure the guide landing page and platform overviews expose the task choices clearly on a phone without relying on the sidebar.

Generated task pages were not yet available when this initial design note was written. Implementation and rendered navigation verification remain pending.

## Generated structure audit

The new task pages and navigation components are now present. The split is coherent: task labels use user goals, the Results topic explicitly means verification outcomes, and saved documents have their own clearly named destination. Task pages show platform/device context in their titles and link back to the overview and setup instructions. CLI destinations are explicitly named and nested under their operating system. Shared concepts are grouped separately.

Source checks passed:

- 74 focused task pages in each language, with 161 screenshot panels per language: all 483 panels remain represented.
- Every explicit next/previous destination stays within the same platform/device guide.
- All 489 legacy anchor mappings point to headings produced by the actual heading-slug library in their localized destination pages, including Romanian and Russian headings.
- The directory component offers localized task search, device filtering, explicit no-results text and device/task cards. Search tolerates Romanian diacritics and includes common feature terms.

Two completion issues were reported to the implementation owner at audit time:

1. The Romanian and Russian Docusaurus sidebar translation files still contain only `version.label`. The new hard-coded sidebar category labels need localized category entries so English navigation headings do not remain in otherwise translated guides.
2. The main `website/docs/platforms.md` landing page still contains the former device table and does not mount `GuideDirectory`. Connect the new directory on the landing page and its translations so global task search and device cards are available from the main guide entry point.

These may be in-flight edits. The focused task-page structure itself has no further major source issue in the sampled pages. Rendered mobile navigation, locale routing, redirects and production build validation remain with the main verification pass.

## Final completion checks

The global directory is mounted in all three languages and linked from the main Guides navigation and documentation footer. Localized sidebar categories were confirmed in the Romanian production HTML. The full three-language production build and SEO checks passed. Browser review confirmed the desktop directory/sidebar, 320px task search, and redirect of a former Mac signing section bookmark. Automated checks now enforce all 222 task routes, 483 preserved panels, same-device pagination and 489 localized bookmark targets.
