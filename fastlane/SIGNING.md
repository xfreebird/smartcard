# fastlane: Apple signing for eSemnBun (SIGNING.md; fastlane regenerates README.md)

Team **H86U5Z8HYB** (the owner's personal account, D-15). Certificates and profiles are kept by
[match](https://docs.fastlane.tools/actions/match/) in `github.com/xfreebird/fastlanecerts` (branch `master`),
encrypted with `MATCH_PASSWORD`. Nothing secret is in this repository: every lane reads its credentials from the
environment, and the owner's copies live outside git (see docs/11 "Signing secrets").

| Variable | Used for |
|---|---|
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | App Store Connect API key (key `U629G2MR4K`) |
| `ASC_KEY_PATH` (local file) or `ASC_KEY_P8` (CI, key content) | the `.p8` itself |
| `MATCH_PASSWORD` | decrypts the match storage |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 `user:token` with **write** access to fastlanecerts (local `certs` / imports only; reading is anonymous) |
| `MATCH_KEYCHAIN_NAME`, `MATCH_KEYCHAIN_PASSWORD` | optional local keychain for the identities (CI uses `setup_ci`) |
| `ESEMNBUN_SIGNING_KEYCHAIN` | optional existing isolated keychain path passed explicitly to archive signing |
| `BUILD_NUMBER` | `CFBundleVersion` / Android `versionCode` (positive integer). Android publish CI uses UTC epoch seconds by default so the value remains above previously published builds; an explicit higher `build_number` can override it. Marketing versions stay `x.y.z`. |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Android Publisher service account; required by Android release CI to publish a signed AAB to testing tracks |
| `PLAY_CLOSED_TRACK` | optional GitHub Actions variable naming the closed-testing track; defaults to Play's standard `alpha` closed track |

```bash
bundle install
bundle exec fastlane certs            # owner, local: App IDs + iOS App Store/development/ad hoc certs and profiles
bundle exec fastlane import_developer_id cer:~/Downloads/developerID_application.cer key:<developer-id.key>
bundle exec fastlane mac_signing      # installs the Developer ID identity (CI: temporary keychain)
bundle exec fastlane ios_release      # dist/ios: -appstore.ipa (+ TestFlight upload in CI) and -adhoc.ipa
bundle exec fastlane ios_release upload:false   # local: both IPAs, no upload
bundle exec fastlane android_testing             # signed AAB → internal, then closed testing (requires Play credentials)
bundle exec fastlane nuke_all         # DESTRUCTIVE, local only: revoke all certificates, delete all profiles
```

Android CI runs for Android/release automation changes merged to `main`, and on explicit Android release
workflows. Each newly built AAB first becomes available to internal testers, then the same version code is
promoted to the configured closed-testing track. Neither path publishes to production.

Notes from setting it up (2026-10-25):

* **Developer ID can't be created with an API key** ("This operation can only be performed by the Account Holder").
  Make it in the portal from a CSR (Certificates → + → Developer ID Application, G2 Sub-CA) and import it with
  `import_developer_id`; macOS signing needs no provisioning profile (unsandboxed, smart-card entitlement only).
* `match_nuke` 2.241 fails on `developer_id` ("Unknown cert type"), so `nuke_all` leaves that type out.
* The project also has macOS targets and only shared schemes are visible to gym: `ios_release` pins
  `generic/platform=iOS` and the `eSemnBun-iOS` scheme is shared.
* Manual signing is applied to the iOS target only (`update_code_signing_settings`) and the project file is restored
  afterwards; command-line overrides would also hit the SwiftPM package targets.
* TestFlight: `upload_to_testflight` with the API key, `skip_waiting_for_build_processing` (the job ends when the
  binary is uploaded) and `skip_submission`. Export compliance is answered by `ITSAppUsesNonExemptEncryption = NO` in
  `apple/Apps/iOS/Info.plist` (owner's declaration: only exempt encryption, i.e. OS TLS plus authentication/signature
  cryptography with the ID card), so builds don't stop at "Missing Compliance". The upload needs
  `apple/Apps/iOS/PrivacyInfo.xcprivacy` (UserDefaults, reason CA92.1).
* Ad hoc: the same archive re-signed with "match AdHoc md.esemnbun.ios". A new device needs registering in the
  portal, then `bundle exec fastlane new_devices` locally (API key, writes to match), then a new build.

The iOS share extension uses `md.esemnbun.ios.share` and the shared App Group
`group.md.esemnbun.shared`. Before producing signed builds, enable App Groups for
both iOS identifiers in the Apple Developer portal, associate this group with
both identifiers, and regenerate their development, App Store and ad hoc profiles
with `fastlane certs force:true`. The release lane reads and exports profiles for both targets.

Configured on 1 November 2026: both identifiers have App Groups enabled and are
associated with `group.md.esemnbun.shared`. App Store, development and ad hoc profiles
for both targets were regenerated and synchronized to the encrypted match repository.

Validation on 1 November 2026: `ios_release upload:false` fetched the profiles
read-only from match, archived successfully, and exported both App Store and ad hoc IPAs.
The main app and embedded extension in both exports passed strict signature checks;
each embedded provisioning profile and signed entitlement contains the shared App Group.
The exports are under `dist/ios/`; no build was uploaded.

macOS has separate distribution lanes. `bundle exec fastlane mac_signing` fetches the
Developer ID identity for the full Desktop DMG. `bundle exec fastlane mac_store_certificates`
creates the sandboxed app's Mac App Store profile and installer identity in encrypted match
storage (owner only; `force:true` refreshes the profile). CI runs
`bundle exec fastlane mac_store_release`, which reads match without changing it, archives
`eSemnBun-macOS-AppStore` / `AppStore Release`, and exports
`dist/macos-app-store/eSemnBun-AppStore.pkg`. It never uploads or submits the package.
For an isolated local signing keychain set the match `MATCH_KEYCHAIN_NAME` and
`MATCH_KEYCHAIN_PASSWORD` variables, plus `ESEMNBUN_SIGNING_KEYCHAIN` for codesign.
The existing Developer ID lane and desktop packaging remain independent.

Export-compliance default (1 November 2026): the owner selected the exempt response,
“None of the algorithms mentioned above.” Both iOS/iPadOS and macOS app plists, plus
the iOS share extension, declare `ITSAppUsesNonExemptEncryption = NO`. This means
no **non-exempt** encryption; it does not mean the app has no cryptographic functions.
The macOS distribution verifier checks that the processed bundle retains this Boolean.
App Store Connect build 100 was read back for both apps: `usesNonExemptEncryption=false`.
The iOS build already declared it; the existing macOS build's unset value was updated
through Apple's API. Future uploads carry the declaration in their binaries.
