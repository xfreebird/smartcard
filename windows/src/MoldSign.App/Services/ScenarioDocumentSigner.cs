#if DEBUG
using MoldSign.Core;

namespace MoldSign.App.Services;

/// Scripted failures wrap the isolated demo signer; successful outputs remain visibly unsigned samples.
internal sealed class ScenarioDocumentSigner(IDocumentSigner demo, string scenario) : IDocumentSigner
{
    public static IDocumentSigner Wrap(IDocumentSigner demo)
    {
        var scenario = Environment.GetEnvironmentVariable("MSIGN_UI_TEST_SCENARIO");
        if (scenario is null) return demo;
        if (Environment.GetEnvironmentVariable("MSIGN_TEST_PREFERENCES") is null || DemoMode.PreviewScenario is null)
            throw new InvalidOperationException("UI scenarios require isolated Debug demo preferences.");
        if (scenario is not ("sign-success" or "sign-mixed" or "sign-fatal"))
            throw new InvalidOperationException("Unknown UI signing scenario.");
        return new ScenarioDocumentSigner(demo, scenario);
    }

    public SignResult Sign(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
        string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null)
    {
        if (Path.GetExtension(input).Equals(".pdf", StringComparison.OrdinalIgnoreCase))
        {
            if (scenario == "sign-mixed") throw new CardException(CardErrorKind.Format, "Mock document failure");
            if (scenario == "sign-fatal") throw new CardException(CardErrorKind.PinBlocked, "Mock blocked card");
        }
        return demo.Sign(input, format, packaging, consent, requester, reader, expectedCertificateSha1);
    }
}
#endif
