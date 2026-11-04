# Android Play rejection: independent app and official sources

Google Play issue 4989536497687389733 identified missing official government information sources in the English full description and the in-app experience. The owner requested the non-government affiliation route, without an appeal or any claim of government authorization.

The Android app now presents an EN/RO/RU independence notice on first launch (including upgrades from older builds), with an acknowledgement stored locally. Browser and Settings > About retain access to the full disclosure and tappable official MSign, MPass, EVO, eVMS and MPay sources. The notice identifies the independent author and explains that service access, requirements and eligibility belong to the external providers.

Android store copy begins with the disclosure and explicit official source URLs in all three languages. The shared metadata exporter also carries this Android-specific correction into the Huawei metadata, without changing the Apple or Windows descriptions. Play metadata now uses the actual ru-RU listing locale and can be uploaded by the testing lane when PLAY_UPLOAD_METADATA=true and the credential has store-presence permissions.

Validation: debug APK compiled, five app unit tests passed, lint completed with zero errors (68 existing warnings and one hint); generated localization, metadata drift, Ruby syntax and whitespace checks passed. The debug APK was installed and launched on a fresh API 36 ARM64 emulator, with no AndroidRuntime crash logged. Native emulator UI inspection was unavailable through the computer-control tool, so launch evidence does not constitute visual layout verification.

Play Console Government apps declaration was inspected and already has No selected. CI and final submission results follow below.

CI run 41884731637 built signed APK/AAB successfully, but metadata commit was denied with HTTP 403. The existing service account was not expanded. Uploaded those exact CI artifacts through the testing API without listing mutations: internal completed and Alpha completed at version code 1793624673, with localized policy-update release notes. Updated all three listings in the authenticated Firefox session; a read-only API comparison confirms exact equality with repository full descriptions. The lane now defaults metadata upload off to preserve working build automation.

Final submission: used Publishing overview > Submit 18 changes for review > Send changes for review. Console confirms **Changes in review**, showing **0.2.1 — independent app and official sources**, with automated quick checks running before review. Google approval is pending; no appeal or government affiliation assertion was filed.
