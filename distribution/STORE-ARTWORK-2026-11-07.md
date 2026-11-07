# Approved store artwork — 7 November 2026

The reviewed pack is now preserved under `distribution/`, with original PNG
bytes retained. No artwork was regenerated during integration.

| Store asset | Tracked source | Count |
| --- | --- | --- |
| Apple standard screenshots | `apple/screenshots/{en,ro,ru}/{iphone,ipad,macos}` | 48 |
| Apple Duo screenshots | `apple/supplemental/{en,ro,ru}/{duo-compact,duo-expanded}` | 30 |
| Apple featured artwork v5 | `apple/creative/current/{en,ro,ru}` | 6 |
| Apple featured composition sources v5 | `apple/creative/source` | 6 current placement sources |
| Google approved composed screenshots | `google/submission-screenshots/{en,ro,ru}/{phone,seven-inch,ten-inch}` | 36 |
| Google native capture archive | `google/assets/android/{en,ro,ru}/{phone,seven-inch,ten-inch}` | 36 |
| Microsoft native screenshots | `microsoft/assets/{en,ro,ru}` | 12 |

The Google submission images are the reviewed rounded compositions marked
`submissionScreenshot: true` in their manifest. The native captures remain
separate. Existing icons, feature graphics, Microsoft hero art and captions are
retained. The 126 screenshots and six Apple featured assets were compared
byte-for-byte with the approved pack. Manifest checksums and RGB/dimensions
were checked where recorded. No builds or application tests were run for this
asset integration.

## Apple uploads

The screenshot uploader accepts `distribution` as its pack root:

```sh
bundle exec ruby distribution/tools/upload-apple-draft.rb ios distribution --screenshots-only --replace-changed-screenshot-sets
bundle exec ruby distribution/tools/upload-apple-draft.rb macos distribution --screenshots-only --replace-changed-screenshot-sets
```

The creative uploader expects `PACK/apple/creative/{locale}`. The local ignored
pack `.local/store-upload-2026-11-07` links that location to
`distribution/apple/creative/current` and links the screenshot paths above.

```sh
bundle exec ruby distribution/tools/upload-apple-creative.rb .local/store-upload-2026-11-07 --replace-existing
```

All commands require the existing App Store Connect environment credentials.
They update editable drafts and do not submit review. The macOS uploader also
retains the established `eSemnBun for Mac` listing name and English-GB copy.

## Google upload mapping

Supply's metadata structure uses `images/phoneScreenshots`,
`images/sevenInchScreenshots` and `images/tenInchScreenshots`, under locales
`en-US`, `ro` and `ru-RU`. The ignored local directory
`.local/store-upload-2026-11-07/google-metadata` links those folders to the
approved composed screenshots. The ordinary Android release lane explicitly
skips screenshots and images, so it does not update this artwork.

Use an account with store-presence permissions or upload the same PNGs through
Play Console. The historically restricted testing service account does not
gain store-presence rights by enabling metadata upload. Huawei's existing APK
upload helper preserves listing artwork; updating Huawei screenshots requires
the AppGallery listing flow separately.

## Microsoft draft upload

`tools/upload-microsoft-screenshots.py` defaults to a read-only pending-submission
inspection. Credentials use existing `MSSTORE_*` environment variables or
`--credentials /absolute/private/path.json`.

```sh
python3 distribution/tools/upload-microsoft-screenshots.py
python3 distribution/tools/upload-microsoft-screenshots.py --submission EXACT_DRAFT_ID --upload
```

The upload requires `PendingCommit`, replaces only desktop screenshots in the
three existing locales, uploads their archive and verifies the draft references.
It never creates, commits, publishes or cancels submissions. Pending package,
image or trailer uploads stop the operation to avoid overwriting an ingestion
archive needed by another upload. The mutation path has not been exercised.

Read-only inspection on 7 November found submission `1152921505702336016`
with package `1.2.204.0`, state `Release`, manual publish mode and no errors.
It is not an editable draft. The last published package was `1.2.203.0`.
Recheck before acting; these are historical observations.

API contract: [Microsoft app submission resources](https://learn.microsoft.com/en-us/windows/uwp/monetize/manage-app-submissions).
