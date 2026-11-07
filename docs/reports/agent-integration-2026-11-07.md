# eSemnBun agent integration proposal — 2026-11-07

## Recommendation and current state

Ship read-only structured verification first, then local stdio MCP backed by an approved-job broker in the desktop app. Keep document bytes, PIN entry and signing on the user's machine. Remote HTTP is a later, separately reviewed product. Everything below is proposed unless identified as existing behavior.

Existing Swift CLI supports PDF/XAdES verification and signing, with human-readable output and exit codes documented in `spec/cli.md`; it has no JSON mode. `verify` can work without a card. Windows CLI is **not feature-equivalent**: `windows/src/MoldSign.Cli/CliApp.cs` still rejects `sign`, `xades`, `verify`, `server` and `cms-for-hash` as unimplemented, despite the shared contract. Windows GUI signing/validation services exist independently.

Reusable seams are Swift `SigningService` (serialized card operations and verification), Apple `AppModel` consent/PIN continuations, Linux `Infrastructure/BridgeHost`, and Windows `Services/BridgeHost`/signing services. The existing vendor bridge is a compatibility endpoint, not an agent authorization boundary. Its public `moldSign: DesktopSuiteClient` header and forgeable origins must never become MCP credentials. See [the current security review](security-2026-11-07.md) for platform PIN-storage differences and validation limits.

Source inspection also found Swift CLI detached-reference reads could escape `docs_dir`. This change routes them through descriptor-relative `DetachedDocumentAccess`, rejecting traversal, absolute paths, symlinks below the selected root and nonregular files. Missing/rejected references remain absent from the validator's supplied-byte map; this does not make an invalid signature valid. Focused regression coverage accompanies the fix; root-run validation is recorded separately.

## Delivery order

1. **Structured CLI:** add `verify --json` and `capabilities --json`, with a versioned schema shared across Swift/.NET. Preserve existing text/exit-code behavior; implement Windows verification before advertising it. Emit one JSON object on stdout, diagnostics on stderr; never parse localized summaries. Use library APIs or argument arrays, never shell interpolation.
2. **Local MCP:** bundle a small native `esemnbun-mcp` executable. Verification can call the core directly; signing must go through a foreground desktop broker that owns the reader lock and approval. Direct CLI signing remains an expert workflow, not an MCP tool accepting PIN input.
3. **Remote access later:** require an explicit document-transfer policy, authenticated users and authorization scopes, audit/retention controls, and an outbound paired desktop channel. A remote service cannot directly access a local card or local filesystem path.

