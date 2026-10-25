using System.Security.Cryptography;

namespace MoldSign.Core;

/// <summary>
/// IAS/ECC secure messaging for the CosmoX ID-A (AES-256 CBC + CMAC-8). Line-by-line port of
/// <c>SecureChannel.swift</c>. Rules (all load-bearing, see docs/01 and spec/vectors):
/// <list type="bullet">
/// <item>CLA |= 0x0C; SSC += 1 before wrapping a command and again before checking its response.</item>
/// <item>IV = AES-ECB(sessENC, SSC); data → ISO 9797-2 pad → AES-CBC → tag 87 (01 || ct) for even INS, 85 for odd.</item>
/// <item>Le → tag 97. MAC = CMAC(sessMAC, pad(SSC || pad(header) || TLVs))[0..&lt;8] in tag 8E.</item>
/// <item>ALWAYS append Le=00, even for case-3 commands.</item>
/// </list>
/// Not thread-safe: one card operation at a time (SigningService holds the card lock).
/// </summary>
public sealed class SecureChannel
{
    private readonly byte[] _sessEnc;
    private readonly byte[] _sessMac;
    private readonly byte[] _ssc;

    public SecureChannel(ReadOnlySpan<byte> sessEnc, ReadOnlySpan<byte> sessMac, ReadOnlySpan<byte> ssc)
    {
        if (ssc.Length != 16) throw new ArgumentException("SSC must be 16 bytes.", nameof(ssc));
        _sessEnc = sessEnc.ToArray();
        _sessMac = sessMac.ToArray();
        _ssc = ssc.ToArray();
        // Validate key sizes early (AES-128/192/256).
        using (AesPrimitives.Create(_sessEnc)) { }
        using (AesPrimitives.Create(_sessMac)) { }
    }

    /// <summary>Current send sequence counter (copy).</summary>
    public byte[] Ssc => (byte[])_ssc.Clone();

    /// <summary>
    /// Big-endian 128-bit increment; returns the new value. Public because the card advances the SSC
    /// for SW-only responses too, and the caller must stay in sync (Swift <c>incSSCPublic</c>).
    /// </summary>
    public byte[] IncrementSsc()
    {
        for (var i = 15; i >= 0; i--)
        {
            _ssc[i]++;
            if (_ssc[i] != 0) break;
        }
        return Ssc;
    }

    /// <summary>Wraps a short plain APDU (case 1–4) into an SM APDU.</summary>
    public byte[] Wrap(ReadOnlySpan<byte> apdu)
    {
        if (apdu.Length < 4) throw new ArgumentException("APDU shorter than its 4-byte header.", nameof(apdu));

        var cla = (byte)(apdu[0] | 0x0C); // SM bit
        var ins = apdu[1];
        var p1 = apdu[2];
        var p2 = apdu[3];

        // Parse the plain body exactly like the Swift reference.
        var body = apdu[4..];
        ReadOnlySpan<byte> cmdData = [];
        byte? le = null;
        if (body.Length == 1)
        {
            le = body[0]; // case 2: CLA INS P1 P2 Le
        }
        else if (body.Length > 1)
        {
            int lc = body[0];
            if (lc > 0)
            {
                if (1 + lc > body.Length)
                    throw new ArgumentException($"Lc={lc} exceeds the APDU body ({body.Length - 1} byte(s)).", nameof(apdu));
                cmdData = body.Slice(1, lc);
            }
            if (body.Length > 2 + lc)
                throw new ArgumentException("Trailing bytes after Le (extended APDUs are not supported).", nameof(apdu));
            if (body.Length > 1 + lc) le = body[^1];
        }

        var ssc1 = IncrementSsc();

        using var macInput = new MemoryStream();
        macInput.Write(ssc1);
        macInput.Write(Iso9797.Pad([cla, ins, p1, p2]));
        using var dataField = new MemoryStream();

        if (!cmdData.IsEmpty)
        {
            var iv = AesPrimitives.EncryptEcb(_sessEnc, ssc1);
            var enc = AesPrimitives.EncryptCbc(_sessEnc, iv, Iso9797.Pad(cmdData));
            // Even INS → tag 87 with the 01 padding-indicator byte, odd INS → tag 85.
            var tlv = ins % 2 == 0 ? BuildTlv(0x87, [0x01, .. enc]) : BuildTlv(0x85, enc);
            macInput.Write(tlv);
            dataField.Write(tlv);
        }

        if (le is { } leByte)
        {
            var tlv = BuildTlv(0x97, [leByte]);
            macInput.Write(tlv);
            dataField.Write(tlv);
        }

        var mac = Cmac.Compute(_sessMac, Iso9797.Pad(macInput.ToArray()));
        dataField.Write(BuildTlv(0x8E, mac.AsSpan(0, 8)));

        var fields = dataField.ToArray();
        if (fields.Length > 255)
            throw new ArgumentException($"SM data field of {fields.Length} bytes needs an extended APDU.", nameof(apdu));

        var result = new byte[5 + fields.Length + 1];
        result[0] = cla;
        result[1] = ins;
        result[2] = p1;
        result[3] = p2;
        result[4] = (byte)fields.Length;
        fields.CopyTo(result, 5);
        result[^1] = 0x00; // the vendor Lua always appends Le=00
        return result;
    }

