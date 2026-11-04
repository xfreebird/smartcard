# Store and installer builds

Run these actions from GitHub Actions → Run workflow. Use a positive whole-number build number higher than the last store upload. Marketing versions stay `x.y.z`.

| Action | Outputs | Store behavior |
| --- | --- | --- |
| Apple TestFlight | iOS / macOS store builds | Uploads selected platforms to TestFlight; no review submission |
| macOS App Store + TestFlight | Signed sandboxed PKG | Uploads to TestFlight; no review submission |
| Android build + Play draft | Release-signed APK and AAB | Optional internal-track draft upload; no rollout |
| Windows build | MSI, MSIX, checksums, winget manifests | Builds only; does not change Partner Center |
| Release | Public installers | Publishes DMG, APK, MSI and Linux packages |

Android signing uses the existing `ANDROID_KEYSTORE_*`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` secrets. Play uploads additionally require `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, containing a service-account JSON authorized for `md.esemnbun.app` in Play Console. It is configured in GitHub Actions and backed up in the owner’s offline secrets folder. The service account has app-scoped read and testing-track release access; it has no production release or financial permissions. Authentication and app access were verified through the Play Developer API. Leaving `upload_play=false` builds packages without calling Play. Store listing metadata is not changed by this upload.

The Windows submission is currently in certification. The build action deliberately has no Partner Center mutation or submission step. MSIX remains a CI artifact for later Store submissions; users download MSI. Automatic Partner Center uploads require its API credentials and a separate implementation that checks submission state before creating or modifying a draft; neither is currently configured.

Artifacts are downloadable from the completed action's summary. Dedicated build actions do not replace public release files; use Release with the appropriate `only` platform when ready to publish installers.

### Play listing permission

The current service account can upload testing builds but cannot commit store listing changes (HTTP 403). The Android lane therefore keeps metadata uploads off by default. Update listings in Play Console using the generated `distribution/google/metadata/android` copy. Only set `PLAY_UPLOAD_METADATA=true` for a credential already authorized to manage store presence. This does not change credential permissions.
