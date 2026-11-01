# Official service shortcuts

`services.json` is the shared list of HTTPS portal entry points. Run
`python3 scripts/export-browser-services.py` after changing it; `--check` verifies
that Swift and Kotlin browser lists match. User-facing generic labels are keys in
`localization/catalog.json`. Selecting a shortcut navigates the current embedded
browser, preserving its native back/forward history.

The list is a navigation aid, not a claim that every operation on every site has
been tested. Authentication and signing still require the normal consent flow.

The bundled icons are the actual artwork declared or displayed by each official website, fetched on 1 November 2026. `icons/sources.json` records source URLs and SHA-256 hashes. MSign uses its 96px favicon; eVMS uses its 180px Apple touch icon. EVO uses its official header SVG mark and MPay its declared favicon SVG, rasterized at 192px with librsvg for native asset use. Original SVG files are retained; artwork was not redrawn. Builds use bundled files without requesting remote icons.

MCabinet and Public Services currently redirect to EVO and declare the EVO icon, so their shortcuts intentionally share its artwork. The website's `<base href="/acasa/">` is honored when resolving EVO assets. Apple assets retain original colors and Android uses untinted Image rendering.

Official references checked on 1 November 2026:

- EVO integrated government portal: https://www.egov.md/ro/node/41043
- MSign and ID-card authentication: https://egov.md/ro/node/40930
- MCabinet and electronic identity: https://egov.md/ro/content/portalul-guvernamental-al-cetateanului
- MCabinet and Public Services use MPass: https://egov.md/ro/node/40873
- MPay authentication: https://mpay.gov.md/Info/TermsAndConditions
- eVMS authentication guidance: https://evms.md/learn
