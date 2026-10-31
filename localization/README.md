# Shared UI translations

Edit `catalog.json`, the shared source for app UI and localized store copy (`storeMetadata`), then export all targets:

```sh
python3 scripts/localize.py --require-complete
python3 scripts/localize.py --platform apple --require-complete
python3 scripts/localize.py --platform macos --require-complete
python3 scripts/localize.py --platform ios --require-complete
python3 scripts/localize.py --platform android --require-complete
python3 scripts/localize.py --platform windows --require-complete
python3 scripts/localize.py --platform linux --require-complete
python3 scripts/localize.py --check --require-complete
python3 scripts/prepare-store-metadata.py
python3 scripts/prepare-store-metadata.py --check
```

The macOS and iOS export selectors write the shared Apple String Catalog, which each native target compiles.
Each entry has a platform, native key, and Romanian/English/Russian translations. Native keys are retained to
preserve resource references and formatting conventions. Keep `{0}` for Windows, `%1$s` / `%d` for Android,
and `%@` / `%lld` for Apple in all translations. Russian plurals define one/few/many/other.

Outputs are generated: Apple String Catalog (`Localizable.xcstrings`), Android resource XML with generated
per-app language configuration, Windows MRT `.resw`, and the Linux Swift lookup table. Native resource formats
are used by the existing platform toolkits; no hosted translation service is involved. Windows' old
`make-strings.py` delegates to this exporter.

Apple views and runtime messages call generated `L10n.text(.stable_identifier, arguments...)`; the native
String Catalog contains those identifiers. Linux uses the same typed-key pattern with native templates.
Do not use translated display text, arbitrary runtime error messages or compiler-extracted prose as keys.
Do not translate certificate names, document paths, protocol tokens or cryptographic identifiers.

Native format references: [Apple String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog),
[Android per-app languages](https://developer.android.com/guide/topics/resources/app-languages).

Stable identifiers are required for every app lookup. Apple and Linux use generated `L10n.Key` cases;
Android uses `R.string`/`R.plurals` and Windows uses MRT resource IDs. Identifiers describe the intent and
remain unchanged when translated wording changes. Add a new identifier for a different meaning instead of
using translated text as a lookup key. The exporter rejects display-text keys and emits the typed Swift APIs.
