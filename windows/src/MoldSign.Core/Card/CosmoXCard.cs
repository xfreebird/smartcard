using System.Security.Cryptography;

namespace MoldSign.Core;

/// <summary>
/// IDEMIA CosmoX ID-A (IAS/ECC) driver over any <see cref="ICardTransport"/>.
/// Line-by-line port of <c>Card.swift</c>; every APDU byte matches the reference (docs/09 §3.2):
/// <code>
/// Authenticate():      SELECT IAS AID → SELECT MF → read D003 (serial) → read D004 (seed)
///                      → Kenc/Kmac → MSE SET 0022C1A4… → GET CHALLENGE → EXTERNAL AUTH (96 B)
///                      → verify CMAC, decrypt → K_ICC → sessENC/sessMAC, SSC
/// SelectMF()           SM
/// SelectGenericAdf()   SM, P2=04, Le=00
/// ReadCertificate()    SELECT MF → ADF → EF 0001, READ BINARY 128-byte chunks, full X.509 (outer SEQ)
/// VerifyPin(pin)       SM VERIFY ref 03; 63Cx → WrongPin(x); 6983 → PinBlocked
/// Sign(digestInfo)     SM MSE SET 41A4 800102840181 → INTERNAL AUTHENTICATE → 512-byte RSA-4096
/// </code>
/// Never logs PINs or key material (SEC-04): the optional trace only gets step names and status words.
/// </summary>
public sealed class CosmoXCard
{
    /// <summary>IAS application AID.</summary>
    public static ReadOnlySpan<byte> IasAid =>
        [0xA0, 0x00, 0x00, 0x00, 0x77, 0x03, 0x0C, 0x60, 0x00, 0x00, 0x00, 0xFE, 0x00, 0x00, 0x05, 0x00];

    /// <summary>Generic (signature) ADF name, 14 bytes; selected with P2=04.</summary>
    public static ReadOnlySpan<byte> GenericAdf =>
        [0xE8, 0x28, 0xBD, 0x08, 0x0F, 0xD2, 0x50, 0x47, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63];

    /// <summary>MSE SET (plain) arming the device-authentication key: <c>0022C1A4098004FF40108C830104</c>.</summary>
    public static ReadOnlySpan<byte> MseSetSmApdu =>
        [0x00, 0x22, 0xC1, 0xA4, 0x09, 0x80, 0x04, 0xFF, 0x40, 0x10, 0x8C, 0x83, 0x01, 0x04];

    /// <summary>MSE SET DST data: algorithm 02 (RSA PKCS#1 v1.5 over a DigestInfo), key 81.</summary>
    public static ReadOnlySpan<byte> MseSignData => [0x80, 0x01, 0x02, 0x84, 0x01, 0x81];

    /// <summary>VERIFY reference of the QSCD signing PIN.</summary>
    public const byte PinReference = 0x03;

    /// <summary>EF holding the signing certificate under the Generic ADF.</summary>
    public const ushort CertificateFileId = 0x0001;

    /// <summary>READ BINARY chunk size (proven on the card).</summary>
    public const int ReadChunkSize = 128;

    private readonly ICardTransport _transport;
    private readonly Action<string>? _trace;

    public CosmoXCard(ICardTransport transport, Action<string>? trace = null)
    {
        _transport = transport ?? throw new ArgumentNullException(nameof(transport));
        _trace = trace;
    }

    public string ReaderName => _transport.ReaderName;

    /// <summary>ASCII serial read from EF D003 (16 bytes).</summary>
    public byte[] SerialNumber { get; private set; } = [];

    /// <summary>ASCII seed read from EF D004 (16 bytes).</summary>
    public byte[] RandomSeed { get; private set; } = [];

    /// <summary>True after a successful <see cref="Authenticate"/> until an SM failure drops the session.</summary>
    public bool HasSecureChannel => Channel is not null;

    /// <summary>The live SM session. Internal so tests can start from the vector state.</summary>
    internal SecureChannel? Channel { get; set; }

