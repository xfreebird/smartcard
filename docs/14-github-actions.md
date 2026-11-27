# GitHub Actions and publishing operations

This is the decision guide for `xfreebird/smartcard`. Workflow files and scripts are authoritative. Store state, highest uploaded build numbers, credential availability and pending reviews must be read live. A green build, an uploaded artifact, a review submission and availability to users are different outcomes.

The macOS and iOS validation jobs share the Xcode 27 runner pool. iOS waits for the macOS
job to finish or be skipped, then runs whenever iOS is selected and the workflow was not cancelled.
A macOS failure does not suppress iOS evidence. This avoids hosted runner-acquisition expiry while a
longer Apple UI batch occupies the available runner; neither job changes host automation permissions.

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

Android's required native batch also runs `edge-to-edge`: light/dark icon appearance, full-window
content and safe navigation/title bounds, plus the production PIN dialog's actions above a real
emulator keyboard. A suite-specific completion marker is required; an adb shell success alone
does not establish a pass. The separate local `android/scripts/test-edge-to-edge.py` matrix adds
phone/tablet size, both navigation modes, real rotation assertions and an emulated phone cutout.

`Select affected platforms` computes a NUL-delimited Git diff: the PR merge base to its head, or a main push's before/after SHAs. Reports, guides and website changes skip native builds. Android/Windows/Linux edits run the corresponding native job plus localization. Swift core changes run Swift, macOS, iOS and Linux. Shared specs/catalog/CI routing or unknown changes run full CI. Missing history or the first push also falls back to full CI. Manual CI dispatch always selects all native jobs.

Selected native jobs run the Debug mock UI suites on macOS, iPhone and iPad simulators, an Android emulator, Linux GTK under Xvfb/D-Bus, and Windows UIAutomation. Apple/Linux application integration suites and Android application unit tests run alongside core tests. UI failures fail the same platform job and `CI result`; missing automation authorization, missing devices and incomplete XCTest completion are errors, never successful skips. UI result bundles/logs are retained for seven days, including on failure. These are injected-service tests, not physical-card or live-PKI evidence. Android uses the API36 AOSP image on the constrained hosted runner; Google-service startup is outside these native mock journeys. Before installing the app, CI checks launcher readiness. It may acknowledge one initial Android framework cold-boot dialog, then requires three healthy observations; recurring or different framework errors and any app-error dialog fail setup. A failed pre-install accessibility dump resets the healthy count and has at most three attempts within the readiness deadline. Readiness trees and boot logs are retained with test evidence. The Android batch requires the saved-identity regression to pass on the same dedicated Debug emulator. It exercises a remembered card without a PIN, clears the NFC and browser choices, then checks reader rediscovery and a fresh model. A separate required browser-authentication UI phase supplies one fictional active certificate plus duplicate remembered metadata, requires one visible identity row with its serial number, and exercises switching to the reader and dismissing the sheet without NFC or PIN entry. Verify journeys also require Clear results beside the top-bar title and retain the document-picker action after clearing.

The iOS batch also requires native carousel gestures, demo/share/restart tests, and a Files-picker protection round trip with byte/permission readback on both device families. Prepared local reruns install the supplied app unless the outer batch explicitly marks it already installed, so app fixes cannot be checked against a stale binary. Android runs crypto/storage and two separate persistence phases after its UI journeys. Windows additionally requires ordinary first launch, isolated demo transitions, card scrolling and synthetic reader-helper activation. These checks use separate profiles/processes and do not modify developer data.

