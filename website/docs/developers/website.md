---
title: Website development and publishing
description: Edit the Docusaurus documentation, maintain diagrams and machine-readable exports, verify content and deploy the existing GitHub Pages website.
---

The website source is `website/`. It uses Docusaurus 3 and publishes static output from `website/pages/` through the `Website` GitHub Actions workflow. The production configuration uses `https://esemnbun.md/`; English is at the root, Romanian under `/ro/` and Russian under `/ru/`.

## Work locally

```sh
cd website
npm ci
npm start
```

Open the local URL printed by Docusaurus. The developer entry is `/docs/developers/overview/`. The production check/preview path is:

```sh
node --test tests/*.test.mjs
npm run build
npm run verify:seo
npm run serve
```

`build` emits all configured locales into `pages/`. `serve` previews that output; it does not rebuild edited sources. Do not commit `pages/`, dependency caches or local preview state.

## Content map

| Content | Location |
| --- | --- |
| Developer handbook | `website/docs/developers/` |
| User guides | `website/docs/platforms/` and localized copies under `website/i18n/` |
| Sidebar structure | `website/sidebars.js` |
| Navigation and site configuration | `website/docusaurus.config.js` |
| React page/component text | `website/src/i18n/catalog.json` and `useText` |
| Theme/navigation translations | `website/i18n/ro` and `website/i18n/ru` |
| Site palette | `website/src/css/palette.css`, `custom.css` |
| Diagram assets | `website/static/img/developers/` |
| Diagram authoring source | `website/scripts/generate-developer-diagrams.py` |
| Agent export selection | `website/src/data/search-discovery.json` |
| Export generator | `website/plugins/search-discovery.cjs` |
| Download metadata | `website/src/data/release.json` |

Each handbook page uses Markdown frontmatter with a title and description, a short explanation, concrete examples and source pointers. Relative `.md` links connect chapters. The dedicated developer sidebar keeps the learning path separate from end-user tasks. Docusaurus supports this with [multiple sidebars](https://docusaurus.io/docs/sidebar/multiple-sidebars).

Generated platform indexes have their own authoring inputs under `docs/user-guide/content/`. Do not hand-edit generated indexes and then overwrite them with a guide generator.

## Diagrams and accessibility

The layered architecture, signing sequence and release pipeline are local SVGs, with no remote diagram service or browser-side renderer dependency. Regenerate them from the repository root after editing their authoring script:

```sh
python3 website/scripts/generate-developer-diagrams.py
```

Keep SVG titles/descriptions, meaningful Markdown alternative text, a full-size link and a nearby textual explanation. The drawings show logical responsibilities and ordering, not a packet capture. Inspect label placement and readability after regeneration, including narrow screens. Public images must never contain a real PIN, live keys or a person's certificate/identity details.

## Documentation for agents

`search-discovery.cjs` creates these from the same public Markdown used for HTML:

- `llms.txt`: a compact document index with Markdown and HTML links.
- `llms-full.txt`: selected documents joined into one plain-text reference.
- `discovery.json`: a site-specific document catalog, not an MCP endpoint.
- `markdown/<document-id>.md`: individual plain-Markdown alternatives.

Existing product references require real translations. The English developer handbook has a separate `englishDocuments` list. Its full text is exported in the English catalog, and every language's index links to the English developer entry. Localized HTML may show the English fallback; it is not advertised as a translated technical reference.

Update the document list when adding a chapter. Avoid a second hand-maintained copy of the same protocol or release claims. The [agent page](agents.md) supplies a task/source/check map, not hidden instructions with authority over a user's task.

## Run the content verification batch

From the repository root:

```sh
python3 scripts/docs/organize-user-guides.py --check
python3 scripts/docs/validate-user-guides.py
cd website
node --test tests/*.test.mjs
npm run build
npm run verify:seo
```

Review the rendered pages, sidebar, navigation, code-block copying, links and diagrams. Broken-link failure is enabled. The SEO check also compares the export catalog and plain-text bodies with their rendered pages. A successful build validates rendering/link structure, not the factual accuracy of a protocol claim.

## Publish with the existing workflow

Push the reviewed source to the intended remote branch. A matching push to `main` triggers `website.yml`; pull requests build without deployment. Successful Release and CLI-package workflow completion can also refresh the site. To intentionally redeploy main:

```sh
GH_HOST=github.com gh workflow run website.yml -R xfreebird/smartcard --ref main
GH_HOST=github.com gh run list -R xfreebird/smartcard --workflow website.yml --limit 10
# Select the run whose source revision matches the intended deployment.
GH_HOST=github.com gh run watch RUN_ID -R xfreebird/smartcard --exit-status
```

The deployment job requires `ENABLE_PAGES_DEPLOYMENT=true` and uses the `github-pages` environment. It uploads `website/pages` as a Pages artifact and deploys through GitHub's Pages action. Domain configuration is separate; an ordinary documentation update does not require DNS changes. See [GitHub's publishing-source documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site) for the hosting mechanism.

On non-PR runs, the workflow reads the latest stable GitHub release and regenerates download metadata and update feeds. It checks release asset SHA-256 digests and stages the installers under the public `/release-downloads/` directory. The signed package feeds are staged at `/packages/`. Both directories are shared by the three website locales. The latest available installer is selected per package and architecture, so an omitted platform can keep its previously published version. It uses Node 22 and Python 3.12+. The public website must contain only deliberately selected public content even when the source repository is private; do not export the internal `docs/`, `re/` or reports directory wholesale.

## Refresh native screenshots

Use synthetic cards and sample documents in the native applications. The Mac, Linux and Windows landing sequences use three aligned reader states in each appearance. iPhone and Android add the NFC path before the USB connection and card-insertion scenes. When replacing captures, check the scene manifests and update `website/src/data/screenshotRevision.json` so the browser fetches the replacements. Guide callouts originate in the localized sources under `docs/user-guide/content/`. Regenerate the pages after aligning those points with the new captures.

## Refresh release metadata locally

For an authorized release refresh, from the repository root:

```sh
GH_HOST=github.com gh api repos/xfreebird/smartcard/releases/latest > /tmp/esemnbun-release.json
python3 website/scripts/generate-downloads.py /tmp/esemnbun-release.json
# Use the actual release tag/version from that response.
python3 website/scripts/generate-update-manifests.py \
  --version ACTUAL_RELEASE_VERSION --release-data website/src/data/release.json
```

Review generated changes. Do not invent store availability or assume a store version equals a standalone version. Replacing an installer under the same URL changes its bytes/hash and may not trigger clients that compare only marketing versions.

## Confirm publication and recover

Check the final **deployment** job, then open the live developer entry, both diagrams, the agent page, `llms.txt`, a developer Markdown export, downloads and affected `/updates/` feeds over HTTPS. Confirm content matches the intended revision. Repeat relevant checks under `/ro/` and `/ru/` for translated navigation and English handbook fallback. Fetch installer links without GitHub authentication and compare their hashes with the corresponding release assets.

If a build fails, fix its reported source/link/generator error and rerun from the intended revision. If deployment is skipped, inspect the repository variable/event condition. If hosting is unavailable, distinguish a local successful build from a deployed page. To roll back content, revert the specific website change through the normal reviewed source workflow and deploy that revision; avoid resetting unrelated release metadata or app source.
