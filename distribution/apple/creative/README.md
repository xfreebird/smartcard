# Header and Search Results artwork

The localized headline and signing instructions come from `localization/catalog.json/storeCreative`. Both placements pair unaltered iPhone Sign captures for NFC and reader signing inside licensed Apple product frames. The composition keeps the important copy and phone within each placement’s template safe area.

Rebuild the six localized compositions from the guarded fictional capture pack:

```sh
python3 distribution/tools/compose-apple-creative.py --raw /absolute/path/PACK/apple/raw --output /absolute/path/PACK/apple/creative-source
python3 distribution/tools/export-apple-creative.py --source /absolute/path/PACK/apple/creative-source --output /absolute/path/PACK/apple/creative
```

The composer uses native 1320 × 2868 captures from `iphone/01-sign.png` and `iphone/02-reader.png`. The output is opaque RGB at 3840 × 1646 for Header and 3840 × 2560 for Search Results. The manifest records source and output hashes. The tracked prior reader campaign is the previous submission baseline.

The all-platform `create-store-screenshots.py` pipeline now composes and exports this artwork automatically for Apple. It keeps intermediate images under `PACK/apple/creative-source`, using the same native captures as the screenshots. Official frame setup is documented in `distribution/apple/SCREENSHOTS.md`.

Upload and read-verify both placements in each editable iOS localization:

```sh
bundle exec ruby distribution/tools/upload-apple-creative.rb /absolute/path/PACK --replace-existing
```

Without the replacement flag, different existing artwork stops the uploader. With explicit replacement, prior images remain in Asset Library; only their draft placements are replaced. If replacement creation fails, the uploader attempts to restore the previous placement. Versioned reference names include the content hash; paginated lookup reuses identical assets on reruns. Receipts are saved under `PACK/upload`. The uploader never submits assets or the application for review. See [Apple's creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications).