iOS validation uses one isolated job per required device family, with `max-parallel: 1` for the single-slot Xcode pool. Each job has a 50-minute execution ceiling and a 45-minute UI step, including simulator boot and setup. The combined budget is 100 runner minutes and 90 UI minutes, plus GitHub’s bounded cancellation cleanup. The cap accounts for measured hosted overhead: the first 16 cases took 588 seconds versus 326 locally, in addition to about six minutes of cold simulator/test-host startup. The full local 35-case run took 905 seconds; a 25-minute UI limit could not accommodate the measured hosted rate. A later hosted run passed 30 cases without assertion failures before the 35-minute limit stopped it: cold setup took eight minutes and the remaining five cases had previously taken about four minutes. Two iPad attempts in run `45136963126` passed 34 cases and reached the final test before the 40-minute cutoff. The expanded iPad budget was verified when it passed the UI step in 40 minutes 10 seconds. The iPhone job in `45198218491` passed 32 cases before reaching the same limit. Its final three cases had previously taken about three minutes. The build step builds the app for the runner architecture and the shared XCTest harness once, and generates native document fixtures. Boot only the assigned simulator after compilation: overlapping cold CoreSimulator startup and Xcode package resolution stalled a hosted build. CI then uses one `test-without-building` session for all 35 cases, avoiding repeated XCTest startup and result processing. Protection/Documents fixtures are seeded before that session and their byte, permission and persistence postchecks run afterward; an exact 35-pass, zero-skip result is required. The result bundle retains individual test and suite evidence. Direct local runners retain separate-suite execution unless `MSIGN_UI_SINGLE_SESSION=1` is set. Each build has a five-minute limit, checkout/SDK discovery have two minutes, and always-run evidence upload has three minutes, all inside the job ceiling. Evidence artifacts include the device family to avoid collisions. UI waits check for already-present controls immediately and take the first stability sample before polling; the second matching visible frame and existing timeout remain required.

The iOS CI wrapper requires an explicit `iPhone` or `iPad` argument and boots only that family's selected simulator. Within the newest eligible runtime, prefer iPhone Duo and iPad mini (falling back to another available tablet). The smaller tablet framebuffer reduces pressure on the 7 GB hosted machine while retaining regular-width tablet navigation, both orientations and all 35 cases. Never select an older runtime solely to obtain a smaller device. Both device families still run every suite. Separate jobs avoid loading the Duo-only 27.1 runtime and the iPad 27.0 runtime together; a simultaneous run encountered an app-launch timeout while both runtimes were active. `MSIGN_UI_FAIL_FAST=1` stops the worker and its child processes after a failed suite or result/postcheck, then shuts down the simulator. Cancellation follows the same cleanup path. Matrix fail-fast is disabled: a phone host failure must not hide the independent tablet result. The families remain sequential and each failed device stops immediately; the aggregate still requires both families, and an investigated rerun can preserve the already-passing family. A successful run requires both matrix jobs and every suite. Direct local `run-mock-ui-tests.sh` calls keep collecting all suites unless that flag is explicitly set. Incomplete results and timeouts remain failures; no automatic UI retries are added. Native XCTest runners use `-collect-test-diagnostics never` to avoid Xcode spending up to ten additional minutes collecting a whole-simulator sysdiagnose after a failed test. Normal XCTest logs, screenshots, recordings and result bundles are retained.

The iOS evidence artifact retains each protection suite's `roundtrip.json` alongside XCTest bundles,
test logs and simulator inventories, so restored-byte hashes and private output permissions remain reviewable.

Branch commits cannot create application releases, reserve Android version codes or upload Store versions. The signed Android builder is manual-only; Release remains an explicit `v*` tag or manual action. Website source pushes can still deploy documentation, and scheduled CLI feed refreshes reuse an existing release. No CI completion triggers a publisher.

The generated macOS UI-test runner is built separately and re-signed locally with its existing testing entitlements except App Sandbox. Xcode's copied runner template adds this entitlement independently of `ENABLE_APP_SANDBOX`; a sandboxed runner drops the native fixture launch settings through NSWorkspace. The helper asserts the QA-only bundle identifier before signing and verifies its signature and debugging entitlement. The application under test and host authorization settings are preserved. `MSIGN_UI_BUILD_ONLY=1` validates this harness without closing or launching a developer's running app.

The Apple CI entry point discovers available iPhone/iPad simulators and uses an ad-hoc signed Debug macOS app without distribution credentials. It requires the runner image's existing XCTest authorization and never changes host security settings. GitHub documents this preauthorization in its [macOS image configuration](https://github.com/actions/runner-images/blob/main/images/macos/scripts/build/configure-machine.sh); Windows UI tests use a [hosted graphical runner](https://learn.microsoft.com/en-us/windows/apps/develop/ai-assisted/testing#run-tests-in-ci).

