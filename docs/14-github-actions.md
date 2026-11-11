# GitHub Actions and publishing operations

This is the decision guide for `xfreebird/smartcard`. Workflow files and scripts are authoritative. Store state, highest uploaded build numbers, credential availability and pending reviews must be read live. A green build, an uploaded artifact, a review submission and availability to users are different outcomes.

## Choose the smallest operation

| Need | Workflow and inputs | What changes externally |
| --- | --- | --- |
| Validate code or a pull request | `ci.yml`; automatic PR/main push, or manual dispatch for a full run | No signing, stores or releases. Produces validation/package artifacts. |
| Change guides or the landing page | Push website/guide sources; `website.yml` | Validates all locales and deploys Pages from main. Downloads/package feeds are refreshed from the current GitHub release. |
| Build a new Android binary (manual only) | `android-build.yml`, optional `build_number`; leave `upload_play=false` | Reserves an Android version code and produces signed APK/AAB Actions artifacts. No track change. |
| Upload an existing Android bundle only | `android-play-publish.yml`: exact `android_run_id`, `operation=artifact_only` | Uploads the AAB without changing any track or submitting a rollout. Same SHA-256 is a no-op. |
| Publish to closed Android testing | Same workflow, `operation=closed_testing`, `closed_track=alpha` or `beta` | Submits only the selected existing closed track. Production/internal and tester lists are preserved. Review is not approval. |
| Build and immediately upload a new Play artifact | `android-build.yml`, explicit `upload_play=true` | Legacy convenience path: builds/signs and runs `android_artifact`. Upload only; no closed-track promotion. Prefer build once, then publish the exact artifact. |
| Check Android phone/tablet runtime | `android-runtime.yml` manually | Debug mock screenshots on x86-64 emulator, no reader/PIN or publishing. |
| Upload iOS, macOS or both to TestFlight | `apple-testflight.yml`, `platform=ios|macos|both`, required `build_number` | Selected uploads only; no App Review selection/submission. Only selected runner jobs are allocated. |
| Existing macOS-only upload shortcut | `macos-app-store.yml`, required `build_number` | Same sandboxed macOS TestFlight route. Prefer Apple TestFlight with `platform=macos`; retained for existing callers. |
| Produce Windows installer inputs | `windows-build.yml`, required `build_number` | MSI/MSIX/CLI/checksums/winget artifacts; no Partner Center submission. Signing is optional when configured. |
| Validate Windows Store access | `windows-store-credentials.yml` | OAuth and read-only app lookup, no submission. |
| Publish GitHub installers | `release.yml`, `only=all|desktop|macos|ios|android|linux|flatpak|windows`, optional `tag`, explicit store-safe build numbers | Creates/replaces selected public release assets and checksums. A `v*` tag builds all platforms. Store actions are opt-in; see below. |
| Publish signed CLI package feeds | `cli-packages.yml`; after successful Release, weekly, or manual | Builds APT/RPM repositories and brew/Chocolatey definitions from a complete existing release. Uploads feed/definition assets and a tested `.nupkg` to GitHub. It does not submit to Chocolatey Community or winget upstream. |
| Stage a Huawei APK draft | `huawei-appgallery.yml`, exact completed main `android_run_id` | Draft only. Existing review defers the workflow; it never cancels or submits production review. |

**Release store flags:** `upload_ios_testflight=true`, `upload_android_play=true`, and `submit_windows_store=true` are separate manual choices. All default false; tag pushes do not activate them. The first uploads a signed IPA to TestFlight, the second uploads an AAB artifact without changing tracks, and the third starts a Microsoft Store submission. IPA/AAB/MSIX/PKG store inputs remain Actions artifacts, not public installer assets. The standalone macOS DMG/CLI use Developer ID/notarization; Mac App Store/TestFlight use the separate sandboxed target.

App Store review selection/submission, Microsoft manual release after certification, Huawei cancellation/resubmission and Play listing changes remain explicit store operations in the [store skill reference](../.agents/skills/esemnbun-release-stores/references/stores.md). They are not implied by uploading a build. A skill documents a flow; it does not grant authorization to publish or replace a review.

## CI selection and cost

`Select affected platforms` computes a NUL-delimited Git diff: the PR merge base to its head, or a main push's before/after SHAs. Reports, guides and website changes skip native builds. Android/Windows/Linux edits run the corresponding native job plus localization. Swift core changes run Swift, macOS, iOS and Linux. Shared specs/catalog/CI routing or unknown changes run full CI. Missing history or the first push also falls back to full CI. Manual CI dispatch always selects all native jobs.

