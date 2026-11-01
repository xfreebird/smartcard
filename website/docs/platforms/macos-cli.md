---
title: macOS CLI
---

# macOS command line

Applies to **eSemnBun 0.2.0**. This guide covers the standalone `esemnbun` command; it is separate from the Mac App Store app.

## Install and check the command

Use the macOS CLI artifact offered in [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest), matching your Mac's architecture. Extract the archive and place the executable in a directory on your PATH. Opening the graphical app does not necessarily install a terminal command.

```sh
command -v esemnbun
esemnbun readers
```

macOS provides PC/SC. Connect the supported reader and card before running reader-dependent commands. If you need the graphical app instead, follow the [desktop guide](./macos.md).

For a source build, install the Xcode command-line tools and build the CLI product from the repository:

```sh
cd swift/MoldSignKit
swift build -c release --product esemnbun
.build/release/esemnbun readers
```

## Select a reader and inspect its certificate

```sh
esemnbun readers
esemnbun cert --out leaf.der
```

The certificate command reads public signing-certificate details without a signing PIN. With multiple readers, use the exact reader name from `readers`:

```sh
esemnbun cert --reader "exact reader name" --out leaf.der
esemnbun sign input.pdf output-signed.pdf --reader "exact reader name"
```

Without `--reader`, the CLI selects the first reader with a card. Check the certificate first when several people have cards connected.

## Sign PDFs and XML signatures

```sh
esemnbun sign input.pdf output-signed.pdf
esemnbun xades XAdES-T original.txt original-signature.xml
esemnbun xades XAdES-BES original.txt embedded.xml --enveloping
```

PDF signing uses PAdES-T. If you omit its output path, the default is `<name>-semnat.pdf` beside the input; existing output is not overwritten. XAdES supports BES, T, and C, and uses a detached signature by default. Keep detached XML and its original file together. `--enveloping` places the document content inside the XML.

XAdES defaults to SHA-256. `--digest SHA-1` exists for relying parties that explicitly require it; do not switch the digest merely to work around an unrelated file error. Timestamped signatures need the public timestamp service; XAdES-C also collects certificate-status references.

## Supply the PIN

Run a signing command interactively to receive a prompt without echo. Do not type a PIN as an argument. For integration with an existing secret-input mechanism, `--pin-stdin` consumes the first line of standard input:

```sh
esemnbun sign input.pdf output-signed.pdf --pin-stdin
```

That command expects input from your caller or terminal; the example deliberately contains no PIN. Input precedence is `--pin-stdin`, then `MSIGN_PIN`, then the secure interactive prompt. Prefer the prompt for manual use. Never store a real PIN in a script or retry automatically after an incorrect-PIN error.

## Verify the result

```sh
esemnbun verify output-signed.pdf
esemnbun verify original-signature.xml /path/to/original-documents
```

For detached XAdES, the directory must contain the referenced original document. Verification prints one result per signature with integrity, signer, level, signing time, available timestamp, and chain status. It is offline validation; it does not establish current revocation status by itself.

### Exit codes

| Code | Meaning | Handling |
| --- | --- | --- |
| 0 | Success; verification found all signatures valid | Continue your workflow. |
| 1 | Usage or unexpected error | Read stderr and check arguments/file structure. |
| 2 | Invalid signature or none found | Do not treat the file as successfully verified. |
| 3 | Wrong PIN | Stop; check the remaining-attempt message and selected card. |
| 4 | PIN blocked | Contact the card provider. |
| 5 | No reader/card | Check the connection and reader selection. |
| 6 | Trust-service network error | Check connectivity/service availability before a deliberate retry. |

Errors are written to stderr with `error:`. `--quiet` suppresses protocol traces. Avoid recording sensitive files or credential input in automation logs.

## Browser service

```sh
esemnbun server
```

Defaults are HTTP on loopback port **18480** and HTTPS on **18443**. Optional positional ports are `esemnbun server <http-port> <https-port>`; government portals normally expect the default HTTPS endpoint.

Keep the server in the foreground and stop it with **Ctrl+C**. Do not run it alongside the desktop app's bridge or MoldSign Server on the same ports. For interactive consent and PIN dialogs, use the desktop app. The CLI is not a replacement for its consent UI, and server packaging must include a usable localhost HTTPS identity for browser compatibility.

See the [CLI contract](https://github.com/xfreebird/smartcard/blob/main/spec/cli.md) for developer commands such as raw digest signing. Most users only need readers, cert, sign, xades, verify, and server.