Simulator selection uses runtime version metadata and the selected `iphonesimulator` SDK. Each family uses its newest available runtime in the SDK's major release, without advancing beyond the SDK's minor version; patch runtimes remain eligible. A phone-only runtime can therefore pair with the previous minor tablet runtime. iPhone Duo is preferred when available at the selected version. Missing either family fails setup, and the device/runtime inventories and selected targets are retained with UI evidence. Newer-runtime compatibility checks use explicit simulator IDs through the native test runners; their failures must remain documented separately, rather than being counted as fixed by SDK-line CI.

Routing and publisher guard tests always run, even for docs-only changes. The parallel `Automation and publishing tools` job installs the hash-pinned script requirements and runs the `scripts`, `scripts/agents` and `scripts/tests` suites on every run. `CI result` is the stable aggregate status: selected failures/cancellations fail it; intentionally skipped jobs are accepted. Use this aggregate if configuring a required branch check rather than requiring every platform to run on every commit. CI has read-only repository permissions and no signing/Store secrets.

The iOS mock batch includes `NFCSigningChoiceUITests`: selecting NFC with synthetic reader cards,
returning to the reader, and NFC demo signing without a reader. It never opens a real NFC session
or collects a real PIN. `PINActionsUITests` checks visible, reachable PIN actions in portrait/landscape using a synthetic PIN with hardware disabled. `SharedCardPINUITests` checks shared reader/NFC PIN management, another-card selection and disconnected accounts using only an in-memory fixture vault. Physical acceptance is tracked in [the NFC guide](16-ios-nfc.md).

Design-system boundary tests also run on every commit. They reject signing-core and application
dependencies in the reusable UI folders on Apple, Android, Windows and Linux. Selected Apple and
Linux jobs additionally compile those components independently of the application and signing core;
native mock journeys exercise the presentation adapters in the complete apps. See the
[architecture contract](09-architecture.md) for the component boundaries and mapping responsibilities.

Superseded CI runs are cancelled per PR/branch. Store/release/version-counter jobs use non-cancelling concurrency groups: cancelling an upload can leave an uncertain outcome or consume a build number. Apple Store jobs serialize per platform across both TestFlight entry points and Release's optional iOS upload. GitHub's normal concurrency queue retains one pending run, not an unlimited FIFO; dispatch publishing operations deliberately instead of enqueueing many replacements.

Gradle and NuGet caches contain dependency downloads only. NuGet keys include project/SDK inputs. Ruby uses Bundler's dependency cache; the website caches npm downloads. Recurring validation/intermediate artifacts are retained for seven days, signed build/publishing-result artifacts for 30 days. GitHub Release assets are independent of Actions artifact retention. Android runtime smoke uploads its phone/tablet captures for inspection. Do not cache signing keychains, temporary keys, credentials, mutable store edits or signed output as validation results. SDK guards require the supported Siri/iPhone Duo toolchains before Apple builds. `scripts/gradle-ci.sh` allows up to three attempts for dependency transport failures. When Gradle hides the transport cause behind a missing managed plugin, the wrapper checks its implementation POM at the official repository. A published POM or a temporary repository outage allows a retry with refreshed dependency metadata. Missing versions, permission errors and compiler/test failures remain failures. The Windows compiler download similarly has bounded retries and a mandatory digest check.

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

