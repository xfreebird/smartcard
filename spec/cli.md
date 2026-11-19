# `esemnbun` CLI contract

One command-line interface on every desktop OS, always a **native** build. The command is `esemnbun`
(public name eSemnBun, docs/10 §0.2b); the code keeps the codename (`Sources/moldsign`, `MoldSign.Cli`). Two implementations follow this contract. Windows command coverage is currently partial; discover the installed implementation with `capabilities --json` rather than assuming parity:

| OS | Implementation | Build |
|---|---|---|
| macOS | Swift: `swift/MoldSignKit/Sources/moldsign` (SwiftPM product `esemnbun`, also the Xcode target `esemnbun-cli`) | `swift build -c release --product esemnbun` or Xcode |
| Linux | Swift: the same sources (product `esemnbun`), built with the Swift toolchain for Linux (LNX-*) | `swift build -c release --static-swift-stdlib` |
| Windows | .NET: `windows/src/MoldSign.Cli` over `MoldSign.Core` (Native AOT) | `dotnet publish -r win-x64 -p:PublishAot=true` |

Plan items: CLI-01…CLI-06 in [`../PLAN.md`](../PLAN.md).

## Commands

```
esemnbun capabilities [--json]                    Discover supported commands and formats without card/PIN access
esemnbun readers                                   List PC/SC readers and card presence
esemnbun cert [--out <file.der>]                   Read the signing certificate (no PIN); print holder, issuer, validity, SHA-1
esemnbun sign <in.pdf> [<out.pdf>]                 PAdES-T (default output: <name>-semnat.pdf next to the input, never overwrite)
esemnbun xades <XAdES-BES|XAdES-T|XAdES-C> <in> <out.xml> [--enveloping] [--digest SHA-1|SHA-256]
                                                   XAdES signature (detached, SHA-256 by default; SHA-1 only where a
                                                   relying party asks for it, like the portal's Xml/Text contents)
esemnbun verify [--json] <file.pdf|sig.xml> [<docs_dir>]    Offline validation report
esemnbun server [<port> [<https_port>]]            Browser bridge (MoldSign Server protocol), defaults http 18480, https 18443
esemnbun sign-hex <digestinfo_hex>                 Developer: raw card signature over a DigestInfo
esemnbun cms-for-hash <sha256_hex>                 Developer: detached CMS for an external content digest

Legacy form (kept for scripts): esemnbun <in.pdf> <out.pdf>   ==  esemnbun sign <in.pdf> <out.pdf>
```

Global options: `--reader <name>` (default: first reader with a card), `--quiet` (no protocol traces),
`--pin-stdin` (read the PIN from the first line of stdin).

## Capability discovery and structured output

`capabilities` is read-only and does not enumerate readers, open a card, access saved credentials,
read stdin, inspect `MSIGN_PIN`, or contact a network service. It reports support in the executable,
not connected hardware, entitlement readiness, certificate availability, or a guarantee that a
future operation succeeds. `--quiet` is also accepted; each flag may appear once. Other options
or positional arguments are rejected.

`capabilities --json` writes exactly one compact UTF-8 JSON object followed by a newline to stdout.
Success exits 0 with no stderr output. Schema version 1 has this envelope and data shape:

```json
{
  "schemaVersion": 1,
  "ok": true,
  "data": {
    "product": "eSemnBun",
    "interface": "cli",
    "platform": "windows",
    "commands": ["capabilities", "help", "readers", "cert", "sign-hex"],
    "structuredOutputCommands": ["capabilities"],
    "documentSigning": {"available": false, "formats": []},
    "verification": {"available": false, "formats": [], "requiresCard": false, "json": false},
    "mcpServerAvailable": false,
    "desktopApprovalBrokerAvailable": false
  }
}
```

`platform` is `macos`, `linux` or `windows`, identifying the implementation. The Swift macOS/Linux
implementation additionally advertises `version`, `sign`, `xades`, `verify`, `server` and
`cms-for-hash`. It advertises document-signing formats `PAdES-T`, `XAdES-BES`, `XAdES-T`,
`XAdES-C`, and verification formats `PDF`, `XAdES`. Verification there is available without a
card. Windows currently has neither document signing nor verification in its CLI, even though
its desktop app implements those features. The Windows `sign-hex` card operation is not document
signing. Unavailable features have empty format lists.

