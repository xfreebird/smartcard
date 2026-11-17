---
title: Card protocol and signing sequence
description: Follow mutual authentication, certificate selection, protected PIN verification and RSA signing on the CosmoX ID-A card.
---

The supported contact-card profile is IDEMIA CosmoX ID-A using IAS/ECC commands. **The card stores the signing key and performs the private-key operation.** The host prepares a digest, supplies authorization through a protected channel, and receives a signature.

The explanations below describe the current implementation. They are not commands to paste into a physical-card console. Use the simulated card for development: retry counters belong to the physical card and a wrong PIN consumes an attempt.

## Signing sequence

![Sequence diagram of user approval, application preparation, secure-channel establishment, certificate identity comparison, encrypted PIN verification, RSA signing and timestamp assembly.](/img/developers/card-sequence.svg)

[Open the full-size sequence](https://esemnbun.md/img/developers/card-sequence.svg). This is the logical flow; certificate discovery may open an earlier session, and the signing path rechecks identity. Local UI details and batch consent differ by platform. Every arrow to the card passes through a transport and reader.

1. **Prepare.** Freeze the selected identity and input bytes. Format code calculates what must be signed.
2. **Authenticate the channel.** The host selects the IAS application, reads protocol initialization data, exchanges fresh challenges and verifies the authentication response. This is separate from the person's signing PIN.
3. **Read identity.** Select the Generic application and certificate file. Compare the certificate with the identity the person approved. Stop if it changed.
4. **Verify PIN.** Send the PIN inside secure messaging, using PIN reference `03`. Stop on a wrong or blocked PIN; do not automatically try it again.
5. **Sign.** Select the signing security environment and send ASN.1 `DigestInfo` to `INTERNAL AUTHENTICATE`. The observed signing key is RSA-4096, producing a 512-byte signature.
6. **Finish.** Obtain any required timestamp, assemble PDF/CMS or XML evidence and write the result. Disconnect and release the operation lock on success or failure.

Mobile NFC reads the public signing certificate before mutual authentication and reuses the same connection through signing. See the [iOS and Android sequences](reader-protocol.md#mobile-nfc-transport).

## APDU anatomy

An APDU is a command message. A short command uses these fields; which optional fields appear depends on the command:

```text
CLA  INS  P1  P2  [Lc  Data...]  [Le]
1 B  1 B 1 B 1 B  1 B Lc bytes  1 B
```

| Field | Meaning | Example |
| --- | --- | --- |
| `CLA` | Command class / secure-messaging indication | Plain `00`; protected header sets bits with `CLA OR 0C` |
| `INS` | Instruction | `A4` select, `B0` read, `20` verify, `22` security environment, `88` sign |
| `P1`, `P2` | Instruction-specific parameters | `P2=03` identifies the PIN for `VERIFY` |
| `Lc` | Number of command-data bytes | `0E` means 14 bytes, not the text “0E” |
| `Data` | Instruction payload | Application identifier, PIN bytes or DigestInfo |
| `Le` | Requested response length | Short `00` encodes up to 256 bytes, not zero response bytes |

Extended APDUs have a leading zero length marker and two-byte lengths. Secure wrapping can make a short logical payload too large for a short APDU; the wrapper chooses the extended representation when needed.

A response is `Data... SW1 SW2`. The status word is two bytes. An outer transport success and a successful card operation are different: protected responses can carry the actual card status inside tag `99`.

## Logical command examples

These are **unwrapped** commands. After authentication, the secure-channel code transforms them before transmission. `PIN`, `DIGEST_INFO` and `N` are placeholders, never literal data to send.

| Operation | Logical bytes | Interpretation |
| --- | --- | --- |
| Select master file | `00 A4 00 0C 02 3F 00 00` | File `3F00`, with trailing `Le=00` |
| Select Generic ADF | `00 A4 04 04 0E E8 28 BD 08 0F D2 50 47 65 6E 65 72 69 63 00` | Four-byte header, 14-byte AID, trailing Le; `P2=04` matters |
| Select certificate EF | `00 A4 02 04 02 00 01 00` | Elementary file `0001` |
| Read first 128 bytes | `00 B0 00 00 80` | Offset zero, `Le=128` |
| Read next 128 bytes | `00 B0 00 80 80` | Offset 128; offset occupies `P1/P2` |
| Verify signing PIN | `00 20 00 03 N PIN` | Raw ASCII PIN bytes are encrypted by secure messaging |
| Set signing environment | `00 22 41 A4 06 80 01 02 84 01 81` | Security-environment TLVs used by this card profile |
| Request signature | `00 88 00 00 N DIGEST_INFO` | Card signs the encoded digest using the selected key |
| Continue response | `00 C0 00 00 xx` | Issued when a response ends in `61xx` |

`80 01 02` is a TLV: tag `80`, length one, value `02`. It is followed by `84 01 81`. TLV lengths count **bytes**, not hexadecimal characters.

The certificate reader first examines the DER sequence length, then reads the complete outer X.509 certificate in chunks of at most 128 bytes. Do not hardcode the length observed on one person's card. Returning only the inner “to-be-signed” certificate body loses the issuer signature and produces an invalid certificate object.

## Mutual authentication and session keys

Before protected commands, `authenticate()` selects IAS/MF and reads the serial/seed files `D003` and `D004`. It configures mutual authentication, requests a 16-byte challenge, and sends a 96-byte external-authentication payload. Both sides contribute fresh material; the host verifies the response and derives session encryption and authentication keys plus an initial sequence counter.

The implementation uses AES-256, CMAC and profile-specific key derivation. Long-term vendor authentication material is intentionally absent from this public guide. Authorized contributors should use the implementation and **synthetic** golden vectors, never copy live session keys or proprietary key material into documentation. Mutual authentication establishes the host/card session; PIN verification separately authorizes signing.

## Secure messaging, byte by byte

For each command, the wrapper increments the 16-byte big-endian send sequence counter (SSC). It sets `CLA |= 0C`, pads the header, encrypts command data when present, includes the expected response length, and authenticates the result.

```text
Protected header | encoded Lc | [87 or 85] | [97] | 8E | outer Le

87 length 01 ciphertext...     encrypted data for an even INS
85 length ciphertext...        encrypted data for an odd INS
97 length expected_length...   original Le, if present
8E 08 mac[0..7]                first eight CMAC bytes
```

The encryption IV is `AES-ECB(sessionENC, incrementedSSC)`. Data uses AES-CBC and ISO 9797-1 method 2 padding: append `80`, then zero bytes until the next 16-byte boundary, including a full padding block when necessary. The CMAC input includes the SSC, padded protected header and encoded data/Le objects, followed by method 2 padding. Truncation to eight bytes is part of this card profile.

The wrapper appends outer `Le=00` for short commands even when the logical command only sends data. Extended commands use the corresponding two-byte outer Le. Omitting it is a compatibility failure.

On response, the SSC advances again. Tags `87`/`85` carry encrypted data, `99` carries status, and `8E` carries the response MAC. The current parser checks a response MAC when supplied and supports status-only responses; that implementation detail is not a general guarantee that every possible response is authenticated. `smTransmit()` advances the counter for a status-only response as well. Unpadding happens **once** in the secure-channel layer; repeating it in the file reader can remove legitimate trailing `00` or `80` bytes.

## Failure and recovery

| Status or symptom | Meaning in this flow | Action |
| --- | --- | --- |
| `9000` | Command succeeded | Continue the expected state machine |
| `61xx` | Additional response bytes available | Core sends GET RESPONSE and joins the data |
| `63Cx` during VERIFY | Wrong PIN; low nibble gives attempts remaining | Stop, discard a saved wrong PIN, show remaining attempts |
| `6983` | PIN blocked | Stop; follow the issuer's recovery process |
| `6985` | Card state/conditions do not allow this operation | Stop repeated authentication; ask for removal/reinsertion |
| `6988` or MAC mismatch | Secure session is out of sync or integrity failed | End the session; investigate framing/counters before retrying |
| Certificate mismatch | A different identity is now in the reader | Stop before VERIFY and refresh selection |

A reset API exists in platform transports, but do not assume every connection automatically resets the card. Check the specific adapter. Do not try to diagnose a channel problem by submitting PINs repeatedly.

## Source and regression anchors

Read `swift/MoldSignKit/Sources/MoldSignKit/Card/{Card,SecureChannel}.swift`, `android/core/src/main/kotlin/md/moldsign/core/card/`, and `windows/src/MoldSign.Core/Card/`. The simulated-card tests and `spec/vectors/card-crypto.json` cover padding, key derivation, CMAC, wrapping, response continuation and identity checks. [Reader framing](reader-protocol.md) explains the bytes outside these APDUs.
