using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public sealed class VerifyDocumentTests
{
    [Fact]
    public void ForbiddenCompanionIsRejectedBeforeReadingAnyFile()
    {
        var verifier = new VerifierSpy();
        var workflow = new VerifyDocument(verifier, path => path.StartsWith("demo/", StringComparison.Ordinal));
        var result = workflow.Execute("demo/signature.xml", ["private/document.pdf"]);
        Assert.Equal(VerificationStatus.Rejected, result.Status);
        Assert.Equal(0, verifier.Calls);
    }

    [Fact]
    public void EmptyReportsRemainUnsignedRatherThanSuccessfulSignatures()
    {
        var verifier = new VerifierSpy();
        var result = new VerifyDocument(verifier, _ => true).Execute("unsigned.pdf");
        Assert.Equal(VerificationStatus.Completed, result.Status);
        Assert.Empty(result.Reports!);
        Assert.Null(result.Verdict);
        Assert.Equal(1, verifier.Calls);
    }

    [Fact]
    public void UnreadableInputPreservesErrorWithoutClaimingInvalidSignature()
    {
        var error = new IOException("unreadable");
        var result = new VerifyDocument(new VerifierSpy { Failure = error }, _ => true).Execute("missing.pdf");
        Assert.Equal(VerificationStatus.Unreadable, result.Status);
        Assert.Same(error, result.Error);
        Assert.Null(result.Reports);
    }

    private sealed class VerifierSpy : IDocumentVerifier
    {
        public int Calls { get; private set; }
        public Exception? Failure { get; init; }
        public IReadOnlyList<VerificationReport> Verify(string file, IReadOnlyList<string>? detachedDocs = null)
        {
            Calls++;
            if (Failure is { } error) throw error;
            return [];
        }
    }
}