Optional Azure Artifact Signing variables are referenced but **not configured as repository secrets** in this snapshot: `MOLDSIGN_TS_ENDPOINT`, `MOLDSIGN_TS_ACCOUNT`, `MOLDSIGN_TS_PROFILE`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`. They are only for Windows signing jobs, not validation CI. `MOLDSIGN_TS_DLIB` is a temporary runner path to the downloaded signing client, not a credential. The workflow's self-signed MSI certificate is not public CA trust; Microsoft separately signs Store-distributed MSIX packages. The public 0.2.14 MSI and standalone CLI were separately signed with Certum using the [manual macOS signing skill](../.agents/skills/esemnbun-certum-sign/SKILL.md); the cloud private key is not an exportable PFX or a configured CI credential.

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

### Website downloads

The Website workflow reads the selected stable release files with its read-only GitHub token and verifies their listed SHA-256 digests. The public download page links to `/release-downloads/` on the website. The build also stages the signed package feeds and installers once at the site root for English, Romanian and Russian. When a release omits a platform, its existing standalone installer keeps its own version and comes from the matching stable release.

### Temporary website runner recovery

If a hosted Actions spending limit blocks Pages deployment, the Website manual dispatch accepts `runner=esemnbun-recovery`. Automatic pushes and pull requests still use `ubuntu-latest`. Start a repository-scoped ephemeral runner with that label on an owner-controlled Mac; register a fresh ephemeral runner for each of the build and deployment jobs, then remove its local workspace and credentials. Do not install a persistent service or use this label for untrusted pull requests. The workflow retains its Pages environment and OIDC permissions. No signing or Store secrets are needed. Verify the final Pages job and live routes; successful local rendering alone is not publication.

The recovery host needs `uv` with an existing managed Python3.12 (`uv python find 3.12`), Node tooling prerequisites, `gh`, `gpg`, `gpgv` and GNU tar (`gtar` on macOS). Hosted runners use `setup-python`; recovery selects the existing managed interpreter without creating a system-wide hosted tool cache.

CI Linux/Windows package artifacts expire after one day; signed Release artifacts keep their separate release retention. CI packages are reproducible validation output. Preserve current release inputs, store-upload artifacts and diagnostic evidence when clearing obsolete CI packages. Hosted storage enforcement may take hours to reflect deletions.


## Scanner hardening and dependency verification (uncommitted acceptance)

Actions are pinned to full SHAs with their version comments retained. Workflow permissions default to read-only; release/feed publishers and Android counter reservation declare their needed write permission at job scope. Windows Release build-number overrides are environment data validated as positive bounded integers before packaging. Updating an action pin or dependency never authorizes a publishing smoke test.

Website CI installs the locked npm graph with `--ignore-scripts`; recheck lifecycle requirements when adding build dependencies.

Play/AppGallery uploader installs use `scripts/requirements/store-publish.txt` with wheel-only, hash-checked dependencies for CPython 3.12 on Ubuntu 24.04 x86_64. To refresh deliberately, resolve `store-publish.in` into a fresh ignored wheel directory with the target Python/platform, then run `scripts/ci/lock-publisher-wheels.py` against it. Review the changed packages and hashes before accepting the lock. Never copy credentials into package metadata or logs.

Android builds enforce `android/gradle/verification-metadata.xml`. To refresh after a reviewed dependency change:

```sh
android/gradlew -p android --write-verification-metadata sha256 resolveDependencyVerification
android/gradlew -p android resolveDependencyVerification
```

This task resolves external artifacts, including the AGP-matched lint tools and AAPT2 host classifiers, without app compilation/tests/signing or version reservation. Do not run `--write-verification-metadata` as an automatic fallback in CI: it would trust the changed bytes that verification was meant to reject. Update the explicit tooling coordinates when changing AGP. Review checksum additions and validate clean-cache builds on the intended hosts.

### SonarQube Cloud coverage

`sonar-coverage.yml` generates coverage independently of required app validation. Its manual run generates reports with the repository variable `SONAR_CI_ENABLED` unset. Set the variable to `reports` to validate report generation on main and same-repository pull requests without contacting SonarQube Cloud. Set it to `true` after switching analysis methods to enable imports on those refs. Fork and Dependabot pull requests continue to use the existing secret-free CI checks.

| Test suite | Coverage imported |
| --- | --- |
| SwiftPM core and Apple application policies | LLVM line coverage in Sonar generic XML |
| Linux GNOME integration | LLVM line coverage in Sonar generic XML |
| Android core, app and USB unit tests | JaCoCo XML from each module, enabled with `-PsonarCoverage=true` |
| Windows portable solution on Windows | Microsoft `dotnet-coverage` XML, with source paths rebased and checksums checked on the Linux scanner host. |
| Website Node tests | LCOV for `website/src` components, hooks and pages (JSX loaded through the Babel test hook in `website/tests/support`), `website/scripts`, `website/plugins` and the site configuration |
| Python automation tests (`scripts/ci`, `scripts`, `scripts/agents`, `scripts/tests`) | Cobertura line coverage from Coverage.py runs in parallel mode, combined; every Sonar-scope Python source directory is reported, so modules no test imports count as uncovered |

The reports measure the listed suites. Native UI journeys, physical card operations and other language/tooling tests still have their own validation. SonarQube Cloud computes project and new-code measurements over the analyzed source scope, including uncovered lines. The workflow supplies no coverage threshold. The project quality gate remains the authority.

First inspect the workflow's generated reports in `reports` mode, or from a manual run with `SONAR_CI_ENABLED` unset. Configure a SonarQube Cloud token with analysis access to `xfreebird_smartcard` as the repository Actions secret `SONAR_TOKEN`. Turn off the project's automatic analysis in **Administration → Analysis Method**. Set `SONAR_CI_ENABLED` to `true` and run CI through a trusted PR or on `main` once the workflow is there. Verify coverage in the SonarQube Cloud analysis and the GitHub check. If the migration fails, unset `SONAR_CI_ENABLED` before restoring automatic analysis. The two analysis modes cannot run concurrently. [SonarQube Cloud coverage documentation](https://docs.sonarsource.com/sonarqube-cloud/analyzing-source-code/test-coverage/overview)

The combined scanner runs on Linux because SonarQube's Swift analyzer does not run on Windows. It builds the portable .NET solution for compiler-based analysis and indexes the WinUI source files. Full WinUI compilation and UI validation run in the native Windows CI job. The scanner reuses source exclusions from `.sonarcloud.properties`. The fixture drivers stay out of production analysis, while production workflow scripts remain in scope. The coverage workflow uses read-only GitHub permissions and requires neither Store credentials nor signing. The Sonar token is scoped to scanner steps. Android dependency verification remains strict, including the additional test-only JaCoCo graph.

The Android build policy command emits JSON to stdout. CI and packaging select their own fixed output files for the toolchain and bundle reports.

The uncommitted changes and complete automated/real integration acceptance matrix are recorded in [the hardening handoff](reports/scanner-hardening-integration-2026-11-22.md). A successful dependency-resolution task is not a passing application build or test run.


Android optimization follow-up: the local toolchain is AGP 9.5.3 / Gradle 9.9.2 / Kotlin 2.4.21 (compileSdk 37.2, targetSdk 36), with built-in Kotlin for Android modules and an explicit optimized-resource policy. Update matched lint/AAPT2 verification coordinates with AGP; preserve the checked Gradle distribution checksum. Dependency resolution does not validate the optimized output: require clean Release APK/AAB, lint and real resource-sensitive integration before an authorized upload. Existing Play notices remain tied to their uploaded bundle.


### Actions enforcement of the Android R8 toolchain

All four Android build entry points (`ci.yml`, `android-runtime.yml`, `android-build.yml` and Release's Android job) run `scripts/ci/android_build_policy.py --verify-wrapper` after JDK setup and before building or reserving a version. It checks the selected AGP/Kotlin/Gradle policy, distribution checksum, explicit optimized resource shrinking and actual wrapper/daemon-JDK selection. Cache inputs include the version catalog, daemon criteria, wrapper JAR/properties and dependency-verification metadata; no workflow substitutes a system Gradle installation.

Secret-free CI additionally compiles an unsigned optimized Release APK/AAB and runs Release lint. It rejects the AAB unless embedded AGP/R8 metadata confirms the selected plugin, shrinking/optimization/obfuscation, full non-Debug mode and optimized resource shrinking. This creates no signing material, version reservation or store upload. Its report and mapping are retained with CI evidence.

Both signed workflows use `scripts/package-android.sh`, which applies the same preflight, validates the actual AAB before signing, and validates/hashes the final AAB. Their existing Android Actions artifact also retains `optimization/` with mapping, configuration and a build-policy report. The public Release file filter continues to publish only its existing installer asset types; optimization evidence is not added to public release downloads.

Artifact-only publishers continue to reuse the explicitly selected source artifact. They do not rebuild an older bundle with the new toolchain; choose the new successful source build after testing and an authorized commit/push. The workflow changes here are local until that push and do not establish a hosted CI pass.
