using MoldSign.Core;

namespace MoldSign.Desktop;

/// <summary>Offline verification policy independent of WinUI, localization, history and dispatching.</summary>
public sealed class VerifyDocument(IDocumentVerifier verifier, Func<string, bool> allowsFile)
{
    public VerificationResult Execute(string path, IReadOnlyList<string>? companions = null)
    {
        if (!allowsFile(path) || companions?.Any(file => !allowsFile(file)) == true)
            return new(VerificationStatus.Rejected);
        try
        {
            var reports = verifier.Verify(path, companions);
            return new(VerificationStatus.Completed, reports, Validator.OverallVerdict(reports));
        }
        catch (NotImplementedException error) { return new(VerificationStatus.Unsupported, Error: error); }
        catch (IOException error) { return new(VerificationStatus.Unreadable, Error: error); }
        catch (Exception error) { return new(VerificationStatus.Failed, Error: error); }
    }
}