    /// <summary>
    /// Verifies and decrypts an SM response (TLVs 87/85, 99, 8E followed by the transport SW).
    /// Responses of 2 bytes or fewer are returned as-is WITHOUT touching the SSC; callers that get a
    /// SW-only answer to a wrapped command must call <see cref="IncrementSsc"/> themselves
    /// (<see cref="CosmoXCard.SmTransmit"/> does).
    /// </summary>
    /// <exception cref="CardException"><see cref="CardErrorKind.SmOutOfSync"/> on MAC mismatch.</exception>
    public ApduResponse Unwrap(ReadOnlySpan<byte> response)
    {
        if (response.Length <= 2) return new ApduResponse([], response.ToArray());

        var swFromTail = response[^2..].ToArray();
        var body = response[..^2];

        var ssc1 = IncrementSsc();
        using var macInput = new MemoryStream();
        macInput.Write(ssc1);

        byte[]? encrypted = null;
        byte[] resultSw = [];
        byte[] respMac = [];

        var pos = 0;
        while (pos < body.Length)
        {
            if (pos + 1 >= body.Length) break;
            var tag = body[pos];
            var l1 = body[pos + 1];
            int len, hdrLen;
            if (l1 < 0x80)
            {
                len = l1;
                hdrLen = 2;
            }
            else if (l1 == 0x81 && pos + 2 < body.Length)
            {
                len = body[pos + 2];
                hdrLen = 3;
            }
            else if (l1 == 0x82 && pos + 3 < body.Length)
            {
                len = (body[pos + 2] << 8) | body[pos + 3];
                hdrLen = 4;
            }
            else
            {
                break;
            }

            var contentEnd = pos + hdrLen + len;
            if (contentEnd > body.Length) break;
            var content = body.Slice(pos + hdrLen, len);
            var fullTlv = body[pos..contentEnd];

            switch (tag)
            {
                case 0x87:
                    macInput.Write(fullTlv);
                    encrypted = (content.Length > 1 ? content[1..] : content).ToArray();
                    break;
                case 0x85:
                    macInput.Write(fullTlv);
                    encrypted = content.ToArray();
                    break;
                case 0x99:
                    macInput.Write(fullTlv);
                    resultSw = content.ToArray();
                    break;
                case 0x8E:
                    respMac = content.ToArray();
                    break;
            }

            pos = contentEnd;
        }

        // Like the Swift reference, the MAC is only checked when the card sent one.
        // TODO(WIN-01): reject MAC-less SM responses once the Swift reference does (behavior change lands in Swift first).
        if (respMac.Length > 0)
        {
            var expected = Cmac.Compute(_sessMac, Iso9797.Pad(macInput.ToArray())).AsSpan(0, 8);
            if (!CryptographicOperations.FixedTimeEquals(expected, respMac))
                throw new CardException(CardErrorKind.SmOutOfSync, "Secure messaging MAC verification failed");
        }

        byte[] data = [];
        if (encrypted is not null)
        {
            if (encrypted.Length % AesPrimitives.BlockSize != 0)
                throw new CardException(CardErrorKind.UnexpectedResponse,
                    $"SM cryptogram length {encrypted.Length} is not a multiple of 16");
            var iv = AesPrimitives.EncryptEcb(_sessEnc, ssc1);
            data = AesPrimitives.DecryptCbc(_sessEnc, iv, encrypted);
            if (data.Length > 0) data = Iso9797.Unpad(data);
        }

        return new ApduResponse(data, resultSw.Length > 0 ? resultSw : swFromTail);
    }

    internal static byte[] BuildTlv(byte tag, ReadOnlySpan<byte> content)
    {
        byte[] header = content.Length switch
        {
            < 0x80 => [tag, (byte)content.Length],
            < 0x100 => [tag, 0x81, (byte)content.Length],
            _ => [tag, 0x82, (byte)(content.Length >> 8), (byte)content.Length],
        };
        var tlv = new byte[header.Length + content.Length];
        header.CopyTo(tlv, 0);
        content.CopyTo(tlv.AsSpan(header.Length));
        return tlv;
    }
}
