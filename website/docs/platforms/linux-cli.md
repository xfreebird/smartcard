---
title: Linux CLI
---

# Linux command line

Applies to **eSemnBun 0.2.0**. The CLI can run without a GNOME desktop; the [desktop app](./linux.md) provides interactive consent, PIN dialogs, and file controls.

## Install and prepare PC/SC

Install the `esemnbun-cli` DEB/RPM for your distribution or extract the Linux CLI archive from [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest). Match the CPU architecture. The desktop package and CLI package are separate.

Ubuntu needs `pcscd` and `libccid`; Fedora needs `pcsc-lite` and `pcsc-lite-ccid`. Enable socket activation:

```sh
sudo systemctl enable --now pcscd.socket
command -v esemnbun
esemnbun readers
```

If the reader works in your desktop session but fails over SSH, review the host PC/SC access policy with your administrator. Repeated signing attempts will not resolve a permission problem.

For source builds, install a Swift toolchain and the PC/SC/OpenSSL development packages, then:

```sh
cd swift/MoldSignKit
swift build -c release --product esemnbun --static-swift-stdlib
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

### Optional systemd user service

CLI packages provide `esemnbun-server.service`; it is not enabled by default:

```sh
systemctl --user enable --now esemnbun-server.service
systemctl --user status esemnbun-server.service
journalctl --user -u esemnbun-server.service
```

This headless service has no graphical consent/PIN dialog. Use the GNOME app's browser connection for interactive requests. Before switching to that app, stop the service:

```sh
systemctl --user disable --now esemnbun-server.service
```

The GUI packages bundle the bridge identity. A CLI-only installation must be configured with a usable HTTPS identity if a website requires HTTPS; an HTTP-only server is insufficient for MSign.
