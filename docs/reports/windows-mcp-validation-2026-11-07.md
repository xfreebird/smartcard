# Windows local MCP validation — 2026-11-07

Implemented `esemnbun.exe mcp` with modern MCP 2026-07-28 and the 2025-11-25 initialization adapter. Tools support configured-root offline PDF/XAdES verification and explicitly enabled unattended PAdES-T signing. No Windows foreground approval broker is advertised.

## Validation performed

Host: existing Windows 11 ARM64 test VM `WIN-ESEMNBUN`, accessed through the owner's MacBook Air. Isolated source copy: `C:\Users\user\esemnbun-mcp-validation`. SDK: .NET 10.0.403 x64; test runtime: .NET 10.0.14. No physical reader or PIN was used.

- 24 targeted tests passed: 7 MCP tests, 7 unattended simulated-card tests, 10 existing CLI capability cases.
- Real Windows filesystem checks passed: junction escape rejection, pinned root rename denial, alternate-stream/device-name rejection, private output ACL enforcement, exclusive output creation and traversal rejection.
- Simulated-card tests passed: actual RSA/PDF output, certificate mismatch before credential read/VERIFY, malformed credential rejection, wrong-PIN single attempt and durable restart lock, permanent timestamp failure, transient timestamp retry without another PIN/signature.
- Release self-contained `win-x64` managed publish passed with NativeAOT compatibility analyzers enabled.
- Real process checks passed for modern tool listing and offline unsigned-PDF verification using an actual raw UTF-8 Romanian filename (`document-șță.pdf`), with JSON-only stdout and empty stderr.
- Real process checks passed for legacy initialization and tool listing.
- Windows packaging script PowerShell AST parsed successfully.
- Local `git diff --check` passed.

Managed publish: `C:\Users\user\esemnbun-mcp-validation\publish`.

| Artifact | SHA-256 |
| --- | --- |
| `esemnbun.exe` (managed apphost) | `e764976d7cbc7f0b2cc563e82f728be3528ff2a22ca7c85c071ed7eee68b6c70` |
| `esemnbun.dll` (application code) | `2f1a3851bc09fce69af7eba86918351500bf4cf6b3239824b3590a826857ef03` |

## Limits

NativeAOT publish was attempted but could not link: the VM has no Visual Studio/MSVC linker, `vswhere`, or Windows Kits 10. The managed build's AOT analyzers passed; a native executable was not produced. MakeAppx schema/package validation was also unavailable. No signed MSI/MSIX, Store execution-alias installation, WinUI build, real Credential Manager access, 1Password authentication, physical-card signing or real unattended deployment was validated. No release or store submission occurred.

The app's existing verification limitations remain: offline chain trust does not establish current revocation, and timestamp/revocation flags preserve the core validator's scope. Cancellation or a watchdog timeout cannot undo a signature; unattended failures leave `.unattended-signing-lock` for explicit operator inspection/reset. Shared HTTP transient retries may repeat timestamp requests, but do not repeat VERIFY or the card signature.
