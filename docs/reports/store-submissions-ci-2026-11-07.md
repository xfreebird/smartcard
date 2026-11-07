# Store submissions and CI follow-up — 7 November 2026

## Store actions

- **Huawei AppGallery:** canceled the older 0.2.0 (`1793624669`) review through AppGallery Connect, as requested. Verified the replacement APK's package `md.esemnbun.app`, version `0.2.5`, code `1793624678`, and SHA-256 `bdc18266b8f30f986dd5fff46bcbe5af65ec558c6499bfae2725c6bc19cd2311`. Uploaded and submitted it. A fresh AppGallery API read reports `releaseState=4` and code `1793624678`: reviewing, not yet available.
- **Google Play:** a fresh Developer API read shows Alpha closed testing release `0.2.5`, code `1793624678`, status `completed`. This is the requested closed track. The Play Console review/rollout state remains distinct from the track's release status; production access is still governed by Google's tester requirement.

## CI cases and changes

| Case | Earlier behavior | Updated behavior |
| --- | --- | --- |
| Ordinary Android push or all-platform release | Artifact-only Play commit could fail because an existing `HALTED` release lacked `userFraction`, making the build run red after packaging succeeded. | Signed APK/AAB and public installers build normally; Play artifact upload is an explicit manual input. The build no longer depends on current Play review or track state. |
| Two jobs request the same Android version code | The second job rejected an already reserved code even when it used the same source commit. | An explicit rebuild may reuse its own commit's reservation. A different commit cannot reuse that code. |
| Tag or release build while Microsoft has a draft/certification | Tag push could start another Store submission. | Partner Center submission requires the explicit `submit_windows_store=true` input; packaging remains separate. |
| Huawei Android workflow after every successful build | It selected the latest artifact and failed during an older active review. | Draft staging is manual with an exact completed main Android run ID. It checks APK identity and hash, and reports an active review as deferred without changing it. |
| Huawei file upload response omits `fileName` | Uploader raised `KeyError` after the file reached Huawei. | Uploader uses the verified APK's filename, checks Huawei's upload success flag, and polls for parsed version before submission. |

## Verification and limits

- Latest main CI before this workflow change: run `42404100604`, completed successfully with no failed jobs. The earlier 0.2.5 CI failure was an older macOS SDK toolbar API, already fixed in source. The earlier Release Flatpak failure was a missing Poppler GLib dependency, fixed in a successful narrow rerun.
- Six AppGallery publishing-boundary unit tests passed, including active-review deferral and Huawei's filename-omitting upload receipt. Updated workflow YAML parsed; `git diff --check` passed. The new workflow revision requires a subsequent GitHub Actions run for live validation.
- Store review, certification, and tester availability can change after this readback. `completed` in the Play track API does not by itself prove a user can install while Google has changes under review.
