# Store badge sources

## Romanian Mac App Store

- Apple artwork: `Download_on_the_Mac_App_Store_Badge_RO_RGB_blk_100317.svg`, retained unchanged as `mac-app-store-ro.svg` on 20 November 2026. Visible text: “Descărcați de pe Mac App Store”.
- The Apple badge API's `download-on-the-mac-app-store/black/ro-ro` endpoint silently returns the English artwork. Do not replace this asset with that response or the iOS badge.
- Retrieved from [Psiphon's pinned copy](https://github.com/Psiphon-Inc/psiphon-website/blob/13d1e3fa96d01a0adfa04002c4aa2513f94f2ff4/src/files/images/macos/mac-app-store.ro.svg), cross-checked against the [badge bundle in ProxyBuilder](https://github.com/fcapria/ProxyBuilder/blob/991a83955d1111555db3fdd8ed52f29da559e784/App%20Store%20buttons/Download-on-the-Mac-App-Store/RO/Download_on_Mac_App_Store/Black_lockup/SVG/Download_on_the_Mac_App_Store_Badge_RO_RGB_blk_100317.svg). Both files are byte-identical.
- SHA-256: `3c94850e7d3944db3acc24555267d109d4f370b3c49ab7dcfc8223583d0cfbb5`.
- [Apple badge guidance](https://developer.apple.com/app-store/marketing/guidelines/).

## Huawei AppGallery

- Original SVG: https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/phones/p40-pro/images/security/app-gallery.svg
- Retrieved 14 November 2026, retained unchanged as appgallery-en.svg.
- Official badge guidance: https://developer.huawei.com/consumer/en/doc/appgallery-connect-Guides/agdlink-getlink-agc-0000001164321881
- The English badge is used as the fallback for Romanian and Russian. The link targets the eSemnBun listing.

## Google Play (README)

- `google-play-en-cropped.png` is `google-play-en.png` with Google's 41 px transparent margin removed (564 × 168), so the badge lines up with the other 40 px store badges in the repository README, where CSS cannot compensate. The website keeps the padded original and offsets it in `custom.css`.
