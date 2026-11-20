---
name: esemnbun-release-stores
description: Create eSemnBun GitHub releases, run distribution workflows, submit Apple/Windows builds, upload Play artifacts or Huawei drafts, and refresh website downloads with explicit review boundaries.
---

# Release and submit eSemnBun

Read [store-specific operations](references/stores.md) only for the selected store, and [build/sign](../esemnbun-build-sign/SKILL.md) for packaging. Source of truth: `.github/workflows/`, `fastlane/Fastfile`, package scripts and current store API state. See [build automation](../../../distribution/BUILD-AUTOMATION.md) and [onboarding](../../../docs/13-developer-onboarding.md).

The canonical [workflow decision guide and credential inventory](../../../docs/14-github-actions.md) lists all supported operations, expected deferrals and owner backup locations. For CI changes use the [automation skill](../esemnbun-ci-automation/SKILL.md).

## Decide the operation

Distinguish build, artifact upload, draft preparation, submission for review and public rollout. A request for one does not authorize all five. Preserve existing reviews unless replacement/cancellation is requested. A skill does not itself grant access or permission. Prefer existing APIs/lanes; use browser UI when a required capability or permission is absent, and explain the fallback.

Inspect git status, remote, intended commit, current release assets and pending store submissions before mutations. On the owner's setup, push/gh/release dispatch run only on the main Mac as the requested author; `GH_HOST=github.com` avoids the employer Enterprise session. On another developer's setup, verify their authorized publishing host and identity instead of impersonating the owner.

For manual Certum signing of Windows MSI/CLI files from macOS, use [Certum signing](../esemnbun-certum-sign/SKILL.md). It signs local copies through SimplySign and Jsign; certificate connection, signing, verification and publication remain distinct operations.

## Build identity and workflows

Marketing version is shared across Apple project settings, `windows/Directory.Build.props`, Android settings and release metadata. Integer builds must exceed the highest already uploaded for each platform; don't trust `github.run_number` after a manual build override. Apple 201 and Android 1793624674 are historical observations, not next-build constants. Android workflow reserves version-code tags to prevent reuse; inspect that logic before a local/manual upload.

| Workflow | Meaning |
| --- | --- |
| `apple-testflight.yml` | Explicit `platform=both|ios|macos`, required higher `build_number`; uploads, no App Review |
| `macos-app-store.yml` | Sandboxed macOS package and TestFlight upload; pass explicit higher build |
| `release.yml` | Public assets, selected `only`, optional `tag` and build overrides; has store side effects—inspect selected job/conditions |
| `windows-build.yml` | Build-only Windows artifacts, not Partner Center submission |
| `windows-store-credentials.yml` | Read-only OAuth/app-access validation |
| `android-build.yml` | Build/sign Android; optional artifact-only upload, no track promotion |
| `android-play-publish.yml` | Reuse exact signed Android-build/Release artifact: upload only or submit one existing closed track |
| `huawei-appgallery.yml` | Upload/draft operations; active-review guard applies |
| `website.yml` | Regenerates downloads/update manifests from latest GitHub release, tests/builds/deploys Pages |

`release.yml` store side effects require explicit manual `upload_ios_testflight`, `upload_android_play` or `submit_windows_store` inputs; all default false and tag pushes do not enable them. Windows submission additionally requires all four Store secrets. A platform rerun may replace only its public assets; maintain the others. Avoid rerunning all platforms merely to repair one upload.

## Complete and verify

1. Commit authorized source changes with the requested identity; no tool attribution. Push the exact source to the publishing remote.
2. Dispatch the narrow workflow with explicit build numbers. Record run IDs and follow to completion. A successful package job is not proof of upload processing or review status.
3. Inspect artifact identity, signature/notarization and checksums. Public releases exclude IPA, AAB, MSIX and PKG. The notarized standalone macOS CLI archive is published as the Mac App Store automation companion. Verify the release's full asset list after replacement; regenerate checksums rather than retaining old ones.
4. Refresh `website/src/data/release.json` with `website/scripts/generate-downloads.py` from the actual GitHub release JSON; regenerate desktop feeds using `generate-update-manifests.py`. The Website workflow also does this at deploy time. A replaced DMG may keep the same URL but change size/hash. Replacing a build under the same marketing version will not necessarily trigger clients' version-based update prompts.
5. Confirm Pages deployment and public `/downloads/` plus `/updates/{macos,windows,linux}.json`. Commit intended generated metadata and update `PLAN.md`; record store status/evidence under `docs/reports/` when useful.
6. Report separately: release published, uploaded/processing/valid, waiting for review, draft pending, public rollout. Do not say “released” for an inactive Play artifact or Apple build awaiting review. Include remaining blockers and actions actually taken.

Never print API tokens, client secrets, keystore passwords or key contents. Use ignored local files/environment or GitHub Actions secrets. Store IDs and tenant/client IDs identify resources but aren't authentication secrets. Read-only credential validation should not create a submission.

## Reuse Android artifacts

Prefer `android-play-publish.yml` over rebuilding or the legacy two-track lane. Inspect the exact Android-build/Release source run and choose `artifact_only` or `closed_testing` with `alpha`/`beta`. Confirm the catalog Android notes or supply explicit localized `notes_json`. The workflow validates the signed APK identity, upload certificate and AAB; the publisher verifies Google's returned code/hash, preserves other tracks, guards existing review and reads state after commit. `deferred_review` means no submission. An `outcome_unknown` result requires live inspection before retrying. Check Play Console for review/approval/tester availability; do not infer availability from track `completed`.
