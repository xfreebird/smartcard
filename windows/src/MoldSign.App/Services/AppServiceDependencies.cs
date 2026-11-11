using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.App.Services;

/// <summary>Composition-time substitutions for hardware, documents, credentials, consent and browser lifecycle.</summary>
public sealed record AppServiceDependencies
{
    public string? DemoScenario { get; init; }
    public ICardDataProvider? CardData { get; init; }
    public IReaderSource? Readers { get; init; }
    public Func<string?, ICardTransport>? Transport { get; init; }
    public IDocumentSigner? Documents { get; init; }
    public IDocumentVerifier? Verifier { get; init; }
    public Func<string, Task<CertificateSummary>>? Certificates { get; init; }
    public IPinVault? Pins { get; init; }
    public ConsentProvider? Authorize { get; init; }
    public IBrowserConnectionController? BrowserConnection { get; init; }
}
