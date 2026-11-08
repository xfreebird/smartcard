# Android closed testing submission — 8 November 2026

Submitted eSemnBun 0.2.6, version code **1793624684**, to the existing **closed testing Alpha** track for `md.esemnbun.app`.

The signed release bundle came from successful Android workflow [42504782544](https://github.com/xfreebird/smartcard/actions/runs/42504782544), source `4972d7ad9e92e52a143f7161905f3960e9893d17`. Android source and the shared localization catalog are unchanged between that build and validated source `78a5c563cd50989e224a19951cbd6a379dfad404`; full CI for the latter passed. No new build was needed to reuse this exact signed artifact.

- AAB SHA-256: `54810174b36ffbdfbcec016bff2cff403905345947d8ec96a5875fb8649f60b2`.
- Upload certificate SHA-256: `0bd6c7ce1a0e57b3f959917d6c166c433184a3101cad5ddd5333b82bce9324cf`, matching the earlier uploaded bundle.
- APK signature verification and AAB JAR verification passed. The self-signed upload certificate is expected for Play App Signing.
- Play returned the expected version code and exact AAB hash. The edit validated and committed with `changesInReviewBehavior=ERROR_IF_IN_REVIEW`.
- A fresh edit confirmed Alpha references 1793624684 with release status `completed`. Production, beta and internal tracks exactly match the before snapshot; no tester settings, store listing or images changed.

English, Romanian and Russian release notes describe the in-app language/theme selectors, localized PDF stamps, browser-stamp/PIN settings and refreshed illustrated guides.

## Verified publication state

The refreshed Play Console Publishing overview shows **Changes in review**, **Closed testing - Alpha**, release **0.2.6 (1793624684)** and **Start full rollout**. Google is running quick checks and displayed up to 14 minutes remaining before review submission. Managed publishing is off.

This confirms a submitted closed-track rollout, not approval or availability to testers. Google controls review and subsequent availability. Existing reviews were not cancelled. No production or internal rollout was performed.
