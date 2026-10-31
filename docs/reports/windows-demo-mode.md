# Windows user demo mode — 31 October 2026

Demo mode is a persistent, user-controlled Settings switch in every build configuration. Entry requires
confirmation; cancellation preserves the current mode. An unclosable banner in the main window and a
tray disclaimer explain that identities/documents are fictional and results are not legal signatures.

The app composes a `DemoReaderSource`, sample-only `DemoSession` signer/verifier, no-storage `DemoPinVault`
and non-listening browser controller. The sandbox creates its own fictional PDF/text fixtures. The
file-picker action supplies only those samples; external drops and arbitrary paths are rejected before
any file read. Simulated output names contain `DEMO-NOT-SIGNED`, PDF contents show the same warning,
and XML output has no `ds:Signature`/`SignatureValue`. Original files are never overwritten.

Switching rejects active operations, cancels pending authorization, stops/drains old readers and browser
work, then clears transient document selection and in-memory history before publishing the next service
generation. Real history is neither loaded nor saved in demo. Saved PIN controls are disabled and the
credential container is never constructed for a demo generation. Helper preferences retain their
choices but make the insertion watcher stop before its next hardware read; the app also suspends its
own matching helper process when entering demo. Normal settings and services return when leaving demo.

Monitoring consent remains saved, but the controller is suspended throughout demo: no SDK initialization,
metrics/crash sending, opt-out flush or old-cache replay. Exiting demo restores the existing real-mode
consent without silently changing it. The monitoring page explicitly explains the pause.

## Validation

- Focused Windows tests: **28 passed, 0 failed**. Coverage includes fictional happy signing/verification,
  unsigned/watermarked results, locked external-input rejection, unchanged source fixtures, no credential
  storage, helper no-read behavior, persistence and monitoring suspension/resumption.
- Release and Debug WinUI builds: **0 warnings, 0 errors**.
- Native **Release** UI flow passed using `windows/scripts/test-demo-mode.ps1`, without any Debug demo
  environment: confirmation cancellation; actual Settings entry; two simulated batch outputs; mock
  verification; persistent mode after process restart; monitoring choices ON but no demo process TCP
  connections; exit to normal mode. Source fixture hashes and real history were unchanged.
- The script backs up/restores the guest's preferences/history and invokes native controls. It waits
  for page-ready automation IDs before using controls after navigation. No consent or service is bypassed.
- Six visually reviewed screenshots: `/Users/nghimbovschi/Desktop/esemnbun-screenshots/windows/2026-10-31/demo-mode/`.
- Logs/TRX and SHA256-linked native proof: `dist/windows/validation-2026-10-31/demo-mode/`.
- SDK non-initialization during demo is enforced and tested by the monitoring runtime-factory suspension
  policy; the native Release flow also observed zero process TCP connections while both monitoring
  choices were switched on in demo. Saved PIN storage is excluded by `DemoPinVault` composition.

The CLI is unaffected by this UI mode. No physical card or PIN is used for
these checks; the Windows guest runs without the reader attached. No deployment or store upload occurred.
