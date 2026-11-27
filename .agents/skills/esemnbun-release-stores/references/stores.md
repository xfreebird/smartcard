# Store operations and lessons

These procedures describe the November 2026 setup. Verify current account/API state and checked-in lanes before mutations; past review states are not current truth.

## Apple

- iOS bundle `md.esemnbun.ios`, app 6826865290; macOS `md.esemnbun.mac`, app 6829451042. Team H86U5Z8HYB. Share extension has its own profile.
- `ios_release` and `mac_store_release` use match and App Store Connect API credentials; normal CI is read-only for certificate/profile storage. `upload:true` sends the IPA/PKG to TestFlight and skips review submission/processing wait.
- Credentials are `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (local file alternative: `ASC_KEY_PATH`), `MATCH_PASSWORD` and authorized access to match storage. Never use a login password as CI credentials.
- Use short-lived ES256 JWTs for App Store Connect API. Query builds via `/v1/builds?filter[app]=APP_ID&sort=-uploadedDate` and poll processing; `sort` is not accepted on the app's relationship `/apps/ID/builds` endpoint.
- A new binary may take minutes to appear after an upload job succeeds. Check processingState VALID and the expected build number before selecting it.
- For an authorized resubmission, inspect current reviewSubmission and version/build relationships. If the old submission is in review, withdraw it with PATCH `/v1/reviewSubmissions/ID`, attributes `{canceled:true}`; wait for cancellation and an editable version. Do not cancel first while the replacement upload is still uncertain.
- `apple-app-review.yml` / `scripts/app_store_submit.py` automate the steps below for an already processed build: `status` reads, `prepare` creates/reuses the version (release type inherited), sets What's New from `distribution/apple` and attaches the build, `submit` adds a review submission. Prefer them to hand-written API calls; they do not cancel or replace reviews (0.2.15 was submitted with an equivalent one-off script).
- Select the processed build with PATCH `/v1/appStoreVersions/ID/relationships/build`. Create a reviewSubmission with app/platform, attach the appStoreVersion using reviewSubmissionItems, then PATCH submission `{submitted:true}`. Verify WAITING_FOR_REVIEW and that the selected build is the replacement. Preserve manual release, screenshots, localizations and review details unless explicitly changing them.
- Use request timeouts; after any timed-out mutation, GET current state before retrying. Avoid duplicate submissions. Missing agreements, review details or export-compliance declarations need their actual resolution, not fabricated answers.
- Developer ID DMGs and macOS TestFlight PKGs are separate builds. Uploading one doesn't update the other. Do not submit macOS App Review when asked only for TestFlight.

## Microsoft Store

- Existing product: 9PDPR6RNT42S; publisher identity must match the manifest. The Store input is MSIX, not the public MSI.
- API authentication needs a linked Entra tenant and registered publishing application with Partner Center Manager access. This is separate from the publisher's legal account type and Entra administrator role. Reuse an appropriate existing tenant when available; never create a tenant merely because the owner used a dedicated one.
- Current GitHub secret names: `MSSTORE_TENANT_ID`, `MSSTORE_CLIENT_ID`, `MSSTORE_CLIENT_SECRET`, `MSSTORE_SELLER_ID`. Local credentials use an owner-controlled path outside the repo, not a mandatory developer pathname. Do not give every contributor production credentials.
- `scripts/check-msstore-credentials.py` gets a client-credentials token for `https://manage.devcenter.microsoft.com`, then reads the existing app. The credential workflow successfully exercised this path. It does not test package upload, create drafts or publish.
- `release.yml` uses `msstore reconfigure` and `msstore publish`; inspect the actual pending submission before dispatching. Initial API credential wiring was verified read-only; don't assume a successful automatic package submission has already been proven.
- Higher MSIX identity/build required. Review, certification, approval and “waiting to be released” are distinct states. Do not click Publish now just because API access works. Self-signed MSI certificates do not replace Microsoft's Store package signing.

## Google Play

- For an existing signed Actions artifact use `android-play-publish.yml`: explicit source run ID, `artifact_only`, one `closed_testing` track or `production`. See [workflow guide](../../../../docs/14-github-actions.md). Never use the legacy internal-plus-closed lane for a closed-only request.
- Package `md.esemnbun.app`; service account secret `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, authorized only for the intended app/tracks. Existing service-account listing edits encountered HTTP 403; metadata defaults off (`PLAY_UPLOAD_METADATA=true` is opt-in and does not grant permissions).
- Artifact-only request: use `android_artifact` lane (and `AAB_PATH` for a specific bundle). It checks bundle SHA-256 idempotently and preserves track state. An uploaded inactive bundle is a successful artifact upload, not a new review/rollout.
- Play edits can reject `changesNotSentForReview`; lane retries without that parameter only for the specific API rejection, retaining `changes_in_review_behavior: ERROR_IF_IN_REVIEW`. Never remove that review guard or cancel an old review to force an artifact upload through.
- An artifact-only commit can also fail with `HALTED release must have fraction` because Play validates existing track state. Do not repair or resume tracks during an artifact-only request; use the Console upload fallback and preserve review state.
- If API commit is blocked but the Console supports All app bundles upload, UI can fulfill artifact-only scope. Confirm uploaded versionCode and inactive status; don't change tracks or send changes for review unless requested. Existing-bundle handling was tested; don't assume all fallback branches were exercised by that test.
- Android upload key/signature must remain compatible with the existing Play app. VersionCode must exceed all uploaded bundles, including inactive ones.
- Since 27 November 2026 the service account may also release to production (owner granted it in Users and permissions). Use `android-play-publish.yml` with `operation=production` and `expected_version`: it assigns the exact bundle at 100%, refuses downgrades and staged/halted/draft production releases, leaves other tracks untouched and reads back after commit. 0.2.15 went out through an equivalent one-off API edit before this operation existed. Before the grant, validating a production edit returned 403 PERMISSION_DENIED.

## Huawei AppGallery

- Existing app ID 119651007. Credentials: `HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON`. Use `scripts/appgallery.py` and its `--draft` mode; inspect CLI help and current status first.
- An active older production review can block a new draft. The script intentionally prevents automatic cancellation. The owner explicitly chose to keep the old review and leave the newer upload pending in November 2026. Preserve that decision until changed; don't treat repeated workflow failures as permission to cancel.
- Prepare/verify the signed APK and metadata independently while blocked. Record exact APK hash/version and why draft creation is pending. An available APK is not proof that AppGallery has a draft.
- For 0.2.15 the workflow attached the draft and `scripts/appgallery.py` (without `--draft`, same APK and version code) submitted it through the API; state 5 (Reviewing) followed. No browser step was needed.
- `scripts/test_appgallery.py` covers guards. Run it when modifying upload behavior. Never submit a draft for review when only draft preparation was requested.

## APIs versus UI

Prefer existing lanes/APIs, then fix small supported automation gaps when authorized. Browser fallback is appropriate for missing permissions/capabilities; state why it was needed. Account creation, security grants and enrollment can require interactive user steps even when later publishing is automated. Don't reproduce personal password handling in a skill or invent an automatic bypass.
