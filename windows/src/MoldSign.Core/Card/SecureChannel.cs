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

        var body = apdu[4..];
        ReadOnlySpan<byte> cmdData = [], le = [];
        var extended = body.Length > 1 && body[0] == 0;
        if (body.Length == 1) le = body;
        else if (extended)
        {
            if (body.Length < 3) throw new ArgumentException("Truncated extended APDU.");
            if (body.Length == 3) le = body[1..];
            else {
                var count = body[1] * 256 + body[2];
                if (count == 0 || (body.Length != count+3 && body.Length != count+5)) throw new ArgumentException("Invalid extended APDU length.");
                cmdData = body.Slice(3,count);
                if (body.Length == count+5) le = body[^2..];
            }
        }
        else if (body.Length > 1)
        {
            var count = body[0];
            if (body.Length != count+1 && body.Length != count+2) throw new ArgumentException("Invalid APDU length.");
            cmdData = body.Slice(1,count);
            if (body.Length == count+2) le = body[^1..];
        }

        if (cmdData.Length > 65488) throw new ArgumentException("Secure APDU payload too large.");
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

        if (!le.IsEmpty)
        {
            var tlv = BuildTlv(0x97, le);
            macInput.Write(tlv);
            dataField.Write(tlv);
        }

        var mac = Cmac.Compute(_sessMac, Iso9797.Pad(macInput.ToArray()));
        dataField.Write(BuildTlv(0x8E, mac.AsSpan(0, 8)));

        var fields = dataField.ToArray();
        if (fields.Length > 65535) throw new ArgumentException("SM APDU too long.");
        byte[] result;
        if (extended || fields.Length > 255)
            result = [cla,ins,p1,p2,0,(byte)(fields.Length >> 8),(byte)fields.Length,..fields,0,0];
        else result = [cla,ins,p1,p2,(byte)fields.Length,..fields,0];
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
        static CardException Invalid() => new(CardErrorKind.SmOutOfSync,"Malformed or unauthenticated secure response.");
        if (response.Length < 2) throw Invalid();
        if (response.Length == 2)
        {
            if (response[0] == 0x90 && response[1] == 0) throw Invalid();
            return new ApduResponse([],response.ToArray()); // SmTransmit advances SSC for bare errors.
        }
        var outer = response[^2..];
        var body = response[..^2];
        var ssc1 = IncrementSsc();
        byte[]? encrypted = null, status = null, mac = null;
        var pos = 0;
        var macStart = 0;
        while (pos < body.Length)
        {
            var start = pos;
            if (pos + 2 > body.Length || mac != null) throw Invalid();
            var tag = body[pos++];
            int length = body[pos++];
            if (length >= 128)
            {
                var count = length & 127;
                if (count is < 1 or > 2 || pos + count > body.Length || body[pos] == 0) throw Invalid();
                length = 0;
                for (var i = 0; i < count; i++) length = length * 256 + body[pos++];
                if (length < 128 || (count == 2 && length < 256)) throw Invalid();
            }
            if (length > body.Length - pos) throw Invalid();
            var value = body.Slice(pos,length);
            pos += length;
            switch (tag)
            {
                case 0x87:
                case 0x85:
                    if (encrypted != null || status != null) throw Invalid();
                    if (tag == 0x87)
                    {
                        if (value.Length < 2 || value[0] != 1) throw Invalid();
                        value = value[1..];
                    }
                    if (value.IsEmpty || value.Length % AesPrimitives.BlockSize != 0) throw Invalid();
                    encrypted = value.ToArray();
                    break;
                case 0x99:
                    if (status != null || length != 2) throw Invalid();
                    status = value.ToArray();
                    break;
                case 0x8e:
                    if (status == null || length != 8 || pos != body.Length) throw Invalid();
                    mac = value.ToArray(); macStart = start;
                    break;
                default: throw Invalid();
            }
        }
        if (status == null || mac == null) throw Invalid();
        using var macInput = new MemoryStream();
        macInput.Write(ssc1); macInput.Write(body[..macStart]);
        var expected = Cmac.Compute(_sessMac,Iso9797.Pad(macInput.ToArray())).AsSpan(0,8);
        if (!CryptographicOperations.FixedTimeEquals(expected,mac)) throw Invalid();
        // Some cards mirror EOF/error status outside the authenticated body.
        if (!(outer[0] == 0x90 && outer[1] == 0) && !outer.SequenceEqual(status)) throw Invalid();
        byte[] plain = [];
        if (encrypted != null)
        {
            var padded = AesPrimitives.DecryptCbc(_sessEnc,AesPrimitives.EncryptEcb(_sessEnc,ssc1),encrypted);
            try
            {
                var end = padded.Length;
                while (end > 0 && padded[end-1] == 0) end--;
                if (end == 0 || padded[end-1] != 0x80) throw Invalid();
                plain = padded.AsSpan(0,end-1).ToArray();
            }
            finally { CryptographicOperations.ZeroMemory(padded); }
        }
        return new ApduResponse(plain,status);
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
