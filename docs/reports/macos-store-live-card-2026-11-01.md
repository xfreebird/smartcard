# macOS Store live-card validation — 1 November 2026

The test used a disposable sandboxed Debug copy with the current App Store entitlements and CryptoTokenKit transport. Hardware access was serialized. Only the repository's harmless 460-byte PDF fixture was signed; no personal document or financial action was submitted.

## Passed

- Both connected signing identities were discovered. The request selected the intended certificate explicitly rather than relying on carousel order.
- Native consent plus the existing saved-PIN flow produced a real-card PAdES-B-T signature through the restricted HTTPS data-signing route. Independent CLI verification reported VALID with a trusted chain.
- In a fresh isolated browser container, the live MSign page accepted the fixture through the native file picker. Identity-card signing displayed both available certificates; choosing the intended identity and accepting native consent reached the signed result page.
- The portal-produced PDF was retrieved through the synthetic request's API and independently verified VALID PAdES-B-T with a trusted chain. Its SHA-256 is `240dc81accb6756511f86e11f5875c564bc8f90d476c4c7c0fbbc9442e11218b`.
- eVMS initiated its normal SAML POST redirect to MPass. The identity-card option was visible; card selection and native consent completed the authentication challenge and returned to the authenticated eVMS account. Testing stopped there, with no financial/account-management action. The test signed out and confirmed the public home page.
- No wrong-PIN or blocked-card response occurred. No PIN was added to source, command arguments, report, or fixture.

## Download validation

A clean single-instance retest of the original browser confirmed the portal clicked its download anchor and WebKit reported `shouldPerformDownload=true`, but no download delegate/destination callback arrived. The targeted fix explicitly starts WebKit's download, retains the download object and attaches a native Save sheet. Through the actual portal result page, the corrected browser displayed the sheet and saved the signed PDF. The UI-saved file is byte-identical to the API-retrieved output and independently verifies VALID PAdES-B-T with a trusted chain. A MIME-derived extension fallback avoids an extensionless `GetFile` suggestion. No additional card signature was required for these retests.

## Browser controls and privacy

The final native navbar was checked in a single window-only sandboxed QA process. MSign, EVO and eVMS shortcuts navigated to their live public sites. All six bundled official website icons were compact and fully visible in the native Services menu. The navbar screenshot is stored locally under `Desktop/esemnbun-screenshots/macos/2026-11-01/browser-final/navbar.png`.

Selective data clearing was checked against a disposable loopback fixture, with native checkbox values inspected before each action:

- Cache only preserved the fixture's session cookie and local storage.
- History only preserved the session cookie and local storage, cleared the address and disabled back/forward navigation.
- Cookies/site data only removed both the fixture cookie and local storage.
- After clearing, the browser stayed blank until an explicit navigation; it did not automatically reload MSign.

No personal browser profile was cleared.

## Signed Store package

The final source was exported through the isolated signing harness to `dist/macos-app-store/eSemnBun-AppStore.pkg`. The Store distribution-boundary audit passed, and `pkgutil --check-signature` confirmed the Apple-issued 3rd Party Mac Developer Installer identity. This is a signed local export; it was not uploaded to App Store Connect.

## Cleanup

All test-owned menu-bar processes were stopped after the duplicate-instance issue. Subsequent QA runs use a Debug-only tray suppression flag and bind the existing test bundle identifier to avoid launching a duplicate. The final window-only QA process and loopback fixture server were stopped after the checks; the installed `/Applications/eSemnBun.app` was left running. The eVMS session was signed out. Signed test outputs and request metadata remain private under the task's temporary folder and are not committed. Financial account details, session identifiers and card protocol traces are omitted from this report.
