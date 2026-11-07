# Store and installer builds

Run these actions from GitHub Actions → Run workflow. Use a positive whole-number build number higher than the last store upload. Marketing versions stay `x.y.z`.

| Action | Outputs | Store behavior |
| --- | --- | --- |
| Apple TestFlight | iOS / macOS store builds | Uploads selected platforms to TestFlight; no review submission |
| macOS App Store + TestFlight | Signed sandboxed PKG | Uploads to TestFlight; no review submission |
| Android build + Play testing | Release-signed APK and AAB | Build-only on push; manual `upload_play=true` attempts an artifact-only Play upload without track changes |
| Windows build | MSI, MSIX, checksums, winget manifests | Builds only; does not change Partner Center |
| Release | Public installers | Publishes DMG, APK, MSI and Linux packages; Play artifact and Microsoft Store submission require explicit manual inputs |

Android signing uses the existing `ANDROID_KEYSTORE_*`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` secrets. Play uploads additionally require `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, containing a service-account JSON authorized for `md.esemnbun.app` in Play Console. It is configured in GitHub Actions and backed up in the owner’s offline secrets folder. The service account has app-scoped read and testing-track release access; it has no production release or financial permissions. Authentication and app access were verified through the Play Developer API. Leaving `upload_play=false` builds packages without calling Play. Store listing metadata is not changed by this upload.

Windows Store API credentials are configured as `MSSTORE_TENANT_ID`, `MSSTORE_CLIENT_ID`, `MSSTORE_CLIENT_SECRET` and `MSSTORE_SELLER_ID`. The dedicated **Windows build** action remains build-only. **Release** submits a Windows package only when manually dispatched with `submit_windows_store=true` and all four credentials present; a tag push packages without starting a Partner Center submission. Inspect pending submissions first and supply a build number higher than every existing upload. The **Windows Store credential check** action validates access without changing submissions. Current certification/publication state must be queried rather than inferred from this guide.

Play artifact upload is also opt-in: set `upload_android_play=true` on **Release** or `upload_play=true` on a manual **Android build + Play testing** run. These inputs do not promote a track. Use Play Console for the closed-track release when an active review or track-state error blocks an artifact-only edit. Android version-code tags may be reused only by an explicit rebuild of the same source commit; a different commit cannot take a reserved code.

**Huawei AppGallery draft upload** is manual and requires the exact completed main Android-build run ID with a packaged APK artifact. A Play-upload failure does not invalidate an already packaged APK. The workflow does not select an arbitrary latest build. A review already in progress defers the draft with a visible warning; replacing that review is a separate owner-authorized action. After cancellation, rerun the draft workflow or submit the verified APK with `scripts/appgallery.py`.

For current per-store operations, API limitations and preservation of existing reviews, see the [release skill](../.agents/skills/esemnbun-release-stores/SKILL.md). For machine and VM setup, start with [developer onboarding](../docs/13-developer-onboarding.md).

Artifacts are downloadable from the completed action's summary. Dedicated build actions do not replace public release files; use Release with the appropriate `only` platform when ready to publish installers.

### Play listing permission

The current service account can upload testing builds but cannot commit store listing changes (HTTP 403). The Android lane therefore keeps metadata uploads off by default. Update listings in Play Console using the generated `distribution/google/metadata/android` copy. Only set `PLAY_UPLOAD_METADATA=true` for a credential already authorized to manage store presence. This does not change credential permissions.
