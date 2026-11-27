# eSemnBun 0.2.15 delivery

The owner requested 0.2.15 on every channel through to production, run from the MacBook Air (from now on an approved publishing host, see AGENTS.md §8). Before any change, no store had a pending review: iOS and Mac 0.2.14 (build 217) were ready for sale, Play production and alpha served 1793624702, the Microsoft Store had published 0.2.14 (1.2.217.0) and Huawei had released 1793624700.

Application source is `2f8ea3a3d6df5d902554048f01653d7b923fc343`, tagged `v0.2.15`. Apple/Windows build is **218**; Android version code is **1793624705**. The Android binary was built from `a39109b4`, which differs from the tag only in the Maven Central mirror for the signed Android workflows (below). Changes since 0.2.14: the security hardening of PR #2, Android R8 optimization with edge-to-edge layout and the NFC reader-mode fix, the macOS window update on card insertion, the Windows PDF page-tree change and dependency updates.

## Delivery state

| Destination | Result observed on 27 November 2026 |
| --- | --- |
| GitHub/direct downloads | [0.2.15 published](https://github.com/xfreebird/smartcard/releases/tag/v0.2.15): notarized macOS DMG/CLI, Certum-signed Windows MSI and CLI, Android APK, Linux packages and Flatpak. 15 payloads match `SHA256SUMS.txt` and GitHub's own asset digests. |
| iOS | 0.2.15 build 218 **WAITING_FOR_REVIEW** (submission `7044806b-fae4-43a1-a1a0-62fd2ff97040`), automatic release after approval. |
| Mac App Store | 0.2.15 build 218 **WAITING_FOR_REVIEW** (submission `9683a3b6-a4c7-4b1f-9dfb-732dcbc9c2c2`), automatic release after approval. |
| Google Play | Production set to **0.2.15 (1793624705)**, full rollout, EN/RO/RU notes; alpha and internal unchanged. API status `completed` means sent to Google, not approved: check Publishing overview. |
| Huawei | Draft 1793624705 submitted through the API; release state **5 (Reviewing)**. |
| Microsoft Store | MSIX **1.2.218.0**, submission `1152921505702523571`, passed certification and is **Published**. |
| CLI package feeds | APT/RPM repositories, Scoop/Homebrew definitions and the Chocolatey package rebuilt from the signed CLI. |
| Website | Downloads (EN/RO/RU) and the macOS/Windows/Linux update feeds advertise 0.2.15. |

Apple versions were created through the App Store Connect API: What's New for every existing locale from `distribution/apple`, build 218 attached, review submission created and submitted. Descriptions, keywords, screenshots and review notes carried over from 0.2.14 and were checked before submission.

## Build and publishing evidence

- Release [45974348610](https://github.com/xfreebird/smartcard/actions/runs/45974348610) (`only=desktop`, build 218, Windows Store submission): every platform job succeeded. Its first GitHub Release job failed with HTTP 403: after `main` gained a workflow-file change, `GITHUB_TOKEN` may no longer create a tag on the older commit. The owner's account created `v0.2.15` → `2f8ea3a3` while `release.yml` was disabled for those seconds (so the tag push started no full rebuild), the workflow was re-enabled, and attempt 2 of only the failed job published the release.
- Apple TestFlight [45974353268](https://github.com/xfreebird/smartcard/actions/runs/45974353268): iOS and macOS build 218 uploaded and processed **VALID**.
- Android build [45974358499](https://github.com/xfreebird/smartcard/actions/runs/45974358499) failed twice: Maven Central answered every Kotlin plugin request with HTTP 429, consuming version codes 1793624703/1793624704 (harmless gaps). `a39109b4` gives `android-build.yml` and Release's Android job the `MAVEN_CENTRAL_MIRROR` CI already used. Build [45975110678](https://github.com/xfreebird/smartcard/actions/runs/45975110678) produced 1793624705; `md.esemnbun.app`, version 0.2.15 and the pinned upload certificate `0bd6c7ce…9324cf` were checked locally.
- Play [45977298917](https://github.com/xfreebird/smartcard/actions/runs/45977298917) uploaded that exact AAB (`artifact_only`). Production was then assigned to the uploaded bundle with an API edit that refused downgrades and other-track changes and was read back after commit. The first validation returned 403 PERMISSION_DENIED; the owner granted the service account production release permission.
- Huawei draft [45978006140](https://github.com/xfreebird/smartcard/actions/runs/45978006140) attached 1793624705; `scripts/appgallery.py` submitted it.
- CLI packages [45976003072](https://github.com/xfreebird/smartcard/actions/runs/45976003072) (unsigned CLI) and [45981883061](https://github.com/xfreebird/smartcard/actions/runs/45981883061) (Certum-signed CLI) succeeded; Website deployments followed.
- CI [45975112915](https://github.com/xfreebird/smartcard/actions/runs/45975112915) on `a39109b4` passed every job (Apple UI journeys remain paused by `APPLE_UI_TESTS`). The superseded run on `2f8ea3a3` had one Robolectric timeout (`AppShellTest.sharedDocumentsAreCopiedAndQueued`) on unchanged code; it passed in the following run.

| Artifact | SHA-256 |
| --- | --- |
| Android APK | `7268bde8ff7bc5d6c8b24231e2e15c4e14f6dad85c1ecc8143f63868ac4851ad` |
| Android AAB | `524b8697ed12ad0c137afefecf37859ccef83a84d98f9dbafc68cd08b0a2a311` |
| macOS DMG | `dbd33d3669cae4cc50e4ff7c16d16c30335233c0112dcd0a52dac1449e9be24e` |
| Windows MSI (Certum) | `119829b1fde280ee057eb0fe2549c3d1f85074eaa44ce20a1996bf3739e9dc53` |
| Windows CLI ZIP (Certum exe) | `9476b77c2fa112f202376097446f3b2c5af7822f0374916fd8e5fe4a445b5b26` |
| Windows `esemnbun.exe` | `b0761848043dec24244e250937b81e28889f6268d8073e0cedeb0f393430d857` |

## Certum signing on the MacBook Air

Set up during this release: SimplySign Desktop 2.10.24 / proCertum SmartSign 9.4.5.0 from Certum's official DMG (`25be8d13…`; installer signed by Asseco Data Systems SA `3A63AEGXJ7`, notarized), Homebrew Jsign 7.6 with OpenJDK 21.0.13.1, osslsigncode 2.16, OpenSC 0.27.1 and the Homebrew CA bundle. The provider configuration lives in ignored `.local/certum/`. The token's only certificate (serial `05041264643BA81E4379AE5878D89D81`, SHA-256 `8D:08:A4:CC…6C:BD`, Certum Code Signing 2021 CA, valid to 20 November 2027) is the one that signed the public 0.2.14 MSI.

Copies of the released MSI (`7c2fac15…`, self-signed) and of `esemnbun.exe` from the CLI ZIP (`0b3a4481…`, unsigned) were signed with Certum's RFC 3161 timestamp. The ZIP was rebuilt with only the executable replaced (entry names, order, timestamps, compression and attributes preserved). osslsigncode verified signature, chain, CRL and timestamp for both. On the Windows 11 VM, `signtool verify /pa /all /v /tw` reported one verified signature, 0 warnings and 0 errors for each, and `Get-AuthenticodeSignature` reported **Valid**; transfer hashes matched. The rebuilt Chocolatey package embeds the signed executable, the Scoop definition references the signed ZIP and the repository archive carries it. The MSI container signature does not add signatures to embedded binaries; SmartScreen reputation is not established by this.

## Website

The landing page no longer says the Mac App Store edition has no card-insertion launcher (`b81bc451`), and the macOS guide (EN/RO/RU) now describes the launcher in both editions (`6f100d72`). 74 website tests and the guide validator passed.

## Follow-ups

- `cli-packages.yml` writes `SHA256SUMS.txt` with CRLF line endings (also in 0.2.14), so `sha256sum -c` on Linux/macOS reports missing files; the hashes themselves are correct.
- `android-play-publish.yml` has no production operation, and Apple review submission has no lane; both were done with guarded API calls this time.
- The Release workflow cannot tag an older commit once `main` has a newer workflow change; dispatch Release before pushing workflow edits, or tag first.

Store review/rollout is asynchronous. Submission and upload success do not establish approval. No credentials, tokens or private keys were printed or committed.
