using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Hardware discovery boundary; UI scenarios can publish snapshots without opening PC/SC.</summary>
public interface IReaderSource : IDisposable
{
    event EventHandler<IReadOnlyList<ReaderSlot>>? Changed;
    void Start();
    void Refresh();
}
