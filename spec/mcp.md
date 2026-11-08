# Native local MCP interface

`esemnbun-mcp` is a separate SwiftPM executable for macOS/Linux. Windows exposes the same
local protocol through `esemnbun.exe mcp` in the native CLI. Both use core library APIs,
not shell commands or CLI-output parsing. There is no HTTP
listener, remote signing service, runtime package download, client-root grant, or PIN tool argument.

## Protocol

The modern MCP revision is **2026-07-28**. Each modern request requires
`params._meta["io.modelcontextprotocol/protocolVersion"]` and
`params._meta["io.modelcontextprotocol/clientCapabilities"]`. Discovery uses `server/discover`;
a separate stdio adapter supports **2025-11-25** through an explicit `initialize` handshake.
Other revisions are rejected. Legacy responses omit `resultType` and modern server metadata;
`notifications/initialized` has no application side effects. Caller-advertised roots grant no access. Results carry `resultType:"complete"` and
server identity metadata on modern responses. Unsupported revisions receive `-32022`; missing metadata receives
`-32602`. Tools support strict input/output schemas, structured content, and a matching JSON text
content block. An execution failure sets `isError:true`; an invalid signature is a successful
execution with an invalid verification status.

Example request (one physical line):

```json
{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{}}}}
```

The implementation follows the official [stdio binding](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/stdio),
[discovery](https://modelcontextprotocol.io/specification/2026-07-28/server/discover),
[metadata/version rules](https://modelcontextprotocol.io/specification/2026-07-28/basic/index), and
[tools contract](https://modelcontextprotocol.io/specification/2026-07-28/server/tools).
The legacy adapter follows the official [2025-11-25 lifecycle](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle).
Application job handles are not MCP Tasks and do not imply a protocol session.

## Agent client setup and reusable skills

See [AI agent integrations](https://esemnbun.md/docs/integrations/mcp-agents/) for ten client
configurations, a downloadable macOS/Linux/Windows integration pack, reusable document skills,
rule/workflow adapters and a local Claude Code plugin. Sources and validation limits are listed
per client. The pack defaults to verification; native approval and unattended signing require
separate operator configuration. Source: `distribution/agents/`; exporter:
`scripts/agents/export_integrations.py`.

## Trusted launch configuration

Build with `swift build --package-path swift/MoldSignKit --product esemnbun-mcp`.
The installed/bundled executable can be configured in a host that supports the pinned revision:

```json
{"command":"/absolute/path/esemnbun-mcp","args":["--root","documents=/Users/me/Documents/Signing"]}
```

`--root ID=/absolute/directory` may appear up to 32 times with unique ASCII IDs.
No roots means discovery only. Roots are explicit operator authority, never supplied by a tool,
client `roots/list`, document text, or client identity. Use canonical physical paths: all symlink
components, including `/tmp` and `/var` aliases on macOS, are rejected. Each directory inode is
held open and descendant file access uses `openat` with no symlink following. Traversal, absolute
references, NULs, colons, backslashes and nonregular files are rejected. No filesystem paths or
raw operating-system errors are returned. Input content is not returned to the model.

## Tools

| Name | Input | Result |
| --- | --- | --- |
| `capabilities` | `{}` | Protocol, root IDs, verification formats, configured broker and unattended availability |
| `verify_document` | `{input:{rootId,relativePath},detachedRootId?}` | Same privacy-minimized offline result as CLI `verify --json` |
| `prepare_signing` | `{input:{rootId,relativePath},format:"PAdES-T"}` | A new opaque job ID and `awaiting_user` |
| `get_job` | `{jobId}` | State, hashes and output reference when available |
| `cancel_job` | `{jobId}` | State and cancellation-requested flag |
| `sign_document` | `{input:{rootId,relativePath},format:"PAdES-T"}` | Completed input/output hashes and output reference; listed only with explicit unattended configuration |

Verification never contacts a network or reader. Detached files are read only when
`detachedRootId` is explicitly supplied; otherwise absent originals remain incomplete.
XML must be UTF-8 and rejects DTD/entity declarations before validation. The existing
vendor-oriented validator's canonicalization limitations remain; this interface does not add
standards coverage. Offline chain trust is not a current revocation check.

## Foreground approval broker

The foreground approval spool is implemented for standalone macOS, Windows WinUI, and Linux
GNOME apps. Enable local signing requests in the desktop settings, then pass the displayed
private directory as `--broker-directory` to the platform CLI/helper. All three expose
`prepare_signing`, `get_job`, and `cancel_job`, with process-owned jobs. Windows and Linux
show the staged PDF before fresh approval and native PIN access; stored PINs never bypass
approval. The selected certificate is frozen and checked before VERIFY. Desktop apps must
be running; the helper does not launch them. macOS App Store keeps the separate CLI fallback.

Default desktop spool locations:

- macOS: `~/Library/Application Support/eSemnBun/AgentBroker`
- Windows: `%LOCALAPPDATA%/MoldSign/MCP`
- Linux: `$XDG_DATA_HOME/eSemnBun/AgentBroker` (default `~/.local/share/eSemnBun/AgentBroker`)

Linux staging lives in an additional private `staging` subdirectory. Its preview uses the app's
PDF editor; the user can choose a localized visible stamp or invisible signing. A separate
approval dialog displays both input and certificate hashes, defaults to rejection, and is
required before PIN access. Expiry, opt-out and cancellation are checked again before signing.
A cancelled PIN/approval dialog may remain visible until dismissed but cannot authorize the
expired job. Requests left in `signing` after a crash are uncertain; inspect outcomes manually.
Windows broker cleanup currently runs only while enabled. These additions require native
build/runtime and installed-package validation, including Flatpak sandbox integration.

Enable the desktop app's broker first, then add `--broker-directory /absolute/private/directory`.
The directory and its `requests`, `responses`, `outputs` subdirectories must already exist,
belong to the current user and have mode 0700. Files are mode 0600 and requests are published
atomically without replacement. Broker availability means this private spool was configured;
it is not a guarantee that the app is currently polling. The helper does not launch or impersonate
the app. Pairing metadata and document filenames are untrusted display data.

The helper stages one bounded PDF in `requests/JOB.json`:

```json
{"schemaVersion":1,"operation":"prepare","jobId":"UUID","name":"document.pdf","pdf":"BASE64"}
```

The app owns immutable staging, certificate selection, foreground approval, PIN entry,
reader serialization and output creation. There is no certificate-selection or output-path
argument to this initial broker interface. App responses at `responses/JOB.json` contain
`schemaVersion`, `jobId`, and `state` (`awaiting_user`, `signing`, `completed`, `failed`,
`cancelled`, `expired`), optional `inputSHA256`, `outputSHA256`, and a fixed `errorCode`.
Only allowlisted metadata is forwarded. Completed output is `outputs/JOB.pdf`, exposed as
`{rootId:"broker-output",relativePath:"JOB.pdf"}`. Jobs are restricted to the helper process
that created them; a guessed job ID or client-supplied name grants no access.

Cancellation publishes `requests/JOB-cancel.json` with `operation:"cancel"` and the job ID.
Repeated cancellation is idempotent. EOF requests cancellation for all owned jobs. Abrupt kills
cannot publish cancellations; the app must expire abandoned approval requests. Cancellation
cannot undo a card operation already in progress. `cancellationRequested:true` is not proof
that a signature was prevented. Restarting the helper does not adopt old job IDs. Approval expires after five minutes; the app
cleans stale spool files incrementally after 24 hours, including after the broker is disabled.
Retrieve completed outputs before that retention window expires.

## Explicit unattended signing

This mode is separately authorized by operator launch configuration. It does not request native
approval per document. It pins the full signing certificate SHA-256, uses a dedicated output root,
and accepts a secret-provider reference rather than a PIN. Example launch arguments:

```text
--root documents=/Users/me/Documents/Signing
--allow-unattended-signing
--signing-certificate-sha256 <64-hex-digit-certificate-SHA256>
--signing-output-directory /Users/me/PrivateSigningOutput
--pin-source env:ESEMNBUN_AUTOMATION_PIN
```

The output directory must already exist, be owned by the user and have mode 0700. Alternative
provider settings are `--pin-source keychain:service:account` (macOS),
`--pin-source secret-service:service:account` (Linux), or
`--pin-source onepassword:op://Vault/Item/field`. The 1Password executable defaults to
`/opt/homebrew/bin/op` on macOS and `/usr/bin/op` on Linux; an operator may set `--onepassword-executable /absolute/path/op`.
A separately provisioned Keychain item must permit noninteractive access; the app's biometric
vault is not weakened. The operator configures 1Password authentication outside MCP. Do not put
PIN values in host launch arguments, tool calls, documents or logs. Environment secrets are
inherited by the helper; host configuration and same-user processes remain within the trust boundary.

No secret provider is read during discovery or validation. Signing reads the configured secret
only when executing an explicitly enabled signing request. The certificate is checked before PIN
verification. Output names are random UUIDs and created exclusively; no overwrite or caller-chosen
output path exists. Before signing, an exclusive, durable `.unattended-signing-lock` marker is created in the output
folder. Success removes it only after output is safely written. Wrong-PIN, process crashes and
uncertain failures leave it in place across restarts. After inspecting the output/card outcome,
the operator must explicitly remove this marker and restart; MCP has no reset tool. PIN verification and card signatures
are never automatically retried. The trust-service client may retry a transient timestamp HTTP
request using the existing signature; this does not repeat a card operation. An exclusive PC/SC connection prevents APDU interleaving with other apps. The whole workflow
needs signed installed-app/physical-card validation before production unattended deployment.

Linux Secret Service uses the operator-selected `/usr/bin/secret-tool` by default; override it
with `--secret-tool-executable /absolute/path/secret-tool`. Provision a separate item using
`secret-tool store --label="eSemnBun automation" service SERVICE account ACCOUNT`, entering
the PIN interactively or via protected stdin. The helper runs bounded `lookup service SERVICE
account ACCOUNT` without a shell, discards diagnostics, and validates the result as 4–8 ASCII
digits before VERIFY. Keep the automation collection unlocked for unattended operation;
credential-provider unlocking/authentication and physical-card behavior remain unvalidated.
The app's saved-PIN items are not reused. See the
[Secret Service CLI contract](https://manpages.debian.org/testing/libsecret-tools/secret-tool.1.en.html).

## Windows launch and credentials

Use the CLI executable bundled in the installer's `bin` directory:

```json
{"command":"C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe","args":["mcp","--root","documents=C:\\Users\\me\\Documents\\Signing"]}
```

Store packaging can expose an execution alias for the packaged CLI where policy permits;
this contract does not claim a Store submission/approval or installed alias verification.
Use an explicit installed executable path until that distribution is validated. The foreground
WinUI app is not a stdio host. No Windows service or TCP endpoint is installed by this command.

Unattended Windows launch uses the same opt-in/certificate/output arguments as Swift, with
Windows absolute paths. The output directory must exist and be owned by the current user;
its ACL may allow only that user, SYSTEM and Administrators. Root ancestry is held open with
Windows handles that prevent rename/delete, and reparse points, UNC/device paths and reserved
DOS names are rejected. Output and persistent lock files are exclusively created and flushed.

Windows credential settings:

| Provider | Trusted launch setting |
| --- | --- |
| Environment | `--pin-source env:ESEMNBUN_AUTOMATION_PIN` |
| Credential Manager | `--pin-source credential:eSemnBun-Automation` |
| 1Password | `--pin-source onepassword:op://Vault/Item/field --onepassword-executable C:\absolute\path\op.exe` |

Credential Manager uses a separately provisioned generic credential with a UTF-16 PIN blob;
it does not access or weaken the app's Windows Hello vault. Reads occur under the executing
user's logon session through [CredReadW](https://learn.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credreadw).
1Password requires an explicit absolute executable path on Windows and existing provider
authentication; output is bounded and its diagnostics are discarded. Neither provider is
read during discovery or verification. PIN values must contain 4–8 ASCII digits.

On signing, the backend selects a readable card matching the configured certificate SHA-256,
then checks the exact DER SHA-256 again inside the signing operation before reading the secret
or sending VERIFY. It requests [exclusive PC/SC access](https://learn.microsoft.com/en-us/windows/win32/api/winscard/nf-winscard-scardconnectw)
to prevent another app interleaving card commands. The same persistent fail-closed output marker
and explicit operator reconciliation apply after a failure or interruption.

## Bounds and lifecycle

Each newline-delimited frame is at most 64 KiB. The Swift helper allows at most eight queued requests. Oversized
frames/queue exhaustion terminate the helper with fixed stderr diagnostics. Documents are at most
8 MiB; detached references share that total budget, with at most 32 references and 64 reported
signatures. The helper creates at most 16 broker jobs per process. Execution is serial; stdin
continues reading cancellation while work runs. Notifications never execute tools or receive replies.
Cancellation suppresses subsequent replies for that request; it does not roll back side effects.
A watchdog terminates requests exceeding 30 seconds (120 seconds for unattended signing).
A killed/timeout signing request has an uncertain outcome: inspect the configured output and
card state rather than retrying blindly. EOF discards pending work, lets active work finish or
reach its watchdog, requests broker cancellation, and exits. Metadata can still leave the machine
through the MCP host.

The Windows host uses an independent bounded reader and a serial executor, with at most
eight active/queued requests. Cancellation notifications suppress queued work or replies while
an operation is running. The watchdog terminates the process after 30 seconds, or 120 seconds
for `sign_document`; it cannot return while a signing task still owns trusted filesystem roots.
Closing/killing the host can leave an uncertain outcome. Do not interpret protocol cancellation
or process exit as proof that no signature was made.

## Validation

`swift test --package-path swift/MoldSignKit --filter MCPServerTests` covers strict protocol/tool
validation, metadata privacy, path traversal/symlink/size rejection, pinned directory inodes,
exclusive output creation, DTD rejection and broker job ownership. After building the helper,
`python3 scripts/test-mcp-process.py swift/MoldSignKit/.build/debug/esemnbun-mcp` exercises real
stdio framing, JSON-only stdout, offline verification, malformed/oversized inputs and shutdown.
No card or credentials are required. Real approval UI, Keychain ACL, 1Password authentication,
Linux packaging, signed installed helpers and physical-card flows require separate validation.

Windows tests in `WindowsMcpUnattendedTests` use simulated card sessions, fixture RSA keys and
fixture timestamp responses to cover immutable input, exact-certificate rejection before secret
access/VERIFY, one PIN attempt, valid output, timestamp failure and persistent replay prevention.
They do not validate real Credential Manager provisioning, 1Password authentication, physical-card
behavior or Store-installed execution aliases. Windows VM/build evidence is recorded separately.

Current parity additions include focused Windows spool/session tests and Linux request-decoding,
settings-default and stamp-language tests. They have been added but not executed in this change;
new native UI/card paths and provider integration are unvalidated until the owner runs builds/tests.