    // MARK: - Raw APDU

    /// <summary>One raw exchange, split into data and SW.</summary>
    public ApduResponse Transmit(byte[] apdu) => ApduResponse.FromRaw(_transport.Transmit(apdu));

    /// <summary>Transmit, then GET RESPONSE (<c>00 C0 00 00 xx</c>) while the card answers <c>61xx</c>.</summary>
    public ApduResponse TransmitFull(byte[] apdu)
    {
        using var result = new MemoryStream();
        var response = Transmit(apdu);
        while (response.Sw.Length == 2 && response.Sw[0] == 0x61)
        {
            result.Write(response.Data);
            response = Transmit([0x00, 0xC0, 0x00, 0x00, response.Sw[1]]);
        }
        result.Write(response.Data);
        return new ApduResponse(result.ToArray(), response.Sw);
    }

    /// <summary>Throws the mapped <see cref="CardException"/> unless SW = 9000.</summary>
    public static void CheckSw(ApduResponse response, string? context = null)
    {
        if (response.Sw.Length != 2)
            throw new CardException(CardErrorKind.CardNotResponding, $"{context}: missing status word");
        if (response.IsSuccess) return;
        throw CardException.FromStatusWord(response.StatusWord, context);
    }

    // MARK: - SM-wrapped transmit

    /// <summary>
    /// Wraps, transmits (with the 61xx loop) and unwraps. A SW-only answer still advances the SSC,
    /// because the card counts its response even when it carries no SM objects.
    /// Any SM failure drops the session (the SSC can no longer be trusted).
    /// </summary>
    public ApduResponse SmTransmit(byte[] apdu)
    {
        var channel = Channel ?? throw new CardException(CardErrorKind.SmOutOfSync,
            "No secure channel: call Authenticate() first");
        try
        {
            var wrapped = channel.Wrap(apdu);
            var raw = TransmitFull(wrapped);
            ApduResponse response;
            if (raw.Data.Length == 0)
            {
                channel.IncrementSsc();
                response = new ApduResponse([], raw.Sw);
            }
            else
            {
                response = channel.Unwrap([.. raw.Data, .. raw.Sw]);
            }
            if (response.StatusWord == 0x6988) Channel = null;
            return response;
        }
        catch (CardException e) when (e.Kind is CardErrorKind.SmOutOfSync or CardErrorKind.CardNotResponding)
        {
            Channel = null;
            throw;
        }
    }

    // MARK: - Mutual authentication

    /// <summary>IAS/ECC device authentication; on success the SM session is live.</summary>
    public void Authenticate()
    {
        Channel = null;

        // 1. SELECT IAS AID
        CheckSw(TransmitFull([0x00, 0xA4, 0x04, 0x00, (byte)IasAid.Length, .. IasAid, 0x00]), "SELECT IAS AID");

        // 2. SELECT MF. The Swift reference re-checks step 1's SW here, i.e. never checks this one;
        //    keep it unchecked so card behavior stays identical.
        TransmitFull([0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00]);

        // 3. Serial (EF D003): skip the 2-byte tag/length, keep 16 ASCII bytes.
        TransmitFull([0x00, 0xA4, 0x02, 0x04, 0x02, 0xD0, 0x03, 0x00]);
        var serial = TransmitFull([0x00, 0xB0, 0x00, 0x00, 0x00]).Data;
        SerialNumber = serial.Skip(2).Take(16).ToArray();

        // 4. Seed (EF D004): first 16 bytes.
        TransmitFull([0x00, 0xA4, 0x02, 0x04, 0x02, 0xD0, 0x04, 0x00]);
        var seed = TransmitFull([0x00, 0xB0, 0x00, 0x00, 0x10]).Data;
        RandomSeed = seed.Take(16).ToArray();
        _trace?.Invoke("Card serial/seed read");

        // 5. Admin keys
        var (kenc, kmac) = IasEcc.DeriveAdminKeys(RandomSeed, SerialNumber);
        try
        {
            // 6. MSE SET for SM
            CheckSw(TransmitFull(MseSetSmApdu.ToArray()), "MSE SET (SM)");

            // 7. GET CHALLENGE
            var challenge = TransmitFull([0x00, 0x84, 0x00, 0x00, 0x10]).Data;
            var rndIcc = challenge.Take(16).ToArray();

            // 8. EXTERNAL AUTHENTICATE
            var snIcc = SerialNumber.Length > 8 ? SerialNumber[^8..] : SerialNumber;
            var payload = IasEcc.BuildExternalAuthenticateData(kenc, kmac, rndIcc, snIcc);
            var ea = TransmitFull([0x00, 0x82, 0x00, 0x00, 0x60, .. payload]);
            CheckSw(ea, "EXTERNAL AUTHENTICATE");

            // 9-10. Check the card's cryptogram, derive the session.
            var plain = IasEcc.OpenExternalAuthenticateResponse(kenc, kmac, ea.Data);
            try
            {
                Channel = IasEcc.OpenSecureChannel(plain);
            }
            finally
            {
                CryptographicOperations.ZeroMemory(plain);
            }
            _trace?.Invoke("Secure channel established");
        }
        finally
        {
            CryptographicOperations.ZeroMemory(kenc);
            CryptographicOperations.ZeroMemory(kmac);
        }
    }

