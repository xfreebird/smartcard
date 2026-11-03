# AppGallery Connect delivery

On 3 November 2026, Android version `0.2.0` (`1793624669`) was submitted and
the portal confirmed **Reviewing**. The APK comes from successful GitHub Actions
run `41547950405`, commit `15adce05d40d6b31dda5548616e810adfdc5bd02`.
SHA-256: `e3eb8ba6696b9977e8ad8c08c55050bf26e44c7261d632c25fb99c5f1e506276`.
The submitted English listing includes the icon and four phone screenshots,
phone/tablet support, privacy links, demo-mode review instructions, and Huawei's
16+ rating for unrestricted browser access. Release is immediate upon approval.

The AppGallery Connect Android record is `119651007` for package
`md.esemnbun.app`. The iOS record is `101653523127320907` for bundle ID
`md.esemnbun.ios`; it is a Huawei developer-services record, not an iOS
marketplace listing.

`listings/{ro,en,ru}.json` is generated from `localization/catalog.json` by
`scripts/prepare-store-metadata.py`. The Android release input is the signed
`dist/android/*.aab` output. Do not use the direct-download publishing mode:
it requires a publicly accessible package URL and has an additional mainland
China distribution constraint for developers outside mainland China.

## CI route

AppGallery Connect provides an API-client flow for Android package upload and
formal release. Once credentials are provisioned, the release workflow should:

1. Build the signed AAB using the existing Android release job.
2. Obtain a short-lived AppGallery access token with an app-scoped API client.
3. Upload the AAB through the Upload Management API, wait for parsing (and AAB
   compilation if App Signing is enabled), then attach the returned package to
   the version.
4. Update localized basic information and visual assets from this directory.
5. Create a formal release only from an explicit `workflow_dispatch` input;
   automated builds must stop after upload and validation.

The implementation must use these repository secrets only in GitHub Actions:

- `HUAWEI_APPGALLERY_CLIENT_ID`
- `HUAWEI_APPGALLERY_CLIENT_SECRET`
- `HUAWEI_APPGALLERY_ANDROID_APP_ID` (value `119651007`)

Create a least-privilege API client with access only to this Android app. Do
not commit credentials, `agconnect-services.json`, or downloaded configuration
files. Provisioning the client and creating its secret are deliberately outside
this repository step because they create persistent third-party access.

Official references: [AppGallery release workflow](https://developer.huawei.com/consumer/en/appgallery),
[Android package upload](https://developer.huawei.com/consumer/en/doc/appgallery-connect-Guides/agcapi-circleci-uploadfile-0000001262051553),
and [formal release requirements](https://developer.huawei.com/consumer/ru/doc/AppGallery-connect-Guides/agcapi-release_app-0000001111685460).
