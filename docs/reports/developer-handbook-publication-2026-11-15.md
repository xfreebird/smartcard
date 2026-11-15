# Developer handbook publication — 15 November 2026

Published the twelve-chapter developer handbook, dedicated navigation, two local SVG diagrams and English agent exports to the existing website.

- Source commit: `a2bde7e190c568c9bb524b22f9f6a233870a28a9`.
- Website workflow: https://github.com/xfreebird/smartcard/actions/runs/43678660078.
- Build and GitHub Pages deployment: succeeded.
- Developer entry: https://esemnbun.md/docs/developers/overview/.
- Agent reference: https://esemnbun.md/docs/developers/agents/.

The authorized Website workflow passed the website unit tests, guide organization and illustrated-guide validation, Docusaurus build for English/Romanian/Russian, and SEO/discovery export checks. No local app builds or native test suites were run.

## Live readback

Fetched and checked 65 HTTPS URLs after deployment:

- 36 developer HTML pages: twelve chapters at each site locale; the technical handbook remains English.
- Twelve English Markdown exports, with canonical source links and matching inclusion in `llms-full.txt`.
- Nine localized text/JSON discovery files, confirming twelve developer records only in the English catalog and an English developer-entry link from every locale index.
- Three localized download pages and three desktop update feeds.
- Two SVG diagrams, byte-identical to the committed source.

The build/run Markdown export retained its shell comments. The card-protocol page contains the secure-messaging section and the signing-sequence SVG contains the protected PIN-verification step.

| Diagram | SHA-256 |
| --- | --- |
| `architecture.svg` | `c3331761d8c2ac8e4de5049bbba6a6a7e7f6118b9e9ed0f6eb5b04edd7d35e17` |
| `card-sequence.svg` | `8d8de3251deeb860248e1776ab04840b8041b59c2856e9caa7100ec6b764861b` |

Local readback evidence is under `/tmp/esemnbun-developer-docs-live-20261115/`, including `verification.json`; temporary files may be removed by the OS. The repository report records the durable result without copying generated site output.

Browser UI inspection could not run because no browser surface was available. Diagram renders were visually inspected during authoring; that does not establish a full live responsive-layout review. No application release, store submission, physical-card operation or DNS change was performed.
