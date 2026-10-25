# 06 — Infrastructure & Trust Material

## Certificate chain

```
mdtrustca (root, self-signed)                       ChainCerts.mdTrustCA
└── MDQSign (issuing CA, CN=MDQSign)                ChainCerts.mdQSign
    └── user signing certs (e.g. CN=Ghimbovschi Nicolae)
```

Both CA certs are **public** — extracted from a signed CMS (certificates[0] in the
middleware output) and embedded as `swift/MoldSignKit/Sources/MoldSignKit/Formats/ChainCerts.swift` base64.
Re-acquire from any freshly-signed document (see doc 02 byte-template tool: offsets
60+1799… of the padding-stripped CMS).

## Network endpoints

| Service | URL | Notes |
|---|---|---|
| MDQTSA (RFC3161) | `http://tsp.pki.gov.md/moldsign2/` | **HTTP only**; `application/timestamp-query`; policy OID `1.2.498.3.32.5` |
| OCSP user certs  | `http://mdqsign.ocsp.pki.md` | via `openssl ocsp` CLI in -C |
| OCSP CA certs    | `http://mdtrustca.ocsp.pki.md` | in cert AIA |
| CRL MDQSign      | `http://pki.md/crl/mdqsign.crl` | curl direct download |
| CRL mdtrustca    | `http://pki.md/crl/mdtrustca.crl` | small/root CRL |
| CA cert files    | `http://pki.md/cert/mdqsign.crt`, `http://_pki.md/cer/mdtrustca.cer` | fetchable if chain needs rebuild |

X509v3 AIA/CRL-DP parsing in `XAdESSigner.extractExtensionURI` uses regex
`https?://[^\s"]+\.(crl|crt|cer)` — naive byte-scan leaks trailing printable DER bytes.

## TLS identity for the local replica

- `https://localhost.cts.md:18443` with a publicly-issued Certum DV cert (CN=`localhost.cts.md`,
  issuer `C=PL, O=Asseco Data Systems S.A., CN=Certum DV TLS G2 R39 CA`, ~1yr validity).
- Vendor ships the identity inside the suite; convert for our use:
  ```bash
  keytool -importkeystore \
    -srckeystore /Applications/STISC/MoldSign/MoldSignData/Server/sslKeyStore2.jks \
    -destkeystore localhost.p12 -deststoretype PKCS12 \
    -srcstorepass <pass-from-decompiled-ApiServer.java> -deststorepass <same>
  → swift/MoldSignKit/Resources/localhost.p12
  ```
  (password is compiled into the vendor binary — `re/decompiled/ClientCardServer-2.0/
  md/cts/moldsign/clientcardmanager/server/ApiServer.java`, `setKeyStorePass(…)`).
- Loaded via `SecPKCS12Import` → `sec_identity_create` →
  `sec_protocol_options_set_local_identity` in NWProtocolTLS.Options (TLS ≥ 1.2).
- macOS auto-trusts the Certum chain system-wide — browsers show no warnings.

## Allow-listed browser origins (vendor `allowedSites.jar`)

`msign.gov.md` (+ staging/test domains). Our replica accepts any Origin on loopback;
if you replicate outside localhost, enforce the same list.

## The local disk footprint of the vendor suite

```
/Applications/STISC/MoldSign/
  lib/                    iText 9.1.0, BC 1.80, IAIK xades/cms/tsp, Grizzly — our probe classpath
  MoldSignData/Server/sslKeyStore2.jks, allowedSites.jar, cache.jks
  jre/, native_lib/       bundled runtime + native PKCS11 libs
  log/                    err/out logs of Desktop + Server
```

## Sensitivity (short form — full version in AGENTS.md §5)

- 🔴 **User PIN QSCD** — never in repo or logs; `MSIGN_PIN` env for automation only.
- 🟡 **Vendor-shipped TLS p12 + its password** — required to function; extract locally,
  don't publish; the Certum cert is public.
- 🟢 Chain certs, TSA/OCSP/CRL URLs, AIDs/APDU shape — public/derived-from-public artifacts.
- 🔵 `re/apdu_capture.log`, `re/sm_exchanges.log` — SM-encrypted but full protocol traces;
  treat as private working files.