The current official revision is **2026-07-28**, with a stateless core and application-owned handles; Tasks moved to an extension. Do not assume older initialize/session/HTTP cancellation behavior. Pin and test a supported revision; add a separately tested 2025-11-25 adapter only when target hosts require it. [Release announcement](https://blog.modelcontextprotocol.io/posts/2026-07-28/), [transports](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports).

## Proposed tool contract

Use strict JSON Schema objects (`additionalProperties:false`, bounded arrays/strings, enums), `outputSchema`, and `structuredContent`. Annotate verification read-only; annotations describe behavior and do not grant permission. [Official tools contract](https://modelcontextprotocol.io/specification/2026-07-28/server/tools).

| Tool | Input | Result |
|---|---|---|
| `capabilities` | `{}` | schema/protocol versions, supported formats/platform features, broker readiness |
| `verify_document` | `{input:{rootId,relativePath}, detachedRootId?}` | signature count; per-signature integrity, crypto, chain trust, timestamp and revocation status; warnings |
| `list_signing_identities` | `{}` | consent-scoped opaque certificate IDs and minimal labels; no full subject/IDNP by default |
| `prepare_signing` | `{input,certificateId,format:"PAdES-T",outputRootId}` | opaque `jobId`, input SHA-256, expiry, `awaiting_user` |
| `get_job` | `{jobId}` | state/progress, or output-relative path/hash and verification result |
| `cancel_job` | `{jobId}` | cancellation disposition and final/remaining state |

Start with one PDF per job; add XAdES/batches after parity tests. No raw-signature, arbitrary-digest, PIN, remembered-PIN-session, remote URL, shell command or arbitrary output-path tools. `prepare_signing` only stages; approval happens in the app.

Result envelope: `{schemaVersion:1,ok:true,data:{...}}`; failures use `{schemaVersion:1,ok:false,error:{code,retryable,message}}`. Stable codes include `INVALID_ARGUMENT`, `PATH_DENIED`, `UNSUPPORTED`, `BROKER_UNAVAILABLE`, `BUSY`, `NO_CARD`, `CARD_CHANGED`, `USER_CANCELLED`, `EXPIRED`, `PIN_INCORRECT`, `PIN_BLOCKED`, `NETWORK_FAILED`, `OUTCOME_UNKNOWN`. Invalid signatures/no signatures are verification results, not execution failures; distinguish unknown revocation from good. MCP execution failures use `isError:true`; malformed protocol requests use JSON-RPC errors. Never return PINs or raw authentication errors containing secrets.

## Approval, privacy and lifecycle

The user selects input/output roots in trusted configuration or app UI. Client-advertised MCP roots are hints, not authority. Enforce containment on every input, detached XML reference and output; reject traversal, symlink/reparse escapes and special files. Apply byte/count/time limits and disable external XML entities/network fetching. A valid signature is not evidence that document instructions are trustworthy.

Stage an immutable private copy and bind its SHA-256, certificate DER SHA-256, format/options, destination, caller and short expiry to the job. Display that exact document and certificate in native foreground approval. Any changed binding requires fresh approval. Recheck the card before VERIFY; retain the existing internal SHA-1 identity mechanism only as compatibility plumbing, not the new job binding. Never automatically retry a PIN or replay approval after reconnect. Do not reuse browser trust or batch PIN sessions.

Bind opaque jobs to an authenticated local connection/capability, not a claimed client name. Pair callers in app settings; enforce per-user IPC permissions and peer identity where available (XPC/audit identity on macOS, restricted named pipe on Windows, private Unix socket/peer credentials on Linux). Short-lived revocable capabilities permit requesting jobs, not silently approving them. Same-user malware remains a limitation. Keep capabilities outside model-visible arguments/logs.

Suggested states: `awaiting_user → signing → completed|failed`, plus `cancelled|expired`. Serialize reader work across UI, bridge and MCP. Connection loss cancels unapproved jobs. Cancellation during an APDU cannot undo a signature: reconcile the outcome, never retry blindly, and report whether output exists. Use atomic exclusive output creation, bounded retention, and cleanup on expiry/restart; invalidate unapproved jobs after restart.

Return metadata only by default: document text, bytes, certificate personal identifiers and full paths must not flow into model context. Treat filenames, certificate names and document content as untrusted data. No document-directed tool calls. Even metadata may leave the machine through the agent host; disclose that during pairing. [MCP security guidance](https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/security_best_practices).

## Packaging and acceptance gates

Stdio requires protocol-only stdout and client-owned process lifecycle. Bundle/sign the helper with the desktop release; do not require runtime package downloads. Official C# and Swift SDKs exist, but their support tiers/revisions differ: verify the pinned SDK's compatibility, NativeAOT/trimming and Linux support before selecting it. [Stdio](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/stdio), [SDK matrix](https://modelcontextprotocol.io/docs/2026-07-28/sdk).

macOS needs signed helper/IPC entitlements and sandbox-aware user file grants. Linux needs explicit desktop-session approval; unlocked libsecret is not biometric authorization. Windows MSI can bundle a separate helper in `bin`; MSIX/Store execution aliases, IPC permissions and updates require separate installed-artifact tests. iOS/Android remain foreground signing clients, not unattended desktop MCP hosts.

Test schemas/parity, no-card verification, malformed/large XML, path escapes/races, prompt-injection fixtures, consent denial, foreign/expired jobs, replay, changed bytes/card, PIN failure without retry, concurrent bridge/UI use, mid-sign cancellation and crashes. Use simulated cards first; then signed installed builds and explicit owner-supervised card tests. No MCP runtime, broker or integration build was created in this research.

For later HTTP, use the current Streamable HTTP binding, origin validation and OAuth resource authorization with audience-bound scoped tokens; never reuse the vendor TLS identity or pass tokens through. [HTTP transport](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http), [authorization](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization).
