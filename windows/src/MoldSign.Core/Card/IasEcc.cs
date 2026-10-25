using System.Security.Cryptography;

namespace MoldSign.Core;

/// <summary>
/// IAS/ECC device-authentication crypto of the CosmoX ID-A (the pure functions behind
/// <see cref="CosmoXCard.Authenticate"/>), exposed separately so <c>spec/vectors/card-crypto.json</c>
/// can check each step byte-for-byte.
/// </summary>
public static class IasEcc
{
    /// <summary>Class master key (from the vendor's extracted Lua; public in every install).</summary>
    public static ReadOnlySpan<byte> MkClass =>
    [
        0xC1, 0x76, 0x5F, 0xCA, 0x5C, 0x11, 0xB6, 0xE9, 0xF8, 0x27, 0xEB, 0x12, 0x30, 0xFA, 0x74, 0xC3,
        0x14, 0x06, 0x19, 0x97, 0x6C, 0xE9, 0x2B, 0x66, 0x19, 0x98, 0x01, 0xCF, 0xDB, 0x12, 0x5F, 0x1E,
    ];

    /// <summary>Host random (static in the vendor middleware).</summary>
    public static ReadOnlySpan<byte> RndIfd =>
    [
        0x19, 0x9F, 0x03, 0x88, 0xC3, 0xAC, 0xEC, 0x2D, 0x84, 0xC6, 0xCE, 0x4C, 0xE7, 0x85, 0xCB, 0x7B,
    ];

    /// <summary>Host serial number.</summary>
    public static ReadOnlySpan<byte> SnIfd => [0x4A, 0x95, 0xFE, 0xD1, 0xDB, 0x60, 0x6A, 0x62];

    /// <summary>Host key-agreement contribution.</summary>
    public static ReadOnlySpan<byte> KIfd =>
    [
        0x44, 0x59, 0x69, 0xC4, 0x02, 0x0C, 0xED, 0xD4, 0xA8, 0xC4, 0xBF, 0xCE, 0x4B, 0x98, 0x20, 0xD2,
        0xBE, 0x8C, 0xDD, 0x97, 0x2F, 0x98, 0x3B, 0x81, 0x30, 0x38, 0xA5, 0x12, 0x90, 0x5B, 0xBF, 0x08,
    ];

    /// <summary><c>Kenc = SHA256(seed || serial || MK || 00000002)</c>, <c>Kmac = … || 00000003</c>.</summary>
    public static (byte[] Kenc, byte[] Kmac) DeriveAdminKeys(ReadOnlySpan<byte> seed, ReadOnlySpan<byte> serial)
    {
        byte[] baseBytes = [.. seed, .. serial, .. MkClass];
        var kenc = SHA256.HashData([.. baseBytes, 0x00, 0x00, 0x00, 0x02]);
        var kmac = SHA256.HashData([.. baseBytes, 0x00, 0x00, 0x00, 0x03]);
        return (kenc, kmac);
    }

    /// <summary>
    /// EXTERNAL AUTHENTICATE data (96 bytes): <c>ct || CMAC(kmac, ct)</c> with
    /// <c>ct = AES-CBC(kenc, IV=0, rnd_ifd || sn_ifd || rnd_icc || sn_icc || k_ifd)</c>.
    /// </summary>
    public static byte[] BuildExternalAuthenticateData(ReadOnlySpan<byte> kenc, ReadOnlySpan<byte> kmac,
                                                       ReadOnlySpan<byte> rndIcc, ReadOnlySpan<byte> snIcc)
    {
        byte[] plain = [.. RndIfd, .. SnIfd, .. rndIcc, .. snIcc, .. KIfd];
        var ct = AesPrimitives.EncryptCbc(kenc, new byte[16], plain);
        var mac = Cmac.Compute(kmac, ct);
        return [.. ct, .. mac];
    }

    /// <summary>
    /// Checks the 96-byte EXTERNAL AUTHENTICATE response (<c>ct(80) || cmac(16)</c>) and returns the
    /// 80-byte plaintext. Throws <see cref="CardErrorKind.SmOutOfSync"/> on MAC mismatch.
    /// </summary>
    public static byte[] OpenExternalAuthenticateResponse(ReadOnlySpan<byte> kenc, ReadOnlySpan<byte> kmac,
                                                          ReadOnlySpan<byte> response)
    {
        if (response.Length != 96)
            throw new CardException(CardErrorKind.UnexpectedResponse,
                $"Bad EXTERNAL AUTHENTICATE response length: {response.Length}");
        var ct = response[..80];
        var mac = response.Slice(80, 16);
        if (!CryptographicOperations.FixedTimeEquals(Cmac.Compute(kmac, ct), mac))
            throw new CardException(CardErrorKind.SmOutOfSync, "EXTERNAL AUTHENTICATE response MAC verification failed");
        return AesPrimitives.DecryptCbc(kenc, new byte[16], ct);
    }

    /// <summary><c>secret = K_ICC XOR K_IFD; sessENC = SHA256(secret || 00000001); sessMAC = SHA256(secret || 00000002)</c>.</summary>
    public static (byte[] SessEnc, byte[] SessMac) DeriveSessionKeys(ReadOnlySpan<byte> kIcc)
    {
        var secret = AesPrimitives.Xor(kIcc, KIfd);
        var sessEnc = SHA256.HashData([.. secret, 0x00, 0x00, 0x00, 0x01]);
        var sessMac = SHA256.HashData([.. secret, 0x00, 0x00, 0x00, 0x02]);
        CryptographicOperations.ZeroMemory(secret);
        return (sessEnc, sessMac);
    }

    /// <summary><c>SSC = plain[8..&lt;16] || rnd_ifd[8..&lt;16]</c>.</summary>
    public static byte[] InitialSsc(ReadOnlySpan<byte> responsePlain) => [.. responsePlain[8..16], .. RndIfd[8..16]];

    /// <summary>Session from the decrypted EXTERNAL AUTHENTICATE response (<c>K_ICC = plain[48..&lt;80]</c>).</summary>
    public static SecureChannel OpenSecureChannel(ReadOnlySpan<byte> responsePlain)
    {
        if (responsePlain.Length < 80)
            throw new CardException(CardErrorKind.UnexpectedResponse, "EXTERNAL AUTHENTICATE plaintext too short");
        var (sessEnc, sessMac) = DeriveSessionKeys(responsePlain[48..80]);
        try
        {
            return new SecureChannel(sessEnc, sessMac, InitialSsc(responsePlain));
        }
        finally
        {
            CryptographicOperations.ZeroMemory(sessEnc);
            CryptographicOperations.ZeroMemory(sessMac);
        }
    }
}
