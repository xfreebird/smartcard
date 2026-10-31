# Mac App Store candidate

`AppStore.xcconfig` enables the sandbox and switches the app's card transport to CryptoTokenKit, using the smart-card entitlement. The normal desktop build keeps its existing transport. Archive with:

```sh
xcodebuild -project apple/eSemnBun.xcodeproj -scheme eSemnBun-macOS -configuration Release -xcconfig apple/Configuration/AppStore.xcconfig -archivePath dist/eSemnBun-AppStore.xcarchive archive
```

Signing uses the owner's installed Apple Distribution identity with manual archive signing and any provisioning profile required by its enabled capabilities. This is a candidate configuration, not an approved or submission-ready binary. Verify smart-card access, loopback HTTPS, PIN keychain access and output export in a signed sandboxed build. The sandboxed variant stores results in its container and offers a native Export action instead of writing next to an arbitrary imported file. No account secrets belong in this directory.

`apple/scripts/package-app-store.sh` archives and exports locally using installed distribution signing assets.
Set `APPLE_TEAM_ID` to override the configured team, and optionally `MAC_APP_STORE_PROFILE` for an existing manual
profile. It does not create/revoke profiles or upload the result. `MAC_APP_STORE_OUTPUT` selects the local output
folder (default `dist/macos-app-store`). A local universal archive attempt on 31 October compiled and reached codesign, which requested the owner’s login-keychain password for private-key access. No password was supplied. Distribution-signed archive/export remain pending that approval. An isolated ad-hoc signed Store Release copy launched successfully with the configured sandbox entitlements and a separate QA bundle identifier/container; actual process sandbox status was verified. Hardware signing, keychain, export and loopback HTTPS still require signed release acceptance.

The macOS target bundles its own `Apps/macOS/PrivacyInfo.xcprivacy` declaring app-owned UserDefaults use
(CA92.1), separately from the iOS target’s manifest. The direct-distribution watcher is excluded from the
Store product.
