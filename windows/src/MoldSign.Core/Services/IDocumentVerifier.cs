namespace MoldSign.Core;

/// <summary>Offline verification boundary, separate from signing and its consent/PIN requirements.</summary>
public interface IDocumentVerifier
{
    IReadOnlyList<VerificationReport> Verify(string file, IReadOnlyList<string>? detachedDocs = null);
}