    // MARK: - SM operations

    public void SelectMF() =>
        CheckSw(SmTransmit([0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00]), "SELECT MF");

    public void SelectGenericAdf() =>
        CheckSw(SmTransmit([0x00, 0xA4, 0x04, 0x04, (byte)GenericAdf.Length, .. GenericAdf, 0x00]), "SELECT Generic ADF");

    /// <summary>READ BINARY in 128-byte chunks (P1 = offset high 7 bits, P2 = offset low byte).</summary>
    public byte[] ReadBinary(int offset, int length)
    {
        using var result = new MemoryStream();
        var remaining = length;
        var off = offset;
        while (remaining > 0)
        {
            var chunk = Math.Min(remaining, ReadChunkSize);
            var response = SmTransmit([0x00, 0xB0, (byte)((off >> 8) & 0x7F), (byte)(off & 0xFF), (byte)chunk]);
            CheckSw(response, "READ BINARY");
            // SecureChannel.Unwrap already removed the ISO 9797 padding. The Swift reference unpads a
            // SECOND time here, which would truncate any chunk whose last real byte is 00 or 80 (common
            // in DER). It never triggered on the reference card (no 128-byte boundary of its 1799-byte
            // certificate ends in 00/80), so the APDU sequence is identical; this port unpads once.
            result.Write(response.Data);
            off += chunk;
            remaining -= chunk;
            if (response.Data.Length == 0) break;
        }
        return result.ToArray();
    }

    /// <summary>SM VERIFY with PIN reference 03. The PIN bytes are sent raw; SM padding aligns them.</summary>
    public void VerifyPin(string pin)
    {
        ArgumentNullException.ThrowIfNull(pin);
        if (pin.Length is < 4 or > 8 || pin.Any(c => c > 0x7F))
            throw new CardException(CardErrorKind.InvalidPinFormat, "PIN must be 4-8 ASCII characters");

        var apdu = new byte[5 + pin.Length];
        apdu[0] = 0x00;
        apdu[1] = 0x20;
        apdu[2] = 0x00;
        apdu[3] = PinReference;
        apdu[4] = (byte)pin.Length;
        for (var i = 0; i < pin.Length; i++) apdu[5 + i] = (byte)pin[i];
        try
        {
            var response = SmTransmit(apdu);
            if (response.Sw.Length != 2)
                throw new CardException(CardErrorKind.UnexpectedResponse, "Bad VERIFY response");
            CheckSw(response, "VERIFY"); // 63Cx → WrongPin(x), 6983 → PinBlocked
        }
        finally
        {
            CryptographicOperations.ZeroMemory(apdu);
        }
    }