Selected native jobs run the Debug mock UI suites on macOS, iPhone and iPad simulators, an Android emulator, Linux GTK under Xvfb/D-Bus, and Windows UIAutomation. Apple/Linux application integration suites and Android application unit tests run alongside core tests. UI failures fail the same platform job and `CI result`; missing automation authorization, missing devices and incomplete XCTest completion are errors, never successful skips. UI result bundles/logs are retained for seven days, including on failure. These are injected-service tests, not physical-card or live-PKI evidence. Android uses the API36 AOSP image on the constrained hosted runner; Google-service startup is outside these native mock journeys. Before installing the app, CI checks launcher readiness. It may acknowledge the initial System UI cold-boot dialog once, then requires three healthy observations; recurring System UI errors or any app-error dialog fail setup. Readiness trees and boot logs are retained with test evidence.

The iOS batch also requires native carousel gestures and demo/share/restart tests on both device families. Android runs crypto/storage and two separate persistence phases after its UI journeys. Windows additionally requires ordinary first launch, isolated demo transitions, card scrolling and synthetic reader-helper activation. These checks use separate profiles/processes and do not modify developer data.

Branch commits cannot create application releases, reserve Android version codes or upload Store versions. The signed Android builder is manual-only; Release remains an explicit `v*` tag or manual action. Website source pushes can still deploy documentation, and scheduled CLI feed refreshes reuse an existing release. No CI completion triggers a publisher.

The Apple CI entry point discovers available iPhone/iPad simulators and uses an ad-hoc signed Debug macOS app without distribution credentials. It requires the runner image's existing XCTest authorization and never changes host security settings. GitHub documents this preauthorization in its [macOS image configuration](https://github.com/actions/runner-images/blob/main/images/macos/scripts/build/configure-machine.sh); Windows UI tests use a [hosted graphical runner](https://learn.microsoft.com/en-us/windows/apps/develop/ai-assisted/testing#run-tests-in-ci).

Routing and publisher guard tests always run, even for docs-only changes. `CI result` is the stable aggregate status: selected failures/cancellations fail it; intentionally skipped jobs are accepted. Use this aggregate if configuring a required branch check rather than requiring every platform to run on every commit. CI has read-only repository permissions and no signing/Store secrets.

Superseded CI runs are cancelled per PR/branch. Store/release/version-counter jobs use non-cancelling concurrency groups: cancelling an upload can leave an uncertain outcome or consume a build number. Apple Store jobs serialize per platform across both TestFlight entry points and Release's optional iOS upload. GitHub's normal concurrency queue retains one pending run, not an unlimited FIFO; dispatch publishing operations deliberately instead of enqueueing many replacements.

Gradle and NuGet caches contain dependency downloads only. NuGet keys include project/SDK inputs. Ruby uses Bundler's dependency cache; the website caches npm downloads. Recurring validation/intermediate artifacts are retained for seven days, signed build/publishing-result artifacts for 30 days. GitHub Release assets are independent of Actions artifact retention. Android runtime smoke uploads its phone/tablet captures for inspection. Do not cache signing keychains, temporary keys, credentials, mutable store edits or signed output as validation results. SDK guards require the supported Siri/iPhone Duo toolchains before Apple builds. `scripts/gradle-ci.sh` retries bounded dependency transport failures, never compiler/tests or publishing. The Windows compiler download similarly has bounded retries and a mandatory digest check.

## Android: build once, publish exactly that artifact

1. Inspect Publishing overview for unrelated pending app changes; Play commit/review operates at app scope, so resolve those within the intended authorization before submitting another rollout. Confirm CI for the intended source. Dispatch `android-build.yml` and use its successful manual run. Its `esemnbun-android` artifact must contain one signed APK and one AAB. Keep the source run ID.
2. Check the highest uploaded Play version code and the reserved `android-play-vc-*` tags. `scripts/ci/reserve-android-version.sh` is shared by Android build and Release; both serialize through `android-play-version-code`. An explicit reserved code can be reused only for the identical source SHA. Failed builds may leave harmless gaps. Build numbers are integers, not marketing versions.
3. Dispatch the new publisher with the exact source run. It accepts the main Android workflow or a completed Release run from main/a stable version tag, verifies package identity and the pinned public upload-certificate fingerprint, and checks the AAB signature. A completed source run with a later upload failure is usable only if its already packaged artifact passes these checks.
4. Select `artifact_only` for an inactive bundle or `closed_testing` and the intended existing closed track for submission. Review EN/RO/RU notes in `localization/catalog.json` first; `notes_json` can explicitly supply a releaseNotes array. No listing images, descriptions, testers or other tracks are edited.
5. The publisher verifies Google's returned version code/hash, validates the edit, commits with `ERROR_IF_IN_REVIEW`, then performs an independent read to verify the bundle and unchanged tracks. A byte-identical bundle is reused. It refuses a selected-track downgrade.
6. Read the workflow result artifact and Play Console **Publishing overview**. `submitted` means submitted for Google review; `completed` on a track does not prove tester availability. Managed publishing and approval may still delay availability.

