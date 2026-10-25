# 08 — `re/` Inventory: what each artifact is and how to use it

The `re/` folder (14 MB after pruning) holds every ground-truth artifact from the
reverse-engineering phase. Grouped by purpose.

## Protocol ground truth

| File | What it is | How to use it |
|---|---|---|
| `apdu_capture.log` | Full plaintext PC/SC trace of a real middleware signing session (from DYLD interposer) | The canonical answer to "what bytes does the middleware send?" — SELECT sequences, VERIFY P2/ref, MSE template, IA payload, chunking. Diff any changed behavior against it |
| `sm_exchanges.log` | SM-layer auth experiments (variants → challenge/payload pairs) | Reference for mutual-auth construction/debug |
| `run_capture.sh` + `pcsc_trace.c` + `pcsc_trace.dylib` | The interposer that produces such logs | Rebuild: `swiftc/clang re/pcsc_trace.c …`; use: `re/run_capture.sh <anything-using-PCSC>` (vendor app, our app) for a fresh trace |
| `specs/IAS_ECC_v2_config3.pdf` | The IAS/ECC spec the card follows | Look up SM/APDU rules to distinguish spec from vendor quirks |

## Keys & test vectors (goldens)

| File | Contents | How to use it |
|---|---|---|
| `test_vectors.txt` | Card serial/seed/keys/expected outputs of the verified session | Source for updating `CryptoTests.swift` golden expectations when keys change |
| `verify_kenc.txt`, `verify_kmac.txt` | Derived Kenc/Kmac for the reference session | Unit-test targets for key-derivation code |
| `signing_session_keys.txt` | K_ICC/K_IFD/sessENC/sessMAC of the session | Golden session-key derivation check |
| `memscan_hits.txt` | Candidate key material found by memory-scanning the middleware | Where session/MK bytes came from; input for `re/memscan <dump>` reruns |
| `verify_ct.bin` | Reference ext-auth ciphertext | Re-encrypt/decrypt debug reference |

## Card dumps

| File | What it is | Use |
|---|---|---|
| `card_ef0001.bin` / `card_ef0001_certfile.der` | Raw EF 0001 as read from the card (1799 B the second) | Offline CMS/chain tests without the card — these contain the full cert |
| `user_cert.der` / `user_cert.pem` | The user signing cert (DER/PEM) | Test fixtures: our xctest PDF/XAdES flows use `/tmp/cert.der` sourced from this |
| `test_cert.pem` | Copy used by earlier probes | Same |
| `verify_ct.bin` | Ciphertext artifact of the auth protocol | Golden vector |

## Reference signatures/CMS

| File | What it is | Use |
|---|---|---|
| `sig1.der` | CMS captured from a middleware-run signature | Structural reference for CMS construction |
| `sig2.der`, `sig2.asn.txt` | Another CMS + its `openssl asn1parse` dump | Same — ASCII form is easiest to compare against when uncertain about attribute nesting |
| `cms1.txt` | asn1parse dump of the middleware CMS used for the byte-template | Precise reference for signedAttrs offsets/DER shape |

## Vendor code truth

| Path | What | Use |
|---|---|---|
| `decompiled/<jar>/` | CFR decompiled vendor jars (SignatureInstance, Signature service, models, providers…) | Read THE source for any route/structure question; `…/summary.txt` in each has the class map |
| `cfr-0.152.jar` | CFR decompiler | `java -jar re/cfr-0.152.jar <jar> --outputdir re/decompiled/<name>` on updates |
| `libbit4xpki_strings.txt` | `strings` of the native PKCS#11 dylib (AIDs, templates, keys-related identifiers) | Fallback source if AIDs/templates move |
| `lua_extracted/*.lua` | The card-driver Lua blobs decrypted from the middleware (`run_N_0xADDR.lua`; only nonzero-blob ones matter) | The SM transmit pipeline exactly — Le rules, TLV order, PIN padding. Read `re/lua_extracted` when SM behavior is in doubt |

## RE tooling (re-run when something changes)

| Tool | Purpose |
|---|---|
| `pcsc_trace.c` | DYLD interposer for APDU capture (see above) |
| `memscan.c` (+ `memscan`, `memscan_x86` built) | Scan dumped memory regions for key material; needs `dump_regions.py` output |
| `dump_regions.py` | Dumps readable regions of a pid (run right after middleware signing) into `re/dumps/` (deleted — re-creates) |
| `scan.py` | Generic byte-pattern scanner over dumps (used during key hunts) |
| `p11_probe.c` (+ `p11_probe`), `test_pcsclib.c` (+ `test_pcsclib`), `test_direct`, `test_dlopen` | Early PC/SC/PKCS#11 probes for the card; kept for raw-reader experiments |
| `sm_probe.c` / `sm_probe_DO_NOT_RUN` | **Never run** — performs blind auth probing; it burned the card's retry counter once |

## Misc data

- `certs/` — currently empty (previously held extracted chain certs; those now live in
  `swift/MoldSignKit/Sources/MoldSignKit/Formats/ChainCerts.swift`).
- `FINDINGS.md` — chronological RE journal; useful for "why does X exist" archaeology.
- `sig2.asn.txt`, `cms1.txt` — see above.

## Rule of thumb

1. Question about *bytes on the wire* → `apdu_capture.log` (+ `specs/`).
2. Question about *vendor code behavior* → `decompiled/` (+ regenerate with `cfr` on update).
3. Need *test fixtures* → `user_cert.der`, `card_ef0001*.der`, `sig2.*`, `*_vectors.txt`.
4. Vendor changed → doc 07 runbook with the tools above.
5. `sm_probe*` — do not run.
