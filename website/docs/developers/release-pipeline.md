---
title: Release pipeline
description: Follow one eSemnBun version from a prepared commit to GitHub downloads, signed Windows files, package feeds, the website and five app stores, with the workflow behind each step.
---

A release starts from one prepared commit on `main` and runs through three delivery lanes. **Downloads** covers the GitHub Release, package feeds, the website and the Microsoft Store. **Apple** covers the App Store and Mac App Store. **Android** covers Google Play and Huawei AppGallery. Most steps are GitHub Actions workflows started by hand; some follow automatically. Two steps run outside Actions: Windows code signing and attaching the Android APK to the GitHub Release.

This page walks through a complete release in order. To choose a single operation, use [Release and store delivery](releasing.md). The repository's `docs/14-github-actions.md` documents every input, guard and recovery case, and the workflow files in `.github/workflows/` are authoritative.

![Release pipeline: a prepared commit on main feeds three lanes. Downloads: Release workflow, GitHub Release, Certum signing, CLI package repositories, website. Apple: TestFlight upload, App Store Connect processing, App Review workflow, App Review. Android: Android build, Play publisher, Huawei draft, APK attached to the GitHub Release. All lanes end in verification.](/img/developers/release-pipeline.svg)

[Open the full-size diagram](https://esemnbun.md/img/developers/release-pipeline.svg). Blue boxes are workflows you dispatch, green boxes run automatically, orange boxes are owner steps outside Actions, and grey boxes are store processing. The lanes are independent: a failed Android build does not block the Apple submission, and each lane is verified on its own.

## What "released" means

Each lane passes through several outcomes. Report them separately; a green workflow is only the first.

| Outcome | Evidence |
| --- | --- |
| Built | The workflow job succeeded and its artifact has a recorded SHA-256 |
| Published download | The file is on the GitHub Release, listed in `SHA256SUMS.txt` and served by the website |
| Uploaded to a store | TestFlight build `VALID`, Play bundle uploaded, Huawei draft attached |
| Submitted for review | App Store `WAITING_FOR_REVIEW`, Play track submitted, Huawei state Reviewing, Microsoft certification |
| Available to users | The store approved and released the version |

## Identities that must line up

| Identity | Where it lives | Rule |
| --- | --- | --- |
| Marketing version `X.Y.Z` | `MARKETING_VERSION` in `apple/eSemnBun.xcodeproj/project.pbxproj` (every target), `<Version>` in `windows/Directory.Build.props`, `versionName` in `android/app/build.gradle.kts`, a `<release>` entry in `linux/data/md.moldsign.MoldSign.metainfo.xml` | Identical on every platform |
| Release tag `vX.Y.Z` | Created by the Release workflow from `MARKETING_VERSION`, unless its `tag` input says otherwise | One tag per version |
| Apple and Windows build number | `build_number` input of Release and Apple TestFlight | One integer for iOS, Mac App Store and Windows; higher than every build already uploaded to each store |
| Android version code | Reserved by `scripts/ci/reserve-android-version.sh` as an `android-play-vc-<code>` tag | Higher than every uploaded bundle; never reused for different source. Failed builds leave harmless gaps |

Read the highest uploaded build in each store before choosing numbers. The workflow run counter is not a reliable source after manual overrides.

## 1. Prepare the version on main

1. Set the marketing version in the four files above and add the Linux `<release>` entry with its date.
2. Write the release notes in `localization/catalog.json`, under `storeMetadata.<en|ro|ru>`: `releaseNotes` and `releaseNotesByPlatform.<android|ios|macos|windows|linux>`. Google Play accepts 500 characters per locale and Apple 4000.
3. Regenerate the store exports (`distribution/`, including Apple's `release_notes.txt` and the Play changelogs), then check that nothing drifted:

   ```sh
   python3 scripts/prepare-store-metadata.py
   python3 scripts/prepare-store-metadata.py --check
   python3 scripts/localize.py --check
   ```

4. Add a `PLAN.md` entry, commit, push to `main` and wait for the `CI result` check.
5. Read the current store state: the highest uploaded builds and any review still pending. The pipeline never replaces an active review on its own. For Apple, the review workflow's `status` operation is read-only.

## 2. Start the three build lanes

Use the same `BUILD` integer for Release and Apple TestFlight. The commands assume the publishing account's `gh` session; `GH_HOST=github.com` keeps it apart from any other GitHub host.

```sh
# Downloads lane: macOS, Linux, Flatpak and Windows, plus the Microsoft Store submission.
GH_HOST=github.com gh workflow run release.yml -R xfreebird/smartcard --ref main \
  -f only=desktop -f build_number=BUILD -f submit_windows_store=true
# Apple lane: iOS and Mac App Store builds to TestFlight.
GH_HOST=github.com gh workflow run apple-testflight.yml -R xfreebird/smartcard \
  -f platform=both -f build_number=BUILD
# Android lane: reserve a version code and build the signed APK and AAB once.
GH_HOST=github.com gh workflow run android-build.yml -R xfreebird/smartcard -f upload_play=false
```

`only=desktop` keeps store builds out of Release. The Apple store packages come from Apple TestFlight. Android is built once by Android build, so Google Play, Huawei AppGallery and the website serve the same APK and bundle. `only=all` also builds iOS and Android inside Release. Google Play accepts such a Release run as its source, but the Huawei workflow accepts only an Android build run.

Identify each run by its workflow, inputs and head commit, and keep the Android build's run ID: the store steps reuse its artifact.

## 3. GitHub Release and what follows automatically

The Release workflow runs these jobs:

1. **Reserve release tag** creates `vX.Y.Z` on the run's commit before any build. A tag created later, after `main` gained a workflow change, would be refused to the workflow token. The job stops if the tag already points at another commit without a release.
2. **Platform builds:**
   - macOS: Developer ID DMG and CLI, notarized.
   - Linux: tarball, `.deb` and `.rpm`.
   - Flatpak bundle.
   - Windows: MSI, MSIX, CLI ZIP and winget manifests.

   With `submit_windows_store=true` and all four Microsoft Store secrets, the Windows job also submits the MSIX with the catalog's Windows release notes. Certification follows in Partner Center.
3. **GitHub Release** creates or updates the release, removes store-only packages (IPA, AAB, MSIX, PKG) and regenerates `SHA256SUMS.txt` over every file. Platforms that failed are named in the run summary, and in the notes of a newly created release; rerun Release with `only=<platform>` to add them.

When Release succeeds, two workflows start on their own:

- **CLI package repositories** (`cli-packages.yml`) waits until the latest stable release has every CLI file. It then builds the signed APT and RPM repositories, the Scoop and Homebrew definitions and a tested Chocolatey package, uploads them to the release and refreshes `SHA256SUMS.txt`. It also runs weekly and on demand.
- **Website** (`website.yml`) regenerates the download metadata and the macOS, Windows and Linux update feeds from the latest release. It verifies the listed digests and deploys GitHub Pages. It runs again after the package feeds succeed.

## 4. Attach the Android APK

The website offers the APK from the Android build. Attach that exact file to the release, regenerate the checksums and redeploy the website, which ran before the APK existed:

```sh
GH_HOST=github.com gh run download ANDROID_RUN -R xfreebird/smartcard --name esemnbun-android --dir android
apk=$(find android -name '*.apk')
GH_HOST=github.com gh release upload vX.Y.Z -R xfreebird/smartcard --clobber "$apk"
mkdir all && GH_HOST=github.com gh release download vX.Y.Z -R xfreebird/smartcard --dir all
(cd all && rm -f SHA256SUMS.txt && shasum -a 256 * > ../SHA256SUMS.txt)
GH_HOST=github.com gh release upload vX.Y.Z -R xfreebird/smartcard --clobber SHA256SUMS.txt
GH_HOST=github.com gh workflow run website.yml -R xfreebird/smartcard
```

Check the APK's package name, version code and upload certificate (`apksigner verify --print-certs`) before uploading.

## 5. Sign the Windows files

The Release MSI carries the project's self-signed certificate. Public releases replace the MSI and the CLI ZIP with copies signed by the Certum code-signing certificate. Its key is a cloud key reached only through Certum SimplySign Desktop, so this step runs on an owner-controlled Mac with SimplySign and Jsign, not in Actions:

1. Download the released MSI and CLI ZIP and record their hashes.
2. Sign `esemnbun.exe` and rebuild a copy of the ZIP with only that file replaced. Keep entry names, order, timestamps and attributes. Signing `esemnbun.exe` covers both its CLI and MCP modes.
3. Sign a copy of the MSI with an RFC 3161 timestamp. The MSI signature covers the installer; it does not add signatures to files inside it.
4. Verify both with `osslsigncode verify`. Ideally also verify on Windows with `signtool verify /pa /all /v` and `Get-AuthenticodeSignature`.
5. Upload both with `--clobber`, regenerate `SHA256SUMS.txt` as in step 4, then dispatch `cli-packages.yml`. The Chocolatey package, the Scoop definition and the repository archive then carry the signed executable, and the website redeploys after it.

The repository's Certum signing skill (`.agents/skills/esemnbun-certum-sign/`) has the exact commands. A valid signature does not establish SmartScreen reputation.

## 6. Submit to the stores

Store steps start after their uploads finish. Each one is a separate operation; a request for one does not authorize the others.

**Apple.** Wait until App Store Connect shows build `BUILD` as `VALID`, then run `status` and, after reading it, `submit`:

```sh
GH_HOST=github.com gh workflow run apple-app-review.yml -R xfreebird/smartcard \
  -f platform=both -f version=X.Y.Z -f build_number=BUILD -f operation=status
GH_HOST=github.com gh workflow run apple-app-review.yml -R xfreebird/smartcard \
  -f platform=both -f version=X.Y.Z -f build_number=BUILD -f operation=submit
```

`submit` does the following:

- Creates or reuses the App Store version, keeping the previous version's release type (manual or after approval).
- Sets What's New for every locale from `distribution/apple/<platform>/<locale>/release_notes.txt`.
- Attaches the build and submits it for review.

It never replaces an active review or another unfinished version. Results:

- `already_submitted`: the version already holds this build; nothing changed.
- `outcome_unknown`: run `status` before anything else.

**Google Play.** Publish the exact Android build artifact. Optionally submit a closed track (`operation=closed_testing -f closed_track=alpha`) first, then roll out to production:

```sh
GH_HOST=github.com gh workflow run android-play-publish.yml -R xfreebird/smartcard \
  -f android_run_id=ANDROID_RUN -f operation=production -f expected_version=X.Y.Z
```

The publisher checks the APK identity and upload certificate, then uploads the bundle if Play does not have it and verifies Google's returned hash. It sets only the selected track, at 100%, with the catalog notes. It commits only when no other change is in review, then reads the result back. Production refuses a downgrade and a track that still holds a staged, halted or draft release. Results:

- `deferred_review`: an existing review was preserved and nothing was submitted.
- `submitted`: sent for Google review. The Play Console's Publishing overview shows the approval.

**Huawei AppGallery.** Stage the same APK as a draft, then submit it for review with the owner's API credentials:

```sh
GH_HOST=github.com gh workflow run huawei-appgallery.yml -R xfreebird/smartcard -f android_run_id=ANDROID_RUN
python3 scripts/appgallery.py --apk path/to/eSemnBun-X.Y.Z.apk --version-code CODE   # HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON set
```

The draft workflow defers without changes while an older review is active. The script reports when the build is already uploaded or superseded.

**Microsoft Store.** Release submitted the MSIX in step 3. Follow certification and publication in Partner Center; certification is not publication.

## 7. Verify and record

- **Checksums:** `shasum -a 256 -c SHA256SUMS.txt` in a folder of downloaded release files. The file also matches the digests GitHub lists for each asset.
- **Signatures:**
  - macOS: `codesign --verify --deep --strict` and `spctl --assess` on the app in the DMG.
  - Windows: `signtool verify /pa` (or `osslsigncode verify`).
  - Android: `apksigner verify --print-certs`.
- **Website:** `/downloads/` in English, Romanian and Russian, and `/updates/macos.json`, `/updates/windows.json` and `/updates/linux.json`, all show the new version. Downloaded bytes match the release, and the guides render.
- **Stores:** Apple through the review workflow's `status`; Google Play through the Publishing overview; Huawei release state; Microsoft submission status.
- **Record:** write a report under `docs/reports/release-X.Y.Z-<date>.md`: run IDs, hashes, store states and follow-ups. Add a `PLAN.md` entry.

## How the workflows connect

| Workflow | Starts on | Starts afterwards |
| --- | --- | --- |
| `ci.yml` | Pushes and pull requests | Nothing; validation never publishes |
| `release.yml` | Manual dispatch or a pushed `v*` tag | CLI package repositories and Website, when it succeeds |
| `cli-packages.yml` | Successful Release, weekly (Monday 05:17 UTC) or manual | Website, when it succeeds |
| `website.yml` | Successful Release or package feeds, website source pushes to `main`, or manual | — |
| `apple-testflight.yml`, `apple-app-review.yml` | Manual | — |
| `android-build.yml`, `android-play-publish.yml`, `huawei-appgallery.yml` | Manual | — |

A tag created by the Release workflow's own token does not start the tag-push path: GitHub starts no workflows from events created with that token.

## Guards built into the pipeline

- **Release store flags.** Release's store options (`upload_ios_testflight`, `upload_android_play`, `submit_windows_store`) default to off. A tag push never turns them on.
- **Serialized publishing.**
  - Android builds and Play operations share the `android-play-version-code` concurrency group.
  - Apple uploads and App Review share `apple-store-ios` and `apple-store-macos`.
  - Publishing runs are never cancelled to save time: a cancelled upload can leave an unknown result or spend a build number.
- **Exact artifacts.** The store steps reuse the exact signed artifact of an inspected run, never "the latest", and verify its package identity, signature and hash.
- **Reviews and other tracks.** No step replaces an active review or changes a track or version it was not asked to change.
- **Uncertain results.** After a timeout or `outcome_unknown`, read the live state before retrying. No step repeats a store change automatically.

## Credentials

Workflows read credentials from repository Actions secrets:

- **Apple:** `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `MATCH_PASSWORD`, `APPLE_TEAM_ID`.
- **Android:** `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- **Stores:** `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `HUAWEI_APPGALLERY_SERVICE_ACCOUNT_JSON`, and `MSSTORE_TENANT_ID`, `MSSTORE_CLIENT_ID`, `MSSTORE_CLIENT_SECRET`, `MSSTORE_SELLER_ID`.
- **Signing:** `WINDOWS_MSI_CERTIFICATE_PFX_BASE64` with `WINDOWS_MSI_CERTIFICATE_PASSWORD` (self-signed MSI) and `PACKAGE_SIGNING_KEY` (APT/RPM).

The Certum key is not among them: it never leaves Certum's service. Credential values never belong in workflow inputs, commands, logs, artifacts or the repository.

## When something fails

| Case | Next step |
| --- | --- |
| A platform job failed in Release | Fix it, then rerun Release with `only=<platform>`; the other assets stay |
| Release tag job: tag points elsewhere and has no release | A stale tag from a failed run: delete it, or pass another `tag` |
| Android build failed after reserving a version code | Rebuild; the skipped code is harmless and is never reused |
| CLI package repositories says "waiting" | The release lacks a CLI file; complete the release and rerun |
| Website still shows the previous version | Dispatch `website.yml` after the last asset change; check with a cache-busting request |
| Play `deferred_review` | An earlier change is in review; rerun after it completes |
| Play or App Review `outcome_unknown` | Inspect the live state (`status` for Apple, Play Console for Google) before anything else |
| Store rejects a build number | Read the store's real maximum, choose a higher number and rebuild that lane |

More cases and their recovery are in [Release and store delivery](releasing.md) and the repository's `docs/14-github-actions.md`.