The Swift macOS/Linux implementation also advertises `structuredOutputCommands:["capabilities","verify"]`
and `verification.json:true`. Windows currently supports JSON for capability discovery only. An
exact `--json` flag on another command is rejected before card/PIN access, with exit 1, one
`UNSUPPORTED` failure envelope on stdout and a fixed diagnostic on stderr. Malformed discovery
arguments use `INVALID_ARGUMENT`. Neither implementation echoes argument values or raw exception
text. Without `--json`, existing text command behavior remains available.

### Structured offline verification (Swift macOS/Linux)

`verify --json <file.pdf|signature.xml> [documents_directory]` reads one explicit regular PDF/XML
file. Symlink and special-file inputs are rejected; detached references are confined beneath the
explicit documents directory (or the current working directory if omitted). Neither reader/card
access nor PIN/environment lookup is needed. This operation is offline and does not check current
certificate revocation status.

A successful verification execution emits one object:

```json
{"schemaVersion":1,"ok":true,"data":{"status":"incomplete","mode":"offline","revocationChecked":false,"signatureCount":1,"signatures":[{"index":1,"kind":"XAdES","level":"XAdES-BES","contentIntact":false,"signatureValid":true,"chainTrusted":false,"missingDocumentCount":1}]}}
```

`ok:true` means verification executed, not that the signature is valid. Status values are:

| Status | Meaning | Exit |
| --- | --- | --- |
| `valid` | Integrity, cryptographic signature and embedded chain checks pass | 0 |
| `unconfirmed` | Integrity/signature pass but embedded trust is unconfirmed | 0 |
| `incomplete` | Original document references are unavailable, without another established signature failure | 2 |
| `invalid` | Cryptographic signature fails or supplied content does not match | 2 |
| `no_recognized_signature` | No supported signature was recognized; this does not distinguish every unsupported representation from unsigned input | 2 |

The existing vendor-oriented XML validator does not implement general XML canonicalization for
every equivalent representation; unsupported spellings may fail verification. This interface
does not expand the underlying validator's standards coverage.

Signature data contains only index, kind, level, integrity/signature/chain booleans and missing
reference count. It omits document paths/names, signer identity, certificate contents and PINs.
Missing originals alone do not establish modification. An independent cryptographic failure takes
priority over incomplete status. Revocation is always reported as unchecked.

Input/usage failures emit `ok:false`, `schemaVersion:1` and `error:{code,retryable:false,message}`;
fixed error codes are `INVALID_ARGUMENT`, `UNSUPPORTED` or `INPUT_UNREADABLE`, with exit 1.
Diagnostics go to stderr. The verifier does not return raw filesystem errors or supplied paths.
`--json` and `--quiet` may each appear once; reader/PIN options and extra positionals are rejected.
The JSON CLI interface is independent of the local MCP interface. macOS/Linux ship the
separate `esemnbun-mcp` executable; Windows exposes `esemnbun mcp`. See [the MCP contract](mcp.md)
for supported protocols, trusted roots, foreground approval and explicit unattended configuration.

## PIN

Order: `--pin-stdin` → `MSIGN_PIN` environment variable → interactive prompt **without echo**.
The PIN is never accepted as a command-line argument (it would land in shell history and `ps`).
Never retry automatically after a wrong PIN.

## Output

* Human-readable lines on stdout. Errors go to stderr, prefixed with `error:`.
* `verify` prints one line per signature: `<name>: VALID|INVALID|INCOMPLETE — <signer>, <level>, signed <time>[, tst <time>], chain trusted|untrusted`.
* `sign-hex` prints the signature hex. `cms-for-hash` prints `CMS_CERT:<hex>` and `CMS_HEX:<hex>` (consumed by scripts).

## Exit codes

| Code | Meaning |
|---|---|
| 0 | success (verify: every signature valid) |
| 1 | usage or unexpected error |
| 2 | verify: at least one signature invalid/incomplete, or none recognized |
| 3 | wrong PIN (stderr shows remaining attempts) |
| 4 | PIN blocked |
| 5 | no reader / no card |
| 6 | network (TSA / OCSP / CRL) failure |

## PC/SC notes per OS

| OS | Library | Swift / .NET binding |
|---|---|---|
| macOS | `PCSC.framework` (32-bit `DWORD`) | `CPCSC` C shim (`apple/Sources/CPCSC`) |
| Linux | `libpcsclite.so.1` from pcsc-lite + the `libccid` driver (`unsigned long` DWORD, 64-bit on x64/arm64) | the same `CPCSC` shim compiled against `<PCSC/winscard.h>` (LNX-02) |
| Windows | `winscard.dll` (32-bit `DWORD`) | `WinSCardTransport` P/Invoke |

