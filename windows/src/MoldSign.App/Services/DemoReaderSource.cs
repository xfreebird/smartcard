using MoldSign.Core;

namespace MoldSign.App.Services;

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
}
