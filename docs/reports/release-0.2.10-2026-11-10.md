# eSemnBun 0.2.10 — protection UX and delivery

## Changes

- Protection is available from native navigation/header menus.
- Password fields have explicit labels and borders; unsupported national-ID certificate/card choices are removed from native app forms. CLI compatibility operations remain available for compatible encryption certificates.
- Completed operations show Done/Close and retain encrypted/decrypted results in Documents, with separate types. Mobile outputs are saved privately; desktop destination-picker flows retain saved results. History clearing does not remove the saved files.
- English, Romanian and Russian illustrated guides were refreshed across Mac, iPhone, iPad, Android phone/tablet, Windows and Linux: 96 native screenshots, 327 task pages and 702 numbered panels. Annotation gutters keep markers outside UI pixels.

## Validation

Production source `7bb81e6` passed full CI `42784306555`. All six platform packaging jobs in `42784324572` passed. The final hosted publication job was blocked by the account's Actions spending budget; the verified assets were published to the repository directly from the main Mac.

- iOS native UI: file picker → encrypt → saved document details → decrypt → app relaunch passed. Restored PDF bytes match the original; managed files use mode 0600.
- Apple document library: seven tests passed.
- Android: 137 core tests, zero failures, one opt-in skip; emulator vendor-compatible crypto, save/reload/delete and separate-process persistence passed.
- Linux: native build/tests passed, including six document-store tests with real encrypt/decrypt and byte comparison.
- Windows: native build passed; seven storage/crypto probe checks passed. These use current library/core code with UI-only stubs.
- Full Windows/Linux UI picker-to-save validation was not completed because remote input was unreliable.
- Guide validation, four annotation/navigation tests and all three locale builds passed. Workflow lint and fourteen CI-selection tests passed after recovery changes.

## Release artifacts

GitHub release (private repository): https://github.com/xfreebird/smartcard/releases/tag/v0.2.10

Apple/Windows build: 212. Android: 1793624693. All twelve release installer/package digests match GitHub's uploaded-asset digests. Store-only IPA/AAB/MSIX/PKG files are excluded. macOS DMG notarization and staple validation passed; Windows downloaded artifact checksums passed.

Linux's AppStream version was corrected in `aad9618`. Exact final-source Linux CI artifacts were repackaged with version 0.2.10; executable/library bytes, modes, symlinks and dependencies were preserved. Flatpak was imported afresh and its complete payload verified; only the three expected AppStream XML copies changed. The x86_64 repack was not installed on the aarch64 verification host. Evidence is in `/tmp/esemnbun-0210-artifacts/repack-evidence/`.

## Store and website state

- iOS: 0.2.10 build212, waiting for review; submission07057305-79bb-49b8-a8c6-89f670927003.
- macOS: pending0.2.9 review withdrawn; 0.2.10 build212 waiting for review, submission85cd559b-0fe4-4a59-97d9-762a59c03b76.
- Play: Alpha0.2.10 (1793624693) submitted; Console confirms In review. Other tracks preserved.
- Windows: 1.2.212.0 passed certification and was manually released in Firefox; Partner Center confirms Update in publishing; submission1152921505702364054. Store propagation remains pending.
- Huawei: older review preserved while the displayed CAPTCHA awaits the tool-required action-time confirmation. Replacement APK is prepared and signature-verified.
- Website: recovery run42789721944 attempt3 built all locales, passed tests/SEO checks, then failed at artifact upload because GitHub storage quota remained exceeded. The updated guides are not live yet. The prior production site remains unchanged.

The original hosted website deployment never started because the Actions budget was exhausted. The first local recovery exposed macOS's older Python; the workflow now pins Python3.12, uses an existing managed interpreter on recovery Macs, and documents GNU tar as a prerequisite. Recovery runners are ephemeral, use the existing Pages/OIDC environment, and need no Store credentials. No permanent runner service is installed.

## Remaining delivery and recovery

GitHub Actions reported a hosted spending-budget block and an artifact-storage quota block. Deleted306 obsolete, reproducible CI artifacts created before9November, reclaiming53,473,119,050bytes; Release/store artifacts and recent validation evidence were preserved. CI Linux/Windows package retention is now one day. GitHub reports storage usage recalculation takes6–12hours, and the final upload retry after cleanup still failed.

After storage accounting refreshes, rerun Website42789721944 failed jobs using two freshly registered ephemeral `esemnbun-recovery` runners (build, then deploy), or dispatch Website on a funded hosted runner. Recovery Macs need the documented Python3.12/uv, Node prerequisites, gh, gpg/gpgv and gtar. Confirm Pages succeeds, verify EN/RO/RU guides and image hashes, and inspect live update feeds.

Huawei replacement remains blocked at the displayed browser CAPTCHA because the computer-use tool requires per-action confirmation. The latest APK remains at `/tmp/esemnbun-0210-artifacts/android/eSemnBun-0.2.10.apk`; SHA256`20cb52cb85e61216e9da9cb991f7e1b178992b222981deaf8ae28dfd774e7587`. Preserve the old review until the authorized browser verification permits replacement.
