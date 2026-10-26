namespace MoldSign.Core.Tests;

public sealed class VerificationSummaryTests
{
    private static readonly VerificationReport s_valid = new()
    {
        Kind = "PAdES", Name = "Signature1", Signer = "Test",
        ContentIntact = true, SignatureValid = true, ChainTrusted = true,
    };

    [Fact]
    public void Unknown_chain_is_not_reported_as_an_invalid_signature()
    {
        var unknown = s_valid with { ChainTrusted = false };
        Assert.Equal(Verdict.Indeterminate, Validator.OverallVerdict([s_valid, unknown]));
        Assert.Equal(Verdict.Valid, Validator.OverallVerdict([s_valid, s_valid]));
        Assert.Null(Validator.OverallVerdict([]));
    }

    [Fact]
    public void Any_invalid_signature_or_timestamp_overrides_other_valid_or_unknown_signatures()
    {
        var unknown = s_valid with { ChainTrusted = false };
        var tampered = s_valid with { ContentIntact = false };
        var badTimestamp = s_valid with { TimestampImprintValid = false };
        Assert.Equal(Verdict.Invalid, Validator.OverallVerdict([s_valid, unknown, tampered]));
        Assert.Equal(Verdict.Invalid, Validator.OverallVerdict([tampered, unknown, s_valid]));
        Assert.Equal(Verdict.Invalid, Validator.OverallVerdict([s_valid, badTimestamp]));
    }
}
