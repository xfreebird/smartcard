namespace MoldSign.Core;

/// <summary>XAdES level (docs/03-xades-signing.md).</summary>
public enum XadesFormat
{
    /// <summary>XAdES-BES.</summary>
    Bes,
    /// <summary>XAdES-T: + SignatureTimeStamp over the c14n SignatureValue.</summary>
    T,
    /// <summary>XAdES-C: + CompleteCertificateRefs / CompleteRevocationRefs (CRL + OCSP).</summary>
    C,
}

/// <summary>Where the signed data lives relative to the signature.</summary>
public enum XadesPackaging
{
    /// <summary><c>URI="file:/&lt;basename&gt;"</c> references (vendor quirk: ObjectReference uses the full path).</summary>
    Detached,
    /// <summary>Base64 data in <c>ds:Object</c>, C14N WithComments.</summary>
    Enveloping,
}

/// <summary>
/// Middleware-faithful XAdES builder. Port target: <c>apple/Sources/MoldSignKit/XAdES.swift</c>.
/// </summary>
public sealed class XadesSigner
{
    public XadesSigner(TrustServices trust) => Trust = trust ?? throw new ArgumentNullException(nameof(trust));

    /// <summary>TSA (-T) and CRL/OCSP (-C) client.</summary>
    public TrustServices Trust { get; }

    /// <summary>
    /// XAdES document for <paramref name="files"/>. Mirrors Swift
    /// <c>XAdESSigner.sign(files:format:type:certDER:chainDER:signBlock:tsaBlock:ocspDerBlock:)</c>.
    /// </summary>
    public byte[] Sign(IReadOnlyList<string> files, XadesFormat format, XadesPackaging packaging,
                       byte[] certificateDer, IReadOnlyList<byte[]> chainDer, Func<byte[], byte[]> signDigestInfo) =>
        // TODO(WIN-01): port XAdES.swift (IDs, inclusive c14n tricks, SigningCertificate DN quirks, -T/-C).
        throw new NotImplementedException("TODO(WIN-01): XAdES signing is not ported yet.");
}