Linux prerequisites: `pcscd` running (`systemctl enable --now pcscd.socket`) and the `libccid` driver
package. The bit4id miniLector is a standard CCID reader.

## File protection

Available in the Swift CLI (macOS/Linux) and Windows CLI:

```text
esemnbun encrypt INPUT NEW-OUTPUT [--password-stdin | --certificate RECIPIENT.der | --card SHA256] [--card-public-key]
esemnbun decrypt INPUT NEW-OUTPUT [--password-stdin | --card SHA256] [--card-public-key]
esemnbun encryption-certs [--reader NAME] [--card-public-key]
esemnbun encryption-certs [--reader NAME] --card SHA256 --out recipient.cer [--card-public-key]
esemnbun remove-file PATH --confirm-removal
```

With no method flag, encryption/decryption prompts for a password without echo; interactive encryption asks for confirmation. `--password-stdin` reads one line for automation. Passwords are never command-line arguments. Card decryption uses the existing `--pin-stdin`, `MSIGN_PIN`, or hidden PIN prompt. Certificate encryption needs no private key/PIN. `--card` identifies the selected public certificate by its full SHA-256 fingerprint from `encryption-certs`, using the same compatibility option during listing, export and decryption.

`--card-public-key` explicitly selects public-key compatibility: the certificate is an RSA key container rather than an assertion of encryption-purpose approval. Default mode still requires X.509 keyEncipherment. The flag requires `--certificate` or `--card` for file operations; it is also valid on `encryption-certs`. It is rejected for password operations and file removal. Senders and recipients must select the flag explicitly; it is never inferred from the encrypted file.

The source is preserved and output creation is exclusive: existing destinations, including the source itself, are refused. Inputs are bounded to approximately 64 MiB. New password files use MoldSign-compatible AES-256; old AES-128/192/256, 3DES, DES and RC2 password files can be read. New certificate files use CMS AES-128 with RSA key transport. CBC compatibility provides no content authentication: successful padding does not prove a correct password or untampered content. Check decrypted content before use.

Card discovery requires a unique PKCS#15 key/certificate/PIN association, advertised decipher usage, matching RSA size and supported numeric PIN metadata (ASCII-numeric or UTF-8). Default mode additionally requires a key-encipherment certificate; compatibility may use a signing-purpose certificate only when its associated card key declares decipher capability. Signing-only keys remain excluded. The selected identity, including policy, is read again before PIN verification; PIN failures are never automatically retried. A card without a supported decipher key cannot decrypt certificate files.

Removal is a separate destructive operation on one regular local file. It attempts a random overwrite, flush and removal, and rejects links and unsupported volumes. It cannot erase SSD remnants, copy-on-write snapshots, backups or other copies. Never use it as a physical-erasure guarantee. Mobile Files/document providers do not expose this overwrite operation.

### Share a public encryption certificate

Connect the card and run `esemnbun encryption-certs` to list supported identities. Export the selected full fingerprint with `esemnbun encryption-certs --card SHA256 --out recipient.cer`. This saves the exact public DER certificate, refuses existing destinations, and never requests a PIN or exports a private key. Both --card and --out are required for export. The recipient imports this file using encrypt --certificate recipient.cer. Confirm the fingerprint with its owner through a trusted channel.

In native apps, open Documents → Protect files → Certificate/card → Read card, select an identity, then Export encryption certificate. No input document is required. Save the .cer file and share it. Apple, Android and Windows use native save pickers; Linux and CLI exports refuse existing destinations.

For public-key compatibility, enable **Card public key compatibility** before reading/importing a certificate in any native app. Export is then labelled **Export public certificate**. The equivalent CLI sequence on macOS, Linux and Windows is:

```sh
esemnbun encryption-certs --card-public-key
esemnbun encryption-certs --card-public-key --card SHA256 --out recipient.cer
# Sender, with only the public certificate:
esemnbun encrypt document.pdf document.pdf.asymmetric.p7m --certificate recipient.cer --card-public-key
# Recipient, with the matching card/reader; PIN is entered through stdin or the hidden prompt:
esemnbun decrypt document.pdf.asymmetric.p7m restored.pdf --card SHA256 --card-public-key --pin-stdin
```
