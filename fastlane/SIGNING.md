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
| `BUILD_NUMBER` | `CFBundleVersion` of the IPA (CI: `<run number>.<attempt>`, unique for TestFlight) |

```bash
bundle install
bundle exec fastlane certs            # owner, local: App IDs + iOS App Store/development/ad hoc certs and profiles
bundle exec fastlane import_developer_id cer:~/Downloads/developerID_application.cer key:<developer-id.key>
bundle exec fastlane mac_signing      # installs the Developer ID identity (CI: temporary keychain)
bundle exec fastlane ios_release      # dist/ios: -appstore.ipa (+ TestFlight upload in CI) and -adhoc.ipa
bundle exec fastlane ios_release upload:false   # local: both IPAs, no upload
bundle exec fastlane nuke_all         # DESTRUCTIVE, local only: revoke all certificates, delete all profiles
```

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
  binary is uploaded) and `skip_submission`. Builds show "Missing Compliance" until the encryption question is answered
  in App Store Connect (or `ITSAppUsesNonExemptEncryption` is set in Info.plist). The upload needs
  `apple/Apps/iOS/PrivacyInfo.xcprivacy` (UserDefaults, reason CA92.1).
* Ad hoc: the same archive re-signed with "match AdHoc md.esemnbun.ios". A new device needs registering in the
  portal, then `fastlane match adhoc --force_for_new_devices` locally, then a new build.
