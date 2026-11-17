# Header and Search Results artwork

The localized headline and signing instructions come from `localization/catalog.json/storeCreative`. Both placements pair unaltered iPhone Sign captures for NFC and reader signing inside licensed Apple product frames. The short central message stays within each placement’s template safe area. Large phone bodies extend into the auxiliary area, with the NFC and reader screens illustrating the two methods. The header reserves space for the App Store navigation controls.

Rebuild the six localized compositions from the guarded fictional capture pack:

```sh
python3 distribution/tools/compose-apple-creative.py --raw /absolute/path/PACK/apple/raw --output /absolute/path/PACK/apple/creative-source
python3 distribution/tools/export-apple-creative.py --source /absolute/path/PACK/apple/creative-source --output /absolute/path/PACK/apple/creative
```

The composer uses native 1320 × 2868 captures from `iphone/01-sign.png` and `iphone/02-reader.png`. The output is opaque RGB at 3840 × 1646 for Header and 3840 × 2560 for Search Results. The manifest records source and output hashes. The tracked `source/` and `current/` folders contain the replacement artwork prepared on 2026-11-17. The owner approved publication; all six files were uploaded and submitted in artwork review `2dd22b15-02ec-4e90-bdd9-f8f77d061cb0`, waiting for Apple review on 2026-11-17. They are not yet the live placements. Prior campaigns remain in git history. The original native screenshots are never retouched.

The all-platform `create-store-screenshots.py` pipeline now composes and exports this artwork automatically for Apple. It keeps intermediate images under `PACK/apple/creative-source`, using the same native captures as the screenshots. Official frame setup is documented in `distribution/apple/SCREENSHOTS.md`.

Upload and read-verify both placements in each editable iOS localization:

```sh
bundle exec ruby distribution/tools/upload-apple-creative.rb /absolute/path/PACK --replace-existing
```

Without the replacement flag, different existing artwork stops the uploader. With explicit replacement, prior images remain in Asset Library; only their draft placements are replaced. If replacement creation fails, the uploader attempts to restore the previous placement. Versioned reference names include the content hash; paginated lookup reuses identical assets on reruns. Receipts are saved under `PACK/upload`. The uploader never submits assets or the application for review. See [Apple's creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications).

## Phone-size review

Review the full export and the actual display scale. The 2026-11-17 owner screenshots from iPhone 11 Pro show that the header uses a horizontally cropped image below the navigation area, while search shows the whole 3:2 canvas. Keep the key message inside Apple’s safe-area bounds, but do not shrink entire phones and explanatory paragraphs into those bounds. The composer asserts localized text bounds and refuses overflow.

See [the comparison and localized previews](../../../../docs/reports/apple-featured-2026-11-17.md). A live 0.2.12 version was confirmed on that date. Standalone creative assets can be reviewed through Asset Library without creating a new app version. Upload with `bundle exec ruby distribution/tools/upload-apple-creative.rb PACK --library-only`; this requires a checksum manifest and writes `PACK/upload/apple-creative-library-receipt.json`. It never creates placements or submits review. Do not combine it with `--replace-existing`.

For an explicitly authorized standalone submission, create an iOS `reviewSubmission`, attach the six `appAssetLibraryImage` relationships through `reviewSubmissionItems`, verify that the submission contains exactly the expected IDs, and submit it. Preserve the submission ID before further mutations and read it back after any timeout. Wait for image state `APPROVED` before replacing the live version's assets through Header and Search Results → Browse Assets. The live-version picker was verified in Firefox; it only lists approved images. Do not delete existing live placements while new assets are still waiting for review.
