# `moldsign` CLI contract

One command-line interface on every desktop OS, always a **native** build. Two implementations follow this contract:

| OS | Implementation | Build |
|---|---|---|
| macOS | Swift: `apple/Sources/moldsign` (SwiftPM product, also the Xcode target `moldsign`) | `swift build -c release` or Xcode |
| Linux | Swift: the same `moldsign` sources, built with the Swift toolchain for Linux (LNX-*) | `swift build -c release --static-swift-stdlib` |
| Windows | .NET: `windows/src/MoldSign.Cli` over `MoldSign.Core` (Native AOT) | `dotnet publish -r win-x64 -p:PublishAot=true` |

Plan items: CLI-01…CLI-06 in [`../PLAN.md`](../PLAN.md).

## Commands

```
moldsign readers                                   List PC/SC readers and card presence
moldsign cert [--out <file.der>]                   Read the signing certificate (no PIN); print holder, issuer, validity, SHA-1
moldsign sign <in.pdf> [<out.pdf>]                 PAdES-T (default output: <name>-semnat.pdf next to the input, never overwrite)
moldsign xades <XAdES-BES|XAdES-T|XAdES-C> <in> <out.xml> [--enveloping] [--digest SHA-1|SHA-256]
                                                   XAdES signature (detached, SHA-256 by default; SHA-1 only where a
                                                   relying party asks for it, like the portal's Xml/Text contents)
moldsign verify <file.pdf|sig.xml> [<docs_dir>]    Offline validation report
moldsign server [<port> [<https_port>]]            Browser bridge (MoldSign Server protocol), defaults http 18480, https 18443
moldsign sign-hex <digestinfo_hex>                 Developer: raw card signature over a DigestInfo
moldsign cms-for-hash <sha256_hex>                 Developer: detached CMS for an external content digest

Legacy form (kept for scripts): moldsign <in.pdf> <out.pdf>   ==  moldsign sign <in.pdf> <out.pdf>
```

Global options: `--reader <name>` (default: first reader with a card), `--quiet` (no protocol traces),
`--pin-stdin` (read the PIN from the first line of stdin).

## PIN

Order: `--pin-stdin` → `MSIGN_PIN` environment variable → interactive prompt **without echo**.
The PIN is never accepted as a command-line argument (it would land in shell history and `ps`).
Never retry automatically after a wrong PIN.

## Output

* Human-readable lines on stdout. Errors go to stderr, prefixed with `error:`.
* `verify` prints one line per signature: `<name>: VALID|INVALID — <signer>, <level>, signed <time>[, tst <time>], chain trusted|untrusted`.
* `sign-hex` prints the signature hex. `cms-for-hash` prints `CMS_CERT:<hex>` and `CMS_HEX:<hex>` (consumed by scripts).

## Exit codes

| Code | Meaning |
|---|---|
| 0 | success (verify: every signature valid) |
| 1 | usage or unexpected error |
| 2 | verify: at least one signature invalid, or none found |
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
