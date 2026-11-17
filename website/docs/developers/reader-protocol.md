---
title: Reader protocol — CCID, T=1 and NFC
description: How identity-card APDUs travel over USB CCID or NFC, with signing sequences for iOS and Android.
---

A card command and a USB packet are different messages. The app's core produces an APDU. A transport delivers it to the reader. Depending on the reader's capabilities, either the reader or host splits it into card-level blocks.

```text
Document → DigestInfo → protected APDU → [T=1 blocks] → CCID messages → USB
                                                                   ↓
Document ← signature ← protected response ← reader ← identity card
```

The brackets mean T=1 framing is visible to the application only for a reader that needs the host to implement it. On desktop PC/SC and Apple CryptoTokenKit paths, the operating-system stack handles lower-level delivery.

## Which platform owns which work?

| Platform | App-facing API | Reader-level work |
| --- | --- | --- |
| macOS CLI | PC/SC through the C shim | OS smart-card/CCID stack |
| Apple native apps | CryptoTokenKit slot and card sessions | OS stack; app needs appropriate access/entitlements |
| Windows | WinSCard P/Invoke adapter | Windows smart-card resource manager and driver |
| Linux | pcsc-lite through the C shim | `pcscd` and a CCID driver, usually libccid |
| Android | USB host APIs, permission, claimed interface and bulk endpoints | `CcidTransport` and, for TPDU readers, the Kotlin `T1` engine |

Android cannot assume a PC/SC daemon exists. The app discovers a CCID interface (USB class `0B`, with a supported vendor-class descriptor fallback), asks for USB access, and claims its bulk IN/OUT endpoints. A connected reader without USB permission is a distinct state from an empty reader.

## Mobile NFC transport

Both mobile apps carry ISO 7816 command and response APDUs over the phone’s contactless connection. The NFC transport replaces USB CCID for that signing attempt. Application selection, certificate reads, secure messaging and the private-key operation still belong to the IAS/ECC card protocol. In both diagrams, arrows between the signing core and the card pass through the indicated NFC transport. See [card protocol](card-protocol.md) for APDU framing, mutual authentication and secure responses.

### iOS NFC sequence

![iOS sequence from PIN approval through Core NFC discovery, certificate binding, protected signing and document output.](/img/developers/nfc-ios-sequence.svg)

