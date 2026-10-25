# 04 — MoldSign Server Protocol Replica

`MoldSignMac/MoldSignMac/Server.swift` — a drop-in replacement for the Java MoldSign Server,
so the msign.gov.md "Sign with MoldSign / IdCard" browser flows work with our app.

## Transport

- Binds **http://127.0.0.1:18480** (plain, like vendor) and
  **https://localhost.cts.md:18443** (TLS), the latter being what the portal's
  `GET /api/direct/GetInstrumentConfig` returns as `moldSignDesktopServerUrlPrefix`.
- `localhost.cts.md` resolves to 127.0.0.1 system-wide; the TLS identity is the vendor's
  publicly-issued Certum DV certificate (see doc 07 / AGENTS.md for extraction).
- HTTP: one request per connection (`Connection: close`), `Content-Length` framed,
  NWListener on a serial queue; heavy work (card ops) runs inside server sessions, never
  inside a connection callback.

## Auth / CORS (mirrors vendor CORSFilter + Certificates.sec)

- Allowed if the `Origin` matches the vendor's allow-list, **OR** the request carries
  `moldSign: DesktopSuiteClient` header. Our replica echoes `Access-Control-Allow-Origin: <Origin>`
  and allows any localhost origin (loopback only).
- Headers allowed+exposed: `Origin, x-requested-with, content-type, accept, error, Location`.
- `OPTIONS` → 200 + `Access-Control-Allow-Methods: GET, POST, OPTIONS`.

## Endpoint inventory

| Method/Path | In | Out |
|---|---|---|
| `GET /certificates[?private_only=true]` | — | `{"certificateModel":[CertificateModel…]}` (XML if Accept xml) |
| `POST /sign/data` | `SignDataInputModel` (JSON or Jersey-XML) | 201 + `Location: <absolute>` |
| `GET /sign/data/PKCS11/{sessionId}/{type}[?keep_pin_session=1]` | — | 303 + Location until ready, then `{"base64File": "…"}` |
| `POST /sign/pdf` | `SignPdfInputModel` | same async, poll → `{"path": "…"}` |
| `POST /sign/file` | `SignFileInputModel` (XML from tool, JSON from browser) | poll → `<XadesSignatureModelContainer>` |
| `POST /sign/file/verify` | `VerifySignedFileInputModel` | poll → `<verifySignedFileResponseModel><valid>bool</valid></…>` |
| `POST /verify/pdf` (alias `/sign/pdf/verify`) | `VerifyPdfInputModel` | poll → `<verifyPdfResponseModel><valid>bool</valid></…>` |

## Required wire habits (bugs we hit)

1. **`Location` must be ABSOLUTE** (`https://localhost.cts.md:18443/sign/data/PKCS11/{id}/Any`
   built from the request's Host). Axios resolves relative Locations against the PORTAL,
   not localhost — the reason browser signing failed with a cryptic error once.
2. **303 while pending**: Java's scheduler returns the same Location until the worker adds
   a result; the browser's polling loop depends on this exact pattern.
3. Model names/fields (from `re/decompiled/TransferObjects-2.0`):
   - `SignDataInputModel`: `data`(b64), `contentType`("Pdf"), `algorithm`("SHA-256"),
     `signFormat`("PAdES-T", "XAdES-T"…), `signatureType`("Embedded"/"Detached"),
     `certificate{…}`, `signatureReference`, `requester` (no PIN field).
   - `SignFileInputModel`: `filesToSign[]`, `signatureFile`, `destinationFile`,
     `signatureReference`, `certificate`, `signFormat`, `signAlgorithm`, `pin`, `type`,
     `eachFileSeparately`, `requester`. Formats: `XAdES-BES|XAdES-T|XAdES-C|PAdES|PAdES-T`,
     types `Embedded|Detached`, algos `SHA-1|SHA-256`.
   - `CertificateModel`: `certificateId`(SHA-1(certDER)), `label`, `providerId`
     (`libbit4xpki.dylib-0`), `policy`, `certificateName`, `subjectDN`, `issuerDN`,
     `authority`, `trusted`, `verified`, `privateKeyPresent`, `certificateBase64`.
   - Response models: `SignDataResponseModel{base64File}`, `SignPdfResponseModel{path}`,
     verify models `{valid}`.
   - **Jersey list serialization**: list fields repeat the TAG per item
     (`<filesToSign><filesToSign>/a</filesToSign></filesToSign>`). Parse leaf pairs only;
     outer-first matching consumes the inner open tag (real bug).
4. `certificate` inside a request may legitimately be empty —
   `Data(base64Encoded: "")` returns EMPTY-not-nil Data and crashes the cert parser:
   guard `!b64.isEmpty` before decoding (crashed the whole server once).

## PIN UX

- Request carries `pin` → use it.
- Else `MSIGN_PIN` env (dev/testing).
- Else native dialog (`osascript display dialog … with hidden answer`) — what the user
  sees when the page says "input PIN" and the Java suite would show its own GUI popup.
- Fallback to tty `readLine` only when interactive.

## Browser frontend map (chunk-4385ef64 on msign.gov.md)

- `/sign/moldsign/:id` and `/sign/idcard/:id` routes share the local-server flow:
  fetch `GetInstrumentConfig` → `GET {prefix}/certificates?private_only=true` → user picks
  cert + format → `POST {prefix}/sign/data` with `p = {algorithm, certificate:null,
  signatureType:"Embedded", signFormat:"XAdES-T"}` → poll Location → POST result to
  `MoldNationalSign/Signature` on the portal.
- `use_pin_session` / `keep_pin_session=1` query params exist to keep the PIN alive
  across multiple-file batches; replicate by honoring-but-ignoring them (replica prompts
  per session today).
- Verify flow: `POST /api/direct/verify` with multipart `VerifyContent` + reCAPTCHA —
  portal-side; the LOCAL replica is not involved in portal verification.

## Extending the replica

Vendor adds a route? Decompile the updated `ClientCardServer-2.0.jar`
(`re/cfr-0.152.jar`), read `server/services/*.java` for `@Path`/`@POST/@GET`, mirror the
URI-building `replacePath(...).path(sessionId)` calls — they dictate the Location shapes.
