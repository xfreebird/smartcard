using System.Diagnostics;
using Windows.Devices.Enumeration;
using Windows.Devices.SmartCards;

namespace MoldSign.App.Services;

/// <summary>One reader and whether a card sits in it.</summary>
public sealed record ReaderSnapshot(string Name, bool CardPresent);

/// <summary>
/// Windows ReaderMonitor (docs/09 §3.7, WIN-03): <see cref="DeviceWatcher"/> over
/// <c>SmartCardReader.GetDeviceSelector(SmartCardReaderKind.Any)</c> for reader hot-plug, plus
/// <c>SmartCardReader.CardAdded/CardRemoved</c> per reader. Events arrive on thread-pool threads.
/// </summary>
public sealed class ReaderWatcher : IDisposable
{
    private readonly object _gate = new();
    private readonly Dictionary<string, SmartCardReader> _readers = new(StringComparer.Ordinal);
    private DeviceWatcher? _watcher;

    /// <summary>Full snapshot after every change (reader added/removed, card inserted/removed).</summary>
    public event EventHandler<IReadOnlyList<ReaderSnapshot>>? Changed;

    public void Start()
    {
        if (_watcher is not null) return;
        _watcher = DeviceInformation.CreateWatcher(SmartCardReader.GetDeviceSelector(SmartCardReaderKind.Any));
        _watcher.Added += OnReaderAdded;
        _watcher.Removed += OnReaderRemoved;
        _watcher.Updated += OnReaderUpdated;
        _watcher.EnumerationCompleted += OnEnumerationCompleted;
        _watcher.Start();
        // TODO(WIN-03): toast on reader connect/disconnect (AppNotificationManager), honoring AppSettings.ReaderToasts.
    }

    public void Dispose()
    {
        if (_watcher is { } watcher)
        {
            watcher.Added -= OnReaderAdded;
            watcher.Removed -= OnReaderRemoved;
            watcher.Updated -= OnReaderUpdated;
            watcher.EnumerationCompleted -= OnEnumerationCompleted;
            if (watcher.Status is DeviceWatcherStatus.Started or DeviceWatcherStatus.EnumerationCompleted)
                watcher.Stop();
            _watcher = null;
        }
        lock (_gate)
        {
            foreach (var reader in _readers.Values) Detach(reader);
            _readers.Clear();
        }
    }

    private async void OnReaderAdded(DeviceWatcher sender, DeviceInformation info)
    {
        try
        {
            var reader = await SmartCardReader.FromIdAsync(info.Id);
            if (reader is null) return;
            reader.CardAdded += OnCardAdded;
            reader.CardRemoved += OnCardRemoved;
            lock (_gate) _readers[info.Id] = reader;
            await PublishAsync();
        }
        catch (Exception e)
        {
            Debug.WriteLine($"ReaderWatcher: cannot open {info.Name}: {e.Message}");
        }
    }

    private async void OnReaderRemoved(DeviceWatcher sender, DeviceInformationUpdate update)
    {
        lock (_gate)
        {
            if (_readers.Remove(update.Id, out var reader)) Detach(reader);
        }
        await PublishAsync();
    }

    private void OnReaderUpdated(DeviceWatcher sender, DeviceInformationUpdate update)
    {
        // Property changes only; card presence comes from CardAdded/CardRemoved.
    }

    private async void OnEnumerationCompleted(DeviceWatcher sender, object args) => await PublishAsync();

    private async void OnCardAdded(SmartCardReader sender, CardAddedEventArgs args) => await PublishAsync();

    private async void OnCardRemoved(SmartCardReader sender, CardRemovedEventArgs args) => await PublishAsync();

    private void Detach(SmartCardReader reader)
    {
        reader.CardAdded -= OnCardAdded;
        reader.CardRemoved -= OnCardRemoved;
    }

    private async Task PublishAsync()
    {
        SmartCardReader[] readers;
        lock (_gate) readers = [.. _readers.Values];

        var snapshot = new List<ReaderSnapshot>(readers.Length);
        foreach (var reader in readers)
        {
            var present = false;
            try
            {
                var cards = await reader.FindAllCardsAsync();
                present = cards.Count > 0;
            }
            catch (Exception e)
            {
                Debug.WriteLine($"ReaderWatcher: {reader.Name}: {e.Message}");
            }
            snapshot.Add(new ReaderSnapshot(reader.Name, present));
        }

        try
        {
            Changed?.Invoke(this, snapshot);
        }
        catch (Exception e)
        {
            Debug.WriteLine($"ReaderWatcher subscriber failed: {e}");
        }
    }
}