Examples (owner's main Mac):

```sh
GH_HOST=github.com gh workflow run android-build.yml -R xfreebird/smartcard -f upload_play=false
GH_HOST=github.com gh workflow run android-play-publish.yml -R xfreebird/smartcard \
  -f android_run_id=EXACT_RUN_ID -f operation=closed_testing -f closed_track=alpha
```

Replace `EXACT_RUN_ID` with the numeric run you inspected. The publisher accepts the Android build workflow on main, or Release on main/a stable version tag. It does not build again or consume another version code. Legacy `bundle exec fastlane android_testing` changes **both internal and closed** tracks and is guarded by `PLAY_ALLOW_INTERNAL_AND_CLOSED=true`; it is not the one-track flow.

## Expected cases and recovery

| Result/case | Meaning and next action |
| --- | --- |
| `already_uploaded` / `already_configured` | Hash/release already matches; no upload or commit was repeated. |
| `deferred_review` | Existing review preserved. A warning and result artifact explain that nothing was submitted; rerun the same exact artifact after review completes, or handle replacement separately when authorized. |
| Unknown/expired/missing Actions artifact | Stop. Identify the intended binary again; rebuild only when necessary with a new unused code. Never silently pick “latest”. |
| Wrong signature, hash, source workflow, package, version or downgrade | Hard failure. Correct the artifact/configuration; do not retry to bypass validation. |
| `outcome_unknown` after upload/commit timeout | Inspect the result checkpoint, live bundles/tracks and review state before retrying. Do not automatically repeat a store mutation. |
| App is still a Play draft | A completed closed rollout may be rejected. Finish the app setup or explicitly stage a draft through the intended flow; never describe a draft as published. |
| API cannot edit listings (403) | Use Console for an authorized listing update. Setting `PLAY_UPLOAD_METADATA=true` does not grant permissions. |
| Play rejects an existing halted-track state | Inspect/resolve only within separately authorized track changes, or use Console's artifact-only upload. Do not resume another track to make an artifact-only edit succeed. |
| Apple build already used / missing profile | Read App Store Connect's actual maximum, select a larger build, or obtain an authorized profile refresh. Build/signature success is not TestFlight processing success. |
| Windows submission in certification / Huawei review active | Preserve it until replacement is authorized. Credential checks and draft uploads are not publication. |
| Partial GitHub release | Inspect per-platform job results and assets; rebuild only the missing/broken platform using `only`, preserve other assets, then verify checksums/feeds/Pages. |
| CLI feed workflow says “waiting” | Required release assets are incomplete. Complete the release and rerun; this is not a published feed. |

## Secrets, identities and storage

Configured values are managed under [repository Actions secrets](https://github.com/xfreebird/smartcard/settings/secrets/actions); public configuration is under the adjacent Variables tab. Verified configured repository secret **names** on 8 November 2026. Values were not read from GitHub (GitHub cannot return them) or written into this guide. The configured owner's backup is **`~/Desktop/eSemnBun-secrets/` on the main Mac**, outside this repository, with its own README and `secrets.env`. Other developers use their own approved secret source; do not assume the same path or transfer this folder to test hosts. The backup is an owner-managed external copy, not a repository file or an assertion that cloud backup/offline protection is configured.

| Repository secret(s) | Consumer / purpose | Owner backup location relative to external folder |
| --- | --- | --- |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` | Apple TestFlight, Mac Store, Release: App Store Connect auth, match, notarization | `secrets.env`; `apple/AuthKey_<KEY_ID>.p8` (`ASC_KEY_PATH` is the local file alternative) |
| `APPLE_TEAM_ID` | Release macOS signing identity/team | `secrets.env`; public team identifier, stored as a secret for existing workflow compatibility |
| `MATCH_PASSWORD` | Decrypt Apple signing storage | `secrets.env`; Apple certificates/profiles are encrypted in `github.com/xfreebird/fastlanecerts`, branch `master` |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Android build/Release: sign upload APK/AAB | `android/esemnbun-upload.jks` and `secrets.env` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play artifact/closed submission; no use in normal CI | `google/GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.json` |
| `HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON` | Huawei draft API | `huawei/HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON.json` |
| `MSSTORE_TENANT_ID`, `MSSTORE_CLIENT_ID`, `MSSTORE_CLIENT_SECRET`, `MSSTORE_SELLER_ID` | Windows credential check; explicitly opted-in Store submission. Client ID also supplies package identity integration. | `windows/MSSTORE_CREDENTIALS.json` (legacy notes in `windows/secrets.txt`) |
| `WINDOWS_MSI_CERTIFICATE_PFX_BASE64`, `WINDOWS_MSI_CERTIFICATE_PASSWORD` | Windows build/Release: current optional self-signed MSI signing | `windows/esemnbun-msi-self-signed.pfx`, `windows/esemnbun-msi-password.txt`; `.cer` is the public certificate |
| `PACKAGE_SIGNING_KEY` | CLI package repositories: sign APT metadata/RPM packages | `packages/signing-private.asc`; revocation certificate beside it |

Optional Azure Artifact Signing variables are referenced but **not configured as repository secrets** in this snapshot: `MOLDSIGN_TS_ENDPOINT`, `MOLDSIGN_TS_ACCOUNT`, `MOLDSIGN_TS_PROFILE`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`. They are only for Windows signing jobs, not validation CI. `MOLDSIGN_TS_DLIB` is a temporary runner path to the downloaded signing client, not a credential. The current self-signed MSI certificate is not public CA trust; Microsoft separately signs Store-distributed MSIX packages.

The owner's manual GitHub CLI session is authenticated as `xfreebird` using the main Mac's macOS keychain/keyring. Use `gh auth status --hostname github.com` to inspect account/storage status without printing its token, and `GH_HOST=github.com` on commands so the separate employer host session remains untouched. This local CLI credential is not a repository Actions secret.

GitHub **variables** are public configuration: `ENABLE_PAGES_DEPLOYMENT`, `MOLDSIGN_MSIX_IDENTITY`, `MOLDSIGN_MSIX_PUBLISHER`, `MOLDSIGN_MSIX_PUBLISHER_DISPLAY_NAME` are configured. `ANDROID_UPLOAD_CERT_SHA256` optionally overrides the public upload-key fingerprint (default pinned in the publisher). Legacy `PLAY_CLOSED_TRACK` / `PLAY_CLOSED_RELEASE_STATUS` affect only the explicitly enabled legacy lane; the new publisher takes its closed-track input. `GITHUB_TOKEN` (`github.token`, passed as `GH_TOKEN`) is short-lived and generated per job; there is no owner backup of it.

Local Apple certificate/profile administration can additionally use `MATCH_GIT_BASIC_AUTHORIZATION` for write access to encrypted match storage and optional `MATCH_KEYCHAIN_NAME`, `MATCH_KEYCHAIN_PASSWORD`, `ESEMNBUN_SIGNING_KEYCHAIN`. Routine CI reads match without changing it; certificate regeneration/nuking is a separate owner operation. Exported Apple identities are backed up under `apple/`, while active signing identities live in authorized macOS keychains.

Jobs decode signing files only into runner-temporary storage and remove them after use; Fastlane CI uses a temporary keychain. Never print tokens/key JSON/passwords, upload them as artifacts, or put secret values in workflow inputs, commands, reports or git. Runtime card PINs and MCP credential providers (Keychain, Credential Manager, Secret Service, 1Password, environment) are separate from distribution credentials; **do not add a user's card PIN to Actions secrets**. The bundled vendor `localhost.p12` is a shipped bridge identity, not a user's PIN or signing key; follow the project's private vendor-material rules.

To audit configuration without reading values:

```sh
GH_HOST=github.com gh secret list -R xfreebird/smartcard
GH_HOST=github.com gh variable list -R xfreebird/smartcard
```

For rotation, provision the replacement with the relevant store/provider, update only its GitHub secret and the authorized external backup, then run the narrow credential check or build validation before publishing. Don't rotate the Android upload key, certificates or Store applications merely to repair a pipeline failure.

References: [GitHub concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency), [GitHub secret use](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions), [Play commit/review behavior](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit), [release skill](../.agents/skills/esemnbun-release-stores/SKILL.md), [signing details](../fastlane/SIGNING.md).

### Temporary website runner recovery

If a hosted Actions spending limit blocks Pages deployment, the Website manual dispatch accepts `runner=esemnbun-recovery`. Automatic pushes and pull requests still use `ubuntu-latest`. Start a repository-scoped ephemeral runner with that label on an owner-controlled Mac; register a fresh ephemeral runner for each of the build and deployment jobs, then remove its local workspace and credentials. Do not install a persistent service or use this label for untrusted pull requests. The workflow retains its Pages environment and OIDC permissions. No signing or Store secrets are needed. Verify the final Pages job and live routes; successful local rendering alone is not publication.

The recovery host needs `uv` with an existing managed Python3.12 (`uv python find 3.12`), Node tooling prerequisites, `gh`, `gpg`, `gpgv` and GNU tar (`gtar` on macOS). Hosted runners use `setup-python`; recovery selects the existing managed interpreter without creating a system-wide hosted tool cache.

CI Linux/Windows package artifacts expire after one day; signed Release artifacts keep their separate release retention. CI packages are reproducible validation output. Preserve current release inputs, store-upload artifacts and diagnostic evidence when clearing obsolete CI packages. Hosted storage enforcement may take hours to reflect deletions.
