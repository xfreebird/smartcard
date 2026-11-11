using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Preview states never request a transport or a credential.</summary>
public sealed class DemoCardDataProvider(string? scenario) : ICardDataProvider
{
    public Task<CardDataResult> ReadAsync(string reader) => Task.FromResult(scenario switch
    {
        "reading" => new CardDataResult(),
        "blocked" => new CardDataResult(Problem: CardErrorKind.PinBlocked),
        "stuck" => new CardDataResult(Problem: CardErrorKind.CardStateStuck),
        _ => new CardDataResult(Certificate(reader), Busy: scenario == "signing"),
    });
    private static CertificateSummary Certificate(string reader) => new()
    {
        CommonName = reader.EndsWith('2') ? "ISTRATI ELENA" : "POPESCU ION",
        Surname = reader.EndsWith('2') ? "ISTRATI" : "POPESCU",
        GivenName = reader.EndsWith('2') ? "ELENA" : "ION",
        Subject = "CN=Fictional demonstration card", Issuer = "CN=Demo CA", IssuerName = "DEMO CA",
        NotBefore = new DateTimeOffset(2025, 1, 1, 0, 0, 0, TimeSpan.Zero),
        NotAfter = new DateTimeOffset(2030, 1, 1, 0, 0, 0, TimeSpan.Zero),
        SerialNumber = reader.EndsWith('2') ? "02" : "01",
        Sha1 = reader.EndsWith('2') ? new string('2', 40) : new string('1', 40), Der = [],
    };
}
