# Mac App Store runtime acceptance — 18 November 2026

The owner checked the installed Mac App Store app following publication of eSemnBun Desktop
0.2.12 and confirmed that USB reader detection, electronic-ID card detection and operation from
an external browser work. This is owner-reported acceptance of the Store-installed app, separate
from earlier Debug/TestFlight and embedded-browser checks.

The report does not specify the external browser, website, reader model or individual signing
format. It does not establish relaunch after explicitly quitting the app, every reader/browser
combination, or independent signature/trust verification. No new hardware operation, build or
test was run for this documentation correction.

Current source agrees with the reported behavior:

- `AppDistribution.browserBridge` is enabled for the Store build; `bridgeFileAccess` is disabled.
- `AppModel` connects through `TKSmartCardTransport`, monitors cards and starts the packaged-TLS
  bridge when enabled. The bridge is not restricted to the embedded browser.
- `ReaderActivationService` excludes the independent launch-agent helper from the Store build.
  The menu-bar app can still detect cards and open its window while running.
- Store settings exclude vendor-process controls and legacy desktop-client access; the local
  automation approval broker is compiled only for the standalone edition.

Update the canonical EN/RO/RU guides, generated platform pages, browser overview, landing/download
copy and developer documentation. Keep the remaining distribution differences explicit and
preserve historical reports as dated evidence.