[Open the full-size iOS sequence diagram](https://esemnbun.md/img/developers/nfc-ios-sequence.svg).

1. The shared `PINCoordinator` obtains authorization before `NFCDocumentSigner` opens the system NFC sheet. `NFCSigningSession` creates an `NFCTagReaderSession` with ISO 14443 polling. The main app declares its NFC TAG entitlement, localized usage text, and the IAS and Generic application identifiers in that order.
2. Core NFC tries the declared application identifiers during discovery. The app accepts one ISO 7816 tag and connects once. `NFCISO7816Transport` sends commands through `NFCISO7816Tag.sendCommand` and returns response data plus SW1/SW2 to the Swift core. Blocking card work stays off the main thread. [Apple Core NFC reference](https://developer.apple.com/documentation/corenfc/nfciso7816tag)
3. The public reader selects the Generic ADF and reads EF `0001` directly. The signer binds the certificate before giving the same transport to the signing service. It requests session invalidation when the signing service reaches timestamping or completion. The output returns after the NFC session closes.

### Android NFC sequence

![Android sequence from PIN approval through foreground reader mode, ISO-DEP discovery, certificate binding, protected signing and document output.](/img/developers/nfc-android-sequence.svg)

[Open the full-size Android sequence diagram](https://esemnbun.md/img/developers/nfc-android-sequence.svg).

1. `NfcSignDocuments` loads the selected documents and obtains authorization through the shared `ConsentBroker` before enabling reader mode.
2. `NfcSigningController` enables foreground NFC-A and NFC-B polling with the NDEF check skipped. It takes the detected tag’s `IsoDep` connection, connects once and calls `transceive` off the UI thread. The transport enforces the device’s maximum command length. [Android ISO-DEP reference](https://developer.android.com/reference/android/nfc/tech/IsoDep)
3. Android explicitly selects IAS before selecting the Generic ADF and EF `0001`. The signer binds the certificate, then supplies that same connection to `CardSigningService`. The card-signature callback closes ISO-DEP and arranges for reader mode to be disabled. Timestamping and saving can then complete without the card.

### Shared IAS/ECC sequence over NFC

| Phase | Command or response | Identity and session rules |
| --- | --- | --- |
| Public certificate | `SELECT` Generic ADF and EF `0001`, then `READ BINARY` | Reads use chunks of up to 128 bytes and enforce a 4,096-byte limit. A known identity must match the exact DER. The first accepted certificate becomes the identity for a new batch. |
| Secure channel | IAS/ECC initialization, challenge and mutual authentication | Uses the same NFC connection. The core validates the response authentication and challenge binding before accepting the channel. |
| PIN check | Read the signing certificate in the secure path and issue protected `VERIFY` for the signing PIN | A changed identity ends the attempt before PIN transmission. Reader and NFC use the same certificate-keyed PIN account. |
| Card signature | Select the signing environment and send encoded `DigestInfo` to `INTERNAL AUTHENTICATE` | The card returns the signature bytes. If SW1 is `61`, bounded `GET RESPONSE` calls take the rest of that response. |
| Document output | Release NFC and finish the PAdES or XAdES result | The app adds the timestamp when the format requires it. Diagnostics distinguish the card signature from a successfully written document. |

A batch collects authorization once and opens one NFC session per document. Cancellation, link loss, identity mismatch or a PIN error stops the batch and closes the active session. The app requires a new user action to retry. No PIN, complete APDU payload or personal certificate belongs in public diagnostics. See [testing](testing.md) for the physical acceptance checks.

## Inspect capabilities before transmitting

The CCID class descriptor tells the transport the available slots, protocols, voltages, maximum message size and exchange level. In `dwFeatures`, the exchange-level bits are:

| Mask | Level | What the host sends |
| --- | --- | --- |
| `00010000` | TPDU | T=1 blocks built by the host |
| `00020000` | Short APDU | Complete short APDUs |
| `00040000` | Extended APDU | Complete APDUs, including extended lengths |

These are hexadecimal masks, not decimal strings. The transport rejects unsupported character-level readers. It selects voltage from the descriptor instead of assuming automatic voltage selection is always supported.

`IccPowerOn` returns an ATR, the card's answer to reset. The ATR advertises communication parameters; it is not a personal identifier or signing certificate. For the miniLector TPDU path, the host configures T=1 with `SetParameters` when automatic parameter negotiation is absent, then negotiates information-field size. It does not assume every CCID reader has the miniLector's capabilities.

## The 10-byte CCID header

| Offset | Size | Field | Meaning |
| --- | --- | --- | --- |
| 0 | 1 | `bMessageType` | Command or response kind |
| 1–4 | 4 | `dwLength` | Payload length, **little-endian**, excluding the header |
| 5 | 1 | `bSlot` | Reader slot index |
| 6 | 1 | `bSeq` | Command sequence, wrapping from 255 to 0 |
| 7–9 | 3 | Message-specific | Power/protocol/transfer parameters, or status/error/chain fields |
| 10 onward | `dwLength` | Payload | ATR, APDU or T=1 block |

For example, this synthetic short-APDU-level message transports the five-byte GET CHALLENGE command:

```text
6F 05 00 00 00 00 2A 00 00 00  00 84 00 00 10
│  └─────┬────┘ │  │  └──┬──┘  └─────┬─────┘
XfrBlock len=5  slot seq  params       APDU
                0   42
```

It illustrates framing only. A TPDU-level reader expects a **T=1 block** in that payload, not this raw APDU. The length would change accordingly. The card driver chooses when GET CHALLENGE is valid within authentication.

| Direction | Type | Purpose |
| --- | --- | --- |
| Host → reader | `62` IccPowerOn | Power/reset and obtain ATR |
| Host → reader | `63` IccPowerOff | End powered session |
| Host → reader | `65` GetSlotStatus | Ask whether a card is present/active |
| Host → reader | `61` SetParameters | Set protocol parameters |
| Host → reader | `6F` XfrBlock | Transfer an APDU or TPDU |
| Reader → host | `80` DataBlock | Data response |
| Reader → host | `81` SlotStatus | Slot-state response |
| Reader → host | `50` NotifySlotChange | Interrupt notification format; monitoring may use polling |

In a response, `bStatus & 03` decodes card state: `0` present/active, `1` present/inactive, `2` absent. `(bStatus >> 6) & 03` decodes command state: `0` success, `1` failed, `2` time extension. A time extension is not a completed APDU response. Match slot and sequence, assemble the advertised payload length, and handle the reader's status before interpreting the card's `SW1/SW2`.

## T=1: splitting and reassembling card traffic

The TPDU path uses:

```text
NAD | PCB | LEN | INF (LEN bytes) | LRC
```

`NAD` addresses the logical nodes (zero in this profile). `PCB` identifies the block type and sequencing. `LEN` counts information bytes. `LRC` is the XOR checksum of preceding block bytes; it detects transmission errors and is **not** a cryptographic MAC.

| Block | Important PCB bits | Role |
| --- | --- | --- |
| I-block | bit 7 = 0; bit 6 = send sequence; bit 5 = more blocks | Carries APDU bytes |
| R-block | top bits `10`; bit 4 = expected sequence | Acknowledges/reports reception state |
| S-block | top bits `11`; subtype selects control exchange | Negotiates IFS or handles waiting-time extension (WTX) |

The host splits commands according to the card's IFSC, acknowledges chained response I-blocks and joins their INF bytes. Host/card sequence bits restart for a new powered session. WTX asks for additional processing time; the engine answers the control exchange rather than resending the signing command as if it had failed. CCID's command sequence, T=1's one-bit sequences and secure messaging's 128-bit SSC are **three different counters**.

## Troubleshoot from the outside inward

1. **USB / OS:** does the device appear, is access granted, and does the correct process or VM own it?
2. **Reader:** can slot status and power-on return a sensible ATR? On Linux, check `pcscd` and local-session permissions.
3. **Transport:** does the descriptor select APDU or TPDU mode? Are length, slot, sequence and T=1 checksums correct?
4. **Card session:** do selection, mutual authentication and secure-message counters agree?
5. **Signing:** does the certificate match, and has the user approved? Only now is PIN verification relevant.

USB success is not evidence that signing succeeded. Card success is not evidence that a timestamp or output-file write succeeded. Keep logs at those boundaries, with private data removed.

Implementation: `android/transport-usb/src/main/kotlin/md/moldsign/transport/usb/{Ccid,CcidTransport,T1}.kt`. For the underlying wire specification, see the [USB-IF CCID 1.1 specification](https://www.usb.org/sites/default/files/DWG_Smart-Card_CCID_Rev110.pdf). The field descriptions here are grounded in the project's implementation; consult the specification for other reader profiles.
