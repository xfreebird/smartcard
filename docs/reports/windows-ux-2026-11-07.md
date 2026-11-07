# Windows UX review — 7 November 2026

The signing action now stays visible while a queued batch and its options scroll. The footer appears after files are selected, preserving space for the initial file chooser at the minimum window height. Shared status labels truncate within their available width with the complete label retained in the tooltip; drop-zone instructions wrap, and Sign/Verify drop-zone edges align. Settings switch states now follow the application's selected Romanian, English or Russian language instead of showing the operating system's default English On/Off labels.

## Target and isolation

- Source: `d0f4f131499e7e23bad8e75be6ead77c0b07fd9b` plus current local Windows changes.
- Windows 11 ARM64 QEMU guest on the MacBook Air, x64 WinUI app under Windows emulation. SDK: .NET 10.0.403 x64. Console: 1600 × 1000, 100% scale.
- Isolated source: `C:\Users\user\esemnbun-ux-20261107`; app: `windows\src\MoldSign.App\bin\x64\Debug\net10.0-windows10.0.19041.0\eSemnBun.exe`.
- Existing installed app, previous source copies, OS appearance/language and startup policy preserved. The existing private localhost identity was copied only within the guest; it was excluded from source transfer and evidence.
- Debug `multiple` preview uses fictional identities and synthetic documents, disabled bridge, and an isolated preferences file. No physical card or PIN used.

## Verification

Native WinUI Debug x64 compilation passed with zero warnings and zero errors (43.71 seconds). `git diff --check` passed. No separate core unit-test run was needed for these UI-only changes. Captures use the newly built app, per-process readiness metadata, requested page checks, and a foreground guard. The capture helper now accepts optional Width/Height and starts the app from its own directory; this fixes launch failure from an unrelated working directory.

Representative coverage: minimum 860 × 580 Romanian Sign/Verify/Documents/Settings in light and dark; standard 1100 × 720 English Sign/Settings in light; minimum Russian Sign/Settings in dark; large 1500 × 900 English Sign/Verify in light. These are outer window pixels, not phone dimensions. Content scrolls at minimum height; the navigation pane collapses to icons as intended.

Evidence folder on the main Mac: `/tmp/esemnbun-ux-2026-11-07/windows/`. `before/` contains baseline evidence; `final/shots/` contains final captures and readiness metadata. Capture-only preview hides the demo banner; all depicted identities are fictional.

Native UI Automation selected the two synthetic documents and asserted that the Sign button was enabled and fully onscreen at 860 × 580 before and after scrolling. It then invoked synthetic batch signing and verification. `interaction-en-US-860x580/interaction.json` records those assertions; `queued-en-US-860x580/` shows the persistent footer with files queued. These are simulation checks, not real signatures.

Foreground restrictions interrupted broader capture attempts; the temporary harness attached to the foreground input thread while focusing its own window, retained the foreground guard, and completed the reduced representative set. No global focus policy or system setting was changed.

## Limits

This pass validates native layout and synthetic interactions. It does not validate real reader transport, PIN consent, cryptographic signing, browser integration, Windows ARM64-native app binaries, high-DPI/multi-monitor behavior, screen readers, or installer changes. The installed app's tray was deliberately not used as evidence for the new build; tray-specific interaction remains untested. No commits or publication performed.

## Windows CLI help follow-up

Transferred only the final `windows/src/MoldSign.Cli/CliApp.cs` help-text change into the same isolated guest source. Native .NET 10.0.403 x64 `dotnet build src/MoldSign.Cli -c Debug` passed with zero warnings/errors in 12.97 seconds. `dotnet run --no-build --project src/MoldSign.Cli -c Debug -- --help` exited 0.

The runtime help lists `readers`, `cert`, and `sign-hex` under Usage, then explicitly labels `sign`, `xades`, `verify`, `server`, `cms-for-hash`, and the legacy PDF positional form as not yet available in the Windows CLI. Document signing and verification direct users to the desktop app. This checks the help output only; none of the reader, certificate, PIN, signing or server commands was executed. The WinUI app source was unchanged, so its build and screenshots were not repeated.
