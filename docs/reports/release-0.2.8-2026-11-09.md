# eSemnBun 0.2.8 release

Source: cbbfff7. Test-only follow-up: fdd6d2a.

## Published

[GitHub release](https://github.com/xfreebird/smartcard/releases/tag/v0.2.8): desktop installers, signed Android APK, desktop CLI archives, Linux packages and CLI feeds. Private Store input files are excluded. Initial twelve checksum entries matched GitHub SHA-256 digests. Existing Windows direct MSI signing policy remains self-signed.

[Illustrated guides](https://esemnbun.md/docs/platforms/): EN/RO/RU instructions, 369 task pages and 684 numbered panels overall. Screenshot captions identify the captured Romanian/English interface; successful physical-card actions are not depicted.

## Store submissions

| Platform | Replacement | Verified state |
| --- | --- | --- |
| iOS | 0.2.8 (209) | WAITING_FOR_REVIEW; replaced 0.2.7 |
| macOS App Store | 0.2.8 (209) | WAITING_FOR_REVIEW; replaced 0.2.7 |
| Windows Store | 1.2.209.0 | Certification; submission 1152921505702353222 |
| Google Play | 1793624688 | Submitted to existing alpha closed track only |
| Huawei | 1793624688 | Review state 4; replaced 0.2.7 |

Apple and Windows notes use platform-specific EN/RO/RU copy. Initial macOS Store release cannot have What's New; that field remains absent. Huawei's existing English locale uses Android notes. No other Play tracks changed. Review/certification is not public availability.

## Validation

- Full CI 42616177821 passed. Linux removal test now uses supported tmpfs instead of the deliberately rejected container overlay filesystem.
- Release 42615342586 and macOS Store upload 42615347470 passed.
- Android artifact source 42615333208; upload certificate SHA-256 verified against the pinned upload key.
- Play 42616393691: first pre-commit HTTP 400 did not change the track. Verified retry submitted the exact bundle and rerun succeeded idempotently.
- CLI repositories 42616965333 passed.
- Website: 25 tests, three locale production builds, guide coverage and SEO checks passed. Initial guide deployment 42615332988 verified live.
- No real-card encryption/decryption operation performed; existing vendor fixture and simulated-card test evidence is in the file-protection report.
