using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Hardware discovery boundary; UI scenarios can publish snapshots without opening PC/SC.</summary>
public interface IReaderSource : IDisposable
{
    event EventHandler<IReadOnlyList<ReaderSlot>>? Changed;
    void Start();
    void Refresh();
}

/// <summary>Deterministic development scenarios. Never opens a reader or uses the real PIN vault.</summary>
public sealed class DemoReaderSource(string scenario) : IReaderSource
{
    public event EventHandler<IReadOnlyList<ReaderSlot>>? Changed;
    public void Start() => Refresh();
    public void Refresh()
    {
        IReadOnlyList<ReaderSlot> slots = scenario switch
        {
            "none" => [],
            "empty" => [new("Demo reader", SlotState.Empty, 1)],
            "mute" => [new("Demo reader", SlotState.Mute, 1)],
            "2" or "multiple" or "multiple-second" => [new("Demo reader 1", SlotState.Card, 1), new("Demo reader 2", SlotState.Card, 1)],
            "3" => [new("Demo reader 1", SlotState.Card, 1), new("Demo reader 2", SlotState.Card, 1), new("Demo reader 3", SlotState.Card, 1)],
            _ => [new("Demo reader 1", SlotState.Card, 1)],
        };
        Changed?.Invoke(this, slots);
    }
    public void Dispose() { }
    public static CertificateSummary Certificate(string reader) => new()
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

/// <summary>User demo mode works in every build; environment fixtures remain Debug-only.</summary>
internal static class DemoMode
{
    private static bool _enabled;
    public static void Configure(bool enabled) => _enabled = enabled;
    public static string? PreviewScenario
    {
        get
        {
#if DEBUG
            return Environment.GetEnvironmentVariable("MSIGN_DEMO_CARDS");
#else
            return null;
#endif
        }
    }
    public static string? Scenario => PreviewScenario ?? (_enabled ? "2" : null);
}
