# CLI capability discovery implementation — 7 November 2026

## Implemented

The Swift macOS/Linux CLI and Windows CLI now expose `esemnbun capabilities` and `esemnbun capabilities --json`. Capability discovery executes before normal command dispatch, reader enumeration, card connection, PIN handling or environment lookup. It emits fixed product and feature metadata only.

The versioned JSON envelope uses `schemaVersion:1`, `ok:true` and a `data` object. Both implementations share the same fields: product, interface, platform, implemented commands, structured-output commands, document-signing formats, verification availability/formats/card requirement, and MCP/broker availability. Windows accurately advertises its existing readers, certificate and raw-signature commands and marks document signing and verification unavailable. Swift advertises its existing PDF/XAdES signing and verification commands.

Only capabilities currently supports JSON. Other commands with an exact `--json` flag fail before any card/PIN access, with a single `UNSUPPORTED` envelope and exit 1. Malformed capability requests use `INVALID_ARGUMENT`; diagnostics go to stderr. Failure messages do not echo argument values, filenames, PIN values or raw exception text. The Windows JSON writer uses explicit UTF-8 output without reflection serialization, preserving NativeAOT compatibility.

`spec/cli.md` documents the schema, feature differences, privacy behavior and current limits. CLI help includes discovery. Existing signing, verification, PIN order and human-readable command behavior remain unchanged.

## Validation and limits

Swift frontend syntax parsing and whitespace checks passed. Focused Windows regression tests were added for accurate metadata, single-object JSON parsing, sanitized errors, and hardware/PIN/environment isolation through throwing fakes. They were not run. No native build, test run, capability-process execution, card operation or release was performed in this implementation round, following the owner-run build/test convention.

Structured verification (`verify --json`), Windows CLI document verification parity, an MCP executable, foreground approval broker, remote access and pairing remain future work. Capability discovery does not grant an agent permission to sign or expose card identities.

## Plan entry suggestion

Begin CLI structured automation with versioned read-only capability discovery across macOS/Linux/Windows; record unavailable Windows document operations explicitly. Next add structured no-card verification and parity tests before advertising a verification JSON contract or adding MCP.
