# Header and Search Results artwork

The three localized product illustrations show an iPhone running the signing flow, a wired USB-C connection, and the slim white bit4id reader holding a fictional identity card. The physical contact chip is covered by the reader. Owner photos were hardware references only; they are not part of these assets.

These are promotional illustrations, separate from the native app screenshot sets. Source artwork is retained in `source/{en,ro,ru}.png`. Export opaque universal 5244 × 2950 PNGs with:

```sh
python3 distribution/tools/export-apple-creative.py --output /absolute/path/PACK/apple/creative
```

Upload and read-verify the two placements in each editable iOS localization with existing ASC credentials:

```sh
bundle exec ruby distribution/tools/upload-apple-creative.rb /absolute/path/PACK
```

The uploader queries Apple's live placement policies, reuses matching images, refuses to replace different existing artwork, and saves receipts under `PACK/upload`. It does not submit assets or the application for review. See [Apple's creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications).
