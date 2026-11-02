# Header and Search Results artwork

The localized marketing headline, feature highlights, three usage steps and key-privacy message come from `localization/catalog.json/storeCreative`. The phone screen and ID-card face use exact native eSemnBun captures. The phone uses Apple's official licensed frame. Only the empty white reader/adapter cutout is a separate product illustration; owner photos are hardware references and are not included. The cable is drawn in an orthographic image plane: it exits the USB-C plug straight downward, then curves right. The printed card's contact chip is fully covered by the reader; composition checks enforce this.

Rebuild the six localized, placement-specific compositions from the guarded fictional capture pack:

```sh
python3 distribution/tools/compose-apple-creative.py --raw /absolute/path/PACK/apple/raw
python3 distribution/tools/export-apple-creative.py --output /absolute/path/PACK/apple/creative
```

The composer uses `02-batch.png` for the phone screen and the IDCardFace crop `(120, 540, 1200, 1207)` from `01-sign.png` for the physical card. It retains the app's typography, colors, avatar and field values; no app or card text is redrawn. Input dimensions, frame hashes and reader occlusion are checked. Source hashes and crop coordinates are recorded in `source/composition-manifest.json`, also copied into the export. Header sources are opaque RGB 3840 × 1646 images; Search Results sources are opaque RGB 3840 × 2560 images. The exporter preserves each native aspect ratio rather than cropping one source for both Store placements.

The all-platform `create-store-screenshots.py` pipeline now composes and exports this artwork automatically for Apple. It keeps intermediate images under `PACK/apple/creative-source`, using the same native captures as the screenshots. Official frame setup is documented in `distribution/apple/SCREENSHOTS.md`.

Upload and read-verify both placements in each editable iOS localization:

```sh
bundle exec ruby distribution/tools/upload-apple-creative.rb /absolute/path/PACK --replace-existing
```

Without the replacement flag, different existing artwork stops the uploader. With explicit replacement, prior images remain in Asset Library; only their draft placements are replaced. If replacement creation fails, the uploader attempts to restore the previous placement. Versioned reference names include the content hash; paginated lookup reuses identical assets on reruns. Receipts are saved under `PACK/upload`. The uploader never submits assets or the application for review. See [Apple's creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications).
