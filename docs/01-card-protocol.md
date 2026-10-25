# 01 — Card Protocol (IDEMIA CosmoX ID-A via IAS/ECC + Secure Messaging)

How MoldSignKit talks to the Moldovan national eID card. Implemented in
`swift/MoldSignKit/Sources/MoldSignKit/Card/{Card,SecureChannel,Crypto,Transport}.swift` + `swift/MoldSignKit/Sources/CPCSC/` (C target).

## Hardware

- Reader: **bit4id miniLector POCKET EVO** (USB CCID, PC/SC)
- Card: **IDEMIA CosmoX ID-A** (Moldovan national eID; OS profile "MDA_ASP" (Moldova ASP), ASCII-visible in the ATR below)
- Chip serial: `XXXXXXXXXXXXXXXX` (per-cardholder value read at runtime) — **unique per physical card**,
  do not publish; it participates in the SM key derivation (`Kenc/Kmac = SHA256(seed‖serial‖MK‖ctr)`).
  The real serial of the development card lives only in the private `re/` golden vectors.
- ATR (example): `3B DF 96 00 81 31 FE 45 80 73 84 21 E0 57 4D 44 41 5F 41 53 50 81 0F 78` —
  **model/OS fingerprint**, identical on all CosmoX ID-A cards with this firmware; use to
  detect the card type, not to identify a person.

The protocol is the same IAS/ECC family used by the Italian CIE middleware
(`cie-middleware-linux`, still at `re/` history / public GitHub), but with
STISC-specific AIDs and templates extracted from runtime traces.

## Connection rules

1. `SCardEstablishContext` → `SCardConnect(SCARD_SHARE_SHARED)`.
2. **Immediately `SCardReconnect(SCARD_RESET_CARD)`** — without this the card may
   be left in secure-messaging state from a crashed session and everything fails.
3. Mutual authentication per IAS/ECC:
   - Kenc = `SHA256(seed ‖ serial ‖ MK ‖ 0x00000002)`, Kmac = `SHA256(seed ‖ serial ‖ MK ‖ 0x00000003)`
   - Ext-auth payload: `AES-256-CBC(Kenc, 80B) ‖ CMAC-16(Kmac)`; card proves with CMAC over ciphertext.
   - Session keys = `SHA256(K_ICC ⊕ K_IFD ‖ counter)` — all vectors in
     `swift/MoldSignKit/Tests/MoldSignKitTests/CryptoTests.swift` + `spec/vectors/card-crypto.json` (golden, from middleware).

## Secure Messaging rules (every bug here was hit once)

- Command encrypt: AES-256-CBC, **`IV = AES-ECB(KsessENC, SSC+1)`** (SSC incremented *before*
  computing the IV but the MAC covers the incremented SSC too), ISO-9797-2 padding (`80 00…`).
- MAC: AES-CMAC over padded `SSC ‖ enc-header ‖ enc-data`, truncated to 8 bytes.
- TLVs: `87` (padded CT), `97` (Le when expected response), `99` (SW), `87/…` reassembled.
- **Always append `Le = 00`** to SM commands, even case-3 (the middleware's Lua driver does;
  without it the INTERNAL AUTHENTICATE response gets truncated at ~291 of 549 bytes).
- **SSC increments for every command AND every response, including SW-only responses**
  (VERIFY PIN's `99 02 90 00` still consumes one).
- Raw (case-2) APDUs like READ BINARY (`00 B0 … Le`) have Lc==1: Le only — never treat
  `body[0]` as an Lc.

## Swift Data traps (root causes of two SIGTRAPs)

- `apdu.dropFirst(4)` keeps `startIndex = 4` in the slice — `slice[0]` **crashes**.
  Always wrap: `Data(apdu.dropFirst(4))` before indexing.
- Building SSC from Data slices shifted the counter into byte 7 instead of 15 —
  convert to `[UInt8]` first.
- Never compute `pdfData.distance(from: otherData.startIndex, to: ...)` across instances.

## Signing flow (happy path, all in Card.swift)

```
CONNECT + RESET
MUTUAL AUTH (IAS/ECC)                    → session keys
SELECT MF            00 A4 00 0C
SELECT Generic ADF   00 A4 04 04 0E E828BD080FD25047656E65726963   (P2=04 — required!)
VERIFY PIN           00 20 00 03  xx pin                              (ref 0x03)
SELECT MF + ADF again (some firmwares require)
MSE SET              00 22 41 A4  80 01 02 84 01 81                  (kid 02, algo RSA-4096 raw)
INTERNAL AUTH        00 88 00 00  Lc DigestInfo(SHA256)              → 512 B RSA-4096 sig
```

## Certificate read

EF `0001` inside Generic ADF: `READ BINARY` in 128-byte chunks → **1799 bytes** full
X.509 outer SEQUENCE (TBS + sigAlg + signature). The first 1263 bytes are the TBS —
feeding TBS-only into the CMS broke chain validation for a full session.

Subject: `CN=Ghimbovschi Nicolae, serialNumber=2002037091774, ST=Republica Moldova,
T=+37369448913, C=MD`; issuer: MDQSign (CN), mdtrustca root above it.

## Status-word playbook

| SW | Meaning | Recovery |
|---|---|---|
| `9000` | OK | — |
| `6988` | SM object/IV/SSC mismatch | review SSC + Le=00 logic; card in fresh state |
| `6A82` | file/AID not found | wrong AID bytes (trailing 00 was ISO padding, not AID) |
| `6985` | conditions not satisfied / counter stuck | **physically re-insert card**, never blind-probe auth (retry counter) |
| `63Cx` | PIN wrong, x tries left | — |

## If the vendor firmware/middleware changes

Rebuild ground truth:
1. `re/pcsc_trace.c` — DYLD interposer on `SCard*`; `re/run_capture.sh <vendor-app>`
   produces `re/apdu_capture.log` (full plaintext of every APDU including SM contents).
2. `re/memscan.c` + `re/dump_regions.py` — attach to the middleware process right after
   a signing run, extract candidate keys; validate against trace (`verify_kenc/kmac.txt`,
   `signing_session_keys.txt` are the current goldens).
3. Re-run `swift test` — CryptoTests are the vector checklist; they fail exactly at the
   piece that drifted.
