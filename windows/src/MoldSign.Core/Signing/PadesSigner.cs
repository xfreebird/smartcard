namespace MoldSign.Core;

/// <summary>
/// PAdES-B-T signer: detached CMS (signingCertificateV2!) + iText-style incremental update, RFC 3161
/// token from MDQTSA (docs/02-pades-signing.md). Port target: <c>apple/Sources/MoldSignKit/Signing.swift</c>.
/// </summary>
public sealed class PadesSigner
{
    public PadesSigner(TrustServices trust) => Trust = trust ?? throw new ArgumentNullException(nameof(trust));

    /// <summary>TSA client for the signature timestamp (PAdES-T is what the portal requires).</summary>
    public TrustServices Trust { get; }

    /// <summary>
    /// Signs <paramref name="pdf"/> (or counter-signs it when it already carries signatures).
    /// <paramref name="signDigestInfo"/> receives the DigestInfo(SHA-256) of the signed attributes and
    /// returns the card's 512-byte RSA signature; it is where consent + VERIFY happen.
    /// Mirrors Swift <c>PAdESSigner.signPDF(_:certDER:tsaUnsignedAttr:signBlock:)</c>.
    /// </summary>
    public byte[] Sign(byte[] pdf, byte[] certificateDer, Func<byte[], byte[]> signDigestInfo) =>
        // TODO(WIN-01): port Signing.swift (incremental update, AcroForm reuse, CMS, TSA unsigned attr).
        throw new NotImplementedException("TODO(WIN-01): PAdES signing is not ported yet.");
}
