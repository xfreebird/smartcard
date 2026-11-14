# Browser language follows the app

Implemented for the embedded browsers on iOS, macOS and Android. Windows and Linux retain their external-browser behavior by the owner's explicit decision. Their external browser and website remain responsible for page language.

## Behavior

- Explicit English, Romanian or Russian selection is used for initial navigation, browser JavaScript language preferences, and MSign's persisted language.
- System mode resolves through supported app languages with the app's Romanian fallback.
- One shared document-start script initializes MSign before its SPA reads storage. Only the top-level HTTPS msign.gov.md origin receives storage changes, and unrelated stored fields are retained.
- App language changes recreate the Android WebView or refresh the Apple page. Apple configuration reuse replaces the locale script rather than accumulating older scripts.
- Explicit opens and new-window requests on Apple retain their request method/body and add Accept-Language. Android explicit opens and downloads use the same header.
- Normal portal redirects and form submissions remain owned by the web engine. No interception/replay of authentication POST requests.
- On older Android WebView providers without document-start injection, page completion seeds MSign storage and reloads at most once per URL per browser session. A brief original-language render is possible on those providers.
- Arbitrary websites can still enforce their own URL, account, cookie or server locale. The browser supplies the app preference; the MSign adapter addresses its known Romanian default.

## Validation — 14 November 2026

The owner explicitly requested builds and tests for this validation. Validation used the main-Mac working tree based on 26fa3bf728ff133531ccb58bb5d3d460523d2867 with the locale changes delivered in this commit. No application release was created.

| Platform/check | Result and coverage |
| --- | --- |
| Shared policy | 17/17 Node tests passed; generated Swift/Kotlin exports match. |
| Android | Debug app and instrumentation APK built; 16 app unit tests passed. Real Android WebView fixture tests passed EN/RO/RU before the first page script, preservation of unrelated persisted state, origin isolation, and the legacy-provider fallback's idempotence. |
| iOS | Full app simulator build passed with Xcode 27.1. Native WKWebView fixture probe passed EN/RO/RU on an isolated iPhone 16 / iOS 26.5 simulator. |
| macOS | Full app compilation passed with Xcode 27.1 (signing disabled). Native WKWebView fixture probe passed EN/RO/RU on macOS 26.7.1. This is not distribution-signing validation. |
| Apple System mode | Native resolver passed regional Russian, unsupported-language Romanian fallback, and secondary supported-language selection on iOS; Russian, English and Romanian fallback passed on macOS. |
| Windows / Linux | Source audit confirmed no changes to either platform. External browsers and websites continue to control their own locale, as requested. No native Windows/Linux runtime run was needed for this unchanged behavior. |

Apple native fixtures used the production BrowserLocale and BrowserLocaleScript code with real WKWebView instances. They checked language before the fixture's first script, existing Romanian storage, preservation of synthetic session fields, repeated script installation, other-origin storage isolation, and preservation of POST method/body when adding the request header. Android's reusable browser-locale instrumentation suite uses the production generated script in real WebViews. These are WebView integration tests, not end-to-end journeys through the production app's settings screens.

### Corrections found during validation

- A failed localStorage read was caught like malformed JSON and could fall through to a write. Read failures now exit without writing; malformed stored JSON is still repaired.
- MSign storage handling now matches the exact https://msign.gov.md origin, excluding alternative ports as well as other protocols/hosts. Added the port-isolation regression test.

### Environment recovery

- Gradle initially failed because of a stale localhost:8888 proxy. Retried successfully using command-scoped proxy overrides; machine proxy settings were not changed.
- The main Mac's new iOS 27.1 simulator failed during data migration when the disk filled. Removed only task-created build intermediates/products and the test simulator/emulator, preserving logs. Repeated iOS checks successfully on the other Mac using a fresh iOS 26.5 simulator.
- Temporary Android and iOS test devices were stopped; the task-created iOS simulator was removed. Existing user simulators were left untouched.

### Evidence and reruns

Evidence is retained under .local/browser-locale-validation on the main Mac and in the task workspace's docs/reports/browser-locale-validation. The native Apple probe source is scripts/validation/browser-locale-apple.swift; its captured output is also retained with the workspace evidence.

- Shared policy: node --test scripts/test-browser-locale.mjs
- Export consistency: python3 scripts/export-browser-locale.py --check
- Android app checks: ./gradlew :app:assembleDebug :app:testDebugUnitTest
- Android native suite: build :app:assembleDebugAndroidTest, install both APKs on an isolated emulator, then run am instrument -w -e suite browser-locale md.esemnbun.app.test/md.moldsign.app.FileProtectionInstrumentation
- Full build logs: ios-build.log, mac-build.log, android-build.log, android-instrumentation-build.log.

### Coverage limits

Live authenticated MSign/MPass sessions, real card signing, form uploads/downloads, and user-driven app-language changes through the full settings UI were not exercised. The tests preserved synthetic session fields, not a real login. The old Android provider path was exercised without document-start injection on a current provider; an actual old WebView installation was not used. Arbitrary websites may override browser language through their own account, cookie or URL preferences.