    /// <summary>MSE SET 41A4 800102840181, then INTERNAL AUTHENTICATE over the DigestInfo.</summary>
    public byte[] Sign(byte[] digestInfo)
    {
        ArgumentNullException.ThrowIfNull(digestInfo);
        if (digestInfo.Length is 0 or > 255)
            throw new ArgumentException("DigestInfo must be 1-255 bytes.", nameof(digestInfo));

        CheckSw(SmTransmit([0x00, 0x22, 0x41, 0xA4, (byte)MseSignData.Length, .. MseSignData]), "MSE SET (sign)");
        var signature = SmTransmit([0x00, 0x88, 0x00, 0x00, (byte)digestInfo.Length, .. digestInfo]);
        CheckSw(signature, "INTERNAL AUTHENTICATE");
        return signature.Data;
    }

    /// <summary>
    /// Reads EF 0001 and returns the full X.509 certificate (the OUTER SEQUENCE: TBS + algorithm +
    /// signature), not just the TBS (the old 1263-byte bug).
    /// </summary>
    public byte[] ReadCertificate()
    {
        SelectMF();
        SelectGenericAdf();
        // SELECT EF 0001, unchecked like the reference.
        SmTransmit([0x00, 0xA4, 0x02, 0x04, 0x02, (byte)(CertificateFileId >> 8), (byte)CertificateFileId, 0x00]);

        var header = ReadBinary(0, 16);
        if (header.Length < 4 || header[0] != 0x30 || header[1] != 0x82)
            throw new CardException(CardErrorKind.UnexpectedResponse, "Certificate file doesn't start with SEQUENCE");
        var totalLength = 4 + ((header[2] << 8) | header[3]);
        var body = ReadBinary(4, totalLength - 4);

        byte[] file = [.. header.AsSpan(0, 4), .. body];
        if (file.Length <= 8 || file[4] != 0x30 || file[5] != 0x82)
            throw new CardException(CardErrorKind.UnexpectedResponse, "No certificate in EF 0001");
        if (file.Length < totalLength)
            throw new CardException(CardErrorKind.UnexpectedResponse,
                $"Certificate truncated: {file.Length} of {totalLength} bytes");
        _trace?.Invoke($"Certificate read: {totalLength} bytes");
        return file[..totalLength];
    }

    /// <summary>The proven signing sequence after the certificate was read: re-select the ADF, VERIFY, sign.</summary>
    public byte[] VerifyPinAndSign(string pin, byte[] digestInfo)
    {
        SelectGenericAdf();
        VerifyPin(pin);
        return Sign(digestInfo);
    }

    /// <summary>
    /// Identity guard (docs/09 §3.1b): throws <see cref="CardErrorKind.CardChanged"/> unless the certificate read
    /// from the card has the SHA-1 that the PIN / consent / UI selection was given for. A null or empty expectation
    /// means "any card" (CLI, PIN-less greeting).
    /// </summary>
    public static void EnsureExpectedCard(byte[] certificateDer, string? expectedCertificateSha1)
    {
        ArgumentNullException.ThrowIfNull(certificateDer);
        if (string.IsNullOrEmpty(expectedCertificateSha1)) return;
        var actual = Hex.Encode(SHA1.HashData(certificateDer));
        if (!string.Equals(actual, expectedCertificateSha1, StringComparison.OrdinalIgnoreCase))
            throw new CardException(CardErrorKind.CardChanged,
                "The card in the reader changed; check the holder and sign again");
    }

    /// <summary>
    /// SELECT MF → ADF → read EF 0001 → identity check → SELECT ADF → VERIFY, the order every port uses
    /// (docs/09 §3.1b). The certificate is read before the PIN goes out, so a swapped card never receives
    /// another card's PIN. Returns the certificate (full X.509 DER).
    /// </summary>
    public byte[] PrepareForSigning(string pin, string? expectedCertificateSha1)
    {
        var certificate = ReadCertificate();
        EnsureExpectedCard(certificate, expectedCertificateSha1);
        SelectGenericAdf();
        VerifyPin(pin);
        return certificate;
    }
}
