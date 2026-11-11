using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.Core.Tests;

public sealed class CardDataProviderTests
{
    [Fact]
    public async Task LiveProviderUsesRequestedReaderAndPreservesFailure()
    {
        var failure = new InvalidOperationException("reader unavailable");
        string? requested = null;
        var provider = new LiveCardDataProvider(reader =>
        {
            requested = reader;
            return Task.FromException<CertificateSummary>(failure);
        });
        var thrown = await Assert.ThrowsAsync<InvalidOperationException>(() => provider.ReadAsync("selected-reader"));
        Assert.Same(failure, thrown);
        Assert.Equal("selected-reader", requested);
    }

    [Fact]
    public async Task DemoReadingRemainsPendingWithoutInventingACertificate()
    {
        var result = await new DemoCardDataProvider("reading").ReadAsync("reader");
        Assert.Null(result.Certificate);
        Assert.Null(result.Problem);
        Assert.False(result.Busy);
    }

    [Theory]
    [InlineData("blocked", CardErrorKind.PinBlocked)]
    [InlineData("stuck", CardErrorKind.CardStateStuck)]
    public async Task DemoFailuresKeepTheirDistinctRecoveryStates(string scenario, CardErrorKind kind)
    {
        var result = await new DemoCardDataProvider(scenario).ReadAsync("reader");
        Assert.Equal(kind, result.Problem);
        Assert.Null(result.Certificate);
    }
}
