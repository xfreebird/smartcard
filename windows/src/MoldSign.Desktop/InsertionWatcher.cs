using MoldSign.Core;

namespace MoldSign.Desktop;

public interface IReaderSnapshotSource
{
    IReadOnlyList<ReaderStatus> Read();
}

public interface IApplicationActivator
{
    Task OpenAsync(CancellationToken cancellationToken);
}

/// <summary>Reader/card insertion edges, including swaps between polls; startup is a baseline, not an insertion.</summary>
public sealed class InsertionActivationPolicy
{
    private Dictionary<string, ReaderStatus>? _previous;

    public bool Update(IReadOnlyList<ReaderStatus> readers, DesktopPreferences preferences)
    {
        var current = readers.ToDictionary(reader => reader.Name, StringComparer.Ordinal);
        var open = false;
        if (_previous is not null)
            foreach (var reader in readers)
            {
                var existed = _previous.TryGetValue(reader.Name, out var previous);
                var readerAdded = !existed;
                var cardAdded = reader.CardPresent &&
                    (!existed || !previous!.CardPresent || previous.EventCount != reader.EventCount);
                open |= preferences.OpenOnReaderInsertion && readerAdded || preferences.OpenOnCardInsertion && cardAdded;
            }
        _previous = current;
        return open;
    }
}

/// <summary>Independent helper orchestration; hardware discovery, launch and preference storage are injectable.</summary>
public sealed class InsertionWatcher(IReaderSnapshotSource readers, IApplicationActivator application,
                                     Func<DesktopPreferences> preferences)
{
    private readonly InsertionActivationPolicy _policy = new();

    public async Task<bool> CheckAsync(CancellationToken cancellationToken)
    {
        var settings = preferences();
        if (!settings.InsertionHelperEnabled) return false;
        if (_policy.Update(readers.Read(), settings)) await application.OpenAsync(cancellationToken);
        return true;
    }
}
