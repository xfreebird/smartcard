# Store delivery preparation

`stores.json` contains non-secret platform identities and the observed portal state (30 October 2026).
`storeMetadata` in `localization/catalog.json` is the editable listing source; `metadata/{ro,en,ru}.json` contains generated normalized exports. Run `python3 scripts/prepare-store-metadata.py`
to export per-store layouts; `--check` validates required fields and export drift without writing. No command uploads or submits anything.

The generated `apple/ios` and `apple/macos` directories follow fastlane deliver metadata folder naming.
`google/metadata/android` follows supply's listing structure. `microsoft/listings` and `huawei/listings`
contain JSON listing payload sources, pending each portal's import/API mapping. Their credentials are never
copied from the owner's Desktop secret folder into this repository.

The screenshot source is `~/Desktop/esemnbun-screenshots/`; only fictional data captures may be used for listings.
Review every screenshot and release note against the actual release binary before an upload.

Remaining store prerequisites are explicit: replace the owner-requested example.invalid support/privacy placeholders; Apple signed sandbox runtime and
App Store record verification; Google app record/declarations; Huawei identity verification; Microsoft refreshed
package upload/listings. Owner-provided legal declarations must be reviewed in each portal; no agreement or
certification submission is performed by these scripts. Store assets must meet the target portal's current
requirements at upload time. The same Android package and upload certificate are used for Play and Huawei;
no Google Play Services dependency is needed by this app.

The updated `docs/privacy-policy.txt` must be published at the real privacy URL before submission. Portal privacy forms must be reviewed before release.
