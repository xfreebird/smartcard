# 07 — Re-Derivation Runbook (if the vendor app changes)

Everything in this project was extracted from the vendor stack at runtime. This is
how to extract it all again when versions shift, with the exact tools kept in `re/`.

## A. Card protocol (APDU level)

1. Build the interposer: `re/pcsc_trace.c` → `re/pcsc_trace.dylib` (DYLD insert into
   `SCardEstablishContext/Connect/Transmit/Disconnect`).
2. `re/run_capture.sh <vendor-signing-run>` → `re/apdu_capture.log`
   — full plaintext trace (SM contents visible because plaintext is captured before wrap).
3. From the trace, re-diff:
   - Generic ADF AID bytes + SELECT P2; PIN verify template + ref; MSE template
     (`80 01 02 84 01 81` = kid 02/alg); INTERNAL AUTH payload shape; SM TLV/SSC/Le rules;
     cert-read file id + chunking.
4. Update `Card.swift`/`SecureChannel.swift` constants; re-run `swift test`.

## B. Middleware keys (IAS master key & derivations)

If ext-auth ever stops matching:
1. `re/dump_regions.py <middleware-pid>` right after a signing run → `re/dumps/…`.
2. `re/memscan <regions>` → candidate key material (`re/memscan_hits.txt` format).
3. Validate candidates against trace-derived values with the unit-test checklist:
   Kenc/Kmac derivation, ext-auth payload, response decode, session keys
   (`verify_kenc.txt`, `verify_kmac.txt`, `signing_session_keys.txt`, `test_vectors.txt`
   hold the current session goldens).

## C. Java code truth

```bash
java -jar re/cfr-0.152.jar /Applications/STISC/MoldSign/lib/<Jar>.jar \
  --outputdir re/decompiled/<Jar>
```

Files that matter:
- `PKCS11CardReader-2.0/…/workers/SignXAdESWorker.java` — XAdES flow + formats
- `…/workers/signatures/SignatureInstance.java` — all XAdES structural details
- `ClientCardServer-2.0/…/server/services/Signature.java` — every REST route + session model
- `…/server/services/Certificates.java`, `CORSFilter.java` — auth + headers
- `…/server/ApiServer.java` — ports, keystore, store passwords
- `TransferObjects-2.0/md/cts/moldsign/transferobjects/models/*` — every DTO's fields
- `…/providers/*` — PKCS#11 security operations (SM template, PIN pipeline)

## D. Golden outputs (structure fixtures)

Via the running vendor server (`moldSign: DesktopSuiteClient` header, plain http:
`localhost:18480/certificates` auth rule), or its GUI once per format:
- `/sign/file` with `signFormat=XAdES-BES|XAdES-T|XAdES-C`, `type=Detached|Embedded`
  → golden XML documents in `destinationFile`.
- `/sign/data` `contentType=Pdf` → golden PAdES PDFs (the byte-template in doc 02).
- Compare ours vs goldens by tag-sequence diff after UUID-normalization (the exact
  approach in this project's session logs; ours now matches 1:1 for all 7 shapes).

## E. Validation harnesses (keep rebuilt)

```bash
# iText + BouncyCastle probe — THE acceptance oracle (same stack as the MSign backend)
CP=$(ls /Applications/STISC/MoldSign/lib/*.jar | tr '\n' ':')
javac Probe.java && java -cp "$CP" Probe.java <files.pdf>
# JDK XMLDSig probe — XAdES oracle with file:/ dereferencer shim
javac Probe3.java && java Probe3 <sig.xml> <docs-dir>
```

## F. Trap log (things that MUST NOT be re-learned the hard way)

- Swift `Data` slicing: wrap ALL slices before indexing.
- `replacingOccurrences` on parameterized text (catalog dict) — insert by position only.
- ByteRange math: element 4 is a LENGTH, not an end offset.
- openssl `cms -verify` without `-binary` canonicalizes CRLF → false negatives.
- SecTrustEvaluateWithError = network fetch of intermediates = unbounded hangs.
- NSRegularExpression on a whole binary PDF — scope to objects/windows.
- Never blind-probe the card's auth retries (6985 = stop and re-insert).
- A vendor update may change object numbers/shapes but NOT, so far: AIDs, SM rules,
  cert encodings, the MDQTSA URL, or the `/sign/*` async pattern (unchanged 2019→now).
