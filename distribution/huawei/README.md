# AppGallery Connect delivery

On 3 November 2026, Android version `0.2.0` (`1793624669`) was submitted and
the portal confirmed **Reviewing**. The APK comes from successful GitHub Actions
run `41547950405`, commit `15adce05d40d6b31dda5548616e810adfdc5bd02`.
SHA-256: `e3eb8ba6696b9977e8ad8c08c55050bf26e44c7261d632c25fb99c5f1e506276`.
The submitted English listing includes the icon and four phone screenshots,
phone/tablet support, privacy links, demo-mode review instructions, and Huawei's
16+ rating for unrestricted browser access. Release is immediate upon approval.

On 7 November 2026, the owner requested replacement of that pending review.
The 0.2.0 review was canceled in AppGallery Connect and signed 0.2.5 APK
`1793624678` (SHA-256 `bdc18266b8f30f986dd5fff46bcbe5af65ec558c6499bfae2725c6bc19cd2311`)
was attached and submitted. The read-only API confirms `releaseState=4` for the
new build: reviewing, not yet publicly available.

The AppGallery Connect Android record is `119651007` for package
`md.esemnbun.app`. The iOS record is `101653523127320907` for bundle ID
`md.esemnbun.ios`; it is a Huawei developer-services record, not an iOS
marketplace listing.

`listings/{ro,en,ru}.json` is generated from `localization/catalog.json` by
`scripts/prepare-store-metadata.py`. The Android release input is the signed
APK from the latest successful main Android workflow. Do not use the direct-download publishing mode:
it requires a publicly accessible package URL and has an additional mainland
China distribution constraint for developers outside mainland China.

## CI route

`.github/workflows/huawei-appgallery.yml` is separate from Android compilation.
Dispatch it with the exact completed main `Android build + Play testing` run ID
that contains the packaged APK artifact. A later Play-upload failure does not
invalidate that artifact.
It validates the selected artifact's package/version, uploads the APK, waits for
parsing and attaches a draft. It does not submit or cancel reviews. An active
review defers the draft with a warning instead of failing the build. Review
replacement and submission are deliberate separate steps; the app's listing
and release settings are retained.

`scripts/appgallery.py --check` verifies authentication without mutations.
Publishing requires `--apk PATH --version-code INTEGER`. The app ID is fixed to
`119651007`. Credentials are supplied through the repository secret
`HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON`; a protected offline copy lives in
`Desktop/eSemnBun-secrets/huawei/HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON.json`.
Huawei publishing endpoints require a developer-level service account: the
project-level account was rejected with HTTP 403 during live validation.
Never commit the private key or log signed JWTs and upload authorization URLs.

Official references: [AppGallery release workflow](https://developer.huawei.com/consumer/en/appgallery),
[Android package upload](https://developer.huawei.com/consumer/en/doc/appgallery-connect-Guides/agcapi-circleci-uploadfile-0000001262051553),
and [formal release requirements](https://developer.huawei.com/consumer/ru/doc/AppGallery-connect-Guides/agcapi-release_app-0000001111685460).
