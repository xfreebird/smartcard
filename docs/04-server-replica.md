# 04 — MoldSign Server Protocol Replica

`swift/MoldSignKit/Sources/MoldSignKit/Bridge/Server.swift` — a drop-in replacement for the Java MoldSign Server,
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
| `GET /sign/data/PKCS11/{sessionId}/{type}[?keep_pin_session=1]` | — | **long-poll**: held until the worker finishes, then `200 {"base64File": "…"}` or `400` + `error` header |
| `POST /sign/pdf` | `SignPdfInputModel` | same async, poll → `{"path": "…"}` |
| `POST /sign/file` | `SignFileInputModel` (XML from tool, JSON from browser) | poll → `<XadesSignatureModelContainer>` |
| `POST /sign/file/verify` | `VerifySignedFileInputModel` | poll → `<verifySignedFileResponseModel><valid>bool</valid></…>` |
| `POST /verify/pdf` (alias `/sign/pdf/verify`) | `VerifyPdfInputModel` | poll → `<verifyPdfResponseModel><valid>bool</valid></…>` |

## Required wire habits (bugs we hit)

1. **`Location` must be ABSOLUTE** (`https://localhost.cts.md:18443/sign/data/PKCS11/{id}/Any`
   built from the request's Host). Axios resolves relative Locations against the PORTAL,
   not localhost — the reason browser signing failed with a cryptic error once.
2. **Long-poll, never 303** (corrected 2026-10-25). The vendor's `GET` handler calls
   `Scheduler.getResult` → `Future.get()`, which blocks until the worker finishes; no vendor class emits 303.
   The portal issues **one** GET per document and fails with "Failed to obtain signature location." if it
   errors. A 0.5 s/303 loop breaks once consent + PIN take > ~10 s, because browsers follow at most 20
   redirects (that regression shipped in 0.1.0). Earlier notes claiming "303 until ready" described our first
   replica, which in practice also long-polled by accident: the poll queued behind the work on one serial queue.
   Failures are `400` with header `error: <message>` (exposed via CORS), like the vendor.
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

- `/sign/moldsign/:id` and `/sign/idcard/:id` routes share the local-server flow (re-read 2026-10-25 from
  `chunk-4385ef64.29411252.js`):
  1. `GetInstrumentConfig` → `moldSignDesktopServerUrlPrefix`; `GET {prefix}/certificates?private_only=true`.
  2. `MoldNationalSign/Signing?id=…` → `contentIDs` + content type. Defaults
     `p = {algorithm:"SHA-1", certificate:null, signatureType:"Embedded", signFormat:"XAdES-T"}`.
     PDF content → `p.contentType="Pdf", p.signFormat="PAdES-T"`, `data` = the PDF (`MoldNationalSign/GetContent`).
     Otherwise `p.contentType = "Text"` (hash content) or `"Xml"`, `data` = `contentHash` → **enveloping XAdES-T**.
  3. `POST {prefix}/sign/data[?use_pin_session=<first sessionId>]` → `201` + `Location`.
  4. **One** `GET` on `Location` (+ `?keep_pin_session=1` for the first of several documents) → `base64File`.
  5. `POST MoldNationalSign/Signature?id=…` with `base64File` → expects `"Signature received"`, then the next document.
- `use_pin_session` / `keep_pin_session=1` keep the PIN alive across a multi-document batch (vendor
  `PinDistributor`). **Implemented (MAC-19):** after a successful signature the PIN is remembered under that
  session id. A later `POST …/sign/data?use_pin_session=<id>` from the **same origin** reuses it with no new consent
  or PIN prompt. A poll without `keep_pin_session=1` ends its session's entry. Entries live in memory only, expire after
  5 idle minutes, and are wiped by `stop()`. The card still VERIFYs the PIN for every document.
- `algorithm` (portal default `"SHA-1"`) is honoured for **XAdES** (R-11), like the vendor
  (`SignFileInputModel.signAlgorithm = SignDataInputModel.algorithm`): `rsa-sha1` + SHA-1 reference,
  SignedProperties and certificate digests, and a SHA-1 DigestInfo to the card. PAdES stays SHA-256; the live portal
  accepted SHA-256 PAdES with macOS 0.1.1.
- Verify flow: `POST /api/direct/verify` with multipart `VerifyContent` + reCAPTCHA —
  portal-side; the LOCAL replica is not involved in portal verification.

## Extending the replica

Vendor adds a route? Decompile the updated `ClientCardServer-2.0.jar`
(`re/cfr-0.152.jar`), read `server/services/*.java` for `@Path`/`@POST/@GET`, mirror the
URI-building `replacePath(...).path(sessionId)` calls — they dictate the Location shapes.


## Several cards, identity guard, names (2026-10-25)

* `/certificates` lists **every** inserted card (vendor `GlobalCertificateProvider`), with decoded names, built
  with `JSONSerialization`. Root cause of "no available signatures" with a second card: the old string-built
  JSON left the `label` unescaped, so `"M\C3\AEndru…"` contained `\C`, an invalid JSON escape the portal couldn't
  parse. (The portal shows that message for an empty list *or* an unparsable body.)
* Sign requests carry the portal's chosen `certificate`. `BridgeRequest.certificateSHA1/certificateHolder` go to
  the consent hook, and the server signs with the reader that holds that card.
* Before VERIFY the server compares the card's certificate with the card the PIN is for (the host's
  `.allow(pin:, certificateSHA1:)`, the request's certificate, or the batch PIN session's card) → `cardChanged`.

## Hardening and embedding (2026-10, F-07 / SEC-01…03)

The replica is now an embeddable component (`MoldSignServer`: `start()` / `stop()` / `run()`), hosted by the
macOS menu-bar app, the iOS app (foreground only) and the `moldsign server` CLI. Behavior changes vs. the
first replica:

| Change | Why |
|---|---|
| **Origin allow-list enforced** (`BridgeOriginPolicy`, vendor list in `spec/bridge/allowed-origins.properties`). Unknown origins → `403` with **no** CORS headers. `moldSign: DesktopSuiteClient` only counts when `Origin` is absent | The first replica echoed any `Origin`: any website could drive signing (with `MSIGN_PIN` set, silently). Matches vendor `Certificates.java` logic |
| **Bound to 127.0.0.1** via `requiredLocalEndpoint` | `NWListener(on:)` listened on all interfaces → LAN-reachable |
| Preflight answers `Access-Control-Allow-Private-Network: true` | Chrome/Edge Private Network / Local Network Access |
| Card work on its own queue; result polls are **long-polls** answered when the session finishes; failures → `400` + `error` header | Matches the vendor (`Future.get()`); consent + PIN may take long. (0.1.0 used 0.5 s/303 and broke browser signing) |
| `authorize` hook (consent + PIN) and `onEvent` (activity) for hosts; CLI fallback unchanged (`MSIGN_PIN` → osascript dialog → tty) | SEC-02 per-request consent in the apps |
| `onListenerError` reports `EADDRINUSE` | The vendor Java server holds 18480/18443 while it runs (MAC-08) |
| Request bodies capped at 64 MB | SEC-03 |

The vendor answers denied origins with `401` + header `error: Web site not authorized` (and still echoes CORS);
ours returns `403` without CORS, so a disallowed page cannot even read the refusal.
