---
title: Release and store delivery
description: Prepare versions, package native applications and choose the correct GitHub or store workflow without confusing upload, review and availability.
---

A release has several independent outcomes: a binary was built, an artifact was uploaded, a listing was prepared, a store accepted a review submission, and a version became available. Record each one separately.

The authoritative operation guide is `docs/14-github-actions.md`; workflow inputs live in `.github/workflows/`, signing lanes in `fastlane/`, and packaging scripts in `scripts/` and `windows/scripts/`. Inspect the current inputs before dispatching: these are operational commands with external effects.

## Prepare a version

1. Select the exact source revision and platforms. Review the diff, relevant tests and remaining validation. Update `PLAN.md` and release notes.
2. Synchronize the marketing version in the platform configuration. This is distinct from integer build numbers.
3. Read the **highest already uploaded** build for each relevant store, including inactive uploads. Choose larger numbers; the workflow counter is not sufficient after manual overrides.
4. Verify the authorized account, repository and publishing host. On the owner's environment, `GH_HOST=github.com` keeps operations separate from the employer's Enterprise session.
5. Confirm signing inputs are available through the configured secret store. Never put credential values in workflow inputs or the repository.

Android reserves version codes with the shared `android-play-version-code` concurrency and `android-play-vc-*` tags. Failed builds can leave gaps; do not reuse a reserved code for different source. Apple store uploads serialize per platform. Do not cancel an in-progress publisher to speed up a newer validation run.

## Choose the operation

| Intent | Workflow | Result / boundary |
| --- | --- | --- |
| Validate code | `ci.yml` | Read-only checks; `CI result` is the aggregate; no store secrets |
| Publish release downloads | `release.yml` | Builds selected platforms, creates/replaces release assets and checksums |
| Build signed Android artifacts | `android-build.yml` | APK/AAB; Play upload is optional and off by default |
| Upload an existing AAB | `android-play-publish.yml`, `artifact_only` | Reuses an exact source run; does not promote a track |
| Submit one closed Play track | Same publisher, `closed_testing` | Selects `alpha` or `beta`; preserves unrelated tracks/review boundaries |
| Upload Apple beta builds | `apple-testflight.yml` | `ios`, `macos` or `both`; no App Review submission |
| Build Windows installers | `windows-build.yml` | Installer artifacts; no Partner Center submission |
| Check Windows Store access | `windows-store-credentials.yml` | Read-only credential/application check |
| Stage Huawei metadata/binary | `huawei-appgallery.yml` | Draft path with active-review guard; no automatic production review submission |
| Refresh package repositories | `cli-packages.yml` | Reuses release inputs according to its workflow contract |
| Publish docs/download metadata | `website.yml` | Builds and conditionally deploys GitHub Pages |

`release.yml` accepts `only=all|desktop|macos|ios|android|linux|flatpak|windows`. Its `upload_ios_testflight`, `upload_android_play` and `submit_windows_store` flags default to false. A version-tag build does not implicitly enable those store actions. `macos-app-store.yml` is a separate macOS TestFlight shortcut; a Developer ID DMG is not that Store build.

## Example: selected GitHub release artifacts

After completing the preparation above, set values for the intended run. The placeholders deliberately are not reusable release numbers:

```sh
# Replace these with the reviewed tag and unused store-safe integers.
release_tag='vX.Y.Z'
release_build='NEXT_BUILD_INTEGER'
android_code='NEXT_ANDROID_INTEGER'
GH_HOST=github.com gh workflow run release.yml -R xfreebird/smartcard --ref main \
  -f only=all -f tag="$release_tag" -f build_number="$release_build" \
  -f android_build_number="$android_code" \
  -f upload_ios_testflight=false -f upload_android_play=false \
  -f submit_windows_store=false
```

The source must already be on the selected remote ref. After dispatch, identify the run with the expected head SHA and inputs; do not blindly watch the most recent unrelated run:

```sh
GH_HOST=github.com gh run list -R xfreebird/smartcard --workflow release.yml --limit 10
GH_HOST=github.com gh run view RUN_ID -R xfreebird/smartcard
GH_HOST=github.com gh run watch RUN_ID -R xfreebird/smartcard --exit-status
```

For a partial failure, inspect assets and rerun only the required platform. Preserve successful assets from the intended release. Changing an existing asset requires refreshed checksums and website metadata even when its filename/version is unchanged.

## Example: reuse an Android artifact

Choose the exact completed Android-build or supported Release run, verify its commit and signed artifact identity, then upload only:

```sh
GH_HOST=github.com gh workflow run android-play-publish.yml -R xfreebird/smartcard \
  -f android_run_id=EXACT_RUN_ID -f operation=artifact_only
```

For an explicitly intended closed-testing submission, use `operation=closed_testing` and the requested `closed_track=alpha` or `beta`. Check localized release notes and existing review state first. Avoid the legacy `android_testing` lane for this task: it changes internal plus closed tracks and requires separate opt-in.

`deferred_review` means the publisher preserved an active review rather than submitting. An `outcome_unknown` result requires live inspection before retrying. A track marked completed does not prove testers can already install it.

## Packaging and signing responsibilities

| Artifact | Entry point | Verify |
| --- | --- | --- |
| macOS Developer ID app/DMG and CLI | `scripts/package-macos.sh` | Signature, hardened runtime, nested helper, entitlements, notarization and stapling |
| Apple Store/TestFlight | `fastlane/Fastfile`, Apple workflows | Correct bundle/profile, build number and upload processing |
| Android APK/AAB | `scripts/package-android.sh` | Application ID, version code, existing signing key and artifact hashes |
| Windows MSI/MSIX/CLI | `windows/scripts/package-windows.ps1` | Architecture, installer behavior, signature/trust and package identity |
| Linux packages | `scripts/package-linux.sh` | Distribution dependencies, install/launch, PC/SC and desktop integration |

Do not confuse a valid self-signed Windows MSI signature with public CA trust; Store signing is separate. Do not regenerate an Android signing key or replace Apple provisioning indiscriminately to fix a build. Match operations are normally read-only.

The release publisher filters store-only inputs from public download assets: IPA, AAB, MSIX and PKG are not public desktop downloads. Follow its current artifact rules instead of uploading every file from `dist/`.

## Verify delivery

Inspect the final release's complete asset list and SHA-256 checksums, then verify downloaded bytes and relevant platform signatures. Check Apple processing/TestFlight state, Google review/tester availability, Huawei draft/review state and Windows certification/availability independently for the operations performed.

After release metadata changes, follow [website publishing](website.md) to refresh downloads, package mirrors and desktop update feeds. A green build job alone proves neither successful Pages deployment nor store availability. Record exact evidence and pending work without including credentials or personal-card data.
