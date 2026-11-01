# macOS distribution variants

Two shared schemes use the same macOS target and source:

| Scheme | Run configuration | Archive configuration | Distribution |
| --- | --- | --- | --- |
| `eSemnBun-macOS-Desktop` | `Debug` | `Release` | Full desktop app, Developer ID signing and notarized DMG |
| `eSemnBun-macOS-AppStore` | `AppStore Debug` | `AppStore Release` | Sandboxed app, Apple Distribution signing and App Store package |

The original `eSemnBun-macOS` scheme remains a compatible alias for the desktop build. Both variants use the existing `md.esemnbun.mac` identifier and therefore share the application identity; install one distribution at a time.

The Store configurations define `APP_STORE`, use CryptoTokenKit for smart-card access and use `Configuration/AppStore.entitlements`. The direct-distribution reader watcher and launch agent are excluded from the Store bundle, including stale outputs when reusing build directories. Store signing results stay inside its container and use a native Export action to save to a chosen location. The desktop configuration keeps the reader watcher, browser connection and normal file-output behavior.

The Store bridge retains normal TLS validation, allowed-origin checks and consent/PIN authorization. Arbitrary filesystem bridge routes are disabled. The bundled vendor localhost identity remains a distribution/review consideration; network entitlements permit the listener but do not imply Store approval.

Feature availability:

| Feature | Desktop | App Store |
| --- | --- | --- |
| Sign and verify documents, activity, language/theme, demo mode, saved PINs | Yes | Yes |
| Smart-card transport | PC/SC | CryptoTokenKit |
| Embedded browser, loopback HTTPS bridge and bundled localhost identity | Yes | Yes, data-only signing routes |
| Separate reader-insertion watcher | Yes | Omitted |
| Reader detection while app is running | Yes | Yes |
| Output beside original file | Yes | Container output plus Save As export |
| Direct-distribution vendor termination | Yes | Disabled |

Build locally without distribution credentials:

```sh
xcodebuild -project apple/eSemnBun.xcodeproj -scheme eSemnBun-macOS-Desktop -configuration Debug build
xcodebuild -project apple/eSemnBun.xcodeproj -scheme eSemnBun-macOS-AppStore -configuration 'AppStore Debug' build
```

Package the full desktop version:

```sh
MACOS_SIGN_IDENTITY='Developer ID Application' scripts/package-macos.sh
```

Package the Store version using match signing assets:

```sh
bundle exec fastlane mac_store_release
```

Or use installed signing assets directly:

```sh
MAC_APP_STORE_PROFILE='match AppStore md.esemnbun.mac' apple/scripts/package-app-store.sh
```

The Store script archives `AppStore Release` and exports locally; it does not upload. `APPLE_TEAM_ID` overrides the configured team, `MAC_APP_STORE_PROFILE` selects the provisioning profile, and `MAC_APP_STORE_OUTPUT` selects the output directory (default `dist/macos-app-store`). `AppStore.xcconfig` remains available as a compatibility override for external archive tooling; the shared Store scheme does not require it.

The macOS target bundles `Apps/macOS/PrivacyInfo.xcprivacy` declaring app-owned UserDefaults use (CA92.1). A successfully signed export is a build artifact, not App Store approval. Hardware signing, keychain access and export should also be checked on installed signed builds before submission.
