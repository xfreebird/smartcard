# Automation and Apple system integration — 7 November 2026

This change adds Apple system discovery and local automation. It has not been published to stores. No physical card or real PIN was used during implementation validation.

## Apple integration

Shared iOS/macOS Shortcuts open Documents, verify a PDF offline, and prepare a PDF for signing. Preparing preserves a bounded app-owned copy and opens the existing review flow; it never signs by itself. OS 27 adds Siri-supported system Open and Search in App schemas, filename search, guarded file entities and opt-in onscreen annotations. Spotlight indexes minimal filename/date metadata only when enabled. Handoff continues the Documents screen without transferring document bytes, identity, PIN or approval.

See [Apple implementation and API evidence](apple-discovery-implementation-2026-11-07.md). Generated App Intents metadata confirms the new schemas. Live voice dispatch, cross-device Handoff and Spotlight activation still need device validation.

## Local MCP and signing

macOS/Linux provide the native `esemnbun-mcp` executable. The server supports both MCP 2026-07-28 and the 2025-11-25 initialization protocol. It advertises actual capabilities, verifies PDFs/XAdES offline through configured input roots, and never exposes PIN arguments or document bodies in responses. Input is bounded, directory traversal/symlinks/special files are rejected, XML external declarations are denied, and protocol stdout stays JSON-only.

Two signing modes are distinct:

- **Desktop approval:** the standalone macOS app has an opt-in local broker. A request gets a five-minute expiry and an immutable PDF copy. The approval sheet contains an interactive PDF preview, selected identity and document/certificate hashes. Reject is the default keyboard action. Approval then uses the app's PIN/Keychain controls. The browser bridge cannot replace this approval flow. Cancellation before signing closes approval/PIN; after signing starts, actual completion or uncertain outcome is retained. Stale spool files are cleaned incrementally after 24 hours.
- **Unattended:** explicit launch configuration enables a signing tool, pins the full certificate SHA-256, chooses trusted input/output folders and selects an environment variable, dedicated macOS Keychain item, or 1Password secret reference. Secret references are operator configuration, never model arguments. Keychain access does not weaken the app's biometric vault. The 1Password command is shell-free, bounded to 32 output bytes and 20 seconds, and discards diagnostics. Certificate mismatch fails before PIN verification. Exclusive PC/SC access prevents another process from interleaving card commands. A durable lock is created before signing and removed only after successful output storage. PIN errors, crashes and uncertain failures leave it locked across automatic host restarts; an operator must reconcile the outcome and explicitly remove the marker. No tool can reset it.

Configuration and exact contracts are in [spec/mcp.md](../../spec/mcp.md). No HTTP listener or remote signing endpoint is introduced. Same-user processes, host configuration and OS credential access remain within the local trust boundary. Standard Swift strings/data cannot guarantee every transient secret copy is zeroized.

## Distribution

The standalone macOS packaging script signs and embeds the helper in `eSemnBun.app/Contents/Helpers`, re-seals the app with its existing entitlements, and includes the helper in the CLI archive. Linux CLI tar, Debian and RPM packaging include it. Packaging changes are source changes; signed release/notarization runs have not been performed for this revision.

Windows MCP is implemented in the existing CLI as `esemnbun mcp`, with real root-scoped PDF/XAdES verification and opt-in unattended PDF signing. Its credential sources are environment variables, a dedicated generic Windows Credential Manager item, or 1Password. The full certificate is matched before credential access, and failed/uncertain operations retain the durable lock. The Windows GUI does not yet expose the macOS foreground approval broker. The Microsoft Store packaging path includes the signed Native AOT CLI under `bin` and generates a full-trust console execution alias, restoring the source manifest after packaging. Store certification and installed alias behavior remain separate release checks.

Mac App Store delivery retains the separate CLI fallback. Apple explicitly supports sandboxed embedded helper tools, but the current externally launched stdio MCP process accepts configured root paths and external credential providers; these do not inherit file permissions from an app that did not launch the process. A supported embedded edition needs an app-owned paired transport, user-selected file grants or bounded bytes/bookmark IPC, and a sandbox-compatible approval broker. No sandbox entitlements were weakened. See [the helper assessment](mcp-appstore-sandbox-assessment-2026-11-07.md) for official Apple sources and the concrete implementation gaps. The standalone packaging script verifies preserved app entitlements and the universal signed nested helper, and notarizes both CLI executables together; no signed package or notarization run was performed here.

## Validation

- Full macOS desktop Debug, iOS simulator Debug (both architectures) and actual Mac App Store Debug builds passed, including App Intents metadata extraction.
- macOS full Swift suite: 88 tests, 5 opt-in skips, zero failures.
- After the Linux credential-timeout correction, 21 focused macOS MCP/provider/gate tests and real stdio process tests passed.
- Fedora ARM64 VM on the second Mac: full Swift suite 52 tests, 7 skips, zero failures; real stdio process checks passed for both protocol revisions. This caught and fixed Foundation's inherited-pipe wait extending a provider timeout.
- Windows VM targeted tests: 24 passed, covering CLI/MCP discovery, offline verification, junction/root replacement/private ACL rejection, and simulated unattended certificate/PIN/timestamp failures. Managed self-contained Release publishing passed with Native AOT analyzers enabled. Actual Windows process checks passed for both protocol revisions, including a raw UTF-8 Romanian filename, JSON-only stdout and empty stderr. See [Windows validation](windows-mcp-validation-2026-11-07.md). Native AOT linking and MakeAppx validation could not run because the VM lacks MSVC and the Windows SDK; no tools were installed.
- Catalog exports for all four native platforms, workflow YAML, shell/Ruby syntax and whitespace checks passed. Apple CI and release jobs now explicitly select Xcode 27 and preflight Siri schema support.
- Existing Huawei polling regression fixture now supplies every poll response; all 6 mocked publishing tests pass. No publishing calls were made.

Remaining validation: Windows Native AOT linking/MakeAppx and signed Store alias installation, native approval interaction with a real identity, actual Keychain ACL and 1Password authorization, physical-card unattended signing, signed packaged helpers, installed Store aliases and live Siri/Handoff/Spotlight. The implementation does not establish Store approval or unattended production readiness.
