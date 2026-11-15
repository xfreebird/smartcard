---
title: Reader protocol — CCID and T=1
description: How APDUs travel through operating-system smart-card APIs or Android USB CCID framing to the physical identity card.
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
